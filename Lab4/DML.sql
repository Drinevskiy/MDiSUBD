ALTER SESSION SET CURRENT_SCHEMA = orm_user;
-- GRANT CREATE TABLE TO orm_user;
-- GRANT CREATE SEQUENCE TO orm_user;
-- GRANT CREATE TRIGGER TO orm_user;
-- Под пользователем с правами DBA
-- ALTER USER ORM_USER QUOTA UNLIMITED ON USERS;
-- GRANT EXECUTE ON DBMS_OUTPUT TO orm_user;
-- DELETE FROM MY_EMPLOYEES;
-- DECLARE
--   v_json CLOB;
-- BEGIN
--   v_json := '{
--     "type": "INSERT",
--     "table": "MY_EMPLOYEES",
--     "values": [{
--         "FIRST_NAME": {"type": "STRING", "value": "Max"},
--         "LAST_NAME": {"type": "STRING", "value": "Doe"},
--         "EMAIL": {"type": "STRING", "value": "max.doe@example.com"},
--         "HIRE_DATE": {"type": "DATE", "value": "2023-01-15"},
--         "SALARY": {"type": "NUMBER", "value": 5000}
--     },
--     {
--         "FIRST_NAME": {"type": "STRING", "value": "Kirill"},
--         "LAST_NAME": {"type": "STRING", "value": "Drinevskiy"},
--         "EMAIL": {"type": "STRING", "value": "drinevskiy3@gmail.com"},
--         "HIRE_DATE": {"type": "DATE", "value": "2023-01-15"},
--         "SALARY": {"type": "NUMBER", "value": 5000}
--     }]
--   }';
  
--   orm_utils.execute_dml(v_json);
-- END;
-- /
-- DELETE FROM APP_LOGS;
-- commit;

DECLARE
  v_json CLOB;
BEGIN
  v_json := '{
    "type": "INSERT",
    "table": "departments",
    "values": [
      {
        "department_name": {"type": "STRING", "value": "IT"},
        "location": {"type": "STRING", "value": "New York"}
      },
      {
        "department_name": {"type": "STRING", "value": "Sales"},
        "location": {"type": "STRING", "value": "London"}
      }
    ]
  }';
  orm_utils.execute_dml(v_json);
END;
/

DECLARE
  v_json CLOB;
BEGIN
  v_json := '{
    "type": "INSERT",
    "table": "temp_employees",
    "values": [
      {
        "emp_id": {"type": "NUMBER", "value": 1001},
        "name": {"type": "STRING", "value": "Mike"},
        "surname": {"type": "STRING", "value": "Johnson"},
        "contact_email": {"type": "STRING", "value": "mike@example.com"},
        "start_date": {"type": "DATE", "value": "2023-05-01"},
        "base_salary": {"type": "NUMBER", "value": 4800},
        "dept_id": {"type": "NUMBER", "value": 10},
        "status": {"type": "STRING", "value": "active"}
      },
      {
        "emp_id": {"type": "NUMBER", "value": 1002},
        "name": {"type": "STRING", "value": "Sarah"},
        "surname": {"type": "STRING", "value": "Connor"},
        "contact_email": {"type": "STRING", "value": "sarah@example.com"},
        "start_date": {"type": "DATE", "value": "2023-06-15"},
        "base_salary": {"type": "NUMBER", "value": 5200},
        "dept_id": {"type": "NUMBER", "value": 20},
        "status": {"type": "STRING", "value": "inactive"}
      }
    ]
  }';
  
  orm_utils.execute_dml(v_json);
END;
/

-- Добавляем сотрудников с привязкой к отделам
DECLARE
  v_json CLOB;
