-- ============================================================================
-- Migration 017: Safe realtime read access
--
-- Only non-secret room/match metadata is streamed. Question answer keys and
-- submitted answers stay sealed behind SECURITY DEFINER RPCs.
-- ============================================================================

CREATE OR REPLACE FUNCTION math_can_view_room(p_room_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM math_rooms r
    WHERE r.id = p_room_id
      AND (
        math_is_room_member(r.id)
        OR (r.visibility = 'public' AND r.status = 'waiting')
      )
  );
$$;

REVOKE ALL ON FUNCTION math_can_view_room(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_can_view_room(uuid) TO authenticated;

ALTER TABLE math_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE math_room_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE math_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE math_match_players ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS math_rooms_select_safe ON math_rooms;
CREATE POLICY math_rooms_select_safe ON math_rooms
  FOR SELECT TO authenticated
  USING (math_can_view_room(id));

DROP POLICY IF EXISTS math_room_players_select_safe ON math_room_players;
CREATE POLICY math_room_players_select_safe ON math_room_players
  FOR SELECT TO authenticated
  USING (math_can_view_room(room_id));

DROP POLICY IF EXISTS math_matches_select_safe ON math_matches;
CREATE POLICY math_matches_select_safe ON math_matches
  FOR SELECT TO authenticated
  USING (math_is_match_participant(id));

DROP POLICY IF EXISTS math_match_players_select_safe ON math_match_players;
CREATE POLICY math_match_players_select_safe ON math_match_players
  FOR SELECT TO authenticated
  USING (math_is_match_participant(match_id));

GRANT SELECT ON TABLE
  math_rooms,
  math_room_players,
  math_matches,
  math_match_players
TO authenticated;

-- Filters in clients use room_id/match_id, so updates must carry those keys.
ALTER TABLE math_rooms REPLICA IDENTITY FULL;
ALTER TABLE math_room_players REPLICA IDENTITY FULL;
ALTER TABLE math_matches REPLICA IDENTITY FULL;
ALTER TABLE math_match_players REPLICA IDENTITY FULL;

DO $$
DECLARE
  v_table text;
BEGIN
  FOREACH v_table IN ARRAY ARRAY[
    'math_rooms', 'math_room_players', 'math_matches', 'math_match_players'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = v_table
    ) THEN
      EXECUTE format(
        'ALTER PUBLICATION supabase_realtime ADD TABLE public.%I',
        v_table
      );
    END IF;
  END LOOP;
END $$;
