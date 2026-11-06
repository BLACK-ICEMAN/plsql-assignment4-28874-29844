-- =====================================================================
-- FUNCTION find_student_id_by_last_name
-- Returns the id of the ONE student having the given last name
-- (case-insensitive). Demonstrates the predefined exceptions
-- NO_DATA_FOUND and TOO_MANY_ROWS.
-- Errors : -20060 no student has this last name
--          -20061 more than one student has this last name
-- =====================================================================
CREATE OR REPLACE FUNCTION find_student_id_by_last_name (
  p_last_name IN students.last_name%TYPE
) RETURN students.student_id%TYPE
IS
  v_student_id students.student_id%TYPE;
BEGIN
  SELECT student_id
    INTO v_student_id
    FROM students
   WHERE UPPER(last_name) = UPPER(TRIM(p_last_name));

  RETURN v_student_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20060, 'No student found with last name ''' || p_last_name || '''.');
  WHEN TOO_MANY_ROWS THEN
    RAISE_APPLICATION_ERROR(-20061,
      'More than one student has the last name ''' || p_last_name || '''. Search by student id instead.');
END find_student_id_by_last_name;
/
