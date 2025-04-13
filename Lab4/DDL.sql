-- CREATE USER orm_user IDENTIFIED BY 1234;
-- GRANT CONNECT, RESOURCE, CREATE TRIGGER TO orm_user;
-- GRANT CREATE TABLE TO orm_user;
-- GRANT CREATE SEQUENCE TO orm_user;
-- GRANT CREATE TRIGGER TO orm_user;
ALTER SESSION SET CURRENT_SCHEMA = orm_user;
-- SELECT * FROM USER_ERRORS WHERE NAME = 'MY_EMPLOYEES_BI_TRG' AND TYPE = 'TRIGGER';
-- DROP SEQUENCE my_employees_SEQ;
DECLARE
  v_json CLOB;
BEGIN
  v_json := '{
    "type": "CREATE_TABLE",
    "name": "my_employees",
    "columns": [
      {
        "name": "employee_id",
        "type": "NUMBER",
        "constraints": ["NOT NULL", "PRIMARY KEY"]
      },
      {
        "name": "first_name",
        "type": "VARCHAR2(50)",
        "constraints": ["NOT NULL"]
      },
      {
        "name": "last_name",
        "type": "VARCHAR2(50)",
        "constraints": ["NOT NULL"]
      },
      {
        "name": "email",
        "type": "VARCHAR2(100)",
        "constraints": ["UNIQUE"]
      },
      {
        "name": "department_id",
        "type": "NUMBER",
        "constraints": ["NOT NULL"]
      },
      {
        "name": "hire_date",
        "type": "DATE",
        "constraints": ["NOT NULL"]
      },
      {
        "name": "salary",
        "type": "NUMBER(8,2)"
      }
    ],
    "generateTrigger": true
  }';
  
  orm_utils.execute_ddl(v_json);
END;
/
DECLARE
  v_json CLOB;
BEGIN
  v_json := '{
    "type": "CREATE_TABLE",
    "name": "departments",
    "columns": [
      {
        "name": "department_id",
        "type": "NUMBER",
        "constraints": ["NOT NULL", "PRIMARY KEY"]
      },
      {
        "name": "department_name",
        "type": "VARCHAR2(100)",
        "constraints": ["NOT NULL"]
      },
      {
        "name": "location",
        "type": "VARCHAR2(200)",
        "constraints": ["NOT NULL"]
      }
    ],
    "generateTrigger": true
  }';
  
  orm_utils.execute_ddl(v_json);
END;
/

DECLARE
  v_json CLOB;
BEGIN
  v_json := '{
    "type": "CREATE_TABLE",
    "name": "temp_employees",
    "columns": [
      {
        "name": "emp_id",
        "type": "NUMBER",
        "constraints": ["NOT NULL", "PRIMARY KEY"]
      },
      {
        "name": "name",
        "type": "VARCHAR2(50)",
        "constraints": ["NOT NULL"]
      },
      {
        "name": "surname",
        "type": "VARCHAR2(50)",
        "constraints": ["NOT NULL"]
      },
      {
        "name": "contact_email",
        "type": "VARCHAR2(100)"
      },
      {
        "name": "start_date",
        "type": "DATE",
        "constraints": ["NOT NULL"]
      },
      {
        "name": "base_salary",
        "type": "NUMBER(8,2)"
      },
      {
        "name": "dept_id",
        "type": "NUMBER"
      },
      {
        "name": "status",
        "type": "VARCHAR2(20)"
      }
    ],
    "generateTrigger": false
  }';
  
  orm_utils.execute_ddl(v_json);
END;
/

DECLARE
  v_json CLOB;
BEGIN
  v_json := '{
    "type": "DROP_TABLE",
    "name": "my_employees"
  }';
  
  orm_utils.execute_ddl(v_json);
END;
/
DECLARE
  v_json CLOB;
BEGIN
  v_json := '{
    "type": "DROP_TABLE",
    "name": "departments"
  }';
  
  orm_utils.execute_ddl(v_json);
END;
/