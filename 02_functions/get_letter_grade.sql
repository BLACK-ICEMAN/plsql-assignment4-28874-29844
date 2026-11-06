-- =====================================================================
-- FUNCTION get_letter_grade
-- Converts a numeric score (0-100) into a letter grade.
-- Errors : -20030 score is NULL or outside 0..100 (never returns a
--          misleading grade for invalid input).
-- Call   : SELECT get_letter_grade(92) FROM dual;
-- =====================================================================
CREATE OR REPLACE FUNCTION get_letter_grade (
  p_score IN NUMBER
) RETURN VARCHAR2
DETERMINISTIC
IS
BEGIN
  IF p_score IS NULL OR p_score < 0 OR p_score > 100 THEN
    RAISE_APPLICATION_ERROR(-20030,
      'Invalid score: ' || NVL(TO_CHAR(p_score), 'NULL') || '. A score must be between 0 and 100.');
  END IF;

  RETURN CASE
           WHEN p_score >= 90 THEN 'A'
           WHEN p_score >= 85 THEN 'B+'
           WHEN p_score >= 80 THEN 'B'
           WHEN p_score >= 75 THEN 'C+'
           WHEN p_score >= 70 THEN 'C'
           WHEN p_score >= 60 THEN 'D'
           ELSE 'F'
         END;
END get_letter_grade;
/
