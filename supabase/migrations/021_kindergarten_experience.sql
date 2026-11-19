-- ============================================================================
-- Migration 021: Kindergarten onboarding and kinder room pacing
--
-- Kindergarten is the first competitive experience for many players, so the
-- tutorial completion is stored with the profile and Kindergarten rooms get a
-- generous floor for answer time. The client still owns the friendly defaults
-- (30 seconds, speed bonus off); this trigger protects the rule if another
-- client creates the room.
-- ============================================================================

ALTER TABLE players
  ADD COLUMN IF NOT EXISTS tutorial_completed_at timestamptz;

-- ---------------------------------------------------------------------------
-- Tutorial completion
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_tutorial_status()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_completed_at timestamptz;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  SELECT tutorial_completed_at INTO v_completed_at
  FROM players
  WHERE id = v_player AND is_deleted = false;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Player not found';
  END IF;

  RETURN jsonb_build_object(
    'completed', v_completed_at IS NOT NULL,
    'completed_at', v_completed_at
  );
END;
$$;

REVOKE ALL ON FUNCTION math_tutorial_status() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_tutorial_status() TO authenticated;

CREATE OR REPLACE FUNCTION math_complete_tutorial()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_player uuid := auth.uid();
  v_completed_at timestamptz;
BEGIN
  IF v_player IS NULL THEN
    RAISE EXCEPTION 'Please sign in first';
  END IF;

  UPDATE players
  SET tutorial_completed_at = coalesce(tutorial_completed_at, clock_timestamp()),
      last_seen_at = clock_timestamp()
  WHERE id = v_player AND is_deleted = false
  RETURNING tutorial_completed_at INTO v_completed_at;

  IF v_completed_at IS NULL THEN
    RAISE EXCEPTION 'Player not found';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'completed', true,
    'completed_at', v_completed_at
  );
END;
$$;

REVOKE ALL ON FUNCTION math_complete_tutorial() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_complete_tutorial() TO authenticated;

-- ---------------------------------------------------------------------------
-- Kindergarten rooms always allow at least 20 seconds per question.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_kindergarten_room_defaults()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.grade = 0 AND NEW.answer_seconds < 20 THEN
    NEW.answer_seconds := 20;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_math_kindergarten_room_defaults ON math_rooms;
CREATE TRIGGER trg_math_kindergarten_room_defaults
  BEFORE INSERT ON math_rooms
  FOR EACH ROW EXECUTE FUNCTION math_kindergarten_room_defaults();
