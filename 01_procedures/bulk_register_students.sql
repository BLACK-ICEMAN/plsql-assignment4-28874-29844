-- =====================================================================
-- PROCEDURE bulk_register_students
-- Registers MANY students (nested-table parameter) in one course with a
-- single FORALL INSERT ... SAVE EXCEPTIONS.
-- Rows that fail (duplicate registration, unknown student id, ...) are
-- reported through SQL%BULK_EXCEPTIONS while the valid rows are kept.
-- Concepts : nested table (t_id_list), %ROWTYPE record, FORALL,
--            SAVE EXCEPTIONS / ORA-24381, SQL%BULK_EXCEPTIONS,
--            OUT parameters, user-defined exceptions.
-- Errors   : -20110 course does not exist
--            -20111 list of students is NULL or empty
--            -20112 not enough free seats for the whole list
-- Note     : capacity is checked for the whole list BEFORE inserting
--            (all-or-nothing for capacity, partial success for row errors).
-- =====================================================================
CREATE OR REPLACE PROCEDURE bulk_register_students (
  p_course_id   IN  courses.course_id%TYPE,
  p_semester    IN  registrations.semester%TYPE,
  p_student_ids IN  t_id_list,
  p_registered  OUT NUMBER,
  p_failed      OUT NUMBER
)
IS
  v_course    courses%ROWTYPE;
  v_taken     NUMBER;
  v_available NUMBER;

  e_empty_list       EXCEPTION;
  e_not_enough_seats EXCEPTION;
  e_bulk_errors      EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);   -- ORA-24381: error(s) in array DML
BEGIN
  p_registered := 0;
  p_failed     := 0;

  IF p_student_ids IS NULL OR p_student_ids.COUNT = 0 THEN
    RAISE e_empty_list;
  END IF;

  BEGIN
    SELECT * INTO v_course FROM courses WHERE course_id = p_course_id FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20110, 'Course ' || p_course_id || ' does not exist.');
  END;

  SELECT COUNT(*)
    INTO v_taken
    FROM registrations
   WHERE course_id = p_course_id
     AND semester  = p_semester
     AND status   <> 'DROPPED';

  v_available := v_course.capacity - v_taken;

  IF p_student_ids.COUNT > v_available THEN
    RAISE e_not_enough_seats;
  END IF;

  -- One context switch to the SQL engine for the whole collection
  BEGIN
    FORALL i IN 1 .. p_student_ids.COUNT SAVE EXCEPTIONS
      INSERT INTO registrations (reg_id, student_id, course_id, semester, status)
      VALUES (seq_reg_id.NEXTVAL, p_student_ids(i), p_course_id, p_semester, 'REGISTERED');

    p_registered := SQL%ROWCOUNT;
  EXCEPTION
    WHEN e_bulk_errors THEN
      p_failed     := SQL%BULK_EXCEPTIONS.COUNT;
      p_registered := p_student_ids.COUNT - p_failed;

      FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('  FAILED student_id=' ||
          p_student_ids(SQL%BULK_EXCEPTIONS(j).ERROR_INDEX) || ' -> ' ||
          SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE));
      END LOOP;
  END;

  DBMS_OUTPUT.PUT_LINE('Bulk registration in ' || v_course.course_code || ' (' || p_semester ||
                       '): registered=' || p_registered || ', failed=' || p_failed);
EXCEPTION
  WHEN e_empty_list THEN
    RAISE_APPLICATION_ERROR(-20111, 'The list of student ids is NULL or empty.');
  WHEN e_not_enough_seats THEN
    RAISE_APPLICATION_ERROR(-20112,
      'Only ' || v_available || ' seat(s) left in ' || v_course.course_code ||
      ' for ' || p_semester || ' but ' || p_student_ids.COUNT || ' student(s) were submitted.');
  WHEN OTHERS THEN
    RAISE;
END bulk_register_students;
/
