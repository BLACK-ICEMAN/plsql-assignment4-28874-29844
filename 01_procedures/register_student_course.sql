-- =====================================================================
-- PROCEDURE register_student_course
-- Registers ONE student in ONE course for a semester.
-- Concepts : %ROWTYPE records, implicit cursor (INSERT + SQL%ROWCOUNT),
--            OUT parameter, predefined + user-defined exceptions,
--            RAISE_APPLICATION_ERROR.
-- Errors   : -20001 student does not exist     (NO_DATA_FOUND)
--            -20002 course does not exist      (NO_DATA_FOUND)
--            -20003 student is not ACTIVE      (user-defined exception)
--            -20004 course is full             (user-defined exception)
--            -20005 already registered         (DUP_VAL_ON_INDEX)
-- The procedure does not COMMIT: the caller controls the transaction.
-- =====================================================================
CREATE OR REPLACE PROCEDURE register_student_course (
  p_student_id IN  students.student_id%TYPE,
  p_course_id  IN  courses.course_id%TYPE,
  p_semester   IN  registrations.semester%TYPE,
  p_reg_id     OUT registrations.reg_id%TYPE
)
IS
  v_student students%ROWTYPE;      -- record based on a table row
  v_course  courses%ROWTYPE;       -- record based on a table row
  v_taken   PLS_INTEGER;
  v_rows    PLS_INTEGER;

  e_student_inactive EXCEPTION;    -- user-defined exceptions
  e_course_full      EXCEPTION;
BEGIN
  -- 1. Load the student record
  BEGIN
    SELECT * INTO v_student FROM students WHERE student_id = p_student_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001, 'Student ' || p_student_id || ' does not exist.');
  END;

  IF v_student.status <> 'ACTIVE' THEN
    RAISE e_student_inactive;
  END IF;

  -- 2. Load (and lock) the course record so two sessions cannot take the last seat together
  BEGIN
    SELECT * INTO v_course FROM courses WHERE course_id = p_course_id FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'Course ' || p_course_id || ' does not exist.');
  END;

  -- 3. Capacity check
  SELECT COUNT(*)
    INTO v_taken
    FROM registrations
   WHERE course_id = p_course_id
     AND semester  = p_semester
     AND status   <> 'DROPPED';

  IF v_taken >= v_course.capacity THEN
    RAISE e_course_full;
  END IF;

  -- 4. Insert the registration (implicit cursor)
  INSERT INTO registrations (reg_id, student_id, course_id, semester, status)
  VALUES (seq_reg_id.NEXTVAL, p_student_id, p_course_id, p_semester, 'REGISTERED')
  RETURNING reg_id INTO p_reg_id;

  v_rows := SQL%ROWCOUNT;          -- capture the attribute immediately
  DBMS_OUTPUT.PUT_LINE('Registered ' || v_student.first_name || ' ' || v_student.last_name ||
                       ' in ' || v_course.course_code || ' (' || p_semester || ').');
  DBMS_OUTPUT.PUT_LINE('Rows inserted (SQL%ROWCOUNT) = ' || v_rows || ', new reg_id = ' || p_reg_id);
EXCEPTION
  WHEN e_student_inactive THEN
    RAISE_APPLICATION_ERROR(-20003,
      'Student ' || p_student_id || ' is ' || v_student.status || ' and cannot register for courses.');
  WHEN e_course_full THEN
    RAISE_APPLICATION_ERROR(-20004,
      'Course ' || v_course.course_code || ' is full (' || v_taken || '/' || v_course.capacity ||
      ') for ' || p_semester || '.');
  WHEN DUP_VAL_ON_INDEX THEN
    RAISE_APPLICATION_ERROR(-20005,
      'Student ' || p_student_id || ' is already registered (or has a dropped record) for course ' ||
      p_course_id || ' in ' || p_semester || '.');
  WHEN OTHERS THEN
    RAISE;   -- re-raise anything unexpected (including -20001 / -20002): never hide an error
END register_student_course;
/
