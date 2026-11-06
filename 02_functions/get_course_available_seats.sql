-- =====================================================================
-- FUNCTION get_course_available_seats
-- Returns capacity minus the number of non-dropped registrations of a
-- course in a semester.
-- Errors : -20050 course does not exist (handled NO_DATA_FOUND)
-- Call   : SELECT course_code, get_course_available_seats(course_id, '2026-FALL')
--            FROM courses;
-- =====================================================================
CREATE OR REPLACE FUNCTION get_course_available_seats (
  p_course_id IN courses.course_id%TYPE,
  p_semester  IN registrations.semester%TYPE
) RETURN NUMBER
IS
  v_capacity courses.capacity%TYPE;
  v_taken    NUMBER;
BEGIN
  BEGIN
    SELECT capacity
      INTO v_capacity
      FROM courses
     WHERE course_id = p_course_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20050, 'Course ' || p_course_id || ' does not exist.');
  END;

  SELECT COUNT(*)
    INTO v_taken
    FROM registrations
   WHERE course_id = p_course_id
     AND semester  = p_semester
     AND status   <> 'DROPPED';

  RETURN v_capacity - v_taken;
END get_course_available_seats;
/
