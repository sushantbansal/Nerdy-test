-- ============================================================================
-- Migration 014: Room lifecycle and discovery
-- ============================================================================

CREATE OR REPLACE FUNCTION math_rate_limit(
  p_action text,
  p_max integer,
  p_window_seconds integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_count integer;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  DELETE FROM math_rate_events
  WHERE player_id = v_player
    AND created_at < clock_timestamp() - interval '1 day';

  INSERT INTO math_rate_events (player_id, action) VALUES (v_player, p_action);

  SELECT count(*) INTO v_count
  FROM math_rate_events
  WHERE player_id = v_player
    AND action = p_action
    AND created_at >= clock_timestamp() - make_interval(secs => p_window_seconds);

  IF v_count > p_max THEN
    RAISE EXCEPTION 'Too many requests. Take a short break and try again.';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION math_rate_limit(text, integer, integer) FROM PUBLIC;

CREATE OR REPLACE FUNCTION math_is_room_member(p_room_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM math_room_players rp
    WHERE rp.room_id = p_room_id
      AND rp.player_id = auth.uid()
      AND rp.left_at IS NULL
  );
$$;

REVOKE ALL ON FUNCTION math_is_room_member(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_is_room_member(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION math_is_match_participant(p_match_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM math_match_players mp
    WHERE mp.match_id = p_match_id AND mp.player_id = auth.uid()
  );
$$;

REVOKE ALL ON FUNCTION math_is_match_participant(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_is_match_participant(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- Create a room
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_create_room(
  p_name text DEFAULT 'MathClash Room',
  p_visibility math_room_visibility DEFAULT 'private',
  p_grade integer DEFAULT 1,
  p_topics math_topic[] DEFAULT ARRAY['addition']::math_topic[],
  p_difficulty math_difficulty DEFAULT 'adaptive',
  p_question_count integer DEFAULT 5,
  p_answer_seconds integer DEFAULT 18,
  p_max_players integer DEFAULT 4,
  p_speed_bonus_enabled boolean DEFAULT true,
  p_auto_start boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_name text;
  v_room math_rooms%ROWTYPE;
  v_topics math_topic[];
  v_grade smallint;
  v_avatar jsonb;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;
  IF p_grade < 0 OR p_grade > 5 THEN
    RAISE EXCEPTION 'Choose a grade between Kindergarten and Grade 5';
  END IF;
  IF p_question_count < 3 OR p_question_count > 8 THEN
    RAISE EXCEPTION 'Questions per match must be between 3 and 8';
  END IF;
  IF p_answer_seconds < 10 OR p_answer_seconds > 45 THEN
    RAISE EXCEPTION 'Answer time must be between 10 and 45 seconds';
  END IF;
  IF p_max_players < 2 OR p_max_players > 8 THEN
    RAISE EXCEPTION 'Rooms must allow between 2 and 8 players';
  END IF;
  IF p_topics IS NULL OR cardinality(p_topics) = 0 OR cardinality(p_topics) > 3 THEN
    RAISE EXCEPTION 'Choose between 1 and 3 math topics';
  END IF;

  PERFORM math_rate_limit('create_room', 3, 60);

  v_name := regexp_replace(trim(coalesce(p_name, '')), '\s+', ' ', 'g');
  v_name := regexp_replace(v_name, '[[:cntrl:]<>{}\[\]/\\@#]', '', 'g');
  IF char_length(v_name) < 3 THEN
    v_name := 'MathClash Room';
  END IF;
  IF char_length(v_name) > 40 THEN
    v_name := left(v_name, 40);
  END IF;

  SELECT array_agg(DISTINCT t) INTO v_topics FROM unnest(p_topics) AS t;
  v_grade := p_grade::smallint;

  UPDATE players
  SET grade = v_grade, last_seen_at = clock_timestamp()
  WHERE id = v_player;

  INSERT INTO math_rooms (
    name, host_id, visibility, grade, topics, difficulty, question_count,
    answer_seconds, max_players, speed_bonus_enabled, auto_start
  ) VALUES (
    v_name, v_player, p_visibility, v_grade, v_topics, p_difficulty,
    p_question_count::smallint, p_answer_seconds::smallint,
    p_max_players::smallint, p_speed_bonus_enabled, p_auto_start
  )
  RETURNING * INTO v_room;

  SELECT jsonb_build_object(
    'display_name', p.display_name,
    'avatar_index', p.avatar_index,
    'avatar_color', p.avatar_color
  ) INTO v_avatar
  FROM players p WHERE p.id = v_player;

  INSERT INTO math_room_players (
    room_id, player_id, display_name, avatar_index, avatar_color, seat, is_ready
  ) VALUES (
    v_room.id,
    v_player,
    coalesce(v_avatar->>'display_name', 'Player'),
    coalesce((v_avatar->>'avatar_index')::int, 0),
    coalesce(v_avatar->>'avatar_color', '#00A2FF'),
    1,
    true
  );

  RETURN jsonb_build_object(
    'success', true,
    'room_id', v_room.id,
    'room_code', v_room.room_code,
    'room_name', v_room.name
  );
END;
$$;

REVOKE ALL ON FUNCTION math_create_room(
  text, math_room_visibility, integer, math_topic[], math_difficulty,
  integer, integer, integer, boolean, boolean
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_create_room(
  text, math_room_visibility, integer, math_topic[], math_difficulty,
  integer, integer, integer, boolean, boolean
) TO authenticated;

-- ---------------------------------------------------------------------------
-- Join by code (rejoin is allowed for current match participants)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_join_room(p_room_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_room math_rooms%ROWTYPE;
  v_profile players%ROWTYPE;
  v_active integer;
  v_seat integer;
  v_member math_room_players%ROWTYPE;
  v_match_id uuid;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  PERFORM math_rate_limit('join_room', 20, 60);

  SELECT * INTO v_room
  FROM math_rooms
  WHERE room_code = upper(trim(p_room_code))
  FOR UPDATE;

  IF v_room.id IS NULL THEN
    RAISE EXCEPTION 'Room not found';
  END IF;

  SELECT * INTO v_member
  FROM math_room_players
  WHERE room_id = v_room.id AND player_id = v_player AND left_at IS NULL;

  IF v_member.id IS NOT NULL THEN
    RETURN jsonb_build_object(
      'success', true,
      'room_id', v_room.id,
      'room_code', v_room.room_code,
      'already_joined', true
    );
  END IF;

  -- A participant of the live match may reconnect even after leaving.
  SELECT m.id INTO v_match_id
  FROM math_matches m
  JOIN math_match_players mp ON mp.match_id = m.id
  WHERE m.room_id = v_room.id
    AND m.id = v_room.current_match_id
    AND mp.player_id = v_player;

  IF v_match_id IS NOT NULL THEN
    UPDATE math_room_players rp
    SET left_at = NULL, is_connected = true
    WHERE rp.id = (
      SELECT id FROM math_room_players
      WHERE room_id = v_room.id AND player_id = v_player
      ORDER BY joined_at DESC
      LIMIT 1
    );

    UPDATE math_rooms SET last_activity_at = clock_timestamp() WHERE id = v_room.id;
    RETURN jsonb_build_object(
      'success', true,
      'room_id', v_room.id,
      'room_code', v_room.room_code,
      'reconnected', true
    );
  END IF;

  IF v_room.status <> 'waiting' THEN
    RAISE EXCEPTION 'This match has already started';
  END IF;

  SELECT count(*) INTO v_active
  FROM math_room_players
  WHERE room_id = v_room.id AND left_at IS NULL;

  IF v_active >= v_room.max_players THEN
    RAISE EXCEPTION 'This room is full';
  END IF;

  SELECT coalesce(max(seat), 0) + 1 INTO v_seat
  FROM math_room_players WHERE room_id = v_room.id;

  SELECT * INTO v_profile FROM players WHERE id = v_player;

  INSERT INTO math_room_players (
    room_id, player_id, display_name, avatar_index, avatar_color, seat,
    is_ready, is_connected
  ) VALUES (
    v_room.id, v_player, v_profile.display_name, v_profile.avatar_index,
    v_profile.avatar_color, v_seat, false, true
  )
  ON CONFLICT DO NOTHING;

  UPDATE math_rooms SET last_activity_at = clock_timestamp() WHERE id = v_room.id;

  RETURN jsonb_build_object(
    'success', true,
    'room_id', v_room.id,
    'room_code', v_room.room_code
  );
END;
$$;

REVOKE ALL ON FUNCTION math_join_room(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_join_room(text) TO authenticated;

-- ---------------------------------------------------------------------------
-- Leave a room; host transfer and safe match continuation
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_leave_room(p_room_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_room math_rooms%ROWTYPE;
  v_next_host uuid;
  v_active integer;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  SELECT * INTO v_room FROM math_rooms WHERE id = p_room_id FOR UPDATE;
  IF v_room.id IS NULL THEN
    RETURN jsonb_build_object('success', true);
  END IF;

  UPDATE math_room_players
  SET left_at = clock_timestamp(), is_connected = false
  WHERE room_id = p_room_id AND player_id = v_player AND left_at IS NULL;

  IF v_room.host_id = v_player THEN
    SELECT player_id INTO v_next_host
    FROM math_room_players
    WHERE room_id = p_room_id AND left_at IS NULL
    ORDER BY seat
    LIMIT 1;

    IF v_next_host IS NOT NULL THEN
      UPDATE math_rooms SET host_id = v_next_host WHERE id = p_room_id;
      UPDATE math_room_players SET is_ready = true
      WHERE room_id = p_room_id AND player_id = v_next_host;
    END IF;
  END IF;

  SELECT count(*) INTO v_active
  FROM math_room_players
  WHERE room_id = p_room_id AND left_at IS NULL;

  IF v_active = 0 THEN
    UPDATE math_rooms
    SET status = CASE
      WHEN status = 'final_results' THEN 'completed'::math_room_status
      WHEN status IN ('waiting', 'countdown') THEN 'abandoned'::math_room_status
      ELSE status
    END,
    last_activity_at = clock_timestamp()
    WHERE id = p_room_id;
  ELSE
    UPDATE math_rooms SET last_activity_at = clock_timestamp() WHERE id = p_room_id;
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$$;

REVOKE ALL ON FUNCTION math_leave_room(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_leave_room(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- Ready state and automatic start
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_start_match_internal(p_room_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_room math_rooms%ROWTYPE;
  v_match math_matches%ROWTYPE;
  v_active integer;
  v_match_number integer;
  v_available integer;
  v_inserted integer;
  v_use_fallback boolean := false;
BEGIN
  SELECT * INTO v_room FROM math_rooms WHERE id = p_room_id FOR UPDATE;
  IF v_room.id IS NULL THEN
    RAISE EXCEPTION 'Room not found';
  END IF;
  IF v_room.status <> 'waiting' THEN
    RAISE EXCEPTION 'This room is not waiting to start';
  END IF;

  SELECT count(*) INTO v_active
  FROM math_room_players
  WHERE room_id = p_room_id AND left_at IS NULL;

  IF v_active < 2 THEN
    RAISE EXCEPTION 'Need at least 2 players to start';
  END IF;

  SELECT coalesce(max(match_number), 0) + 1 INTO v_match_number
  FROM math_matches WHERE room_id = p_room_id;

  INSERT INTO math_matches (
    room_id, match_number, grade, topics, difficulty, question_count,
    answer_seconds, speed_bonus_enabled, status, countdown_ends_at
  ) VALUES (
    p_room_id, v_match_number, v_room.grade, v_room.topics, v_room.difficulty,
    v_room.question_count, v_room.answer_seconds, v_room.speed_bonus_enabled,
    'countdown', clock_timestamp() + interval '3 seconds'
  )
  RETURNING * INTO v_match;

  INSERT INTO math_match_players (
    match_id, player_id, display_name, avatar_index, avatar_color, seat
  )
  SELECT
    v_match.id, rp.player_id, rp.display_name, rp.avatar_index, rp.avatar_color, rp.seat
  FROM math_room_players rp
  WHERE rp.room_id = p_room_id AND rp.left_at IS NULL
  ORDER BY rp.seat;

  SELECT count(*) INTO v_available
  FROM math_questions q
  WHERE q.is_active
    AND q.grade = v_room.grade
    AND q.topic = ANY(v_room.topics)
    AND (
      v_room.difficulty = 'adaptive'
      OR q.difficulty = v_room.difficulty
    );

  -- Graceful fallback for unusual filter combinations: widen to the whole
  -- grade only when the exact topic/difficulty slice cannot fill the match.
  v_use_fallback := v_available < v_room.question_count;

  IF v_use_fallback THEN
    SELECT count(*) INTO v_available
    FROM math_questions q
    WHERE q.is_active AND q.grade = v_room.grade;
  END IF;

  IF v_available < v_room.question_count THEN
    RAISE EXCEPTION 'Not enough questions are available for this room';
  END IF;

  WITH picked AS (
    SELECT q.id, row_number() OVER (ORDER BY random()) AS position
    FROM math_questions q
    WHERE q.is_active
      AND q.grade = v_room.grade
      AND (
        v_use_fallback
        OR (
          q.topic = ANY(v_room.topics)
          AND (
            v_room.difficulty = 'adaptive'
            OR q.difficulty = v_room.difficulty
          )
        )
      )
    ORDER BY random()
    LIMIT v_room.question_count
  )
  INSERT INTO math_match_questions (
    match_id, position, question_id, question_text, answer_type, options,
    correct_answer, explanation, hint, visual, topic, skill, difficulty,
    estimated_seconds
  )
  SELECT
    v_match.id, picked.position, q.id, q.question_text, q.answer_type,
    q.options, q.correct_answer, q.explanation, q.hint, q.visual, q.topic,
    q.skill, q.difficulty, q.estimated_seconds
  FROM picked
  JOIN math_questions q ON q.id = picked.id
  ORDER BY picked.position;

  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  IF v_inserted <> v_room.question_count THEN
    RAISE EXCEPTION 'Could not prepare the full question set';
  END IF;

  UPDATE math_rooms
  SET status = 'countdown',
      current_match_id = v_match.id,
      countdown_ends_at = v_match.countdown_ends_at,
      last_activity_at = clock_timestamp()
  WHERE id = p_room_id;

  RETURN v_match.id;
END;
$$;

REVOKE ALL ON FUNCTION math_start_match_internal(uuid) FROM PUBLIC;

CREATE OR REPLACE FUNCTION math_try_autostart(p_room_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_room math_rooms%ROWTYPE;
  v_active integer;
  v_ready integer;
BEGIN
  SELECT * INTO v_room FROM math_rooms WHERE id = p_room_id FOR UPDATE;
  IF v_room.id IS NULL OR v_room.status <> 'waiting' OR NOT v_room.auto_start THEN
    RETURN false;
  END IF;

  SELECT count(*), count(*) FILTER (WHERE is_ready)
  INTO v_active, v_ready
  FROM math_room_players
  WHERE room_id = p_room_id AND left_at IS NULL;

  IF v_active >= 2 AND v_ready = v_active THEN
    PERFORM math_start_match_internal(p_room_id);
    RETURN true;
  END IF;
  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION math_try_autostart(uuid) FROM PUBLIC;

CREATE OR REPLACE FUNCTION math_set_ready(p_room_id uuid, p_ready boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_room math_rooms%ROWTYPE;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  SELECT * INTO v_room FROM math_rooms WHERE id = p_room_id FOR UPDATE;
  IF v_room.id IS NULL THEN
    RAISE EXCEPTION 'Room not found';
  END IF;
  IF v_room.status <> 'waiting' THEN
    RAISE EXCEPTION 'The match is already starting';
  END IF;

  UPDATE math_room_players
  SET is_ready = p_ready
  WHERE room_id = p_room_id AND player_id = v_player AND left_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'You are not in this room';
  END IF;

  UPDATE math_rooms SET last_activity_at = clock_timestamp() WHERE id = p_room_id;
  PERFORM math_try_autostart(p_room_id);

  RETURN jsonb_build_object('success', true, 'is_ready', p_ready);
END;
$$;

REVOKE ALL ON FUNCTION math_set_ready(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_set_ready(uuid, boolean) TO authenticated;

CREATE OR REPLACE FUNCTION math_start_match(p_room_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_room math_rooms%ROWTYPE;
  v_match_id uuid;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  SELECT * INTO v_room FROM math_rooms WHERE id = p_room_id FOR UPDATE;
  IF v_room.id IS NULL THEN
    RAISE EXCEPTION 'Room not found';
  END IF;
  IF v_room.host_id <> v_player THEN
    RAISE EXCEPTION 'Only the host can start the match';
  END IF;

  v_match_id := math_start_match_internal(p_room_id);
  RETURN jsonb_build_object('success', true, 'match_id', v_match_id);
END;
$$;

REVOKE ALL ON FUNCTION math_start_match(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_start_match(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- Public room discovery
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_list_rooms(
  p_grade integer DEFAULT NULL,
  p_topic math_topic DEFAULT NULL,
  p_difficulty math_difficulty DEFAULT NULL,
  p_only_available boolean DEFAULT false,
  p_limit integer DEFAULT 30
)
RETURNS TABLE (
  id uuid,
  room_code text,
  name text,
  host_id uuid,
  host_name text,
  host_avatar_index integer,
  host_avatar_color text,
  grade smallint,
  topics math_topic[],
  difficulty math_difficulty,
  question_count smallint,
  answer_seconds smallint,
  max_players smallint,
  speed_bonus_enabled boolean,
  player_count bigint,
  status math_room_status,
  created_at timestamptz,
  is_joined boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    r.id,
    r.room_code,
    r.name,
    r.host_id,
    p.display_name AS host_name,
    p.avatar_index AS host_avatar_index,
    p.avatar_color AS host_avatar_color,
    r.grade,
    r.topics,
    r.difficulty,
    r.question_count,
    r.answer_seconds,
    r.max_players,
    r.speed_bonus_enabled,
    count(rp.player_id) FILTER (WHERE rp.left_at IS NULL) AS player_count,
    r.status,
    r.created_at,
    EXISTS (
      SELECT 1 FROM math_room_players me
      WHERE me.room_id = r.id AND me.player_id = auth.uid() AND me.left_at IS NULL
    ) AS is_joined
  FROM math_rooms r
  JOIN players p ON p.id = r.host_id
  LEFT JOIN math_room_players rp ON rp.room_id = r.id
  WHERE r.visibility = 'public'
    AND r.status = 'waiting'
    AND r.last_activity_at >= clock_timestamp() - interval '2 hours'
    AND (p_grade IS NULL OR r.grade = p_grade)
    AND (p_topic IS NULL OR p_topic = ANY(r.topics))
    AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
  GROUP BY r.id, p.display_name, p.avatar_index, p.avatar_color
  HAVING (NOT p_only_available OR count(rp.player_id) FILTER (WHERE rp.left_at IS NULL) < r.max_players)
  ORDER BY r.created_at DESC
  LIMIT greatest(1, least(50, coalesce(p_limit, 30)));
$$;

REVOKE ALL ON FUNCTION math_list_rooms(
  integer, math_topic, math_difficulty, boolean, integer
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_list_rooms(
  integer, math_topic, math_difficulty, boolean, integer
) TO authenticated;

-- ---------------------------------------------------------------------------
-- Replay, close and heartbeat
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_play_again(p_room_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_room math_rooms%ROWTYPE;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  SELECT * INTO v_room FROM math_rooms WHERE id = p_room_id FOR UPDATE;
  IF v_room.id IS NULL THEN
    RAISE EXCEPTION 'Room not found';
  END IF;
  IF v_room.host_id <> v_player THEN
    RAISE EXCEPTION 'Only the host can restart the room';
  END IF;
  IF v_room.status NOT IN ('final_results', 'completed') THEN
    RAISE EXCEPTION 'The current match is still in progress';
  END IF;

  UPDATE math_rooms
  SET status = 'waiting',
      current_match_id = NULL,
      countdown_ends_at = NULL,
      last_activity_at = clock_timestamp()
  WHERE id = p_room_id;

  UPDATE math_room_players
  SET is_ready = (player_id = v_player)
  WHERE room_id = p_room_id AND left_at IS NULL;

  RETURN jsonb_build_object('success', true);
END;
$$;

REVOKE ALL ON FUNCTION math_play_again(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_play_again(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION math_close_room(p_room_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_room math_rooms%ROWTYPE;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  SELECT * INTO v_room FROM math_rooms WHERE id = p_room_id FOR UPDATE;
  IF v_room.id IS NULL THEN
    RETURN jsonb_build_object('success', true);
  END IF;
  IF v_room.host_id <> v_player THEN
    RAISE EXCEPTION 'Only the host can close this room';
  END IF;
  IF v_room.status IN ('countdown', 'question_active', 'question_reveal', 'next_question') THEN
    RAISE EXCEPTION 'Finish the current match before closing the room';
  END IF;

  UPDATE math_rooms
  SET status = 'completed', last_activity_at = clock_timestamp()
  WHERE id = p_room_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

REVOKE ALL ON FUNCTION math_close_room(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_close_room(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION math_heartbeat(p_room_id uuid)
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

  UPDATE math_room_players
  SET is_connected = true
  WHERE room_id = p_room_id AND player_id = v_player AND left_at IS NULL;

  UPDATE math_rooms
  SET last_activity_at = clock_timestamp()
  WHERE id = p_room_id;

  UPDATE players SET last_seen_at = clock_timestamp() WHERE id = v_player;

  RETURN jsonb_build_object(
    'success', true,
    'server_now', clock_timestamp()
  );
END;
$$;

REVOKE ALL ON FUNCTION math_heartbeat(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_heartbeat(uuid) TO authenticated;
