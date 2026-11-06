
-- Credit-weighted GPA (4.0 scale) of a student, computed from all
-- COMPLETED registrations that have a letter grade.
-- Uses an EXPLICIT CURSOR (cursor FOR loop).
-- Scale  : A=4.0 B+=3.5 B=3.0 C+=2.5 C=2.0 D=1.0 F=0.0
-- Errors : -20040 student does not exist (handled NO_DATA_FOUND)
--          -20041 student has no graded course yet (GPA undefined, so
--                 we raise an error instead of returning a misleading 0)
--          -20042 unknown letter grade stored in the data
-- =====================================================================
CREATE OR REPLACE FUNCTION calculate_student_gpa (
  p_student_id IN students.student_id%TYPE
) RETURN NUMBER
IS
  v_student_id    students.student_id%TYPE;
  v_points        NUMBER;
  v_total_points  NUMBER := 0;
  v_total_credits NUMBER := 0;

  CURSOR c_graded IS
    SELECT c.credits, r.letter_grade
      FROM registrations r
      JOIN courses c ON c.course_id = r.course_id
     WHERE r.student_id   = p_student_id
       AND r.status       = 'COMPLETED'
       AND r.letter_grade IS NOT NULL;
BEGIN
  BEGIN
    SELECT student_id
      INTO v_student_id
      FROM students
     WHERE student_id = p_student_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20040, 'Student ' || p_student_id || ' does not exist.');
  END;

  FOR rec IN c_graded LOOP
    CASE rec.letter_grade
      WHEN 'A'  THEN v_points := 4;
      WHEN 'B+' THEN v_points := 3.5;
      WHEN 'B'  THEN v_points := 3;
      WHEN 'C+' THEN v_points := 2.5;
      WHEN 'C'  THEN v_points := 2;
      WHEN 'D'  THEN v_points := 1;
      WHEN 'F'  THEN v_points := 0;
      ELSE
        RAISE_APPLICATION_ERROR(-20042, 'Unknown letter grade ''' || rec.letter_grade || '''.');
    END CASE;

    v_total_points  := v_total_points  + (v_points * rec.credits);
    v_total_credits := v_total_credits + rec.credits;
  END LOOP;

  IF v_total_credits = 0 THEN
    RAISE_APPLICATION_ERROR(-20041,
      'Student ' || p_student_id || ' has no graded courses, so the GPA is undefined.');
  END IF;

  RETURN ROUND(v_total_points / v_total_credits, 2);
END calculate_student_gpa;
/
