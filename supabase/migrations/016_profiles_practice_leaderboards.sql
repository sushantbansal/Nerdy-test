-- ============================================================================
-- Migration 016: Profiles, practice, leaderboards and account lifecycle
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Preserve match history when a host or room is deleted (account deletion).
-- ---------------------------------------------------------------------------
ALTER TABLE math_rooms DROP CONSTRAINT IF EXISTS math_rooms_host_id_fkey;
ALTER TABLE math_rooms ALTER COLUMN host_id DROP NOT NULL;
ALTER TABLE math_rooms
  ADD CONSTRAINT math_rooms_host_id_fkey
  FOREIGN KEY (host_id) REFERENCES players(id) ON DELETE SET NULL;

ALTER TABLE math_matches DROP CONSTRAINT IF EXISTS math_matches_room_id_fkey;
ALTER TABLE math_matches ALTER COLUMN room_id DROP NOT NULL;
ALTER TABLE math_matches
  ADD CONSTRAINT math_matches_room_id_fkey
  FOREIGN KEY (room_id) REFERENCES math_rooms(id) ON DELETE SET NULL;

-- Practice submissions are idempotent per client attempt.
ALTER TABLE math_practice_answers
  ADD COLUMN IF NOT EXISTS attempt_id uuid NOT NULL DEFAULT gen_random_uuid();

CREATE UNIQUE INDEX IF NOT EXISTS idx_math_practice_attempt
  ON math_practice_answers (player_id, attempt_id);

