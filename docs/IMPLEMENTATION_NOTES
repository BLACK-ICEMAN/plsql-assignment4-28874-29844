# Implementation Notes - Student Registration System (Oracle PL/SQL)

This document explains how the required concepts are implemented, the design decisions we took,
and the performance considerations, especially for bulk processing.

## Contents

1. [Design overview](#1-design-overview)
2. [Where each required concept is used](#2-where-each-required-concept-is-used)
3. [Bulk processing and performance](#3-bulk-processing-and-performance)
4. [Error codes and error-handling principles](#4-error-codes-and-error-handling-principles)
5. [Testing](#5-testing)
6. [Known limitations](#6-known-limitations)

---

## 1. Design overview

The database has four tables: `DEPARTMENTS`, `STUDENTS`, `COURSES` and `REGISTRATIONS`.
`REGISTRATIONS` resolves the many-to-many relation between students and courses. It stores the semester,
the numeric score, the letter grade and the status (`REGISTERED`, `DROPPED`, `COMPLETED`).

**Business rules** (enforced in PL/SQL and backed by constraints):

- Only `ACTIVE` students can register.
- A course cannot receive more registrations than its capacity in a semester. Dropped registrations free the seat.
- A student can register for a course only once per semester (`UQ_REG_STU_CRS_SEM`).
- Scores must be between 0 and 100 and are converted to letter grades by one single function, `get_letter_grade`.
- Procedures **never COMMIT**. The caller decides when to commit or roll back, so the test scripts roll back and can be re-run.

**Design decisions:**

- Capacity is calculated from the registrations (a `COUNT` of non-dropped rows per course and semester)
  instead of being stored in a counter column. This avoids a redundant column that could become inconsistent.
- The course row is locked with `SELECT ... FOR UPDATE` before the capacity check, so two sessions cannot
  take the last seat at the same time.

## 2. Where each required concept is used

| Requirement | Where |
|---|---|
| **%ROWTYPE records** | `register_student_course` (`students%ROWTYPE`, `courses%ROWTYPE`), `drop_registration` (`registrations%ROWTYPE`), `bulk_register_students`, `print_student_transcript`, `report_course_enrollment` (`c_courses%ROWTYPE`) |
| **User-defined record** | `print_student_transcript`: `t_transcript_rec` (one transcript line) |
| **Nested table** | Schema type `t_id_list` (input of `bulk_register_students`); `t_transcript_tab`, a collection of records, in `print_student_transcript` |
| **Associative arrays** | `bulk_assign_letter_grades` (`INDEX BY PLS_INTEGER`); `report_course_enrollment` (`INDEX BY VARCHAR2`: course code to occupancy %) |
| **Implicit cursors** | `register_student_course` (INSERT, `SQL%ROWCOUNT`); `drop_registration` and `record_student_score` (UPDATE, `SQL%NOTFOUND`, `SQL%FOUND`, `SQL%ROWCOUNT`); `purge_dropped_registrations` (DELETE, `SQL%FOUND`, `SQL%NOTFOUND`, `SQL%ROWCOUNT`) |
| **Explicit cursors** | `report_course_enrollment` (parameterized cursor, `OPEN` / `FETCH` / `CLOSE`, `%NOTFOUND`, `%ROWCOUNT`, `%ISOPEN`); `bulk_assign_letter_grades` (`OPEN` / `FETCH ... BULK COLLECT ... LIMIT` / `CLOSE`); `calculate_student_gpa` (cursor `FOR` loop) |
| **BULK COLLECT** | `bulk_assign_letter_grades` (with `LIMIT`); `print_student_transcript` (`SELECT ... BULK COLLECT INTO` a collection of records) |
| **FORALL** | `bulk_register_students` (INSERT) and `bulk_assign_letter_grades` (UPDATE), both with `SAVE EXCEPTIONS` |
| **Bulk DML errors** | `ORA-24381` mapped with `PRAGMA EXCEPTION_INIT`; failed rows are read from `SQL%BULK_EXCEPTIONS` (`ERROR_INDEX`, `ERROR_CODE`) |
| **Stored procedures** | 8 procedures in `01_procedures/` with IN, OUT and default parameters |
| **Stored functions** | 4 functions in `02_functions/`, called from SQL (`SELECT ... FROM dual / courses`) and from anonymous blocks |
| **Predefined exceptions** | `NO_DATA_FOUND`, `TOO_MANY_ROWS`, `DUP_VAL_ON_INDEX` |
| **User-defined exceptions** | `e_student_inactive`, `e_course_full`, `e_not_droppable`, `e_invalid_score`, `e_reg_not_open`, `e_empty_list`, `e_not_enough_seats`, `e_bulk_errors` (bound to ORA-24381) |
| **RAISE_APPLICATION_ERROR** | Every business error uses a code in the range -20001 to -20130 (see section 4) |

## 3. Bulk processing and performance

### Why row-by-row processing is slow

Oracle runs PL/SQL in the **PL/SQL engine** and SQL in the **SQL engine**. Every SQL statement executed
inside a PL/SQL loop forces a *context switch* between the two engines. Registering 10,000 students with a
`FOR` loop and one `INSERT` per iteration means 10,000 context switches and 10,000 statement executions,
which costs CPU time and latency even when each INSERT is cheap.

### What bulk processing does

- `BULK COLLECT` fetches many rows into a collection with **one** context switch.
- `FORALL` sends the whole collection to the SQL engine in **one** switch and runs the DML for every element.
  It is not a loop: it is one DML statement bound to an array.

The number of context switches drops from *N* to 1 (or to *N / batch size* when `LIMIT` is used), so the
benefit grows with the data volume.

### Choices made in this project

- `bulk_register_students` registers a whole list of students with one `FORALL INSERT`.
- `bulk_assign_letter_grades` reads rows with `BULK COLLECT ... LIMIT 100` from an explicit cursor, converts
  scores to letter grades in PL/SQL, and writes them back with one `FORALL UPDATE` per batch. `LIMIT` keeps the
  collection (PGA memory) small and constant even if a course has thousands of rows. An unlimited
  `BULK COLLECT` would load everything into memory at once.
- `SAVE EXCEPTIONS` lets valid rows succeed while invalid rows (duplicate registration `ORA-00001`, unknown
  student `ORA-02291`, ...) are collected in `SQL%BULK_EXCEPTIONS` and reported individually. Without it, the
  first failing element would stop the statement and undo the whole `FORALL`.
- Capacity is checked **once** for the whole list before the `FORALL`, not once per student.
- The index `idx_reg_course_sem (course_id, semester)` supports the capacity checks and the enrollment report.

### What to keep in mind

- `FORALL` only works for DML (INSERT, UPDATE, DELETE, MERGE). The collection must be dense (no gaps) unless
  `INDICES OF` or `VALUES OF` is used. Our collections are dense.
- `BULK COLLECT` without `LIMIT` is fine for small result sets (the transcript of one student) but should be
  combined with `LIMIT` for potentially large sets.
- If a task can be written as a single SQL statement, a set-based `INSERT ... SELECT` or `UPDATE ... WHERE` is
  faster than `FORALL`. Bulk processing is the right tool when PL/SQL logic (validation, function calls,
  per-row decisions) has to run between reading and writing, as with the grade conversion.

## 4. Error codes and error-handling principles

### Error codes

| Code | Raised by | Meaning |
|---|---|---|
| -20001 / -20002 | `register_student_course` | Student / course does not exist |
| -20003 | `register_student_course` | Student is not ACTIVE (e.g. suspended) |
| -20004 | `register_student_course` | Course is full |
| -20005 | `register_student_course` | Duplicate registration (`DUP_VAL_ON_INDEX`) |
| -20011 / -20012 | `drop_registration` | Registration missing / not in REGISTERED status |
| -20030 | `get_letter_grade` | Score is NULL or outside 0..100 |
| -20040 / -20041 / -20042 | `calculate_student_gpa` | Student missing / no graded courses / unknown letter grade |
| -20050 | `get_course_available_seats` | Course does not exist |
| -20060 / -20061 | `find_student_id_by_last_name` | No match (`NO_DATA_FOUND`) / several matches (`TOO_MANY_ROWS`) |
| -20080 / -20081 | `record_student_score` | Invalid score / registration not open |
| -20090 | `purge_dropped_registrations` | Semester is NULL |
| -20100 | `bulk_assign_letter_grades` | Course does not exist |
| -20110 | `bulk_register_students` | Course does not exist |
| -20111 | `bulk_register_students` | Empty or NULL student list |
| -20112 | `bulk_register_students` | Not enough seats for the list |
| -20120 | `report_course_enrollment` | Department does not exist |
| -20130 | `print_student_transcript` | Student does not exist |

### Error-handling principles

1. Business errors are translated to meaningful messages with `RAISE_APPLICATION_ERROR`. The message contains
   the offending value.
2. Unexpected errors are **re-raised** with `RAISE`, never swallowed. For example, `ORA-01400` when the
   semester is NULL (test `e17`) reaches the caller unchanged.
3. Functions never return a misleading value. `get_letter_grade` rejects invalid scores, and
   `calculate_student_gpa` raises -20041 instead of returning 0 when there are no grades.
4. Cursors are closed in the exception handler (`%ISOPEN` check), so no cursor is left open.
5. `SQL%` attributes are read immediately after the DML statement (or copied into a variable), because any
   later SQL statement would overwrite them.

## 5. Testing

- `03_tests/test_success_cases.sql` runs every procedure and function with valid input and prints the results.
  It rolls back at the end of each test.
- `03_tests/test_error_cases.sql` triggers every business error, plus `NO_DATA_FOUND`, `TOO_MANY_ROWS`,
  bulk DML errors and an unexpected Oracle error (`e17`). Each block catches the error only to print it, so
  the output can be captured for the screenshots in `screenshots/`.

## 6. Known limitations

- A student who dropped a course cannot register again for the same course and semester until the dropped
  record is purged (`purge_dropped_registrations`), because of the unique constraint on
  (student, course, semester). We kept the history of dropped registrations on purpose.
- `bulk_register_students` validates capacity and database constraints (duplicates, unknown students) but,
  unlike `register_student_course`, does not check the student's status. The bulk procedure is meant for an
  administrator loading a vetted list.
- GPA uses a simple 4.0 scale defined inside `calculate_student_gpa` and `get_letter_grade`. Changing the
  grading policy means changing these two functions only.
- `SQLERRM` for constraint errors shows the generic message without the constraint name.
