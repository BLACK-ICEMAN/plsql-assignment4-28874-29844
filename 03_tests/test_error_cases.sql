-- =====================================================================
-- test_error_cases.sql
-- Exception handling. Each call is WRAPPED in a block that catches the
-- error ONLY to print it (so we can take a screenshot). The procedures
-- and functions themselves never hide errors: they raise them to the
-- caller with RAISE_APPLICATION_ERROR or re-raise them.
-- Every block ends with ROLLBACK, so the file can be re-run.
-- =====================================================================

-- ==== TEST e01_student_or_course_not_found | NO_DATA_FOUND -> ORA-20001 / ORA-20002 ====
SET SERVEROUTPUT ON
DECLARE
  v_reg registrations.reg_id%TYPE;
BEGIN
  BEGIN
    register_student_course(99999, 101, '2026-FALL', v_reg);
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (unknown student): ' || SQLERRM);
  END;

  BEGIN
    register_student_course(1004, 999, '2026-FALL', v_reg);
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (unknown course) : ' || SQLERRM);
  END;
END;
/
ROLLBACK;

-- ==== TEST e02_student_suspended | user-defined exception e_student_inactive -> ORA-20003 ====
SET SERVEROUTPUT ON
DECLARE
  v_reg registrations.reg_id%TYPE;
BEGIN
  register_student_course(1009, 101, '2026-FALL', v_reg);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
ROLLBACK;

-- ==== TEST e03_course_full | user-defined exception e_course_full -> ORA-20004 ====
SET SERVEROUTPUT ON
DECLARE
  v_reg registrations.reg_id%TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Seats left in INSY350 (2026-FALL): ' || get_course_available_seats(106, '2026-FALL'));
  register_student_course(1001, 106, '2026-FALL', v_reg);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
ROLLBACK;

-- ==== TEST e04_duplicate_registration | predefined exception DUP_VAL_ON_INDEX -> ORA-20005 ====
SET SERVEROUTPUT ON
DECLARE
  v_reg registrations.reg_id%TYPE;
BEGIN
  -- student 1001 is already registered in INSY229 for 2026-FALL (reg 9)
  register_student_course(1001, 102, '2026-FALL', v_reg);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
ROLLBACK;

-- ==== TEST e05_drop_registration_not_found | NO_DATA_FOUND -> ORA-20011 ====
SET SERVEROUTPUT ON
BEGIN
  drop_registration(99999);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
ROLLBACK;

-- ==== TEST e06_drop_registration_not_droppable | SQL%NOTFOUND + user-defined exception -> ORA-20012 ====
SET SERVEROUTPUT ON
BEGIN
  -- reg 19 is already DROPPED, reg 1 is COMPLETED
  BEGIN
    drop_registration(19);
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (already dropped): ' || SQLERRM);
  END;

  BEGIN
    drop_registration(1);
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (completed)      : ' || SQLERRM);
  END;
END;
/
ROLLBACK;

-- ==== TEST e07_invalid_score | user-defined exception e_invalid_score -> ORA-20080 ====
SET SERVEROUTPUT ON
BEGIN
  BEGIN
    record_student_score(12, 150);
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (score 150) : ' || SQLERRM);
  END;

  BEGIN
    record_student_score(12, NULL);
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (score NULL): ' || SQLERRM);
  END;
END;
/
ROLLBACK;

-- ==== TEST e08_score_registration_not_open | SQL%NOTFOUND + user-defined exception -> ORA-20081 ====
SET SERVEROUTPUT ON
BEGIN
  BEGIN
    record_student_score(1, 80);       -- reg 1 is already COMPLETED
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (completed reg)  : ' || SQLERRM);
  END;

  BEGIN
    record_student_score(99999, 80);   -- reg does not exist
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (unknown reg)    : ' || SQLERRM);
  END;
END;
/
ROLLBACK;

-- ==== TEST e09_bulk_register_invalid_input | ORA-20110 / ORA-20111 ====
SET SERVEROUTPUT ON
DECLARE
  v_ok NUMBER;
  v_ko NUMBER;