BEGIN
  v_json := '{
    "type": "INSERT",
    "table": "my_employees",
    "values": [
      {
        "first_name": {"type": "STRING", "value": "John"},
        "last_name": {"type": "STRING", "value": "Doe"},
        "email": {"type": "STRING", "value": "john@example.com"},
        "hire_date": {"type": "DATE", "value": "2023-01-01"},
        "salary": {"type": "NUMBER", "value": 6000},
        "department_id": {"type": "NUMBER", "value": 1}
      },
      {
        "first_name": {"type": "STRING", "value": "Alice"},
        "last_name": {"type": "STRING", "value": "Smith"},
        "email": {"type": "STRING", "value": "alice@example.com"},
        "hire_date": {"type": "DATE", "value": "2023-02-15"},
        "salary": {"type": "NUMBER", "value": 7500},
        "department_id": {"type": "NUMBER", "value": 2}
      },
      {
        "first_name": {"type": "STRING", "value": "Bob"},
        "last_name": {"type": "STRING", "value": "Brown"},
        "email": {"type": "STRING", "value": "bob@example.com"},
        "hire_date": {"type": "DATE", "value": "2023-03-10"},
        "salary": {"type": "NUMBER", "value": 5500},
        "department_id": {"type": "NUMBER", "value": 1}
      }
    ]
  }';
  orm_utils.execute_dml(v_json);
END;
/

DECLARE
  v_json CLOB;
BEGIN
  v_json := '{
    "type": "INSERT",
    "table": "my_employees",
    "columns": ["first_name", "last_name", "email", "hire_date", "salary", "department_id"],
    "subquery": {
        "type": "SELECT",
        "columns": ["name", "surname", "contact_email", "start_date", "base_salary", "dept_id"],
        "tables": [{"name": "temp_employees"}],
        "conditions": [{
            "column": "status",
            "operator": "=",
            "value": {"type": "STRING", "value": "active"}
        }]
    }
  }';
  
  orm_utils.execute_dml(v_json);
END;
/

DECLARE
  v_json CLOB;
BEGIN
  v_json := '{
    "type": "UPDATE",
    "table": "my_employees",
    "values": {
        "SALARY": {
            "type": "NUMBER",
            "value": 6000
        }
    },
    "conditions": [
        {
            "column": "FIRST_NAME",
            "operator": "=",
            "value": {
                "type": "STRING",
                "value": "John"
            }
        }
    ]
  }';
  
  orm_utils.execute_dml(v_json);
END;
/

DECLARE
  v_json CLOB;
BEGIN
  v_json := '{
    "type": "UPDATE",
    "table": "my_employees",
    "values": {
        "department_id": {"type": "NUMBER", "value": 2}
    },
    "conditions": [{
        "column": "department_id",
        "operator": "IN",
        "subquery": {
            "type": "SELECT",
            "columns": ["department_id"],
            "tables": [{"name": "departments"}],
            "conditions": [{
                "column": "location",
                "operator": "=",
                "value": {"type": "STRING", "value": "London"}
            }]
        }
    }]
  }';
  
  orm_utils.execute_dml(v_json);
END;
/

DECLARE
  v_json CLOB;
BEGIN
  v_json := '{
    "type": "UPDATE",
    "table": "departments",
    "values": {
        "department_id": {"type": "NUMBER", "value": 2}
    },
    "conditions": [{
        "column": "location",
        "operator": "=",
        "value": {"type": "STRING", "value": "London"}
    }]
  }';
  
  orm_utils.execute_dml(v_json);
END;
/

DECLARE
  v_json CLOB;
BEGIN
  v_json := '{
    "type": "DELETE",
    "table": "my_employees",
    "conditions": [
      {
        "column": "salary",
        "operator": "<",
        "value": {
                "type": "NUMBER",
                "value": 5500

            }
      }
    ]
  }';
  
  orm_utils.execute_dml(v_json);
END;
/

DECLARE
  v_json CLOB;
BEGIN
  v_json := '{
    "type": "DELETE",
    "table": "my_employees",
    "conditions": [
      {
        "column": "department_id",
        "operator": "=",
        "value": {
                "type": "NUMBER",
                "value": 10
            }
      }
    ]
  }';
  orm_utils.execute_dml(v_json);
END;
/

DECLARE
  v_json CLOB;
BEGIN
  v_json := '{
    "type": "DELETE",
    "table": "my_employees",
    "conditions": [
      {
        "column": "salary",
        "operator": "<",
        "value": {"type": "NUMBER", "value": 6000}
      },
      {
        "logicalOperator": "AND",
        "column": "department_id",
        "operator": "=",
        "subquery": {
          "type": "SELECT",
            "columns": ["department_id"],
            "tables": [{"name": "departments"}],
            "conditions": [{
                "column": "location",
                "operator": "=",
                "value": {"type": "STRING", "value": "New York"}
            }]
        }
      }
    ]
  }';
  
  orm_utils.execute_dml(v_json);
END;
/