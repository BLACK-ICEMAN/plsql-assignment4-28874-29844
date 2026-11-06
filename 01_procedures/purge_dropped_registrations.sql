-- =====================================================================
-- PROCEDURE purge_dropped_registrations
-- Deletes all DROPPED registrations of a semester.
-- Concepts : implicit cursor with DELETE (SQL%FOUND, SQL%NOTFOUND,
--            SQL%ROWCOUNT), OUT parameter.
-- Errors   : -20090 semester is NULL
-- =====================================================================
CREATE OR REPLACE PROCEDURE purge_dropped_registrations (
  p_semester IN  registrations.semester%TYPE,
  p_deleted  OUT NUMBER
)
IS
  v_found BOOLEAN;
BEGIN
  IF p_semester IS NULL THEN
    RAISE_APPLICATION_ERROR(-20090, 'The semester must be provided.');
  END IF;

  DELETE FROM registrations
   WHERE semester = p_semester
     AND status   = 'DROPPED';

  v_found   := SQL%FOUND;          -- capture attributes right after the DELETE
  p_deleted := SQL%ROWCOUNT;

  IF v_found THEN
    DBMS_OUTPUT.PUT_LINE('SQL%FOUND = TRUE  -> ' || p_deleted || ' dropped registration(s) deleted for ' || p_semester || '.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('SQL%NOTFOUND = TRUE -> nothing to delete for ' || p_semester || '.');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END purge_dropped_registrations;
/
