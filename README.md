# Student Registration System - Advanced Oracle PL/SQL (Group Assignment IV)

**Course:** Database Development with PL/SQL (INSY 8311) - AUCA **Instructor:** Eric Maniraguha \| **Teaching Assistant:** Afanyu Emmanuel **Topic:** Cursors, Bulk Processing, Stored Procedures, Functions and Exception Handling

## 1. Group members

| # | Full name | Student ID | Class group |
| --- | --- | --- | --- |
| 1 | Abdelgafar Faisal Abdelgafar | 28874 | \<I / B / C / D\> |
| 2 | \<PARTNER FULL NAME\> | \<PARTNER ID\> | \<I / B / C / D\> |

## 2. Application description and requirements

**Scenario: Student Registration (and grading).** A university registrar needs to register students in courses for a semester, respect course capacities, let students drop courses, record scores, convert them to letter grades, and produce transcripts, GPAs and enrollment reports.

Functional requirements implemented:

1. Register one student in one course (only ACTIVE students, only if seats are available, no duplicates).
2. Register many students at once in a course (bulk) and report which rows failed and why.
3. Drop a registration and purge dropped registrations.
4. Record a student's numeric score, then convert all recorded scores of a course to letter grades in bulk.
5. Print a student's transcript with credits earned and GPA.
6. Report the enrollment (enrolled / capacity / occupancy %) of every course for a semester.
7. Query helpers: letter-grade conversion, available seats, student lookup by last name, GPA.
8. Every operation validates its input and raises meaningful errors (`RAISE_APPLICATION_ERROR`); unexpected errors are never hidden.

## 3. Database schema

```
DEPARTMENTS (dept_id PK, dept_name UQ)
     | 1                          | 1
     | N                          | N
STUDENTS (student_id PK, ..., dept_id FK, status)      COURSES (course_id PK, course_code UQ, credits, capacity, dept_id FK)
     | 1                                                      | 1
     | N                                                      | N
     +------------------- REGISTRATIONS --------------------+
        (reg_id PK, student_id FK, course_id FK, semester,
         grade_score, letter_grade, status)
         UNIQUE (student_id, course_id, semester)
```

- Full DDL with all constraints (PK, FK, UNIQUE, CHECK, NOT NULL, DEFAULT): [`00_schema/01_create_tables.sql`](00_schema/01_create_tables.sql)
- Sample data (3 departments, 10 students, 6 courses, 19 registrations): [`00_schema/02_insert_sample_data.sql`](00_schema/02_insert_sample_data.sql)
- Optional reset script: [`00_schema/00_drop_objects.sql`](00_schema/00_drop_objects.sql)

## 4. How to run

Use any Oracle schema (user) that can create tables, sequences, types, procedures and functions. In SQL Developer open each file and press **F5 (Run Script)**; or from the repository root run `@run_all.sql` in SQL\*Plus / SQLcl.

1. `00_schema/01_create_tables.sql`
2. `00_schema/02_insert_sample_data.sql`
3. Compile the **functions** in `02_functions/` (they are compiled before the procedures because `bulk_assign_letter_grades` and `print_student_transcript` call them)
4. Compile the **stored procedures** in `01_procedures/`
5. Run `03_tests/test_success_cases.sql`
6. Run `03_tests/test_error_cases.sql`
7. Compare the results with the screenshots below. Every test block ends with `ROLLBACK`, so the tests can be re-run at any time.

To start from scratch run `00_schema/00_drop_objects.sql` first.

## 5. Requirement coverage

| Requirement | Files |
| --- | --- |
| Records (user-defined + `%ROWTYPE`) | `print_student_transcript.sql`, `register_student_course.sql`, `drop_registration.sql`, `report_course_enrollment.sql` |
| Collections (nested table, associative arrays) | `t_id_list` in `01_create_tables.sql`, `bulk_register_students.sql`, `bulk_assign_letter_grades.sql`, `report_course_enrollment.sql`, `print_student_transcript.sql` |
| Implicit cursors (`SQL%ROWCOUNT`, `SQL%FOUND`, `SQL%NOTFOUND`) | `register_student_course.sql`, `drop_registration.sql`, `purge_dropped_registrations.sql`, `record_student_score.sql` |
| Explicit cursors | `report_course_enrollment.sql` (OPEN/FETCH/CLOSE), `bulk_assign_letter_grades.sql`, `calculate_student_gpa.sql` (cursor FOR loop) |
| BULK COLLECT / FORALL / bulk errors | `bulk_register_students.sql`, `bulk_assign_letter_grades.sql`, `print_student_transcript.sql` |
| Stored procedures (IN/OUT, exceptions) | `01_procedures/` (8 procedures) |
| Stored functions | `02_functions/` (4 functions) |
| Predefined / user-defined exceptions, `RAISE_APPLICATION_ERROR` | all files; see `docs/IMPLEMENTATION_NOTES.md` section 4 |

Implementation and performance explanation: [`docs/IMPLEMENTATION_NOTES.md`](docs/IMPLEMENTATION_NOTES.md)

## 6. Test cases - successful execution

