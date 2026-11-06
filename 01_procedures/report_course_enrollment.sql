-- =====================================================================
-- PROCEDURE report_course_enrollment
-- Enrollment report: enrolled / capacity per course for a semester,
-- optionally restricted to one department.
-- Concepts : explicit PARAMETERIZED cursor with OPEN / FETCH / CLOSE,
--            cursor%ROWTYPE record, cursor attributes (%NOTFOUND,
--            %ROWCOUNT, %ISOPEN), associative array indexed by VARCHAR2.
-- Errors   : -20120 department does not exist (NO_DATA_FOUND)
-- =====================================================================
CREATE OR REPLACE PROCEDURE report_course_enrollment (
  p_semester       IN  registrations.semester%TYPE,
  p_dept_id        IN  departments.dept_id%TYPE DEFAULT NULL,
  p_courses_listed OUT NUMBER
)
IS
  CURSOR c_courses (cp_semester VARCHAR2, cp_dept_id NUMBER) IS
    SELECT c.course_code,
           c.course_name,
           c.capacity,
           COUNT(r.reg_id) AS enrolled
      FROM courses c
      LEFT JOIN registrations r
             ON r.course_id = c.course_id
            AND r.semester  = cp_semester
            AND r.status   <> 'DROPPED'
     WHERE cp_dept_id IS NULL OR c.dept_id = cp_dept_id
     GROUP BY c.course_code, c.course_name, c.capacity
     ORDER BY c.course_code;

  v_course c_courses%ROWTYPE;                          -- record shaped like the cursor row

  TYPE t_fill_tab IS TABLE OF NUMBER INDEX BY VARCHAR2(20);   -- associative array: course code -> fill %
  v_fill t_fill_tab;
  v_key  VARCHAR2(20);

  v_dept_id departments.dept_id%TYPE;
BEGIN
  p_courses_listed := 0;

  IF p_dept_id IS NOT NULL THEN
    BEGIN
      SELECT dept_id INTO v_dept_id FROM departments WHERE dept_id = p_dept_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20120, 'Department ' || p_dept_id || ' does not exist.');
    END;
  END IF;

  DBMS_OUTPUT.PUT_LINE('ENROLLMENT REPORT - ' || p_semester);
  DBMS_OUTPUT.PUT_LINE(RPAD('Code', 10) || RPAD('Course', 44) || RPAD('Enrolled', 10) || 'Capacity');
  DBMS_OUTPUT.PUT_LINE(RPAD('-', 72, '-'));

  OPEN c_courses(p_semester, p_dept_id);
  LOOP
    FETCH c_courses INTO v_course;
    EXIT WHEN c_courses%NOTFOUND;

    DBMS_OUTPUT.PUT_LINE(RPAD(v_course.course_code, 10) ||
                         RPAD(SUBSTR(v_course.course_name, 1, 42), 44) ||
                         RPAD(v_course.enrolled, 10) || v_course.capacity);

    v_fill(v_course.course_code) := ROUND(v_course.enrolled * 100 / v_course.capacity, 1);
  END LOOP;
  p_courses_listed := c_courses%ROWCOUNT;
  CLOSE c_courses;

  DBMS_OUTPUT.PUT_LINE(RPAD('-', 72, '-'));
  DBMS_OUTPUT.PUT_LINE('Courses listed: ' || p_courses_listed);
  DBMS_OUTPUT.PUT_LINE('Seat occupancy per course:');

  v_key := v_fill.FIRST;
  WHILE v_key IS NOT NULL LOOP
    DBMS_OUTPUT.PUT_LINE('  ' || RPAD(v_key, 10) || v_fill(v_key) || '%');
    v_key := v_fill.NEXT(v_key);
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    IF c_courses%ISOPEN THEN
      CLOSE c_courses;
    END IF;
    RAISE;
END report_course_enrollment;
/
