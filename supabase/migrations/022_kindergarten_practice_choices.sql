-- ============================================================================
-- Migration 022: Three picture-friendly choices for Kindergarten practice
--
-- A four-year-old is still learning to scan a set of choices. Kindergarten
-- practice therefore returns three options instead of four. The correct answer
-- is always kept, and the other choice is dropped only after the server has
-- selected the question. Competitive rooms still use the full question bank.
-- ============================================================================

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
  v_options text[];
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

  IF v_question.grade = 0 AND cardinality(v_question.options) > 3 THEN
    SELECT array_agg(opt ORDER BY ord)
    INTO v_options
    FROM (
      SELECT opt, ord
      FROM unnest(v_question.options) WITH ORDINALITY AS t(opt, ord)
      ORDER BY (lower(opt) = lower(v_question.correct_answer)) DESC, ord
      LIMIT 3
    ) picked;
  END IF;

  RETURN jsonb_build_object(
    'id', v_question.id,
    'grade', v_question.grade,
    'topic', v_question.topic,
    'skill', v_question.skill,
    'difficulty', v_question.difficulty,
    'text', v_question.question_text,
    'options', to_jsonb(coalesce(v_options, v_question.options)),
    'answer_type', v_question.answer_type,
    'hint', v_question.hint,
    'visual', v_question.visual,
    'estimated_seconds', v_question.estimated_seconds
  );
END;
$$;

REVOKE ALL ON FUNCTION math_next_practice_question(integer, math_topic) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION math_next_practice_question(integer, math_topic) TO authenticated;
