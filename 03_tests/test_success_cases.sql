-- =====================================================================
-- test_success_cases.sql
-- Successful executions. Every test block is independent:
--   * it starts with SET SERVEROUTPUT ON
--   * it ends with ROLLBACK so the sample data is back to normal
--     (the test file can be re-run any number of times).
-- Run the whole file (F5 in SQL Developer) or select ONE block at a
-- time (marker line to ROLLBACK;), press F5 and take the screenshot.
-- =====================================================================

-- ==== TEST s00_schema_and_objects | Tables, row counts and compilation status of all objects ====
SET SERVEROUTPUT ON
SELECT table_name
  FROM user_tables
 WHERE table_name IN ('DEPARTMENTS', 'STUDENTS', 'COURSES', 'REGISTRATIONS')
 ORDER BY table_name;

SELECT (SELECT COUNT(*) FROM departments)  AS departments,
       (SELECT COUNT(*) FROM students)     AS students,
       (SELECT COUNT(*) FROM courses)      AS courses,
       (SELECT COUNT(*) FROM registrations) AS registrations
  FROM dual;

SELECT object_type, object_name, status
  FROM user_objects
 WHERE object_name IN ('T_ID_LIST', 'SEQ_REG_ID',
                       'REGISTER_STUDENT_COURSE', 'DROP_REGISTRATION', 'PURGE_DROPPED_REGISTRATIONS',
                       'RECORD_STUDENT_SCORE', 'BULK_REGISTER_STUDENTS', 'BULK_ASSIGN_LETTER_GRADES',
                       'PRINT_STUDENT_TRANSCRIPT', 'REPORT_COURSE_ENROLLMENT',
                       'GET_LETTER_GRADE', 'CALCULATE_STUDENT_GPA',
                       'GET_COURSE_AVAILABLE_SEATS', 'FIND_STUDENT_ID_BY_LAST_NAME')
 ORDER BY object_type, object_name;

-- ==== TEST s01_register_student_course | register_student_course: %ROWTYPE records + implicit INSERT cursor ====
SET SERVEROUTPUT ON
DECLARE
  v_reg_id registrations.reg_id%TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Seats left in SENG201 (2026-FALL) BEFORE: ' || get_course_available_seats(105, '2026-FALL'));
  register_student_course(p_student_id => 1004,
                          p_course_id  => 105,
                          p_semester   => '2026-FALL',
                          p_reg_id     => v_reg_id);
  DBMS_OUTPUT.PUT_LINE('OUT parameter p_reg_id = ' || v_reg_id);
  DBMS_OUTPUT.PUT_LINE('Seats left in SENG201 (2026-FALL) AFTER : ' || get_course_available_seats(105, '2026-FALL'));
END;
/
ROLLBACK;

-- ==== TEST s02_drop_registration | drop_registration: implicit UPDATE cursor (SQL%NOTFOUND / SQL%ROWCOUNT) ====
SET SERVEROUTPUT ON
DECLARE
  v_reg_id registrations.reg_id%TYPE;
  v_status registrations.status%TYPE;
BEGIN
  register_student_course(1004, 105, '2026-FALL', v_reg_id);
  drop_registration(v_reg_id);

  SELECT status INTO v_status FROM registrations WHERE reg_id = v_reg_id;
  DBMS_OUTPUT.PUT_LINE('Status stored in the table now: ' || v_status);
  DBMS_OUTPUT.PUT_LINE('Seats left in SENG201 (2026-FALL): ' || get_course_available_seats(105, '2026-FALL') ||
                       ' (the dropped seat is free again)');
END;
/
ROLLBACK;

-- ==== TEST s03_purge_dropped_registrations | purge_dropped_registrations: implicit DELETE cursor (SQL%FOUND / SQL%NOTFOUND) ====
SET SERVEROUTPUT ON
DECLARE
  v_deleted NUMBER;
BEGIN
  purge_dropped_registrations('2025-FALL', v_deleted);
  DBMS_OUTPUT.PUT_LINE('OUT p_deleted = ' || v_deleted);

  -- second call: nothing left to delete -> SQL%NOTFOUND branch
  purge_dropped_registrations('2025-FALL', v_deleted);
  DBMS_OUTPUT.PUT_LINE('OUT p_deleted = ' || v_deleted);
END;
/
ROLLBACK;

-- ==== TEST s04_record_student_score | record_student_score: implicit UPDATE cursor (SQL%FOUND) ====
SET SERVEROUTPUT ON
DECLARE
  v_score registrations.grade_score%TYPE;
BEGIN
  record_student_score(p_reg_id => 12, p_score => 70);

  SELECT grade_score INTO v_score FROM registrations WHERE reg_id = 12;
  DBMS_OUTPUT.PUT_LINE('grade_score stored in the table for reg 12 = ' || v_score);
