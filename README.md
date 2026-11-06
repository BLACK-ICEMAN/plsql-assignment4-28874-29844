# plsql-assignment4-28874-29844

## Group Members  
* **Student 1 ID:** 29844
* **Student 2 ID:** 29844

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
* `01_procedures/`: Contains individual `.sql` files for each stored procedure (e.g., `bulk_register_students.sql`, `bulk_assign_letter_grades.sql`, `drop_registration.sql`, `print_student_transcript.sql`).
* `02_functions/`: Contains individual `.sql` files for user-defined functions (e.g., `calculate_student_gpa.sql`).
* `03_tests/`: Contains anonymous PL/SQL blocks used to test the procedures and functions, simulating both successful executions and error conditions.
* `screenshots/`: Contains `.png` images capturing the DBMS_OUTPUT of the test scripts to verify correct execution and exception handling.
* `docs/`: Contains `IMPLEMENTATION_NOTES.md` detailing the design decisions and specific PL/SQL features used.
* `run_all.sql`: A utility script to compile and execute the entire project in the correct order.

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

## Installation and Execution
You can deploy the entire schema, compile the PL/SQL objects, and run the tests using the provided `run_all.sql` script, or execute them manually in the following order:

1. **Schema Creation & Data Seeding:**
   Run the scripts in `00_schema/` to create the tables and insert sample data.
2. **Compile Functions & Procedures:**
   Execute the scripts in `02_functions/` followed by `01_procedures/` to compile the PL/SQL objects into the database.
3. **Run Tests:**
   Execute the scripts in `03_tests/` to verify functionality. Ensure `SERVEROUTPUT` is turned on (`SET SERVEROUTPUT ON;`) to view the results.

