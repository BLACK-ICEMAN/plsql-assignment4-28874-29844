-- Run order: 2nd (after 01_create_tables.sql)

-- DEPARTMENTS
INSERT INTO departments (dept_id, dept_name) VALUES (10, 'Information Technology');
INSERT INTO departments (dept_id, dept_name) VALUES (20, 'Business Administration');
INSERT INTO departments (dept_id, dept_name) VALUES (30, 'Software Engineering');

-- STUDENTS (1002 and 1006 share the last name Mugisha on purpose -> TOO_MANY_ROWS test;
--           1009 is SUSPENDED -> registration must be refused)
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (1001, 'Aline',    'Uwase',        'aline.uwase@auca.ac.rw',         10, DATE '2024-09-02', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (1002, 'Jean',     'Mugisha',      'jean.mugisha@auca.ac.rw',        10, DATE '2024-09-02', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (1003, 'Grace',    'Mukamana',     'grace.mukamana@auca.ac.rw',      20, DATE '2024-09-02', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (1004, 'Patrick',  'Habimana',     'patrick.habimana@auca.ac.rw',    10, DATE '2024-09-02', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (1005, 'Diane',    'Ingabire',     'diane.ingabire@auca.ac.rw',      30, DATE '2024-09-02', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (1006, 'Samuel',   'Mugisha',      'samuel.mugisha@auca.ac.rw',      20, DATE '2025-09-01', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (1007, 'Claudine', 'Uwimana',      'claudine.uwimana@auca.ac.rw',    30, DATE '2025-09-01', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (1008, 'Emmanuel', 'Niyonzima',    'emmanuel.niyonzima@auca.ac.rw',  10, DATE '2025-09-01', 'ACTIVE');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (1009, 'Sandrine', 'Iradukunda',   'sandrine.iradukunda@auca.ac.rw', 20, DATE '2024-09-02', 'SUSPENDED');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, enroll_date, status)
VALUES (1010, 'David',    'Nshimiyimana', 'david.nshimiyimana@auca.ac.rw',  30, DATE '2025-09-01', 'ACTIVE');

-- COURSES (course 106 has capacity 2 -> used for the "course is full" test)
INSERT INTO courses (course_id, course_code, course_name, credits, dept_id, capacity)
VALUES (101, 'INSY8311', 'Database Development with PL/SQL', 3, 10, 40);
INSERT INTO courses (course_id, course_code, course_name, credits, dept_id, capacity)
VALUES (102, 'INSY229', 'Computer Networks', 3, 10, 40);
INSERT INTO courses (course_id, course_code, course_name, credits, dept_id, capacity)
VALUES (103, 'AMAT8111', 'Advanced Vector Spaces and Matrix Algebra', 3, 30, 35);
INSERT INTO courses (course_id, course_code, course_name, credits, dept_id, capacity)
VALUES (104, 'BUSI101', 'Principles of Management', 3, 20, 30);
INSERT INTO courses (course_id, course_code, course_name, credits, dept_id, capacity)
VALUES (105, 'SENG201', 'Software Engineering', 4, 30, 30);
INSERT INTO courses (course_id, course_code, course_name, credits, dept_id, capacity)
VALUES (106, 'INSY350', 'Capstone Seminar', 2, 10, 2);

-- REGISTRATIONS
-- 2025-FALL: completed (graded) registrations + one dropped registration
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (1,  1001, 101, '2025-FALL', 92, 'A',  'COMPLETED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (2,  1001, 104, '2025-FALL', 85, 'B+', 'COMPLETED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (3,  1002, 101, '2025-FALL', 78, 'C+', 'COMPLETED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (4,  1002, 102, '2025-FALL', 66, 'D',  'COMPLETED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (5,  1003, 104, '2025-FALL', 88, 'B+', 'COMPLETED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (6,  1004, 101, '2025-FALL', 81, 'B',  'COMPLETED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (7,  1005, 103, '2025-FALL', 95, 'A',  'COMPLETED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (8,  1005, 105, '2025-FALL', 72, 'C',  'COMPLETED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (19, 1009, 104, '2025-FALL', NULL, NULL, 'DROPPED');

-- 2026-FALL: current semester. Regs 11,13,14,16 (course 101) already have a score but no letter grade yet.
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (9,  1001, 102, '2026-FALL', NULL, NULL, 'REGISTERED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (10, 1002, 103, '2026-FALL', NULL, NULL, 'REGISTERED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (11, 1003, 101, '2026-FALL', 77,   NULL, 'REGISTERED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (12, 1004, 102, '2026-FALL', NULL, NULL, 'REGISTERED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (13, 1005, 101, '2026-FALL', 91,   NULL, 'REGISTERED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (14, 1006, 101, '2026-FALL', 58,   NULL, 'REGISTERED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (15, 1007, 105, '2026-FALL', NULL, NULL, 'REGISTERED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (16, 1008, 101, '2026-FALL', 84,   NULL, 'REGISTERED');
-- course 106 (capacity 2) is now full
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (17, 1010, 106, '2026-FALL', NULL, NULL, 'REGISTERED');
INSERT INTO registrations (reg_id, student_id, course_id, semester, grade_score, letter_grade, status) VALUES (18, 1008, 106, '2026-FALL', NULL, NULL, 'REGISTERED');

COMMIT;


SELECT table_name
FROM   user_tables
WHERE  table_name IN ('DEPARTMENTS', 'STUDENTS', 'COURSES', 'REGISTRATIONS')
ORDER  BY table_name;