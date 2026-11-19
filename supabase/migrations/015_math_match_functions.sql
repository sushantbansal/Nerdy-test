-- ============================================================================
-- Migration 015: Server-authoritative match engine
--
-- All timing, correctness, speed bonuses, ranks and persistence happen here.
-- Clients can only submit an answer; they never submit correctness or points.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Achievements and XP
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_unlock_achievement(p_player_id uuid, p_code text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_xp integer;
BEGIN
  INSERT INTO math_player_achievements (player_id, achievement_code)
  VALUES (p_player_id, p_code)
  ON CONFLICT DO NOTHING;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  SELECT xp INTO v_xp FROM math_achievements WHERE code = p_code;
  v_xp := coalesce(v_xp, 0);

  INSERT INTO math_xp_transactions (player_id, amount, reason, reference)
  VALUES (p_player_id, v_xp, 'achievement', 'achievement:' || p_code)
  ON CONFLICT (player_id, reference) DO NOTHING;

  IF FOUND AND v_xp > 0 THEN
    -- Cosmetic progression only. Never used for competitive scoring.
    UPDATE players
    SET xp = xp + v_xp,
        level = 1 + ((xp + v_xp) / 250)
    WHERE id = p_player_id;
  END IF;

  RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION math_unlock_achievement(uuid, text) FROM PUBLIC;

CREATE OR REPLACE FUNCTION math_evaluate_achievements(p_player_id uuid)
RETURNS text[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_unlocked text[] := '{}';
  v_player players%ROWTYPE;
  v_games integer := 0;
  v_perfect integer := 0;
  v_best_accuracy numeric := 0;
  v_speed integer := 0;
  v_topics integer := 0;
  v_days integer := 0;
  v_mastered integer := 0;
  v_practice integer := 0;
BEGIN
  SELECT * INTO v_player FROM players WHERE id = p_player_id;
  IF v_player.id IS NULL THEN
    RETURN v_unlocked;
  END IF;

  SELECT count(*) INTO v_games
  FROM math_match_players mp
  JOIN math_matches m ON m.id = mp.match_id
  WHERE mp.player_id = p_player_id AND m.status = 'completed';

  SELECT count(*) INTO v_perfect
  FROM math_match_players mp
  JOIN math_matches m ON m.id = mp.match_id
  WHERE mp.player_id = p_player_id
    AND m.status = 'completed'
    AND m.question_count >= 5
    AND mp.correct_count = m.question_count;

  SELECT coalesce(max(
    CASE WHEN m.question_count > 0
      THEN mp.correct_count::numeric / m.question_count
      ELSE 0
    END
  ), 0) INTO v_best_accuracy
  FROM math_match_players mp
  JOIN math_matches m ON m.id = mp.match_id
  WHERE mp.player_id = p_player_id
    AND m.status = 'completed'
    AND m.question_count >= 5;

  SELECT coalesce(sum(mp.speed_bonus_count), 0) INTO v_speed
  FROM math_match_players mp
  WHERE mp.player_id = p_player_id;

  SELECT count(DISTINCT topic) INTO v_topics
  FROM math_practice_answers
  WHERE player_id = p_player_id;

  SELECT count(DISTINCT answered_on) INTO v_days
  FROM math_practice_answers
  WHERE player_id = p_player_id;

  SELECT count(*) INTO v_practice
  FROM math_practice_answers
  WHERE player_id = p_player_id;

  SELECT count(*) INTO v_mastered
  FROM math_skill_progress
  WHERE player_id = p_player_id AND mastery = 'mastered';

  IF v_games >= 1
     AND math_unlock_achievement(p_player_id, 'first_match') THEN
    v_unlocked := array_append(v_unlocked, 'first_match');
  END IF;

  IF v_perfect >= 1
     AND math_unlock_achievement(p_player_id, 'perfect_match') THEN
    v_unlocked := array_append(v_unlocked, 'perfect_match');
  END IF;

  IF v_best_accuracy >= 0.8
     AND math_unlock_achievement(p_player_id, 'accuracy_star') THEN
    v_unlocked := array_append(v_unlocked, 'accuracy_star');
  END IF;

  IF v_speed >= 3
     AND math_unlock_achievement(p_player_id, 'speed_champion') THEN
    v_unlocked := array_append(v_unlocked, 'speed_champion');
  END IF;

  IF v_topics >= 3
     AND math_unlock_achievement(p_player_id, 'math_explorer') THEN
    v_unlocked := array_append(v_unlocked, 'math_explorer');
  END IF;

  IF v_days >= 3
     AND math_unlock_achievement(p_player_id, 'consistent_learner') THEN
    v_unlocked := array_append(v_unlocked, 'consistent_learner');
  END IF;

  IF v_mastered >= 1
     AND math_unlock_achievement(p_player_id, 'skill_master') THEN
    v_unlocked := array_append(v_unlocked, 'skill_master');
  END IF;

  IF v_player.best_win_streak >= 5
     AND math_unlock_achievement(p_player_id, 'five_streak') THEN
    v_unlocked := array_append(v_unlocked, 'five_streak');
  END IF;

  IF v_practice >= 10
     AND math_unlock_achievement(p_player_id, 'practice_10') THEN
    v_unlocked := array_append(v_unlocked, 'practice_10');
  END IF;

  IF (v_player.level >= 5 OR (1 + (v_player.xp / 250)) >= 5)
     AND math_unlock_achievement(p_player_id, 'level_5') THEN
    v_unlocked := array_append(v_unlocked, 'level_5');
  END IF;

  RETURN v_unlocked;
END;
$$;

REVOKE ALL ON FUNCTION math_evaluate_achievements(uuid) FROM PUBLIC;

-- ---------------------------------------------------------------------------
-- Close the active question: speed bonus, points, reveal transition
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_close_question_internal(p_match_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_match math_matches%ROWTYPE;
  v_question math_match_questions%ROWTYPE;
  v_now timestamptz;
  v_fastest_player uuid;
  v_fastest_at timestamptz;
  v_tie_count integer;
  v_closed_count integer;
BEGIN
  SELECT * INTO v_match FROM math_matches WHERE id = p_match_id FOR UPDATE;
  IF v_match.id IS NULL OR v_match.status <> 'question_active' THEN
    RETURN;
  END IF;

  SELECT * INTO v_question
  FROM math_match_questions
  WHERE match_id = p_match_id AND position = v_match.question_index
  FOR UPDATE;

  IF v_question.id IS NULL OR v_question.closed_at IS NOT NULL THEN
    RETURN;
  END IF;

  v_now := clock_timestamp();

  UPDATE math_answers
  SET points = CASE WHEN is_correct THEN 1 ELSE 0 END,
      speed_bonus = false
  WHERE match_question_id = v_question.id;

  SELECT a.player_id, a.submitted_at
  INTO v_fastest_player, v_fastest_at
  FROM math_answers a
  WHERE a.match_question_id = v_question.id AND a.is_correct
  ORDER BY a.submitted_at ASC, a.player_id ASC
  LIMIT 1;

  IF v_fastest_player IS NOT NULL AND v_match.speed_bonus_enabled THEN
    SELECT count(*) INTO v_tie_count
    FROM math_answers a
    WHERE a.match_question_id = v_question.id
      AND a.is_correct
      AND a.submitted_at = v_fastest_at;

    IF v_tie_count = 1 THEN
      UPDATE math_answers
      SET points = 2, speed_bonus = true
      WHERE match_question_id = v_question.id
        AND player_id = v_fastest_player;
    END IF;
  END IF;

  UPDATE math_match_questions
  SET closed_at = v_now
  WHERE id = v_question.id;

  SELECT count(*) INTO v_closed_count
  FROM math_match_questions
  WHERE match_id = p_match_id AND closed_at IS NOT NULL;

  UPDATE math_match_players mp
  SET points = coalesce((
        SELECT sum(a.points) FROM math_answers a
        WHERE a.match_id = mp.match_id AND a.player_id = mp.player_id
      ), 0),
      correct_count = coalesce((
        SELECT count(*) FROM math_answers a
        WHERE a.match_id = mp.match_id AND a.player_id = mp.player_id
          AND a.is_correct
      ), 0),
      incorrect_count = coalesce((
        SELECT count(*) FROM math_answers a
        WHERE a.match_id = mp.match_id AND a.player_id = mp.player_id
          AND NOT a.is_correct
      ), 0),
      answered_count = coalesce((
        SELECT count(*) FROM math_answers a
        WHERE a.match_id = mp.match_id AND a.player_id = mp.player_id
      ), 0),
      speed_bonus_count = coalesce((
        SELECT count(*) FROM math_answers a
        WHERE a.match_id = mp.match_id AND a.player_id = mp.player_id
          AND a.speed_bonus
      ), 0),
      total_response_ms = coalesce((
        SELECT sum(a.response_ms) FROM math_answers a
        WHERE a.match_id = mp.match_id AND a.player_id = mp.player_id
          AND a.is_correct
      ), 0),
      unanswered_count = greatest(
        0,
        v_closed_count - coalesce((
          SELECT count(*) FROM math_answers a
          WHERE a.match_id = mp.match_id AND a.player_id = mp.player_id
        ), 0)
      )
  WHERE mp.match_id = p_match_id;

  UPDATE math_matches
  SET status = 'question_reveal',
      reveal_ends_at = v_now + interval '5 seconds'
  WHERE id = p_match_id;

  UPDATE math_rooms
  SET status = 'question_reveal',
      last_activity_at = v_now
  WHERE id = v_match.room_id;
END;
$$;

REVOKE ALL ON FUNCTION math_close_question_internal(uuid) FROM PUBLIC;

-- ---------------------------------------------------------------------------
-- Finalize: ranks, results, stats, XP and achievements (exactly once)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_finalize_match_internal(p_match_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_match math_matches%ROWTYPE;
  v_now timestamptz;
  v_mp math_match_players%ROWTYPE;
  v_xp integer;
  v_new_streak integer;
  v_fastest integer;
  v_new_achievements text[];
BEGIN
  SELECT * INTO v_match FROM math_matches WHERE id = p_match_id FOR UPDATE;
  IF v_match.id IS NULL OR v_match.finalized_at IS NOT NULL THEN
    RETURN;
  END IF;

  v_now := clock_timestamp();

  UPDATE math_match_players mp
  SET unanswered_count = greatest(0, v_match.question_count - mp.answered_count),
      incorrect_count = mp.answered_count - mp.correct_count
  WHERE mp.match_id = p_match_id;

  WITH ranked AS (
    SELECT
      mp.player_id,
      rank() OVER (
        ORDER BY mp.points DESC, mp.correct_count DESC, mp.total_response_ms ASC
      ) AS rnk,
      count(*) OVER (
        PARTITION BY mp.points, mp.correct_count, mp.total_response_ms
      ) AS tie_count
    FROM math_match_players mp
    WHERE mp.match_id = p_match_id
  )
  UPDATE math_match_players mp
  SET rank = ranked.rnk,
      result = CASE
        WHEN ranked.rnk = 1 AND ranked.tie_count > 1 THEN 'draw'::math_match_outcome
        WHEN ranked.rnk = 1 THEN 'win'::math_match_outcome
        ELSE 'loss'::math_match_outcome
      END
  FROM ranked
  WHERE mp.match_id = p_match_id AND mp.player_id = ranked.player_id;

  -- Mark the match completed before evaluating achievements so aggregate
  -- queries see this result. The whole function is one transaction.
  UPDATE math_matches
  SET status = 'completed',
      finalized_at = v_now,
      completed_at = v_now
  WHERE id = p_match_id;

  FOR v_mp IN
    SELECT * FROM math_match_players WHERE match_id = p_match_id
  LOOP
    SELECT min(a.response_ms) INTO v_fastest
    FROM math_answers a
    WHERE a.match_id = p_match_id AND a.player_id = v_mp.player_id AND a.is_correct;

    v_new_streak := CASE
      WHEN v_mp.result = 'win' THEN (
        SELECT current_win_streak + 1 FROM players WHERE id = v_mp.player_id
      )
      WHEN v_mp.result = 'loss' THEN 0
      ELSE (SELECT current_win_streak FROM players WHERE id = v_mp.player_id)
    END;

    UPDATE players
    SET games_played = games_played + 1,
        wins = wins + CASE WHEN v_mp.result = 'win' THEN 1 ELSE 0 END,
        losses = losses + CASE WHEN v_mp.result = 'loss' THEN 1 ELSE 0 END,
        draws = draws + CASE WHEN v_mp.result = 'draw' THEN 1 ELSE 0 END,
        total_points = total_points + v_mp.points,
        best_match_points = greatest(best_match_points, v_mp.points),
        correct_answers = correct_answers + v_mp.correct_count,
        incorrect_answers = incorrect_answers + v_mp.incorrect_count,
        unanswered_count = unanswered_count + v_mp.unanswered_count,
        total_response_ms = total_response_ms + v_mp.total_response_ms,
        fastest_correct_ms = CASE
          WHEN v_fastest IS NULL THEN fastest_correct_ms
          ELSE least(coalesce(fastest_correct_ms, 2147483647), v_fastest)
        END,
        current_win_streak = v_new_streak,
        best_win_streak = greatest(best_win_streak, v_new_streak),
        last_seen_at = v_now
    WHERE id = v_mp.player_id;

    v_xp := 10 + (5 * v_mp.correct_count) + (3 * v_mp.speed_bonus_count);

    INSERT INTO math_xp_transactions (player_id, amount, reason, reference)
    VALUES (v_mp.player_id, v_xp, 'match', 'match:' || p_match_id || ':' || v_mp.player_id)
    ON CONFLICT (player_id, reference) DO NOTHING;

    IF FOUND THEN
      UPDATE players
      SET xp = xp + v_xp,
          level = 1 + ((xp + v_xp) / 250)
      WHERE id = v_mp.player_id;
    END IF;

    v_new_achievements := math_evaluate_achievements(v_mp.player_id);

    UPDATE math_match_players
    SET new_achievements = v_new_achievements
    WHERE match_id = p_match_id AND player_id = v_mp.player_id;
  END LOOP;

  UPDATE math_rooms
  SET status = 'final_results',
      last_activity_at = v_now
  WHERE id = v_match.room_id;
END;
$$;

REVOKE ALL ON FUNCTION math_finalize_match_internal(uuid) FROM PUBLIC;

-- ---------------------------------------------------------------------------
-- Submit one answer (duplicate-safe, deadline-enforced)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_submit_answer(
  p_room_id uuid,
  p_match_question_id uuid,
  p_answer text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_room math_rooms%ROWTYPE;
  v_match math_matches%ROWTYPE;
  v_question math_match_questions%ROWTYPE;
  v_now timestamptz;
  v_answer text;
  v_response_ms integer;
  v_is_correct boolean;
  v_eligible integer;
  v_answered integer;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  PERFORM math_rate_limit('submit_answer', 40, 60);

  SELECT * INTO v_room FROM math_rooms WHERE id = p_room_id FOR UPDATE;
  IF v_room.id IS NULL OR v_room.current_match_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'match_not_active');
  END IF;
  IF NOT math_is_room_member(p_room_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'not_in_room');
  END IF;

  SELECT * INTO v_match FROM math_matches WHERE id = v_room.current_match_id FOR UPDATE;
  IF v_match.status <> 'question_active' THEN
    RETURN jsonb_build_object('success', false, 'error', 'question_closed');
  END IF;

  SELECT * INTO v_question
  FROM math_match_questions
  WHERE id = p_match_question_id
    AND match_id = v_match.id
    AND position = v_match.question_index;

  IF v_question.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'invalid_question');
  END IF;

  v_now := clock_timestamp();
  IF v_now >= v_match.question_ends_at THEN
    RETURN jsonb_build_object('success', false, 'error', 'time_up');
  END IF;

  IF EXISTS (
    SELECT 1 FROM math_answers
    WHERE match_question_id = v_question.id AND player_id = v_player
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'already_answered');
  END IF;

  v_answer := trim(coalesce(p_answer, ''));
  IF char_length(v_answer) = 0 OR char_length(v_answer) > 40 THEN
    RETURN jsonb_build_object('success', false, 'error', 'invalid_answer');
  END IF;
  IF NOT (v_answer = ANY(v_question.options)) THEN
    RETURN jsonb_build_object('success', false, 'error', 'invalid_answer');
  END IF;

  v_response_ms := greatest(
    0,
    floor(extract(epoch FROM (v_now - v_match.question_started_at)) * 1000)::integer
  );
  v_is_correct := lower(v_answer) = lower(v_question.correct_answer);

  INSERT INTO math_answers (
    match_id, match_question_id, player_id, question_position, answer,
    is_correct, submitted_at, response_ms, points, speed_bonus
  ) VALUES (
    v_match.id, v_question.id, v_player, v_question.position, v_answer,
    v_is_correct, v_now, v_response_ms, 0, false
  )
  ON CONFLICT (match_question_id, player_id) DO NOTHING;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'already_answered');
  END IF;

  SELECT count(*) INTO v_eligible
  FROM math_room_players rp
  JOIN math_match_players mp
    ON mp.match_id = v_match.id AND mp.player_id = rp.player_id
  WHERE rp.room_id = p_room_id AND rp.left_at IS NULL;

  SELECT count(*) INTO v_answered
  FROM math_answers a
  JOIN math_room_players rp ON rp.player_id = a.player_id
  WHERE a.match_question_id = v_question.id
    AND rp.room_id = p_room_id
    AND rp.left_at IS NULL;

  IF v_eligible > 0 AND v_answered >= v_eligible THEN
    PERFORM math_close_question_internal(v_match.id);
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'submitted', true,
    'answered_at', v_now,
    'response_ms', v_response_ms
  );
END;
$$;

REVOKE ALL ON FUNCTION math_submit_answer(uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_submit_answer(uuid, uuid, text) TO authenticated;

-- ---------------------------------------------------------------------------
-- Server clock / lifecycle tick
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_advance_match(p_room_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_room math_rooms%ROWTYPE;
  v_match math_matches%ROWTYPE;
  v_now timestamptz;
  v_eligible integer;
  v_answered integer;
  v_new_index integer;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  SELECT * INTO v_room FROM math_rooms WHERE id = p_room_id FOR UPDATE;
  IF v_room.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'room_not_found');
  END IF;
  IF NOT math_is_room_member(p_room_id) AND NOT (
    v_room.current_match_id IS NOT NULL
    AND math_is_match_participant(v_room.current_match_id)
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'not_in_room');
  END IF;

  IF v_room.status = 'waiting' THEN
    IF v_room.auto_start THEN
      PERFORM math_try_autostart(p_room_id);
      SELECT * INTO v_room FROM math_rooms WHERE id = p_room_id;
    END IF;
    RETURN jsonb_build_object(
      'success', true,
      'status', v_room.status,
      'server_now', clock_timestamp()
    );
  END IF;

  IF v_room.current_match_id IS NULL THEN
    RETURN jsonb_build_object('success', true, 'status', v_room.status, 'server_now', clock_timestamp());
  END IF;

  SELECT * INTO v_match FROM math_matches WHERE id = v_room.current_match_id FOR UPDATE;
  IF v_match.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'match_not_found');
  END IF;

  v_now := clock_timestamp();

  IF v_match.status = 'countdown' THEN
    IF v_now >= v_match.countdown_ends_at THEN
      UPDATE math_matches
      SET status = 'question_active',
          question_index = 1,
          question_started_at = v_now,
          question_ends_at = v_now + make_interval(secs => v_match.answer_seconds),
          reveal_ends_at = NULL,
          next_starts_at = NULL
      WHERE id = v_match.id;

      UPDATE math_rooms
      SET status = 'question_active', last_activity_at = v_now
      WHERE id = p_room_id;
    END IF;
  ELSIF v_match.status = 'question_active' THEN
    SELECT count(*) INTO v_eligible
    FROM math_room_players rp
    JOIN math_match_players mp
      ON mp.match_id = v_match.id AND mp.player_id = rp.player_id
    WHERE rp.room_id = p_room_id AND rp.left_at IS NULL;

    SELECT count(*) INTO v_answered
    FROM math_answers a
    JOIN math_room_players rp ON rp.player_id = a.player_id
    WHERE a.match_id = v_match.id
      AND a.question_position = v_match.question_index
      AND rp.room_id = p_room_id
      AND rp.left_at IS NULL;

    IF v_now >= v_match.question_ends_at
       OR (v_eligible > 0 AND v_answered >= v_eligible) THEN
      PERFORM math_close_question_internal(v_match.id);
    END IF;
  ELSIF v_match.status = 'question_reveal' THEN
    IF v_now >= v_match.reveal_ends_at THEN
      IF v_match.question_index < v_match.question_count THEN
        UPDATE math_matches
        SET status = 'next_question',
            next_starts_at = v_now + interval '1500 milliseconds'
        WHERE id = v_match.id;
        UPDATE math_rooms
        SET status = 'next_question', last_activity_at = v_now
        WHERE id = p_room_id;
      ELSE
        PERFORM math_finalize_match_internal(v_match.id);
      END IF;
    END IF;
  ELSIF v_match.status = 'next_question' THEN
    IF v_now >= v_match.next_starts_at THEN
      v_new_index := v_match.question_index + 1;
      UPDATE math_matches
      SET status = 'question_active',
          question_index = v_new_index,
          question_started_at = v_now,
          question_ends_at = v_now + make_interval(secs => v_match.answer_seconds),
          reveal_ends_at = NULL,
          next_starts_at = NULL
      WHERE id = v_match.id;

      UPDATE math_rooms
      SET status = 'question_active', last_activity_at = v_now
      WHERE id = p_room_id;
    END IF;
  END IF;

  SELECT * INTO v_room FROM math_rooms WHERE id = p_room_id;
  SELECT * INTO v_match FROM math_matches WHERE id = v_room.current_match_id;

  RETURN jsonb_build_object(
    'success', true,
    'status', v_room.status,
    'match_status', v_match.status,
    'question_index', v_match.question_index,
    'server_now', clock_timestamp()
  );
END;
$$;

REVOKE ALL ON FUNCTION math_advance_match(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_advance_match(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- Authorized state snapshot
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_room_state(p_room_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_room math_rooms%ROWTYPE;
  v_match math_matches%ROWTYPE;
  v_has_match boolean := false;
  v_question math_match_questions%ROWTYPE;
  v_has_question boolean := false;
  v_players jsonb := '[]'::jsonb;
  v_leaderboard jsonb := '[]'::jsonb;
  v_my_answer jsonb := NULL;
  v_reveal jsonb := NULL;
  v_final jsonb := NULL;
  v_question_json jsonb := NULL;
  v_room_json jsonb;
  v_active_count integer;
  v_my_new_achievements text[] := '{}';
  v_is_member boolean;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  SELECT * INTO v_room FROM math_rooms WHERE id = p_room_id;
  IF v_room.id IS NULL THEN
    RAISE EXCEPTION 'Room not found';
  END IF;

  v_is_member := math_is_room_member(p_room_id);

  IF v_room.current_match_id IS NOT NULL THEN
    SELECT * INTO v_match FROM math_matches WHERE id = v_room.current_match_id;
    v_has_match := v_match.id IS NOT NULL;
  END IF;

  IF NOT v_is_member AND NOT (
    v_has_match AND math_is_match_participant(v_match.id)
  ) THEN
    RAISE EXCEPTION 'You are not in this room';
  END IF;

  SELECT count(*) INTO v_active_count
  FROM math_room_players
  WHERE room_id = p_room_id AND left_at IS NULL;

  SELECT coalesce(jsonb_agg(
    jsonb_build_object(
      'player_id', rp.player_id,
      'display_name', rp.display_name,
      'avatar_index', rp.avatar_index,
      'avatar_color', rp.avatar_color,
      'seat', rp.seat,
      'is_ready', rp.is_ready,
      'is_connected', rp.is_connected,
      'is_host', rp.player_id = v_room.host_id,
      'points', coalesce(mp.points, 0),
      'correct_count', coalesce(mp.correct_count, 0),
      'speed_bonus_count', coalesce(mp.speed_bonus_count, 0),
      'submitted_current', (
        v_has_match AND v_match.question_index > 0 AND EXISTS (
          SELECT 1 FROM math_answers a
          WHERE a.match_id = v_match.id
            AND a.player_id = rp.player_id
            AND a.question_position = v_match.question_index
        )
      )
    ) ORDER BY rp.seat
  ), '[]'::jsonb)
  INTO v_players
  FROM math_room_players rp
  LEFT JOIN math_match_players mp
    ON v_has_match AND mp.match_id = v_match.id AND mp.player_id = rp.player_id
  WHERE rp.room_id = p_room_id AND rp.left_at IS NULL;

  IF v_has_match THEN
    SELECT coalesce(jsonb_agg(
      jsonb_build_object(
        'player_id', ranked.player_id,
        'display_name', ranked.display_name,
        'avatar_index', ranked.avatar_index,
        'avatar_color', ranked.avatar_color,
        'points', ranked.points,
        'correct_count', ranked.correct_count,
        'speed_bonus_count', ranked.speed_bonus_count,
        'rank', ranked.live_rank
      ) ORDER BY ranked.live_rank, ranked.points DESC
    ), '[]'::jsonb)
    INTO v_leaderboard
    FROM (
      SELECT
        mp.*,
        coalesce(
          mp.rank,
          row_number() OVER (
            ORDER BY mp.points DESC, mp.correct_count DESC,
                     mp.total_response_ms ASC, mp.seat ASC
          )
        ) AS live_rank
      FROM math_match_players mp
      WHERE mp.match_id = v_match.id
    ) AS ranked;
  END IF;

  IF v_has_match
     AND v_match.question_index > 0
     AND v_match.status IN ('question_active', 'question_reveal') THEN
    SELECT * INTO v_question
    FROM math_match_questions
    WHERE match_id = v_match.id AND position = v_match.question_index;
    v_has_question := v_question.id IS NOT NULL;

    IF v_has_question THEN
      v_question_json := jsonb_build_object(
        'id', v_question.id,
        'position', v_question.position,
        'text', v_question.question_text,
        'options', v_question.options,
        'answer_type', v_question.answer_type,
        'topic', v_question.topic,
        'skill', v_question.skill,
        'difficulty', v_question.difficulty,
        'estimated_seconds', v_question.estimated_seconds,
        'visual', v_question.visual
      );

      IF v_match.status = 'question_reveal' THEN
        v_question_json := v_question_json || jsonb_build_object(
          'correct_answer', v_question.correct_answer,
          'explanation', v_question.explanation
        );
      END IF;
    END IF;

    SELECT jsonb_build_object(
      'answer', a.answer,
      'submitted_at', a.submitted_at,
      'response_ms', a.response_ms,
      'is_correct', CASE WHEN v_match.status = 'question_reveal' THEN a.is_correct ELSE NULL END,
      'points', CASE WHEN v_match.status = 'question_reveal' THEN a.points ELSE NULL END,
      'speed_bonus', CASE WHEN v_match.status = 'question_reveal' THEN a.speed_bonus ELSE NULL END
    )
    INTO v_my_answer
    FROM math_answers a
    WHERE a.match_id = v_match.id
      AND a.match_question_id = v_question.id
      AND a.player_id = v_player;
  END IF;

  IF v_has_match
     AND v_has_question
     AND v_match.status = 'question_reveal' THEN
    v_reveal := jsonb_build_object(
      'correct_answer', v_question.correct_answer,
      'explanation', v_question.explanation,
      'speed_bonus_withheld_for_tie', (
        EXISTS (
          SELECT 1 FROM math_answers a
          WHERE a.match_question_id = v_question.id AND a.is_correct
        )
        AND NOT EXISTS (
          SELECT 1 FROM math_answers a
          WHERE a.match_question_id = v_question.id AND a.speed_bonus
        )
      ),
      'fastest_player_id', (
        SELECT a.player_id FROM math_answers a
        WHERE a.match_question_id = v_question.id AND a.speed_bonus
        LIMIT 1
      ),
      'fastest_player_name', (
        SELECT mp.display_name
        FROM math_answers a
        JOIN math_match_players mp ON mp.match_id = a.match_id AND mp.player_id = a.player_id
        WHERE a.match_question_id = v_question.id AND a.speed_bonus
        LIMIT 1
      ),
      'results', (
        SELECT coalesce(jsonb_agg(
          jsonb_build_object(
            'player_id', rp.player_id,
            'display_name', rp.display_name,
            'answer', a.answer,
            'is_correct', coalesce(a.is_correct, false),
            'points', coalesce(a.points, 0),
            'speed_bonus', coalesce(a.speed_bonus, false),
            'response_ms', a.response_ms,
            'submitted', a.id IS NOT NULL
          ) ORDER BY coalesce(a.points, 0) DESC, coalesce(a.response_ms, 999999) ASC
        ), '[]'::jsonb)
        FROM math_room_players rp
        LEFT JOIN math_answers a
          ON a.match_id = v_match.id
          AND a.match_question_id = v_question.id
          AND a.player_id = rp.player_id
        WHERE rp.room_id = p_room_id AND rp.left_at IS NULL
      )
    );
  END IF;

  IF v_has_match AND v_room.status IN ('final_results', 'completed') THEN
    SELECT mp.new_achievements INTO v_my_new_achievements
    FROM math_match_players mp
    WHERE mp.match_id = v_match.id AND mp.player_id = v_player;

    v_final := jsonb_build_object(
      'standings', (
        SELECT coalesce(jsonb_agg(
          jsonb_build_object(
            'player_id', mp.player_id,
            'display_name', mp.display_name,
            'avatar_index', mp.avatar_index,
            'avatar_color', mp.avatar_color,
            'points', mp.points,
            'correct_count', mp.correct_count,
            'question_count', v_match.question_count,
            'speed_bonus_count', mp.speed_bonus_count,
            'total_response_ms', mp.total_response_ms,
            'rank', mp.rank,
            'result', mp.result,
            'new_achievements', mp.new_achievements
          ) ORDER BY coalesce(mp.rank, 999), mp.points DESC
        ), '[]'::jsonb)
        FROM math_match_players mp
        WHERE mp.match_id = v_match.id
      ),
      'review', (
        SELECT coalesce(jsonb_agg(
          jsonb_build_object(
            'position', q.position,
            'question_text', q.question_text,
            'options', q.options,
            'correct_answer', q.correct_answer,
            'explanation', q.explanation,
            'visual', q.visual,
            'topic', q.topic,
            'my_answer', a.answer,
            'my_is_correct', coalesce(a.is_correct, false)
          ) ORDER BY q.position
        ), '[]'::jsonb)
        FROM math_match_questions q
        LEFT JOIN math_answers a
          ON a.match_id = q.match_id
          AND a.match_question_id = q.id
          AND a.player_id = v_player
        WHERE q.match_id = v_match.id
      )
    );
  END IF;

  v_room_json := jsonb_build_object(
    'id', v_room.id,
    'room_code', v_room.room_code,
    'name', v_room.name,
    'host_id', v_room.host_id,
    'visibility', v_room.visibility,
    'grade', v_room.grade,
    'topics', to_jsonb(v_room.topics),
    'difficulty', v_room.difficulty,
    'question_count', v_room.question_count,
    'answer_seconds', v_room.answer_seconds,
    'max_players', v_room.max_players,
    'speed_bonus_enabled', v_room.speed_bonus_enabled,
    'auto_start', v_room.auto_start,
    'status', v_room.status,
    'countdown_ends_at', v_room.countdown_ends_at,
    'created_at', v_room.created_at,
    'is_host', v_room.host_id = v_player,
    'my_ready', (
      SELECT coalesce(bool_or(is_ready), false)
      FROM math_room_players
      WHERE room_id = p_room_id AND player_id = v_player AND left_at IS NULL
    ),
    'can_start', (
      v_room.host_id = v_player
      AND v_room.status = 'waiting'
      AND v_active_count >= 2
    )
  );

  RETURN jsonb_build_object(
    'server_now', clock_timestamp(),
    'room', v_room_json,
    'players', v_players,
    'match', CASE WHEN v_has_match THEN jsonb_build_object(
      'id', v_match.id,
      'match_number', v_match.match_number,
      'status', v_match.status,
      'question_index', v_match.question_index,
      'question_count', v_match.question_count,
      'answer_seconds', v_match.answer_seconds,
      'speed_bonus_enabled', v_match.speed_bonus_enabled,
      'countdown_ends_at', v_match.countdown_ends_at,
      'question_started_at', v_match.question_started_at,
      'question_ends_at', v_match.question_ends_at,
      'reveal_ends_at', v_match.reveal_ends_at,
      'next_starts_at', v_match.next_starts_at,
      'started_at', v_match.started_at,
      'completed_at', v_match.completed_at
    ) ELSE NULL END,
    'question', v_question_json,
    'my_answer', v_my_answer,
    'reveal', v_reveal,
    'leaderboard', v_leaderboard,
    'final_results', v_final,
    'my_new_achievements', to_jsonb(v_my_new_achievements)
  );
END;
$$;

REVOKE ALL ON FUNCTION math_room_state(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_room_state(uuid) TO authenticated;