-- ---------------------------------------------------------------------------
-- Profile update (validated, rate limited)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_update_profile(
  p_display_name text,
  p_avatar_index integer DEFAULT NULL,
  p_avatar_color text DEFAULT NULL,
  p_grade integer DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_name text;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  PERFORM math_rate_limit('update_profile', 10, 60);

  v_name := regexp_replace(trim(coalesce(p_display_name, '')), '\s+', ' ', 'g');

  IF char_length(v_name) < 2 OR char_length(v_name) > 20 THEN
    RAISE EXCEPTION 'Display names must be between 2 and 20 characters';
  END IF;
  IF v_name !~ '^[A-Za-z0-9][A-Za-z0-9 ._''-]*$' THEN
    RAISE EXCEPTION 'Use letters, numbers, spaces, dots, dashes or apostrophes only';
  END IF;
  IF v_name ~* '(https?://|www\.|@)' THEN
    RAISE EXCEPTION 'Display names cannot contain links or contact details';
  END IF;

  IF p_avatar_index IS NOT NULL AND (p_avatar_index < 0 OR p_avatar_index > 11) THEN
    RAISE EXCEPTION 'Choose a valid avatar';
  END IF;
  IF p_avatar_color IS NOT NULL
     AND p_avatar_color !~ '^#[0-9A-Fa-f]{6}$' THEN
    RAISE EXCEPTION 'Choose a valid avatar color';
  END IF;
  IF p_grade IS NOT NULL AND (p_grade < 0 OR p_grade > 5) THEN
    RAISE EXCEPTION 'Choose a grade between Kindergarten and Grade 5';
  END IF;

  UPDATE players
  SET display_name = v_name,
      avatar_index = coalesce(p_avatar_index, avatar_index),
      avatar_color = coalesce(p_avatar_color, avatar_color),
      grade = coalesce(p_grade::smallint, grade),
      last_seen_at = clock_timestamp()
  WHERE id = v_player;

  -- Keep waiting-room identity fresh. Match snapshots never change mid-match.
  UPDATE math_room_players
  SET display_name = v_name,
      avatar_index = coalesce(p_avatar_index, avatar_index),
      avatar_color = coalesce(p_avatar_color, avatar_color)
  WHERE player_id = v_player AND left_at IS NULL;

  RETURN jsonb_build_object('success', true, 'display_name', v_name);
END;
$$;

REVOKE ALL ON FUNCTION math_update_profile(text, integer, text, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_update_profile(text, integer, text, integer) TO authenticated;

CREATE OR REPLACE FUNCTION math_update_settings(
  p_sound_enabled boolean DEFAULT NULL,
  p_reduced_motion boolean DEFAULT NULL,
  p_leaderboard_visible boolean DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  PERFORM math_rate_limit('update_settings', 20, 60);

  UPDATE players
  SET sound_enabled = coalesce(p_sound_enabled, sound_enabled),
      reduced_motion = coalesce(p_reduced_motion, reduced_motion),
      leaderboard_visible = coalesce(p_leaderboard_visible, leaderboard_visible),
      last_seen_at = clock_timestamp()
  WHERE id = v_player;

  RETURN jsonb_build_object('success', true);
END;
$$;

REVOKE ALL ON FUNCTION math_update_settings(boolean, boolean, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_update_settings(boolean, boolean, boolean) TO authenticated;

-- ---------------------------------------------------------------------------
-- Profile read model
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_profile(p_player_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_target uuid;
  v_is_me boolean;
  v_p players%ROWTYPE;
  v_achievements jsonb := '[]'::jsonb;
  v_skills jsonb := '[]'::jsonb;
  v_matches jsonb := '[]'::jsonb;
  v_rank integer;
  v_answered integer;
  v_accuracy numeric;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  v_target := coalesce(p_player_id, v_player);
  v_is_me := v_target = v_player;

  SELECT * INTO v_p
  FROM players
  WHERE id = v_target AND is_deleted = false;

  IF v_p.id IS NULL THEN
    RAISE EXCEPTION 'Player not found';
  END IF;

  v_answered := v_p.correct_answers + v_p.incorrect_answers;
  v_accuracy := CASE
    WHEN v_answered > 0 THEN round(100.0 * v_p.correct_answers / v_answered, 1)
    ELSE 0
  END;

  SELECT coalesce(jsonb_agg(
    jsonb_build_object(
      'code', a.code,
      'title', a.title,
      'description', a.description,
      'icon', a.icon,
      'xp', a.xp,
      'unlocked_at', pa.unlocked_at
    ) ORDER BY pa.unlocked_at DESC
  ), '[]'::jsonb)
  INTO v_achievements
  FROM math_player_achievements pa
  JOIN math_achievements a ON a.code = pa.achievement_code
  WHERE pa.player_id = v_target;

  SELECT coalesce(jsonb_agg(
    jsonb_build_object(
      'grade', sp.grade,
      'topic', sp.topic,
      'skill', sp.skill,
      'attempts', sp.attempts,
      'correct', sp.correct,
      'consecutive_correct', sp.consecutive_correct,
      'mastery', sp.mastery,
      'xp', sp.xp,
      'last_practiced_at', sp.last_practiced_at
    ) ORDER BY sp.mastery DESC, sp.attempts DESC
  ), '[]'::jsonb)
  INTO v_skills
  FROM math_skill_progress sp
  WHERE sp.player_id = v_target;

  SELECT coalesce(jsonb_agg(
    jsonb_build_object(
      'match_id', recent.match_id,
      'completed_at', recent.completed_at,
      'grade', recent.grade,
      'topics', recent.topics,
      'question_count', recent.question_count,
      'player_count', recent.player_count,
      'points', recent.points,
      'correct_count', recent.correct_count,
      'speed_bonus_count', recent.speed_bonus_count,
      'total_response_ms', recent.total_response_ms,
      'rank', recent.rank,
      'result', recent.result
    ) ORDER BY recent.completed_at DESC
  ), '[]'::jsonb)
  INTO v_matches
  FROM (
    SELECT
      m.id AS match_id,
      m.completed_at,
      m.grade,
      to_jsonb(m.topics) AS topics,
      m.question_count,
      mp.points,
      mp.correct_count,
      mp.speed_bonus_count,
      mp.total_response_ms,
      mp.rank,
      mp.result,
      (
        SELECT count(*) FROM math_match_players x WHERE x.match_id = m.id
      ) AS player_count
    FROM math_match_players mp
    JOIN math_matches m ON m.id = mp.match_id
    WHERE mp.player_id = v_target AND m.status = 'completed'
    ORDER BY m.completed_at DESC
    LIMIT 10
  ) AS recent;

  SELECT r.rnk INTO v_rank
  FROM (
    SELECT
      aggregated.player_id,
      rank() OVER (
        ORDER BY aggregated.points DESC,
                 aggregated.wins DESC,
                 aggregated.accuracy DESC,
                 aggregated.player_id
      ) AS rnk
    FROM (
      SELECT
        mp.player_id,
        sum(mp.points)::bigint AS points,
        count(*) FILTER (WHERE mp.result = 'win') AS wins,
        CASE
          WHEN sum(mp.answered_count) > 0
            THEN sum(mp.correct_count)::numeric / sum(mp.answered_count)
          ELSE 0
        END AS accuracy
      FROM math_match_players mp
      JOIN math_matches m ON m.id = mp.match_id
      JOIN players pl ON pl.id = mp.player_id
      WHERE m.status = 'completed'
        AND pl.leaderboard_visible = true
        AND pl.is_deleted = false
      GROUP BY mp.player_id
      HAVING count(*) >= 3
    ) AS aggregated
  ) AS r
  WHERE r.player_id = v_target;

  RETURN jsonb_build_object(
    'id', v_p.id,
    'display_name', v_p.display_name,
    'avatar_index', v_p.avatar_index,
    'avatar_color', v_p.avatar_color,
    'grade', v_p.grade,
    'is_me', v_is_me,
    'level', v_p.level,
    'xp', v_p.xp,
    'xp_to_next', (v_p.level * 250) - v_p.xp,
    'games_played', v_p.games_played,
    'wins', v_p.wins,
    'losses', v_p.losses,
    'draws', v_p.draws,
    'win_rate', CASE
      WHEN v_p.games_played > 0
        THEN round(100.0 * v_p.wins / v_p.games_played, 1)
      ELSE 0
    END,
    'total_points', v_p.total_points,
    'average_points', CASE
      WHEN v_p.games_played > 0
        THEN round(v_p.total_points::numeric / v_p.games_played, 1)
      ELSE 0
    END,
    'best_match_points', v_p.best_match_points,
    'correct_answers', v_p.correct_answers,
    'incorrect_answers', v_p.incorrect_answers,
    'unanswered_count', v_p.unanswered_count,
    'accuracy', v_accuracy,
    'average_response_ms', CASE
      WHEN v_p.correct_answers > 0
        THEN round(v_p.total_response_ms::numeric / v_p.correct_answers)
      ELSE 0
    END,
    'fastest_correct_ms', v_p.fastest_correct_ms,
    'current_win_streak', v_p.current_win_streak,
    'best_win_streak', v_p.best_win_streak,
    'practice_questions', v_p.practice_questions,
    'practice_correct', v_p.practice_correct,
    'practice_streak', v_p.practice_streak,
    'best_practice_streak', v_p.best_practice_streak,
    'last_practice_on', v_p.last_practice_on,
    'leaderboard_visible', CASE WHEN v_is_me THEN v_p.leaderboard_visible END,
    'sound_enabled', CASE WHEN v_is_me THEN v_p.sound_enabled END,
    'reduced_motion', CASE WHEN v_is_me THEN v_p.reduced_motion END,
    'leaderboard_rank', v_rank,
    'member_since', v_p.created_at,
    'achievements', v_achievements,
    'skills', v_skills,
    'recent_matches', v_matches
  );
END;
$$;

REVOKE ALL ON FUNCTION math_profile(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_profile(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION math_achievement_catalogue()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT coalesce(jsonb_agg(
    jsonb_build_object(
      'code', a.code,
      'title', a.title,
      'description', a.description,
      'icon', a.icon,
      'xp', a.xp,
      'unlocked_at', pa.unlocked_at
    ) ORDER BY a.sort_order
  ), '[]'::jsonb)
  FROM math_achievements a
  LEFT JOIN math_player_achievements pa
    ON pa.achievement_code = a.code AND pa.player_id = auth.uid();
$$;

REVOKE ALL ON FUNCTION math_achievement_catalogue() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_achievement_catalogue() TO authenticated;

CREATE OR REPLACE FUNCTION math_my_active_room()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT jsonb_build_object(
    'room_id', r.id,
    'room_code', r.room_code,
    'name', r.name,
    'status', r.status,
    'grade', r.grade
  )
  FROM math_room_players rp
  JOIN math_rooms r ON r.id = rp.room_id
  WHERE rp.player_id = auth.uid()
    AND rp.left_at IS NULL
    AND r.status NOT IN ('completed', 'abandoned')
  ORDER BY r.last_activity_at DESC
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION math_my_active_room() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_my_active_room() TO authenticated;

-- ---------------------------------------------------------------------------
-- Practice mode: adaptive question selection and authoritative validation
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_mastery_for(
  p_attempts integer,
  p_correct integer,
  p_consecutive integer
)
RETURNS math_mastery
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_attempts <= 0 THEN 'not_started'::math_mastery
    WHEN p_attempts >= 15
      AND p_correct::numeric / p_attempts >= 0.85
      AND p_consecutive >= 5 THEN 'mastered'::math_mastery
    WHEN p_attempts >= 10
      AND p_correct::numeric / p_attempts >= 0.75 THEN 'proficient'::math_mastery
    WHEN p_attempts >= 5
      AND p_correct::numeric / p_attempts >= 0.60 THEN 'practicing'::math_mastery
    ELSE 'learning'::math_mastery
  END;
$$;

REVOKE ALL ON FUNCTION math_mastery_for(integer, integer, integer) FROM PUBLIC;

CREATE OR REPLACE FUNCTION math_next_practice_question(
  p_grade integer,
  p_topic math_topic DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_topic math_topic;
  v_mastery math_mastery;
  v_difficulty math_difficulty;
  v_question math_questions%ROWTYPE;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;
  IF p_grade < 0 OR p_grade > 5 THEN
    RAISE EXCEPTION 'Choose a grade between Kindergarten and Grade 5';
  END IF;

  PERFORM math_rate_limit('practice_question', 120, 60);

  v_topic := p_topic;

  IF v_topic IS NULL THEN
    SELECT sp.topic INTO v_topic
    FROM math_skill_progress sp
    WHERE sp.player_id = v_player
      AND sp.grade = p_grade
      AND sp.attempts > 0
    ORDER BY sp.mastery ASC,
             CASE WHEN sp.attempts > 0
               THEN sp.correct::numeric / sp.attempts ELSE 1 END ASC,
             sp.last_practiced_at ASC
    LIMIT 1;
  END IF;

  IF v_topic IS NULL THEN
    SELECT t INTO v_topic
    FROM unnest(ARRAY[
      'addition', 'subtraction', 'place_value', 'multiplication',
      'division', 'fractions', 'geometry', 'measurement'
    ]::math_topic[]) AS t
    ORDER BY random()
    LIMIT 1;
  END IF;

  SELECT sp.mastery INTO v_mastery
  FROM math_skill_progress sp
  WHERE sp.player_id = v_player
    AND sp.grade = p_grade
    AND sp.topic = v_topic
  ORDER BY sp.attempts DESC
  LIMIT 1;

  v_difficulty := CASE coalesce(v_mastery, 'not_started'::math_mastery)
    WHEN 'not_started' THEN 'easy'::math_difficulty
    WHEN 'learning' THEN 'easy'::math_difficulty
    WHEN 'practicing' THEN 'medium'::math_difficulty
    ELSE 'hard'::math_difficulty
  END;

  SELECT * INTO v_question
  FROM math_questions q
  WHERE q.is_active AND q.grade = p_grade AND q.topic = v_topic
    AND q.difficulty = v_difficulty
  ORDER BY random()
  LIMIT 1;

  IF v_question.id IS NULL THEN
    SELECT * INTO v_question
    FROM math_questions q
    WHERE q.is_active AND q.grade = p_grade AND q.topic = v_topic
    ORDER BY random()
    LIMIT 1;
  END IF;

  IF v_question.id IS NULL THEN
    SELECT * INTO v_question
    FROM math_questions q
    WHERE q.is_active AND q.grade = p_grade
    ORDER BY random()
    LIMIT 1;
  END IF;

  IF v_question.id IS NULL THEN
    RAISE EXCEPTION 'No practice questions are available for this grade yet';
  END IF;

  RETURN jsonb_build_object(
    'id', v_question.id,
    'grade', v_question.grade,
    'topic', v_question.topic,
    'skill', v_question.skill,
    'difficulty', v_question.difficulty,
    'text', v_question.question_text,
    'options', v_question.options,
    'answer_type', v_question.answer_type,
    'hint', v_question.hint,
    'visual', v_question.visual,
    'estimated_seconds', v_question.estimated_seconds
  );
END;
$$;

REVOKE ALL ON FUNCTION math_next_practice_question(integer, math_topic) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_next_practice_question(integer, math_topic) TO authenticated;

CREATE OR REPLACE FUNCTION math_submit_practice_answer(
  p_question_id uuid,
  p_answer text,
  p_attempt_id uuid,
  p_used_hint boolean DEFAULT false,
  p_elapsed_ms integer DEFAULT 0
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_question math_questions%ROWTYPE;
  v_answer text;
  v_is_correct boolean;
  v_xp integer;
  v_today date := current_date;
  v_last date;
  v_streak integer;
  v_attempts integer;
  v_correct integer;
  v_consecutive integer;
  v_mastery math_mastery;
  v_new_achievements text[] := '{}';
  v_practice_count integer;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  PERFORM math_rate_limit('practice_answer', 120, 60);

  SELECT * INTO v_question FROM math_questions WHERE id = p_question_id;
  IF v_question.id IS NULL THEN
    RAISE EXCEPTION 'Question not found';
  END IF;

  v_answer := trim(coalesce(p_answer, ''));
  IF v_answer = '' OR NOT (v_answer = ANY(v_question.options)) THEN
    RAISE EXCEPTION 'Choose one of the available answers';
  END IF;

  INSERT INTO math_practice_answers (
    player_id, question_id, grade, topic, skill, answer, is_correct,
    used_hint, elapsed_ms, answered_on, attempt_id
  ) VALUES (
    v_player, v_question.id, v_question.grade, v_question.topic,
    v_question.skill, v_answer,
    lower(v_answer) = lower(v_question.correct_answer),
    p_used_hint, greatest(0, least(p_elapsed_ms, 600000)), v_today,
    p_attempt_id
  )
  ON CONFLICT (player_id, attempt_id) DO NOTHING;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'already_submitted');
  END IF;

  v_is_correct := lower(v_answer) = lower(v_question.correct_answer);

  INSERT INTO math_skill_progress (
    player_id, grade, topic, skill, attempts, correct, consecutive_correct,
    mastery, xp, last_practiced_at
  ) VALUES (
    v_player, v_question.grade, v_question.topic, v_question.skill,
    1, CASE WHEN v_is_correct THEN 1 ELSE 0 END,
    CASE WHEN v_is_correct THEN 1 ELSE 0 END,
    'learning', 0, clock_timestamp()
  )
  ON CONFLICT (player_id, grade, topic, skill) DO UPDATE
  SET attempts = math_skill_progress.attempts + 1,
      correct = math_skill_progress.correct + CASE WHEN v_is_correct THEN 1 ELSE 0 END,
      consecutive_correct = CASE
        WHEN v_is_correct THEN math_skill_progress.consecutive_correct + 1
        ELSE 0
      END,
      xp = math_skill_progress.xp + CASE WHEN v_is_correct THEN 5 ELSE 1 END,
      last_practiced_at = clock_timestamp();

  SELECT sp.attempts, sp.correct, sp.consecutive_correct
  INTO v_attempts, v_correct, v_consecutive
  FROM math_skill_progress sp
  WHERE sp.player_id = v_player
    AND sp.grade = v_question.grade
    AND sp.topic = v_question.topic
    AND sp.skill = v_question.skill;

  v_mastery := math_mastery_for(v_attempts, v_correct, v_consecutive);

  UPDATE math_skill_progress
  SET mastery = v_mastery
  WHERE player_id = v_player
    AND grade = v_question.grade
    AND topic = v_question.topic
    AND skill = v_question.skill;

  SELECT last_practice_on, practice_streak INTO v_last, v_streak
  FROM players WHERE id = v_player;

  IF v_last = v_today THEN
    v_streak := greatest(v_streak, 1);
  ELSIF v_last = v_today - 1 THEN
    v_streak := v_streak + 1;
  ELSE
    v_streak := 1;
  END IF;

  UPDATE players
  SET practice_questions = practice_questions + 1,
      practice_correct = practice_correct + CASE WHEN v_is_correct THEN 1 ELSE 0 END,
      last_practice_on = v_today,
      practice_streak = v_streak,
      best_practice_streak = greatest(best_practice_streak, v_streak),
      last_seen_at = clock_timestamp()
  WHERE id = v_player;

  v_xp := CASE WHEN v_is_correct THEN 5 ELSE 1 END
    + CASE WHEN p_used_hint THEN 0 ELSE 1 END
    + CASE WHEN v_is_correct AND v_consecutive >= 5 THEN 2 ELSE 0 END;

  INSERT INTO math_xp_transactions (player_id, amount, reason, reference)
  VALUES (v_player, v_xp, 'practice', 'practice:' || p_attempt_id)
  ON CONFLICT (player_id, reference) DO NOTHING;

  IF FOUND THEN
    UPDATE players
    SET xp = xp + v_xp,
        level = 1 + ((xp + v_xp) / 250)
    WHERE id = v_player;
  END IF;

  v_new_achievements := math_evaluate_achievements(v_player);

  SELECT practice_questions INTO v_practice_count
  FROM players WHERE id = v_player;

  RETURN jsonb_build_object(
    'success', true,
    'is_correct', v_is_correct,
    'correct_answer', v_question.correct_answer,
    'explanation', v_question.explanation,
    'hint', v_question.hint,
    'xp_earned', v_xp,
    'mastery', v_mastery,
    'skill_attempts', v_attempts,
    'skill_correct', v_correct,
    'practice_streak', v_streak,
    'practice_questions', v_practice_count,
    'new_achievements', to_jsonb(v_new_achievements)
  );
END;
$$;

REVOKE ALL ON FUNCTION math_submit_practice_answer(uuid, text, uuid, boolean, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_submit_practice_answer(uuid, text, uuid, boolean, integer) TO authenticated;

-- ---------------------------------------------------------------------------
-- Leaderboards (competitive matches only; practice never counts)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_leaderboard(
  p_grade integer DEFAULT NULL,
  p_topic math_topic DEFAULT NULL,
  p_window text DEFAULT 'all_time',
  p_limit integer DEFAULT 25
)
RETURNS TABLE (
  rank integer,
  player_id uuid,
  display_name text,
  avatar_index integer,
  avatar_color text,
  grade smallint,
  points bigint,
  wins bigint,
  games bigint,
  accuracy numeric,
  speed_bonuses bigint,
  is_me boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF p_window NOT IN ('all_time', 'weekly') THEN
    RAISE EXCEPTION 'Unknown leaderboard window';
  END IF;
  IF p_grade IS NOT NULL AND (p_grade < 0 OR p_grade > 5) THEN
    RAISE EXCEPTION 'Choose a grade between Kindergarten and Grade 5';
  END IF;

  RETURN QUERY
  WITH aggregated AS (
    SELECT
      mp.player_id,
      sum(mp.points)::bigint AS points,
      count(*) FILTER (WHERE mp.result = 'win')::bigint AS wins,
      count(*)::bigint AS games,
      sum(mp.correct_count)::bigint AS correct,
      sum(mp.answered_count)::bigint AS answered,
      sum(mp.speed_bonus_count)::bigint AS speed_bonuses
    FROM math_match_players mp
    JOIN math_matches m ON m.id = mp.match_id
    JOIN players pl ON pl.id = mp.player_id
    WHERE m.status = 'completed'
      AND pl.leaderboard_visible = true
      AND pl.is_deleted = false
      AND (p_grade IS NULL OR m.grade = p_grade)
      AND (p_topic IS NULL OR p_topic = ANY(m.topics))
      AND (
        p_window = 'all_time'
        OR m.completed_at >= date_trunc('week', now())
      )
    GROUP BY mp.player_id
    HAVING count(*) >= CASE WHEN p_window = 'weekly' THEN 2 ELSE 3 END
  ),
  ranked AS (
    SELECT
      a.*,
      rank() OVER (
        ORDER BY a.points DESC,
                 a.wins DESC,
                 CASE WHEN a.answered > 0
                   THEN a.correct::numeric / a.answered ELSE 0 END DESC,
                 a.player_id
      )::integer AS rnk
    FROM aggregated a
  )
  SELECT
    r.rnk,
    r.player_id,
    pl.display_name,
    pl.avatar_index,
    pl.avatar_color,
    pl.grade,
    r.points,
    r.wins,
    r.games,
    round(
      CASE WHEN r.answered > 0
        THEN 100.0 * r.correct / r.answered ELSE 0 END,
      1
    ) AS accuracy,
    r.speed_bonuses,
    (r.player_id = auth.uid()) AS is_me
  FROM ranked r
  JOIN players pl ON pl.id = r.player_id
  ORDER BY r.rnk
  LIMIT least(greatest(coalesce(p_limit, 25), 1), 100);
END;
$$;

REVOKE ALL ON FUNCTION math_leaderboard(integer, math_topic, text, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_leaderboard(integer, math_topic, text, integer) TO authenticated;

-- ---------------------------------------------------------------------------
-- Account deletion (hard delete of the auth user cascades profile data).
-- Hosted rooms are handed over so other players keep their match history.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_delete_my_account()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_room record;
  v_next_host uuid;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  FOR v_room IN
    SELECT id FROM math_rooms WHERE host_id = v_player
  LOOP
    SELECT rp.player_id INTO v_next_host
    FROM math_room_players rp
    WHERE rp.room_id = v_room.id
      AND rp.player_id <> v_player
      AND rp.left_at IS NULL
    ORDER BY rp.seat
    LIMIT 1;

    IF v_next_host IS NOT NULL THEN
      UPDATE math_rooms SET host_id = v_next_host WHERE id = v_room.id;
    ELSE
      -- Matches keep their snapshots: math_matches.room_id becomes NULL.
      DELETE FROM math_rooms WHERE id = v_room.id;
    END IF;
  END LOOP;

  DELETE FROM math_room_players WHERE player_id = v_player;
  DELETE FROM math_rate_events WHERE player_id = v_player;

  -- Cascades to players, matches participants, answers, skills, achievements
  -- and XP transactions. Anonymous auth users are deleted the same way.
  DELETE FROM auth.users WHERE id = v_player;

  RETURN jsonb_build_object('success', true);
END;
$$;

REVOKE ALL ON FUNCTION math_delete_my_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_delete_my_account() TO authenticated;

-- ---------------------------------------------------------------------------
-- Retention: remove stale empty rooms. Match history is preserved.
-- Schedule with pg_cron in production (see docs/OPERATIONS.md).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_cleanup_stale_rooms()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_deleted integer;
BEGIN
  WITH stale AS (
    SELECT r.id
    FROM math_rooms r
    WHERE r.last_activity_at < now() - interval '6 hours'
      AND r.status IN ('waiting', 'final_results', 'completed', 'abandoned')
      AND NOT EXISTS (
        SELECT 1 FROM math_room_players rp
        WHERE rp.room_id = r.id AND rp.left_at IS NULL
      )
  )
  DELETE FROM math_rooms r USING stale
  WHERE r.id = stale.id;

  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;

REVOKE ALL ON FUNCTION math_cleanup_stale_rooms() FROM PUBLIC;
