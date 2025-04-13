ALTER SESSION SET CURRENT_SCHEMA = orm_user;
-- ALTER SESSION SET CURRENT_SCHEMA = SYS;
-- SELECT * FROM my_employees;
-- GRANT SELECT ON my_employees TO orm_user;
-- VAR cr SYS_REFCURSOR;
-- SET SERVEROUTPUT ON;
-- GRANT EXECUTE ON DBMS_OUTPUT TO orm_user;
-- SELECT employee_id, first_name, last_name FROM my_employees e WHERE last_name = 'Drinevskiy' ORDER BY last_name ASC;

-- connect system / 1234 as sysdba;
-- grant create session to orm_user;
-- grant execute on DBMS_OUTPUT  to orm_user with grant option;
-- SET SERVEROUTPUT ON;

DECLARE
  v_json CLOB;
  v_cursor SYS_REFCURSOR;
BEGIN
  v_json := '{
    "type": "SELECT",
    "columns": ["employee_id", "first_name", "last_name", "email"],
    "tables": [{"name": "my_employees", "alias": "e"}],
    "conditions": [{
      "column": "last_name",
      "operator": "IS NOT NULL"
    }]
  }';
  
  -- Получаем курсор
  v_cursor := orm_utils.execute_query(v_json);
  output_formatter.print_cursor(v_cursor);
END;
/

DECLARE
  v_json CLOB;
  v_cursor SYS_REFCURSOR;
BEGIN
  v_json := '{
    "type": "SELECT",
    "columns": ["employee_id", "first_name", "last_name"],
    "tables": [
      {
        "name": "my_employees",
        "alias": "e"
      }
    ],
    "conditions": [
      {
        "column": "department_id",
        "operator": "IN",
        "subquery": {
          "type": "SELECT",
          "columns": ["department_id"],
          "tables": [
            {
              "name": "departments",
              "alias": "d"
            }
          ],
          "conditions": [
            {
              "column": "location",
              "operator": "=",
              "value": {"type": "STRING", "value": "New York"}
            }
          ]
        }
      }
    ]
  }';
  
  v_cursor := orm_utils.execute_query(v_json);
  output_formatter.print_cursor(v_cursor);
END;
/

DECLARE
  v_json CLOB;
  v_cursor SYS_REFCURSOR;
BEGIN
  v_json := '{
    "type": "SELECT",
    "columns": ["employee_id", "first_name", "last_name"],
    "tables": [
      {
        "name": "my_employees",
        "alias": "e"
      }
    ],
    "conditions": [
      {
        "column": "department_id",
        "operator": "IN",
        "valueArray": [
        {
          "value" : {"type": "NUMBER", "value": 1}
        }, 
        {
          "value": {"type": "NUMBER", "value": 2}
        }
        ]
      }
    ]
  }';
  
  v_cursor := orm_utils.execute_query(v_json);
  output_formatter.print_cursor(v_cursor);
END;
/

DECLARE
  v_json CLOB;
  v_cursor SYS_REFCURSOR;
BEGIN
  v_json := '{
    "type": "SELECT",
    "columns": ["employee_id", "first_name", "last_name"],
    "tables": [
      {
        "name": "my_employees",
        "alias": "e"
      }
    ],
    "conditions": [
      {
        "column": "department_id",
        "operator": "EXISTS",
        "subquery": {
          "type": "SELECT",
          "columns": ["1"],
          "tables": [
            {
              "name": "departments",
              "alias": "d"
            }
          ],
          "conditions": [
            {
              "column": "e.department_id",
              "operator": "=",
              "value": {"type": "TABLE_COLUMN", "value": "d.department_id"}
            }
          ]
        }
      }
    ]
  }';
  
  v_cursor := orm_utils.execute_query(v_json);
  output_formatter.print_cursor(v_cursor);
END;
/

DECLARE
  v_json CLOB;
  v_cursor SYS_REFCURSOR;
BEGIN
  v_json := '{
    "type": "SELECT",
    "columns": ["employee_id", "first_name"],
    "tables": [{"name": "my_employees"}],
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
                "value": {"type": "STRING", "value": "New York"}
            }]
        }
    }]
  }';
  
  v_cursor := orm_utils.execute_query(v_json);
  output_formatter.print_cursor(v_cursor);
END;
/

DECLARE
  v_json CLOB;
  v_cursor SYS_REFCURSOR;
BEGIN
  v_json := '{
    "type": "SELECT",
    "columns": ["e.first_name", "e.last_name", "d.department_name", "e.salary"],
    "tables": [
      {"name": "my_employees", "alias": "e"}
    ],
    "joins": [
      {
        "type": "INNER",
        "table": "departments",
        "alias": "d",
        "condition": "e.department_id = d.department_id"
      }
    ],
    "orderBy": [{"column": "e.salary", "direction": "DESC"}]
  }';
  
  v_cursor := orm_utils.execute_query(v_json);
  output_formatter.print_cursor(v_cursor);
END;
/

DECLARE
  v_json CLOB;
  v_cursor SYS_REFCURSOR;
BEGIN
  v_json := '{
    "type": "SELECT",
    "columns": ["d.department_name", "AVG(e.salary) AS avg_salary"],
    "tables": [
      {"name": "my_employees", "alias": "e"}
    ],
    "joins": [
      {
        "type": "INNER",
        "table": "departments",
        "alias": "d",
        "condition": "e.department_id = d.department_id"
      }
    ],
    "groupBy": ["d.department_name"],
    "having": [{"column": "AVG(e.salary)", "operator": ">", "value": {"type": "NUMBER", "value": 6000}}],
    "orderBy": [{"column": "avg_salary", "direction": "DESC"}]
  }';
  
  v_cursor := orm_utils.execute_query(v_json);
  output_formatter.print_cursor(v_cursor);
END;
/

DECLARE
  v_json CLOB;
  v_cursor SYS_REFCURSOR;
BEGIN
  v_json := '{
    "type": "SELECT",
    "columns": ["d.department_name", "COUNT(e.employee_id) AS employees_count"],
    "tables": [
      {"name": "my_employees", "alias": "e"}
    ],
    "joins": [
      {
        "type": "INNER",
        "table": "departments",
        "alias": "d",
        "condition": "e.department_id = d.department_id"
      }
    ],
    "groupBy": ["d.department_name"],
    "having": [{"column": "COUNT(e.employee_id)", "operator": ">=", "value": {"type": "NUMBER", "value": 2}}],
    "orderBy": [{"column": "employees_count", "direction": "DESC"}]
  }';
  
  v_cursor := orm_utils.execute_query(v_json);
  output_formatter.print_cursor(v_cursor);
END;
/