END;
/
ROLLBACK;

-- ==== TEST s05_bulk_register_students | bulk_register_students: nested table + FORALL ... SAVE EXCEPTIONS ====
SET SERVEROUTPUT ON
DECLARE
  v_registered NUMBER;
  v_failed     NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Seats left in INSY8311 (2026-FALL) BEFORE: ' || get_course_available_seats(101, '2026-FALL'));

  -- 1004, 1007, 1010 are valid; 1006 is already registered; 9999 does not exist
  bulk_register_students(p_course_id   => 101,
                         p_semester    => '2026-FALL',
                         p_student_ids => t_id_list(1004, 1006, 1007, 9999, 1010),
                         p_registered  => v_registered,
                         p_failed      => v_failed);

  DBMS_OUTPUT.PUT_LINE('OUT p_registered = ' || v_registered || ', OUT p_failed = ' || v_failed);
  DBMS_OUTPUT.PUT_LINE('Seats left in INSY8311 (2026-FALL) AFTER : ' || get_course_available_seats(101, '2026-FALL'));
END;
/
ROLLBACK;

-- ==== TEST s06_bulk_assign_letter_grades | bulk_assign_letter_grades: explicit cursor + BULK COLLECT LIMIT + FORALL UPDATE ====
SET SERVEROUTPUT ON
DECLARE
  v_updated NUMBER;
  v_failed  NUMBER;
BEGIN
  bulk_assign_letter_grades(p_course_id => 101,
                            p_semester  => '2026-FALL',
                            p_updated   => v_updated,
                            p_failed    => v_failed);
  DBMS_OUTPUT.PUT_LINE('OUT p_updated = ' || v_updated || ', OUT p_failed = ' || v_failed);

  FOR rec IN (SELECT reg_id, student_id, grade_score, letter_grade, status
                FROM registrations
               WHERE course_id = 101
                 AND semester  = '2026-FALL'
               ORDER BY reg_id)
  LOOP
    DBMS_OUTPUT.PUT_LINE('reg ' || rec.reg_id || ' | student ' || rec.student_id ||
                         ' | score ' || rec.grade_score || ' | grade ' || rec.letter_grade ||
                         ' | ' || rec.status);
  END LOOP;
END;
/
ROLLBACK;

-- ==== TEST s07_print_student_transcript | print_student_transcript: user-defined record + collection of records ====
SET SERVEROUTPUT ON
DECLARE
  v_credits NUMBER;
BEGIN
  print_student_transcript(p_student_id => 1001, p_total_credits => v_credits);
  DBMS_OUTPUT.PUT_LINE('OUT p_total_credits = ' || v_credits);
  DBMS_OUTPUT.PUT_LINE(' ');

  -- student without any graded course: the GPA is reported as "not available"
  print_student_transcript(p_student_id => 1007, p_total_credits => v_credits);
  DBMS_OUTPUT.PUT_LINE('OUT p_total_credits = ' || v_credits);
END;
/
ROLLBACK;

-- ==== TEST s08_report_course_enrollment | report_course_enrollment: parameterized explicit cursor + associative array ====
SET SERVEROUTPUT ON
DECLARE
  v_listed NUMBER;
BEGIN
  report_course_enrollment(p_semester => '2026-FALL', p_courses_listed => v_listed);
  DBMS_OUTPUT.PUT_LINE('OUT p_courses_listed = ' || v_listed);
  DBMS_OUTPUT.PUT_LINE(' ');

  -- only the Software Engineering department (dept_id = 30)
  report_course_enrollment(p_semester => '2026-FALL', p_dept_id => 30, p_courses_listed => v_listed);
  DBMS_OUTPUT.PUT_LINE('OUT p_courses_listed = ' || v_listed);
END;
/
ROLLBACK;

-- ==== TEST s09_functions | Functions called from SQL statements and from an anonymous PL/SQL block ====
SET SERVEROUTPUT ON
-- (a) from SQL statements
SELECT get_letter_grade(92)   AS grade_92,
       get_letter_grade(85)   AS grade_85,
       get_letter_grade(59.9) AS grade_59_9
  FROM dual;

SELECT course_code,
       capacity,
       get_course_available_seats(course_id, '2026-FALL') AS seats_left
  FROM courses
 ORDER BY course_code;

-- (b) from an anonymous block
DECLARE
  v_id  students.student_id%TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('GPA of student 1001 = ' || calculate_student_gpa(1001));
  DBMS_OUTPUT.PUT_LINE('GPA of student 1005 = ' || calculate_student_gpa(1005));

  v_id := find_student_id_by_last_name('Uwase');
  DBMS_OUTPUT.PUT_LINE('Student with last name Uwase has id = ' || v_id);
END;
/
ROLLBACK;
