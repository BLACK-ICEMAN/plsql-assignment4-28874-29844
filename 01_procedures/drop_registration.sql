-- =====================================================================
-- PROCEDURE drop_registration
-- Marks a REGISTERED registration as DROPPED.
-- Concepts : %ROWTYPE record, implicit cursor (UPDATE + SQL%NOTFOUND /
--            SQL%ROWCOUNT), user-defined exception, RAISE_APPLICATION_ERROR.
-- Errors   : -20011 registration does not exist (NO_DATA_FOUND)
--            -20012 registration is not in REGISTERED status
-- =====================================================================
CREATE OR REPLACE PROCEDURE drop_registration (
  p_reg_id IN registrations.reg_id%TYPE
)
IS
  v_reg  registrations%ROWTYPE;
  v_rows PLS_INTEGER;

  e_not_droppable EXCEPTION;
BEGIN
  BEGIN
    SELECT * INTO v_reg FROM registrations WHERE reg_id = p_reg_id FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20011, 'Registration ' || p_reg_id || ' does not exist.');
  END;

  UPDATE registrations
     SET status = 'DROPPED'
   WHERE reg_id = p_reg_id
     AND status = 'REGISTERED';

  IF SQL%NOTFOUND THEN             -- no row was updated
    RAISE e_not_droppable;
  END IF;

  v_rows := SQL%ROWCOUNT;
  DBMS_OUTPUT.PUT_LINE('Registration ' || p_reg_id || ' dropped. Rows updated (SQL%ROWCOUNT) = ' || v_rows);
EXCEPTION
  WHEN e_not_droppable THEN
    RAISE_APPLICATION_ERROR(-20012,
      'Registration ' || p_reg_id || ' cannot be dropped because its status is ' || v_reg.status || '.');
  WHEN OTHERS THEN
    RAISE;
END drop_registration;
/