BEGIN
  BEGIN
    bulk_register_students(101, '2026-FALL', t_id_list(), v_ok, v_ko);          -- empty collection
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (empty list)  : ' || SQLERRM);
  END;

  BEGIN
    bulk_register_students(101, '2026-FALL', NULL, v_ok, v_ko);                -- atomically NULL collection
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (NULL list)   : ' || SQLERRM);
  END;

  BEGIN
    bulk_register_students(999, '2026-FALL', t_id_list(1004), v_ok, v_ko);      -- unknown course
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (bad course)  : ' || SQLERRM);
  END;
END;
/
ROLLBACK;

-- ==== TEST e10_bulk_register_not_enough_seats | user-defined exception e_not_enough_seats -> ORA-20112 ====
SET SERVEROUTPUT ON
DECLARE
  v_ok NUMBER;
  v_ko NUMBER;
BEGIN
  -- INSY350 has capacity 2 and is already full for 2026-FALL
  bulk_register_students(106, '2026-FALL', t_id_list(1001, 1004), v_ok, v_ko);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
ROLLBACK;

-- ==== TEST e11_bulk_grades_course_not_found | NO_DATA_FOUND -> ORA-20100 ====
SET SERVEROUTPUT ON
DECLARE
  v_updated NUMBER;
  v_failed  NUMBER;
BEGIN
  bulk_assign_letter_grades(999, '2026-FALL', v_updated, v_failed);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
ROLLBACK;

-- ==== TEST e12_invalid_score_for_letter_grade | function get_letter_grade -> ORA-20030 ====
SET SERVEROUTPUT ON
DECLARE
  v_grade VARCHAR2(2);
BEGIN
  BEGIN
    v_grade := get_letter_grade(150);
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (score 150): ' || SQLERRM);
  END;

  BEGIN
    v_grade := get_letter_grade(NULL);
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (score NULL): ' || SQLERRM);
  END;
END;
/
ROLLBACK;

-- ==== TEST e13_gpa_errors | function calculate_student_gpa: NO_DATA_FOUND -> ORA-20040, no graded course -> ORA-20041 ====
SET SERVEROUTPUT ON
DECLARE
  v_gpa NUMBER;
BEGIN
  BEGIN
    v_gpa := calculate_student_gpa(99999);     -- student does not exist
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (unknown student) : ' || SQLERRM);
  END;

  BEGIN
    v_gpa := calculate_student_gpa(1007);      -- student exists but has no graded course
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (no graded course): ' || SQLERRM);
  END;
END;
/
ROLLBACK;

-- ==== TEST e14_find_student_errors | predefined NO_DATA_FOUND and TOO_MANY_ROWS -> ORA-20060 / ORA-20061 ====
SET SERVEROUTPUT ON
DECLARE
  v_id students.student_id%TYPE;
BEGIN
  BEGIN
    v_id := find_student_id_by_last_name('Nobody');      -- no row   -> NO_DATA_FOUND
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (no match)       : ' || SQLERRM);
  END;

  BEGIN
    v_id := find_student_id_by_last_name('Mugisha');     -- 2 rows   -> TOO_MANY_ROWS
  EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR (several matches): ' || SQLERRM);
  END;
END;
/
ROLLBACK;

-- ==== TEST e15_transcript_student_not_found | NO_DATA_FOUND -> ORA-20130 ====
SET SERVEROUTPUT ON
DECLARE
  v_credits NUMBER;
BEGIN
  print_student_transcript(p_student_id => 99999, p_total_credits => v_credits);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
ROLLBACK;

-- ==== TEST e16_report_department_not_found | NO_DATA_FOUND -> ORA-20120 ====
SET SERVEROUTPUT ON
DECLARE
  v_listed NUMBER;
BEGIN
  report_course_enrollment(p_semester => '2026-FALL', p_dept_id => 999, p_courses_listed => v_listed);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
ROLLBACK;

-- ==== TEST e17_unexpected_error_is_not_hidden | an unexpected Oracle error is re-raised, not swallowed ====
SET SERVEROUTPUT ON
DECLARE
  v_reg registrations.reg_id%TYPE;
BEGIN
  -- semester NULL violates NOT NULL: not one of our business rules, so the procedure re-raises it (ORA-01400)
  register_student_course(1004, 105, NULL, v_reg);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
ROLLBACK;
