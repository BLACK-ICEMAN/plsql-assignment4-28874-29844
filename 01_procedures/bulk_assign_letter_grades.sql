-- =====================================================================
-- PROCEDURE bulk_assign_letter_grades
-- For one course/semester, converts every recorded score that has no
-- letter grade yet into a letter grade and marks the registration
-- COMPLETED.
-- Concepts : explicit cursor (OPEN / FETCH ... BULK COLLECT ... LIMIT /
--            CLOSE), associative arrays, FORALL UPDATE with SAVE
--            EXCEPTIONS, function call (get_letter_grade), OUT params.
-- Errors   : -20100 course does not exist
-- Needs    : function get_letter_grade (compile functions first)
-- =====================================================================
CREATE OR REPLACE PROCEDURE bulk_assign_letter_grades (
  p_course_id IN  courses.course_id%TYPE,
  p_semester  IN  registrations.semester%TYPE,
  p_updated   OUT NUMBER,
  p_failed    OUT NUMBER
)
IS
  TYPE t_id_tab     IS TABLE OF registrations.reg_id%TYPE       INDEX BY PLS_INTEGER;
  TYPE t_score_tab  IS TABLE OF registrations.grade_score%TYPE  INDEX BY PLS_INTEGER;
  TYPE t_letter_tab IS TABLE OF registrations.letter_grade%TYPE INDEX BY PLS_INTEGER;

  v_ids     t_id_tab;
  v_scores  t_score_tab;
  v_letters t_letter_tab;

  c_batch_size CONSTANT PLS_INTEGER := 100;
  v_course_id  courses.course_id%TYPE;

  e_bulk_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);

  CURSOR c_ungraded IS
    SELECT reg_id, grade_score
      FROM registrations
     WHERE course_id    = p_course_id
       AND semester     = p_semester
       AND status       = 'REGISTERED'
       AND grade_score  IS NOT NULL
       AND letter_grade IS NULL
     ORDER BY reg_id;
BEGIN
  p_updated := 0;
  p_failed  := 0;

  BEGIN
    SELECT course_id INTO v_course_id FROM courses WHERE course_id = p_course_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20100, 'Course ' || p_course_id || ' does not exist.');
  END;

  OPEN c_ungraded;
  LOOP
    -- fetch up to 100 rows at once into collections (one context switch per batch)
    FETCH c_ungraded BULK COLLECT INTO v_ids, v_scores LIMIT c_batch_size;
    EXIT WHEN v_ids.COUNT = 0;

    FOR i IN 1 .. v_ids.COUNT LOOP
      v_letters(i) := get_letter_grade(v_scores(i));
    END LOOP;

    BEGIN
      FORALL i IN 1 .. v_ids.COUNT SAVE EXCEPTIONS
        UPDATE registrations
           SET letter_grade = v_letters(i),
               status       = 'COMPLETED'
         WHERE reg_id = v_ids(i);

      p_updated := p_updated + SQL%ROWCOUNT;
    EXCEPTION
      WHEN e_bulk_errors THEN
        p_failed  := p_failed  + SQL%BULK_EXCEPTIONS.COUNT;
        p_updated := p_updated + (v_ids.COUNT - SQL%BULK_EXCEPTIONS.COUNT);

        FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
          DBMS_OUTPUT.PUT_LINE('  FAILED reg_id=' || v_ids(SQL%BULK_EXCEPTIONS(j).ERROR_INDEX) ||
                               ' -> ' || SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE));
        END LOOP;
    END;
  END LOOP;
  CLOSE c_ungraded;

  DBMS_OUTPUT.PUT_LINE('Letter grades assigned for course ' || p_course_id || ' (' || p_semester ||
                       '): updated=' || p_updated || ', failed=' || p_failed);
EXCEPTION
  WHEN OTHERS THEN
    IF c_ungraded%ISOPEN THEN
      CLOSE c_ungraded;
    END IF;
    RAISE;
END bulk_assign_letter_grades;
/
