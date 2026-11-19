-- ============================================================================
-- Migration 013: Transform SketchRush into MathClash
--
-- The drawing-game tables are retired. Player identities are preserved and
-- extended into a math profile. Question answers live server-side only.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Retire drawing-game objects
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS game_turns CASCADE;
DROP TABLE IF EXISTS room_players CASCADE;
DROP TABLE IF EXISTS game_rooms CASCADE;
DROP TABLE IF EXISTS word_bank CASCADE;

DROP FUNCTION IF EXISTS join_room(text, uuid) CASCADE;
DROP FUNCTION IF EXISTS leave_room(uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS get_random_words(word_difficulty, integer, text, text[]) CASCADE;
DROP FUNCTION IF EXISTS list_public_rooms(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS cleanup_stale_rooms() CASCADE;
DROP FUNCTION IF EXISTS handle_player_leave() CASCADE;
DROP FUNCTION IF EXISTS assign_turn_order() CASCADE;
DROP FUNCTION IF EXISTS generate_room_code() CASCADE;

DROP TYPE IF EXISTS room_status CASCADE;
DROP TYPE IF EXISTS game_phase CASCADE;
DROP TYPE IF EXISTS player_role CASCADE;
DROP TYPE IF EXISTS word_difficulty CASCADE;
DROP TYPE IF EXISTS message_type CASCADE;

-- ---------------------------------------------------------------------------
-- Math domain enums
-- ---------------------------------------------------------------------------
CREATE TYPE math_topic AS ENUM (
  'addition',
  'subtraction',
  'multiplication',
  'division',
  'fractions',
  'geometry',
  'measurement',
  'place_value',
  'mixed'
);

CREATE TYPE math_difficulty AS ENUM ('easy', 'medium', 'hard', 'adaptive');
CREATE TYPE math_room_visibility AS ENUM ('public', 'private');

CREATE TYPE math_room_status AS ENUM (
  'waiting',
  'countdown',
  'question_active',
  'question_reveal',
  'next_question',
  'final_results',
  'completed',
  'abandoned'
);

CREATE TYPE math_answer_type AS ENUM ('choice', 'numeric', 'fraction', 'text');
CREATE TYPE math_mastery AS ENUM (
  'not_started',
  'learning',
  'practicing',
  'proficient',
  'mastered'
);
CREATE TYPE math_match_outcome AS ENUM ('win', 'loss', 'draw');

-- ---------------------------------------------------------------------------
-- Player identity and profile
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'players'
      AND column_name = 'games_won'
  ) THEN
    ALTER TABLE players RENAME COLUMN games_won TO wins;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'players'
      AND column_name = 'total_score'
  ) THEN
    ALTER TABLE players RENAME COLUMN total_score TO total_points;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'players'
      AND column_name = 'best_score'
  ) THEN
    ALTER TABLE players RENAME COLUMN best_score TO best_match_points;
  END IF;
END $$;

ALTER TABLE players
  ADD COLUMN IF NOT EXISTS grade smallint NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS losses integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS draws integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS correct_answers integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS incorrect_answers integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS unanswered_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_response_ms bigint NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fastest_correct_ms integer,
  ADD COLUMN IF NOT EXISTS current_win_streak integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS best_win_streak integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS practice_questions integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS practice_correct integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS practice_streak integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS best_practice_streak integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_practice_on date,
  ADD COLUMN IF NOT EXISTS xp integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS level integer NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS sound_enabled boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS reduced_motion boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS leaderboard_visible boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS is_deleted boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS last_seen_at timestamptz NOT NULL DEFAULT now();

-- Sanitize existing names before the stricter constraint is applied.
UPDATE players
SET display_name = LEFT(
  nullif(trim(regexp_replace(display_name, '[[:cntrl:]<>{}\[\]/\\@#]', '', 'g')), ''),
  20
)
WHERE display_name ~ '[[:cntrl:]<>{}\[\]/\\@#]';

UPDATE players
SET display_name = 'Player'
WHERE char_length(display_name) < 2;

ALTER TABLE players
  DROP CONSTRAINT IF EXISTS players_grade_check,
  DROP CONSTRAINT IF EXISTS players_display_name_check,
  ADD CONSTRAINT players_grade_check CHECK (grade BETWEEN 0 AND 5),
  ADD CONSTRAINT players_display_name_check CHECK (char_length(display_name) BETWEEN 2 AND 20),
  ADD CONSTRAINT players_xp_check CHECK (xp >= 0),
  ADD CONSTRAINT players_level_check CHECK (level >= 1);

-- Stats are never updated directly by clients; RLS is tightened below.
DROP POLICY IF EXISTS players_select_all ON players;
DROP POLICY IF EXISTS players_insert_own ON players;
DROP POLICY IF EXISTS players_update_own ON players;
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE players FROM anon, authenticated;

