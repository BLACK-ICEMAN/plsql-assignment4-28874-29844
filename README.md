# plsql-assignment4-28874-29844

## Group Members  
* Name: Abdelgafar Faisal Abdelgafar
* **ID:** 28874
* Name: CYUSA Bruno
* **ID:** 29844


## Project Overview
This repository contains a comprehensive PL/SQL implementation of a **Student Registration and Grading System**. The project demonstrates advanced database programming techniques in Oracle PL/SQL, including the use of explicit and implicit cursors, Records, Collections, bulk processing (`FORALL`, `BULK COLLECT`), and robust exception handling.

The system allows university administrators to register students for courses, assign grades in bulk, calculate GPAs, and generate student transcripts. 

## Repository Structure
```text
plsql-assignment4-29844-<PARTNER_ID>/
├── 00_schema/
│   ├── 01_create_tables.sql
│   └── 02_insert_sample_data.sql
├── 01_procedures/
│   ├── bulk_assign_letter_grades.sql
│   ├── bulk_register_students.sql
│   ├── drop_registration.sql
│   └── print_student_transcript.sql
├── 02_functions/
│   └── calculate_student_gpa.sql
├── 03_tests/
│   ├── test_bulk_operations.sql
│   ├── test_drop_registration.sql
├── docs/
│   └── IMPLEMENTATION_NOTES.md
├── screenshots/
│   ├── 01_register_student_course_output.png
│   ├── 02_bulk_assign_grades_output.png
│   |── e01_student_or_course_not_found_output.png
|   └── (All test case screenshots}
├── .gitignore
├── README.md
└── run_all.sql
```
### Scripts must be run in numeric order.

* `00_schema/`: Contains DDL scripts for setting up and tearing down the database schema, as well as DML scripts for seeding initial sample data (`01_create_tables.sql`, `02_insert_sample_data.sql`, `00_drop_objects.sql`).
* `02_functions/`: Contains individual `.sql` files for user-defined functions (e.g., `calculate_student_gpa.sql`).
* `01_procedures/`: Contains individual `.sql` files for each stored procedure (e.g., `bulk_register_students.sql`, `bulk_assign_letter_grades.sql`, `drop_registration.sql`, `print_student_transcript.sql`).
* `03_tests/`: Contains anonymous PL/SQL blocks used to test the procedures and functions, simulating both successful executions and error conditions.
* `screenshots/`: Contains `.png` images capturing the DBMS_OUTPUT of the test scripts to verify correct execution and exception handling.
* `docs/`: Contains `IMPLEMENTATION_NOTES.md` detailing the design decisions and specific PL/SQL features used.
* `run_all.sql`: A utility script to compile and execute the entire project in the correct order.

 **Functions must be compiled before procedures**
because procedures call them (for example `bulk_assign_letter_grades` calls `get_letter_grade`).

## Prerequisites
* Oracle Database (19c or later recommended)
* SQL Developer, SQLcl, or SQL*Plus

## Project Summary
The **Student Registration and Grading System** is a robust, backend relational database application built entirely using Oracle PL/SQL. It simulates the core academic operations of a university or school, managing the complex relationships between students, courses, enrollments, and academic performance. 

The primary business workflows handled by this system include:
* **Enrollment Management:** Safely registering students into courses and handling course drops while maintaining data integrity.
* **Academic Grading:** Assigning letter grades to students at the end of a semester.
* **Performance Calculation:** Dynamically computing a student's Grade Point Average (GPA) based on earned letter grades and course credit hours.
* **Reporting:** Generating formatted academic transcripts for individual students.

**Technical Objective:** 
Beyond the business logic, this project serves as a comprehensive showcase of advanced PL/SQL programming capabilities. It is specifically architected to demonstrate the performance benefits of **Bulk Processing** (`FORALL`, `BULK COLLECT`) for high-volume transactions (like semester-wide grading), the precision of **Explicit and Implicit Cursors** for row-by-row data manipulation, and the reliability of custom **Exception Handling** to enforce academic business rules (e.g., preventing duplicate enrollments).

### Business rules

* Only students with status `ACTIVE` can register for a course.
* A course cannot exceed its `capacity` in a given semester; dropped registrations free the seat.
* A student can register for a given course only once per semester. A course that was failed
  can be registered again in a later semester (each attempt is stored as its own registration row).
* Scores must be between 0 and 100; letter grades are produced by one function, `get_letter_grade`.
* Grade scale: A ≥ 90, B+ ≥ 85, B ≥ 80, C+ ≥ 75, C ≥ 70, D ≥ 60, F < 60 (GPA: A=4.0, B+=3.5, B=3.0, C+=2.5, C=2.0, D=1.0, F=0.0).
* The procedures never `COMMIT`; the caller decides when to commit or roll back.

