-- =====================================================================
-- PROCEDURE record_student_score
-- Stores the numeric score of an open (REGISTERED) registration.
-- Concepts : implicit cursor (UPDATE + SQL%FOUND / SQL%NOTFOUND),
--            user-defined exceptions, RAISE_APPLICATION_ERROR.
-- Errors   : -20080 score is NULL or outside 0..100
--            -20081 registration does not exist or is not REGISTERED
-- =====================================================================
CREATE OR REPLACE PROCEDURE record_student_score (
  p_reg_id IN registrations.reg_id%TYPE,
  p_score  IN registrations.grade_score%TYPE
)
IS
  v_rows PLS_INTEGER;

  e_invalid_score  EXCEPTION;
  e_reg_not_open   EXCEPTION;
BEGIN
  IF p_score IS NULL OR p_score < 0 OR p_score > 100 THEN
    RAISE e_invalid_score;
  END IF;

  UPDATE registrations
     SET grade_score = p_score
   WHERE reg_id = p_reg_id
     AND status = 'REGISTERED';

  IF SQL%NOTFOUND THEN
    RAISE e_reg_not_open;
  END IF;

  v_rows := SQL%ROWCOUNT;
  DBMS_OUTPUT.PUT_LINE('Score ' || p_score || ' saved for registration ' || p_reg_id ||
                       '. SQL%FOUND = TRUE, SQL%ROWCOUNT = ' || v_rows);
EXCEPTION
  WHEN e_invalid_score THEN
    RAISE_APPLICATION_ERROR(-20080,
      'Invalid score ' || NVL(TO_CHAR(p_score), 'NULL') || '. A score must be between 0 and 100.');
  WHEN e_reg_not_open THEN
    RAISE_APPLICATION_ERROR(-20081,
      'Registration ' || p_reg_id || ' does not exist or is not in REGISTERED status.');
  WHEN OTHERS THEN
    RAISE;
END record_student_score;
/
