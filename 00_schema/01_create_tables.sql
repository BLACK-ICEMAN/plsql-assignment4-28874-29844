-- This first part is optional (use only to reset the schema)
-- Drops every object created by this project so the scripts can be
-- re-run from scratch. Safe to run on an empty schema.

BEGIN
  FOR o IN (SELECT object_name, object_type
              FROM user_objects
             WHERE object_type IN ('PROCEDURE', 'FUNCTION')
               AND object_name IN ('REGISTER_STUDENT_COURSE', 'DROP_REGISTRATION',
                                   'PURGE_DROPPED_REGISTRATIONS', 'RECORD_STUDENT_SCORE',
                                   'BULK_REGISTER_STUDENTS', 'BULK_ASSIGN_LETTER_GRADES',
                                   'PRINT_STUDENT_TRANSCRIPT', 'REPORT_COURSE_ENROLLMENT',
                                   'GET_LETTER_GRADE', 'CALCULATE_STUDENT_GPA',
                                   'GET_COURSE_AVAILABLE_SEATS', 'FIND_STUDENT_ID_BY_LAST_NAME'))
  LOOP
    EXECUTE IMMEDIATE 'DROP ' || o.object_type || ' ' || o.object_name;
  END LOOP;

  FOR t IN (SELECT table_name
              FROM user_tables
             WHERE table_name IN ('REGISTRATIONS', 'COURSES', 'STUDENTS', 'DEPARTMENTS'))
  LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;

  FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name = 'SEQ_REG_ID')
  LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
  END LOOP;

  FOR ty IN (SELECT type_name FROM user_types WHERE type_name = 'T_ID_LIST')
  LOOP
    EXECUTE IMMEDIATE 'DROP TYPE ' || ty.type_name || ' FORCE';
  END LOOP;
END;
/

-- Second part: create the tables, sequences, and types needed for the project

-- Sequence for registration ids (sample data uses ids 1..19)

CREATE SEQUENCE seq_reg_id START WITH 100 INCREMENT BY 1 NOCACHE;


-- DEPARTMENTS

CREATE TABLE departments (
  dept_id    NUMBER(4)     NOT NULL,
  dept_name  VARCHAR2(80)  NOT NULL,
  CONSTRAINT pk_departments  PRIMARY KEY (dept_id),
  CONSTRAINT uq_dept_name    UNIQUE (dept_name)
);

-- STUDENTS  (many students belong to one department)

CREATE TABLE students (
  student_id   NUMBER(6)     NOT NULL,
  first_name   VARCHAR2(50)  NOT NULL,
  last_name    VARCHAR2(50)  NOT NULL,
  email        VARCHAR2(100) NOT NULL,
  dept_id      NUMBER(4)     NOT NULL,
  enroll_date  DATE          DEFAULT SYSDATE NOT NULL,
  status       VARCHAR2(10)  DEFAULT 'ACTIVE' NOT NULL,
  CONSTRAINT pk_students        PRIMARY KEY (student_id),
  CONSTRAINT uq_students_email  UNIQUE (email),
  CONSTRAINT fk_students_dept   FOREIGN KEY (dept_id) REFERENCES departments (dept_id),
  CONSTRAINT ck_students_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'GRADUATED'))
);


-- COURSES  (many courses belong to one department)

CREATE TABLE courses (
  course_id    NUMBER(4)     NOT NULL,
  course_code  VARCHAR2(20)  NOT NULL,
  course_name  VARCHAR2(120) NOT NULL,
  credits      NUMBER(1)     NOT NULL,
  dept_id      NUMBER(4)     NOT NULL,
  capacity     NUMBER(3)     NOT NULL,
  CONSTRAINT pk_courses         PRIMARY KEY (course_id),
  CONSTRAINT uq_courses_code    UNIQUE (course_code),
  CONSTRAINT fk_courses_dept    FOREIGN KEY (dept_id) REFERENCES departments (dept_id),
  CONSTRAINT ck_courses_credits CHECK (credits BETWEEN 1 AND 6),
  CONSTRAINT ck_courses_cap     CHECK (capacity > 0)
);

-- REGISTRATIONS 

CREATE TABLE registrations (
  reg_id        NUMBER(10)    NOT NULL,
  student_id    NUMBER(6)     NOT NULL,
  course_id     NUMBER(4)     NOT NULL,
  semester      VARCHAR2(20)  NOT NULL,
  reg_date      DATE          DEFAULT SYSDATE NOT NULL,
  grade_score   NUMBER(5,2),
  letter_grade  VARCHAR2(2),
  status        VARCHAR2(10)  DEFAULT 'REGISTERED' NOT NULL,
  CONSTRAINT pk_registrations   PRIMARY KEY (reg_id),
  CONSTRAINT fk_reg_student     FOREIGN KEY (student_id) REFERENCES students (student_id),
  CONSTRAINT fk_reg_course      FOREIGN KEY (course_id)  REFERENCES courses (course_id),
  CONSTRAINT uq_reg_stu_crs_sem UNIQUE (student_id, course_id, semester),
  CONSTRAINT ck_reg_status      CHECK (status IN ('REGISTERED', 'DROPPED', 'COMPLETED')),
  CONSTRAINT ck_reg_score       CHECK (grade_score BETWEEN 0 AND 100),
  CONSTRAINT ck_reg_letter      CHECK (letter_grade IN ('A', 'B+', 'B', 'C+', 'C', 'D', 'F'))
);

CREATE INDEX idx_reg_course_sem ON registrations (course_id, semester);
CREATE OR REPLACE TYPE t_id_list AS TABLE OF NUMBER;
/