## Installation and Execution (Two options)
### Option 1:
You can deploy the entire schema, compile the PL/SQL objects, and run the tests using the provided `run_all.sql` script.  
We use `SET SERVEROUTPUT ON` so the test output is visible. Every test ends with `ROLLBACK`, so tests can be re-run without changing the sample data.  

To make sure everything was compiled without any error, you can Verify it using the command below:  
```sql
SELECT object_type, object_name, status FROM user_objects
WHERE  object_type IN ('FUNCTION', 'PROCEDURE', 'TYPE', 'SEQUENCE')
ORDER  BY object_type, object_name;
```
or use the command below:
```sql
SELECT object_type, object_name, status
FROM   user_objects
WHERE  object_name IN (
         'CALCULATE_STUDENT_GPA', 'FIND_STUDENT_ID_BY_LAST_NAME',
         'GET_COURSE_AVAILABLE_SEATS', 'GET_LETTER_GRADE',
         'BULK_ASSIGN_LETTER_GRADES', 'BULK_REGISTER_STUDENTS',
         'DROP_REGISTRATION', 'PRINT_STUDENT_TRANSCRIPT',
         'PURGE_DROPPED_REGISTRATIONS', 'RECORD_STUDENT_SCORE',
         'REGISTER_STUDENT_COURSE', 'REPORT_COURSE_ENROLLMENT',
         'SEQ_REG_ID', 'T_ID_LIST')
ORDER  BY object_type, object_name;
```
<img width="641" height="367" alt="image" src="https://github.com/user-attachments/assets/9fcc08a9-259c-4cb0-be65-941dde57bbbe" />

-> You will be able to see the Object list, our sample data is 3 departments, 10 students, 6 courses, 19 registrations. So for example if you run:
```sql
SELECT COUNT(*) FROM departments;
```
-> You will be able to see that you have 3 departments
```sql
SELECT COUNT(*) FROM students;
```
-> You will be able to see that you have 10 students
```sql
SELECT COUNT(*) FROM courses;
```
-> You will be able to see that you have 6 courses
```sql
SELECT COUNT(*) FROM registrations;
```
-> You will be able to see that you have 19 registrations

### Option2
You can also do the installation manually in the following order:
1. **Schema Creation & Data Seeding:**
   Run the scripts in `00_schema/` to create the tables and insert sample data.
   After tables are created you should get this exact output
   
   <img width="715" height="391" alt="image" src="https://github.com/user-attachments/assets/f11b4b91-7dcd-4796-8c86-5fafc268140c" />
   
   When you are also done seeding data into the tables, you can check by using this command
```sql
SELECT t.table_name,
       (SELECT COUNT(*) FROM user_tab_columns c WHERE c.table_name = t.table_name) AS columns,
       t.num_rows
FROM   user_tables t
WHERE  t.table_name IN ('DEPARTMENTS', 'STUDENTS', 'COURSES', 'REGISTRATIONS')
ORDER  BY t.table_name;
```

<img width="502" height="171" alt="image" src="https://github.com/user-attachments/assets/97a94f0c-7d77-40d7-a012-0eb75310508d" />

2. **Compile Functions & Procedures:**
   Execute the scripts in `02_functions/` followed by `01_procedures/` to compile the PL/SQL objects into the database.
   For every function you compile you will see an output saying `Function function_name compiled` as well as for procedures `Procedure procedure_name compiled`
3. **Run Tests:**
   Execute the scripts in `03_tests/` to verify functionality. Ensure `SERVEROUTPUT` is turned on (`SET SERVEROUTPUT ON;`) to view the results.
   -> When you run `test_error_cases.sql` you will get the output below (same order as in source code).
   <img width="792" height="717" alt="image" src="https://github.com/user-attachments/assets/6bcb93a8-ed03-4bb4-9204-b6b80a22b198" />
   <img width="752" height="792" alt="image" src="https://github.com/user-attachments/assets/57934f5a-156c-4e2d-8232-3b6b364738c6" />
   <img width="841" height="860" alt="image" src="https://github.com/user-attachments/assets/7e2975d0-f95a-44c9-bf05-ab62a8215c11" />   
   <img width="702" height="172" alt="image" src="https://github.com/user-attachments/assets/c578cb9b-a887-419b-9525-93da67224cbd" />

   -> `test_success_cases.sql` includes many test cases, after running every test in this file you need to also `rollback` Below are the screenshots (same order as in source code).
   
   <img width="622" height="207" alt="image" src="https://github.com/user-attachments/assets/8d6d9240-6f0b-43ef-b505-a53e82cd962d" />
   <img width="597" height="197" alt="image" src="https://github.com/user-attachments/assets/440bb2a9-4089-4627-906d-5616bbcfffe3" />
   <img width="701" height="202" alt="image" src="https://github.com/user-attachments/assets/72406c3a-8ac4-4407-a272-c258401f8b29" />
   <img width="667" height="157" alt="image" src="https://github.com/user-attachments/assets/4235cddc-f109-4f79-8bf3-6aba8d832d6d" />
   <img width="862" height="225" alt="image" src="https://github.com/user-attachments/assets/5a6dc7ca-72a8-45a6-85e4-e61003bb4c4a" />
   <img width="697" height="220" alt="image" src="https://github.com/user-attachments/assets/215afa71-a65c-427f-925f-83eef16c8d9a" />
   <img width="737" height="452" alt="image" src="https://github.com/user-attachments/assets/dd93b123-57ce-4df2-b319-4fe0dc46e11b" />
   <img width="721" height="655" alt="image" src="https://github.com/user-attachments/assets/4eb80787-6f65-4a7f-b115-7e714e9eafc1" />
   <img width="681" height="180" alt="image" src="https://github.com/user-attachments/assets/e3e7abb5-7990-4bf0-ab1b-1431c6649dc0" />