CREATE INDEX IF NOT EXISTS idx_players_leaderboard
  ON players (leaderboard_visible, total_points DESC, wins DESC)
  WHERE is_deleted = false;
CREATE INDEX IF NOT EXISTS idx_players_grade
  ON players (grade, total_points DESC)
  WHERE is_deleted = false;

-- ---------------------------------------------------------------------------
-- Rooms
-- ---------------------------------------------------------------------------
CREATE TABLE math_rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_code text NOT NULL UNIQUE,
  name text NOT NULL DEFAULT 'MathClash Room',
  host_id uuid NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  visibility math_room_visibility NOT NULL DEFAULT 'private',
  grade smallint NOT NULL DEFAULT 1 CHECK (grade BETWEEN 0 AND 5),
  topics math_topic[] NOT NULL DEFAULT ARRAY['addition']::math_topic[],
  difficulty math_difficulty NOT NULL DEFAULT 'adaptive',
  question_count smallint NOT NULL DEFAULT 5 CHECK (question_count BETWEEN 3 AND 8),
  answer_seconds smallint NOT NULL DEFAULT 18 CHECK (answer_seconds BETWEEN 10 AND 45),
  max_players smallint NOT NULL DEFAULT 4 CHECK (max_players BETWEEN 2 AND 8),
  speed_bonus_enabled boolean NOT NULL DEFAULT true,
  auto_start boolean NOT NULL DEFAULT false,
  status math_room_status NOT NULL DEFAULT 'waiting',
  current_match_id uuid,
  countdown_ends_at timestamptz,
  last_activity_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT math_rooms_topics_check CHECK (cardinality(topics) BETWEEN 1 AND 3)
);

CREATE INDEX idx_math_rooms_public
  ON math_rooms (status, grade, created_at DESC)
  WHERE visibility = 'public' AND status = 'waiting';
CREATE INDEX idx_math_rooms_code ON math_rooms (room_code);
CREATE INDEX idx_math_rooms_host ON math_rooms (host_id, status);
CREATE INDEX idx_math_rooms_activity ON math_rooms (last_activity_at DESC);

CREATE TABLE math_room_players (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL REFERENCES math_rooms(id) ON DELETE CASCADE,
  player_id uuid NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  display_name text NOT NULL,
  avatar_index integer NOT NULL DEFAULT 0,
  avatar_color text NOT NULL DEFAULT '#00A2FF',
  seat integer NOT NULL DEFAULT 0,
  is_ready boolean NOT NULL DEFAULT false,
  is_connected boolean NOT NULL DEFAULT true,
  joined_at timestamptz NOT NULL DEFAULT now(),
  left_at timestamptz
);

CREATE UNIQUE INDEX idx_math_room_players_unique
  ON math_room_players (room_id, player_id)
  WHERE left_at IS NULL;
CREATE INDEX idx_math_room_players_room
  ON math_room_players (room_id, seat)
  WHERE left_at IS NULL;
CREATE INDEX idx_math_room_players_player
  ON math_room_players (player_id, room_id)
  WHERE left_at IS NULL;

-- ---------------------------------------------------------------------------
-- Matches and immutable snapshots
-- ---------------------------------------------------------------------------
CREATE TABLE math_matches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL REFERENCES math_rooms(id) ON DELETE CASCADE,
  match_number integer NOT NULL,
  grade smallint NOT NULL CHECK (grade BETWEEN 0 AND 5),
  topics math_topic[] NOT NULL,
  difficulty math_difficulty NOT NULL,
  question_count smallint NOT NULL,
  answer_seconds smallint NOT NULL,
  speed_bonus_enabled boolean NOT NULL DEFAULT true,
  status math_room_status NOT NULL DEFAULT 'countdown',
  question_index integer NOT NULL DEFAULT 0,
  countdown_ends_at timestamptz,
  question_started_at timestamptz,
  question_ends_at timestamptz,
  reveal_ends_at timestamptz,
  next_starts_at timestamptz,
  started_at timestamptz NOT NULL DEFAULT now(),
  finalized_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (room_id, match_number)
);

ALTER TABLE math_rooms
  ADD CONSTRAINT math_rooms_current_match_fk
  FOREIGN KEY (current_match_id) REFERENCES math_matches(id) ON DELETE SET NULL;

CREATE INDEX idx_math_matches_room ON math_matches (room_id, created_at DESC);
CREATE INDEX idx_math_matches_completed ON math_matches (completed_at DESC)
  WHERE status = 'completed';

