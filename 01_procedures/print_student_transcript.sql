-- =====================================================================
-- PROCEDURE print_student_transcript
-- Prints the transcript of a student (optionally for one semester).
-- Concepts : user-defined RECORD type, nested table of records,
--            SELECT ... BULK COLLECT INTO, %ROWTYPE record, OUT parameter,
--            function call (calculate_student_gpa), NO_DATA_FOUND.
-- Errors   : -20130 student does not exist
-- Needs    : function calculate_student_gpa (compile functions first)
-- =====================================================================
CREATE OR REPLACE PROCEDURE print_student_transcript (
  p_student_id    IN  students.student_id%TYPE,
  p_semester      IN  registrations.semester%TYPE DEFAULT NULL,
  p_total_credits OUT NUMBER
)
IS
  -- user-defined record: one line of the transcript
  TYPE t_transcript_rec IS RECORD (
    course_code  courses.course_code%TYPE,
    course_name  courses.course_name%TYPE,
    credits      courses.credits%TYPE,
    semester     registrations.semester%TYPE,
    grade_score  registrations.grade_score%TYPE,
    letter_grade registrations.letter_grade%TYPE
  );
  -- collection of those records
  TYPE t_transcript_tab IS TABLE OF t_transcript_rec;

  v_student students%ROWTYPE;     -- %ROWTYPE record
  v_rows    t_transcript_tab;
  v_gpa     NUMBER;
BEGIN
  p_total_credits := 0;

  BEGIN
    SELECT * INTO v_student FROM students WHERE student_id = p_student_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20130, 'Student ' || p_student_id || ' does not exist.');
  END;

  SELECT c.course_code, c.course_name, c.credits, r.semester, r.grade_score, r.letter_grade
    BULK COLLECT INTO v_rows
    FROM registrations r
    JOIN courses c ON c.course_id = r.course_id
   WHERE r.student_id = p_student_id
     AND r.status    <> 'DROPPED'
     AND (p_semester IS NULL OR r.semester = p_semester)
   ORDER BY r.semester, c.course_code;

  DBMS_OUTPUT.PUT_LINE('TRANSCRIPT: ' || v_student.first_name || ' ' || v_student.last_name ||
                       ' (ID ' || v_student.student_id || ', ' || v_student.status || ')');
  DBMS_OUTPUT.PUT_LINE(RPAD('Semester', 11) || RPAD('Code', 10) || RPAD('Course', 44) ||
                       RPAD('Cr', 4) || RPAD('Score', 8) || 'Grade');
  DBMS_OUTPUT.PUT_LINE(RPAD('-', 82, '-'));

  IF v_rows.COUNT = 0 THEN
    DBMS_OUTPUT.PUT_LINE('(no registrations found)');
  ELSE
    FOR i IN 1 .. v_rows.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE(
        RPAD(v_rows(i).semester, 11) ||
        RPAD(v_rows(i).course_code, 10) ||
        RPAD(SUBSTR(v_rows(i).course_name, 1, 42), 44) ||
        RPAD(v_rows(i).credits, 4) ||
        RPAD(NVL(TO_CHAR(v_rows(i).grade_score), '--'), 8) ||
        NVL(v_rows(i).letter_grade, '--'));

      IF v_rows(i).letter_grade IS NOT NULL AND v_rows(i).letter_grade <> 'F' THEN
        p_total_credits := p_total_credits + v_rows(i).credits;
      END IF;
    END LOOP;
  END IF;

  DBMS_OUTPUT.PUT_LINE(RPAD('-', 82, '-'));
  DBMS_OUTPUT.PUT_LINE('Credits earned: ' || p_total_credits);

  -- The GPA may legitimately be undefined (-20041); any other error is re-raised.
  BEGIN
    v_gpa := calculate_student_gpa(p_student_id);
    DBMS_OUTPUT.PUT_LINE('GPA: ' || TO_CHAR(v_gpa, 'FM0.00'));
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -20041 THEN
        DBMS_OUTPUT.PUT_LINE('GPA: not available (no graded courses yet)');
      ELSE
        RAISE;
      END IF;
  END;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END print_student_transcript;
/