## Errors Encountered and Resolution  
1. When `01_procedures/` is run before `02_functions/` you will get an error. Procedures will tend to call functions for example: procedure `bulk_assign_letter_grades` will call function `get_letter_grade`, you will get the following error in the screenshot because it will be considered as if function `get_letter_grade` has not been declared. So to avoid it, you have to run/compile functions first and then procedures after.
<img width="832" height="297" alt="bulk assign letter grades error" src="https://github.com/user-attachments/assets/ca120a23-3a57-45c4-8a51-d23274433ac0" />

## Database schema

Tables: `departments`, `students`, `courses`, `registrations`; sequence
`seq_reg_id` (starts at 100); collection type `t_id_list`; index
`idx_reg_course_sem`. Relationships: one department has many students and
courses; `registrations` resolves the many-to-many relation between students and
courses, with a unique key on `(student_id, course_id, semester)`.
Check constraints restrict statuses, letter grades, scores, credits and capacity.

## Procedures and functions

<!-- Descriptions below are based on the test output; adjust if your code differs. -->

| Name | Type | Purpose |
|---|---|---|
| `register_student_course` | Procedure | Registers a student in a course, checks rules, returns the new `reg_id` (OUT) |
| `drop_registration` | Procedure | Marks a registration as DROPPED |
| `purge_dropped_registrations` | Procedure | Deletes dropped registrations for a semester, returns the count (OUT) |
| `record_student_score` | Procedure | Saves a score for a registered student |
| `bulk_register_students` | Procedure | Registers many students at once, reports successes and failures |
| `bulk_assign_letter_grades` | Procedure | `BULK COLLECT` + `FORALL` to assign letter grades for a course/semester |
| `print_student_transcript` | Procedure | Prints a transcript with GPA using records and cursors |
| `report_course_enrollment` | Procedure | Prints enrollment and seat occupancy per course |
| `get_letter_grade` | Function | Converts a score to a letter grade |
| `get_course_available_seats` | Function | Seats left in a course for a semester |
| `find_student_id_by_last_name` | Function | Looks up a student id by last name |
| `calculate_student_gpa` | Function | Computes a student's GPA |


## Error codes

| Code | Meaning |
|---|---|
| ORA-20001 | Student does not exist |
| ORA-20002 | Course does not exist |
| ORA-20003 | Student is suspended |
| ORA-20004 | Course is full |
| ORA-20005 | Student already registered (or has a dropped record) |
| ORA-20011 | Registration does not exist |
| ORA-20012 | Registration cannot be dropped in its current status |
| ORA-20080 | Invalid score (outside 0-100 or NULL) |
| ORA-20081 | Registration missing or not in REGISTERED status |
| ORA-20030 | Invalid score passed to `get_letter_grade` |
| ORA-20040 | Student does not exist (GPA) |
| ORA-20041 | Student has no graded course (GPA) |
| ORA-20060 | No student with that last name |
| ORA-20061 | Several students share that last name |
| ORA-20100 | Course does not exist (bulk grading) |
| ORA-20110 / ORA-20111 | Empty or NULL student list (bulk registration) |
| ORA-20112 | Not enough seats for the bulk registration |
| ORA-20120 | Department does not exist (enrollment report) |
| ORA-20130 | Student does not exist (transcript) |
| ORA-01400 | Unexpected NOT NULL violation, re-raised instead of hidden |

## Implementation and performance

See [docs/IMPLEMENTATION_NOTES.md](docs/IMPLEMENTATION_NOTES.md).

## Use of AI assistance
We used an AI assistant, Claude AI was used as a helper in this project: to propose the initial structure of the schema and of the PL/SQL units, to analyze the test scripts and the documentation for error like typos, and to explain Oracle features (bulk processing, `SAVE EXCEPTIONS`, cursor attributes). We reviewed every file, ran all the scripts in Oracle ourselves, produced the screenshots from our own runs, and both members can explain and justify every line of the code.