CREATE TABLE math_match_players (
  match_id uuid NOT NULL REFERENCES math_matches(id) ON DELETE CASCADE,
  player_id uuid NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  display_name text NOT NULL,
  avatar_index integer NOT NULL DEFAULT 0,
  avatar_color text NOT NULL DEFAULT '#00A2FF',
  seat integer NOT NULL DEFAULT 0,
  points integer NOT NULL DEFAULT 0,
  correct_count integer NOT NULL DEFAULT 0,
  incorrect_count integer NOT NULL DEFAULT 0,
  unanswered_count integer NOT NULL DEFAULT 0,
  answered_count integer NOT NULL DEFAULT 0,
  speed_bonus_count integer NOT NULL DEFAULT 0,
  total_response_ms bigint NOT NULL DEFAULT 0,
  rank integer,
  result math_match_outcome,
  new_achievements text[] NOT NULL DEFAULT '{}',
  PRIMARY KEY (match_id, player_id)
);

CREATE INDEX idx_math_match_players_player
  ON math_match_players (player_id, match_id);
CREATE INDEX idx_math_match_players_points
  ON math_match_players (match_id, points DESC);

CREATE TABLE math_match_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id uuid NOT NULL REFERENCES math_matches(id) ON DELETE CASCADE,
  position integer NOT NULL,
  question_id uuid,
  question_text text NOT NULL,
  answer_type math_answer_type NOT NULL,
  options text[] NOT NULL CHECK (cardinality(options) = 4),
  correct_answer text NOT NULL,
  explanation text NOT NULL,
  hint text,
  visual jsonb,
  topic math_topic NOT NULL,
  skill text NOT NULL,
  difficulty math_difficulty NOT NULL,
  estimated_seconds integer NOT NULL DEFAULT 15,
  closed_at timestamptz,
  UNIQUE (match_id, position)
);

CREATE INDEX idx_math_match_questions_match
  ON math_match_questions (match_id, position);

CREATE TABLE math_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  grade smallint NOT NULL CHECK (grade BETWEEN 0 AND 5),
  topic math_topic NOT NULL,
  difficulty math_difficulty NOT NULL CHECK (difficulty <> 'adaptive'),
  skill text NOT NULL,
  question_text text NOT NULL,
  answer_type math_answer_type NOT NULL DEFAULT 'choice',
  correct_answer text NOT NULL,
  options text[] NOT NULL CHECK (cardinality(options) = 4),
  explanation text NOT NULL,
  hint text,
  visual jsonb,
  estimated_seconds integer NOT NULL DEFAULT 15 CHECK (estimated_seconds BETWEEN 3 AND 90),
  curriculum_tags text[] NOT NULL DEFAULT '{}',
  source text NOT NULL DEFAULT 'generated',
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_math_questions_selection
  ON math_questions (grade, topic, difficulty, is_active);
CREATE INDEX idx_math_questions_skill
  ON math_questions (skill, grade);

CREATE TABLE math_answers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id uuid NOT NULL REFERENCES math_matches(id) ON DELETE CASCADE,
  match_question_id uuid NOT NULL REFERENCES math_match_questions(id) ON DELETE CASCADE,
  player_id uuid NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  question_position integer NOT NULL,
  answer text NOT NULL,
  is_correct boolean NOT NULL DEFAULT false,
  submitted_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  response_ms integer NOT NULL DEFAULT 0 CHECK (response_ms >= 0),
  points integer NOT NULL DEFAULT 0,
  speed_bonus boolean NOT NULL DEFAULT false,
  UNIQUE (match_question_id, player_id)
);

CREATE INDEX idx_math_answers_match
  ON math_answers (match_id, question_position);
CREATE INDEX idx_math_answers_player
  ON math_answers (player_id, match_id);

-- ---------------------------------------------------------------------------
-- Practice, mastery, achievements and XP
-- ---------------------------------------------------------------------------
CREATE TABLE math_practice_answers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id uuid NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  question_id uuid NOT NULL REFERENCES math_questions(id) ON DELETE CASCADE,
  grade smallint NOT NULL,
  topic math_topic NOT NULL,
  skill text NOT NULL,
  answer text NOT NULL,
  is_correct boolean NOT NULL,
  used_hint boolean NOT NULL DEFAULT false,
  elapsed_ms integer NOT NULL DEFAULT 0 CHECK (elapsed_ms >= 0),
  answered_on date NOT NULL DEFAULT CURRENT_DATE,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX idx_math_practice_player
  ON math_practice_answers (player_id, created_at DESC);
CREATE INDEX idx_math_practice_day
  ON math_practice_answers (player_id, answered_on);

CREATE TABLE math_skill_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id uuid NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  grade smallint NOT NULL CHECK (grade BETWEEN 0 AND 5),
  topic math_topic NOT NULL,
  skill text NOT NULL,
  attempts integer NOT NULL DEFAULT 0,
  correct integer NOT NULL DEFAULT 0,
  consecutive_correct integer NOT NULL DEFAULT 0,
  mastery math_mastery NOT NULL DEFAULT 'not_started',
  xp integer NOT NULL DEFAULT 0,
  last_practiced_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (player_id, grade, topic, skill)
);

