-- ============================================================================
-- Migration 024: Typed answers for older-grade practice
--
-- Grades 2-5 can type a numeric or fraction answer instead of tapping a
-- choice. The server still validates the answer against the stored correct
-- answer, so the client never decides correctness.
-- ============================================================================

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
  -- Practice accepts either an option or a typed numeric/fraction answer.
  -- Correctness is still decided here on the server, never on the client.
  IF v_answer = '' THEN
    RAISE EXCEPTION 'Choose or type an answer';
  END IF;
  IF NOT (v_answer = ANY(v_question.options))
     AND v_answer !~ '^-?[0-9]+([./][0-9]+)?$' THEN
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