Each test shows the code that was executed followed by its screenshot.

### S00 - Tables, row counts and compilation status of all objects

```
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
```

s00\_schema\_and\_objects

### S01 - register\_student\_course: %ROWTYPE records + implicit INSERT cursor

```
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
```

s01\_register\_student\_course

### S02 - drop\_registration: implicit UPDATE cursor (SQL%NOTFOUND / SQL%ROWCOUNT)

```
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
```

s02\_drop\_registration

### S03 - purge\_dropped\_registrations: implicit DELETE cursor (SQL%FOUND / SQL%NOTFOUND)

```
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
```

s03\_purge\_dropped\_registrations

### S04 - record\_student\_score: implicit UPDATE cursor (SQL%FOUND)

```
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
```

s04\_record\_student\_score

### S05 - bulk\_register\_students: nested table + FORALL ... SAVE EXCEPTIONS

```
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
```

s05\_bulk\_register\_students

### S06 - bulk\_assign\_letter\_grades: explicit cursor + BULK COLLECT LIMIT + FORALL UPDATE

```
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
```

s06\_bulk\_assign\_letter\_grades

### S07 - print\_student\_transcript: user-defined record + collection of records

```
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
```

s07\_print\_student\_transcript

### S08 - report\_course\_enrollment: parameterized explicit cursor + associative array

```
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
```

s08\_report\_course\_enrollment

### S09 - Functions called from SQL statements and from an anonymous PL/SQL block

```
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
```

s09\_functions

## 7. Test cases - error handling

Each call is wrapped only to print the error for the screenshot; the procedures/functions themselves raise the errors to the caller.

### E01 - NO\_DATA\_FOUND -\> ORA-20001 / ORA-20002

```
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
```

e01\_student\_or\_course\_not\_found

### E02 - user-defined exception e\_student\_inactive -\> ORA-20003

```
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
```

e02\_student\_suspended

### E03 - user-defined exception e\_course\_full -\> ORA-20004

```
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
```

e03\_course\_full

### E04 - predefined exception DUP\_VAL\_ON\_INDEX -\> ORA-20005

```
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
```

e04\_duplicate\_registration

### E05 - NO\_DATA\_FOUND -\> ORA-20011

```
SET SERVEROUTPUT ON
BEGIN
  drop_registration(99999);
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('EXPECTED ERROR: ' || SQLERRM);
END;
/
ROLLBACK;
```

e05\_drop\_registration\_not\_found

### E06 - SQL%NOTFOUND + user-defined exception -\> ORA-20012

```
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
```

e06\_drop\_registration\_not\_droppable

### E07 - user-defined exception e\_invalid\_score -\> ORA-20080

```
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
```

e07\_invalid\_score

### E08 - SQL%NOTFOUND + user-defined exception -\> ORA-20081

```
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
```

e08\_score\_registration\_not\_open

### E09 - ORA-20110 / ORA-20111

```
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
```

e09\_bulk\_register\_invalid\_input

### E10 - user-defined exception e\_not\_enough\_seats -\> ORA-20112

```
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
```

e10\_bulk\_register\_not\_enough\_seats

### E11 - NO\_DATA\_FOUND -\> ORA-20100

```
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
```

e11\_bulk\_grades\_course\_not\_found

### E12 - function get\_letter\_grade -\> ORA-20030

```
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
```

e12\_invalid\_score\_for\_letter\_grade

### E13 - function calculate\_student\_gpa: NO\_DATA\_FOUND -\> ORA-20040, no graded course -\> ORA-20041

```
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
```

e13\_gpa\_errors

### E14 - predefined NO\_DATA\_FOUND and TOO\_MANY\_ROWS -\> ORA-20060 / ORA-20061

```
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
```

e14\_find\_student\_errors

### E15 - NO\_DATA\_FOUND -\> ORA-20130

```
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
```

e15\_transcript\_student\_not\_found

### E16 - NO\_DATA\_FOUND -\> ORA-20120

```
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
```

e16\_report\_department\_not\_found

### E17 - an unexpected Oracle error is re-raised, not swallowed

```
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
```

e17\_unexpected\_error\_is\_not\_hidden

## 8. Use of AI assistance

An AI assistant (Claude, by Anthropic) was used as a helper in this project: to propose the initial structure of the schema and of the PL/SQL units, to draft the test scripts and the documentation, and to explain Oracle features (bulk processing, `SAVE EXCEPTIONS`, cursor attributes). We reviewed every file, ran all the scripts in Oracle ourselves, produced the screenshots from our own runs, and both members can explain and justify every line of the code.

## 9. Repository structure

```
plsql-assignment4-28874-<partnerID>/
|-- README.md
|-- .gitignore
|-- run_all.sql
|-- 00_schema/        00_drop_objects.sql, 01_create_tables.sql, 02_insert_sample_data.sql
|-- 01_procedures/    8 stored procedures (one file each)
|-- 02_functions/     4 stored functions (one file each)
|-- 03_tests/         test_success_cases.sql, test_error_cases.sql
|-- screenshots/      <test_name>_output.png
`-- docs/             IMPLEMENTATION_NOTES.md
```