CREATE INDEX idx_math_skill_progress_player
  ON math_skill_progress (player_id, mastery);

CREATE TABLE math_achievements (
  code text PRIMARY KEY,
  title text NOT NULL,
  description text NOT NULL,
  icon text NOT NULL,
  xp integer NOT NULL DEFAULT 0,
  sort_order integer NOT NULL DEFAULT 0
);

CREATE TABLE math_player_achievements (
  player_id uuid NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  achievement_code text NOT NULL REFERENCES math_achievements(code) ON DELETE CASCADE,
  unlocked_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (player_id, achievement_code)
);

CREATE INDEX idx_math_player_achievements_player
  ON math_player_achievements (player_id, unlocked_at DESC);

CREATE TABLE math_xp_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id uuid NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  amount integer NOT NULL,
  reason text NOT NULL,
  reference text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  UNIQUE (player_id, reference)
);

CREATE INDEX idx_math_xp_player
  ON math_xp_transactions (player_id, created_at DESC);

CREATE TABLE math_rate_events (
  id bigserial PRIMARY KEY,
  player_id uuid NOT NULL,
  action text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX idx_math_rate_events_lookup
  ON math_rate_events (player_id, action, created_at DESC);

-- ---------------------------------------------------------------------------
-- Achievement catalogue
-- ---------------------------------------------------------------------------
INSERT INTO math_achievements (code, title, description, icon, xp, sort_order) VALUES
  ('first_match', 'First Match', 'Finish your first multiplayer math match.', 'rocket', 20, 1),
  ('perfect_match', 'Perfect Match', 'Answer every question correctly in one match.', 'star', 50, 2),
  ('accuracy_star', 'Accuracy Star', 'Finish a match with at least 80% accuracy.', 'target', 30, 3),
  ('speed_champion', 'Speed Champion', 'Earn three legitimate speed bonuses.', 'bolt', 30, 4),
  ('math_explorer', 'Math Explorer', 'Practice three different math topics.', 'compass', 25, 5),
  ('consistent_learner', 'Consistent Learner', 'Practice on three different days.', 'calendar', 35, 6),
  ('skill_master', 'Skill Master', 'Reach Mastered level in any skill.', 'crown', 60, 7),
  ('five_streak', 'High Five Streak', 'Win five matches in a row.', 'flame', 50, 8),
  ('practice_10', 'Practice Pro', 'Answer ten practice questions.', 'pencil', 20, 9),
  ('level_5', 'Rising Star', 'Reach player level 5.', 'sparkle', 40, 10)
ON CONFLICT (code) DO UPDATE
SET title = EXCLUDED.title,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    xp = EXCLUDED.xp,
    sort_order = EXCLUDED.sort_order;

-- ---------------------------------------------------------------------------
-- Shared triggers and secure room codes
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION math_assign_room_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  candidate text;
  attempts integer := 0;
BEGIN
  IF NEW.room_code IS NOT NULL AND length(NEW.room_code) = 6 THEN
    RETURN NEW;
  END IF;

  LOOP
    candidate := '';
    FOR i IN 1..6 LOOP
      candidate := candidate || substr(
        alphabet,
        (get_byte(extensions.gen_random_bytes(1), 0) % length(alphabet)) + 1,
        1
      );
    END LOOP;

    EXIT WHEN NOT EXISTS (SELECT 1 FROM math_rooms WHERE room_code = candidate);

    attempts := attempts + 1;
    IF attempts >= 20 THEN
      RAISE EXCEPTION 'Could not allocate a room code';
    END IF;
  END LOOP;

  NEW.room_code := candidate;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_math_room_code
  BEFORE INSERT ON math_rooms
  FOR EACH ROW EXECUTE FUNCTION math_assign_room_code();

CREATE TRIGGER trg_math_rooms_updated_at
  BEFORE UPDATE ON math_rooms
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- RLS: tables are sealed; clients use SECURITY DEFINER RPCs.
-- The safe room tables are readable for realtime and lobby rendering.
-- ---------------------------------------------------------------------------
ALTER TABLE math_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE math_room_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE math_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE math_match_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE math_match_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE math_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE math_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE math_practice_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE math_skill_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE math_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE math_player_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE math_xp_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE math_rate_events ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE
  math_rooms,
  math_room_players,
  math_matches,
  math_match_players,
  math_match_questions,
  math_questions,
  math_answers,
  math_practice_answers,
  math_skill_progress,
  math_achievements,
  math_player_achievements,
  math_xp_transactions,
  math_rate_events
FROM anon, authenticated;
