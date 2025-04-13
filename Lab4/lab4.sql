-- ALTER SESSION SET orm_user;
-- CONNECT orm_user/1234;
-- ALTER SESSION SET CURRENT_SCHEMA = orm_user;
-- CREATE TABLE app_logs (
--     log_id      NUMBER GENERATED ALWAYS AS IDENTITY,
--     log_time    TIMESTAMP DEFAULT SYSTIMESTAMP,
--     log_message VARCHAR2(4000)
-- );

CREATE OR REPLACE PACKAGE orm_utils  AS
  -- Основная функция для выполнения SELECT-запросов
  FUNCTION execute_query(p_json IN CLOB) RETURN SYS_REFCURSOR;
  
  -- Процедура для выполнения DML-запросов (INSERT, UPDATE, DELETE)
  PROCEDURE execute_dml(p_json IN CLOB);
  
  -- Процедура для выполнения DDL-запросов (CREATE/DROP TABLE)
  PROCEDURE execute_ddl(p_json IN CLOB);
  
  -- Функция для парсинга и формирования SELECT-запроса (для использования в других функциях)
  FUNCTION parse_select_internal(p_json IN JSON_OBJECT_T) RETURN VARCHAR2;
END orm_utils;
/

CREATE OR REPLACE PACKAGE BODY orm_utils AS
  -- Включение/выключение подробного логирования
  g_debug BOOLEAN := TRUE;
  
  PROCEDURE log_debug(p_message IN VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION; -- Чтобы сохранить логи даже при откате основной транзакции
    BEGIN
        IF g_debug THEN
            INSERT INTO app_logs (log_message) VALUES (p_message);
            COMMIT;
        END IF;
    END log_debug;
  -- Процедура для логирования, если включено
--   PROCEDURE log_debug(p_message IN VARCHAR2) IS
--   BEGIN
--     IF g_debug THEN
--       DBMS_OUTPUT.PUT_LINE('DEBUG: ' || p_message);
--     END IF;
--   END log_debug;
  
  -- Функция для экранирования строковых значений
  FUNCTION escape_string(p_value IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN REPLACE(p_value, '''', '''''');
  END escape_string;
  
  -- Функция для преобразования JSON-значения в строку SQL
  FUNCTION json_value_to_sql(p_json_obj IN JSON_OBJECT_T, p_key IN VARCHAR2) RETURN VARCHAR2 IS
    v_type VARCHAR2(100);
    v_value_node JSON_OBJECT_T;
    v_data_type VARCHAR2(100);
    v_value VARCHAR2(4000);
BEGIN
    IF NOT p_json_obj.has(p_key) THEN
        RAISE_APPLICATION_ERROR(-20020, 'Missing required field: ' || p_key);
    END IF;

    -- Получаем вложенный объект с типом и значением
    v_value_node := p_json_obj.get_object(p_key);

    -- Проверяем наличие полей type и value
    IF NOT v_value_node.has('type') THEN
        RAISE_APPLICATION_ERROR(-20022, 'Missing "type" field for key: ' || p_key);
    END IF;

    IF NOT v_value_node.has('value') THEN
        RAISE_APPLICATION_ERROR(-20023, 'Missing "value" field for key: ' || p_key);
    END IF;

    -- Получаем тип данных
    v_data_type := v_value_node.get_string('type');

    -- Обрабатываем значение в зависимости от типа
    CASE v_data_type
        WHEN 'STRING' THEN
            RETURN '''' || escape_string(v_value_node.get_string('value')) || '''';

        WHEN 'TABLE_COLUMN' THEN
            RETURN '' || escape_string(v_value_node.get_string('value')) || '';

        WHEN 'NUMBER' THEN
            RETURN TO_CHAR(v_value_node.get_number('value'));

        WHEN 'DATE' THEN
            RETURN 'TO_DATE(''' 
                   || escape_string(v_value_node.get_string('value')) 
                   || ''', ''' 
                   || NVL(v_value_node.get_string('format'), 'YYYY-MM-DD') 
                   || ''')';

        WHEN 'BOOLEAN' THEN
            RETURN CASE 
                   WHEN v_value_node.get_boolean('value') THEN '1' 
                   ELSE '0' 
                   END;

        ELSE
            RAISE_APPLICATION_ERROR(-20021, 'Unsupported data type: ' || v_data_type);
    END CASE;
  END json_value_to_sql;
  
  -- Функция для парсинга условий WHERE
  FUNCTION parse_conditions(p_conditions IN JSON_ARRAY_T) RETURN VARCHAR2 IS
    v_result VARCHAR2(32767);
    v_json_obj JSON_OBJECT_T;
    v_logical_operator VARCHAR2(10);
    v_column VARCHAR2(100);
    v_operator VARCHAR2(20);
    v_value VARCHAR2(4000);
    v_value_type VARCHAR2(100);
    v_subquery_json JSON_OBJECT_T;
    v_subquery VARCHAR2(32767);
  BEGIN
    IF p_conditions IS NULL OR p_conditions.get_size = 0 THEN
      RETURN NULL;
    END IF;
    
    v_result := 'WHERE ';
    
    FOR i IN 0..p_conditions.get_size - 1 LOOP
      v_json_obj := TREAT(p_conditions.get(i) AS JSON_OBJECT_T);
      
      -- Получаем логический оператор (AND/OR)
      IF i > 0 THEN
        v_logical_operator := v_json_obj.get_string('logicalOperator');
        IF v_logical_operator IS NULL THEN
          v_logical_operator := 'AND';
        END IF;
        v_result := v_result || ' ' || v_logical_operator || ' ';
      END IF;
      
      -- Проверяем, есть ли группа условий (для сложных условий с вложенными AND/OR)
      IF v_json_obj.has('conditions') THEN
        -- Рекурсивный вызов для обработки вложенной группы условий
        v_result := v_result || '(' || 
                   SUBSTR(parse_conditions(v_json_obj.get_array('conditions')), 7) || 
                   ')';
      ELSE
        v_column := v_json_obj.get_string('column');
        v_operator := v_json_obj.get_string('operator');
        
        -- Проверяем, есть ли подзапрос
        IF v_json_obj.has('subquery') THEN
          v_subquery_json := v_json_obj.get_object('subquery');
          v_subquery := '(' || parse_select_internal(v_subquery_json) || ')';
          
          CASE v_operator
            WHEN 'IN' THEN
              v_result := v_result || v_column || ' IN ' || v_subquery;
            WHEN 'NOT IN' THEN
              v_result := v_result || v_column || ' NOT IN ' || v_subquery;
            WHEN 'EXISTS' THEN
              v_result := v_result || 'EXISTS ' || v_subquery;
            WHEN 'NOT EXISTS' THEN
              v_result := v_result || 'NOT EXISTS ' || v_subquery;
            ELSE
              v_result := v_result || v_column || ' ' || v_operator || ' ' || v_subquery;
          END CASE;
        ELSIF v_json_obj.has('valueArray') THEN
          -- Обработка массива значений для IN
          DECLARE
            v_values_array JSON_ARRAY_T;
            v_in_list VARCHAR2(4000) := '(';
            v_obj JSON_OBJECT_T;
          BEGIN
            v_values_array := v_json_obj.get_array('valueArray');
            -- v_keys := v_values_obj.get_keys();
            FOR j IN 0..v_values_array.get_size - 1 LOOP
              v_obj := TREAT(v_values_array.get(j) AS JSON_OBJECT_T);
              IF j > 0 THEN
                v_in_list := v_in_list || ', ';
              END IF;
              v_in_list := v_in_list || json_value_to_sql(TREAT(v_values_array.get(j) AS JSON_OBJECT_T), 'value');
              -- IF v_values_array.get_type(j) = 'STRING' THEN
                -- v_in_list := v_in_list || '''' || escape_string(v_values_array.get_string(j)) || '''';
              -- ELSE
                -- v_in_list := v_in_list || v_values_array.get_string(j);
              -- END IF;
            END LOOP;
            
            v_in_list := v_in_list || ')';
            
            CASE v_operator
              WHEN 'IN' THEN
                v_result := v_result || v_column || ' IN ' || v_in_list;
              WHEN 'NOT IN' THEN
                v_result := v_result || v_column || ' NOT IN ' || v_in_list;
              ELSE
                v_result := v_result || v_column || ' ' || v_operator || ' ' || v_in_list;
            END CASE;
          END;
        ELSE
          -- Обычное условие без подзапроса
          
          -- Особая обработка для операторов IS NULL и IS NOT NULL
          IF v_operator = 'IS NULL' THEN
            v_result := v_result || v_column || ' IS NULL';
          ELSIF v_operator = 'IS NOT NULL' THEN
            v_result := v_result || v_column || ' IS NOT NULL';
          ELSE
            v_value := json_value_to_sql(v_json_obj, 'value');
            v_result := v_result || v_column || ' ' || v_operator || ' ' || v_value;
          END IF;
        END IF;
      END IF;
    END LOOP;
    
    RETURN v_result;
  END parse_conditions;
  
  -- Функция для парсинга и формирования SELECT-запроса
  FUNCTION parse_select_internal(p_json IN JSON_OBJECT_T) RETURN VARCHAR2 IS
    v_sql VARCHAR2(32767);
    v_columns VARCHAR2(4000);
    v_tables VARCHAR2(4000);
    v_joins VARCHAR2(32767);
    v_conditions VARCHAR2(32767);
    v_group_by VARCHAR2(4000);
    v_having VARCHAR2(4000);
    v_order_by VARCHAR2(4000);
    
    v_columns_array JSON_ARRAY_T;
    v_tables_array JSON_ARRAY_T;
    v_joins_array JSON_ARRAY_T;
    v_conditions_array JSON_ARRAY_T;
    v_group_by_array JSON_ARRAY_T;
    v_having_array JSON_ARRAY_T;
    v_order_by_array JSON_ARRAY_T;
    
    v_table_json JSON_OBJECT_T;
    v_join_json JSON_OBJECT_T;
    v_order_by_json JSON_OBJECT_T;
  BEGIN
    -- Парсинг столбцов
    v_columns_array := p_json.get_array('columns');
    IF v_columns_array IS NOT NULL AND v_columns_array.get_size > 0 THEN
      FOR i IN 0..v_columns_array.get_size - 1 LOOP
        IF i > 0 THEN
          v_columns := v_columns || ', ';
        END IF;
        v_columns := v_columns || v_columns_array.get_string(i);
      END LOOP;
    ELSE
      v_columns := '*';
    END IF;
    
    -- Парсинг таблиц
    v_tables_array := p_json.get_array('tables');
    IF v_tables_array IS NOT NULL AND v_tables_array.get_size > 0 THEN
      FOR i IN 0..v_tables_array.get_size - 1 LOOP
        IF i > 0 THEN
          v_tables := v_tables || ', ';
        END IF;
        
        v_table_json := TREAT(v_tables_array.get(i) AS JSON_OBJECT_T);
        v_tables := v_tables || v_table_json.get_string('name');
        
        IF v_table_json.has('alias') AND v_table_json.get_string('alias') IS NOT NULL THEN
          v_tables := v_tables || ' ' || v_table_json.get_string('alias');
        END IF;
      END LOOP;
    END IF;
    
    -- Парсинг JOIN-ов
    v_joins_array := p_json.get_array('joins');
    IF v_joins_array IS NOT NULL AND v_joins_array.get_size > 0 THEN
      FOR i IN 0..v_joins_array.get_size - 1 LOOP
        v_join_json := TREAT(v_joins_array.get(i) AS JSON_OBJECT_T);
        
        v_joins := v_joins || ' ' || v_join_json.get_string('type') || ' JOIN ' ||
                   v_join_json.get_string('table');
        
        IF v_join_json.has('alias') AND v_join_json.get_string('alias') IS NOT NULL THEN
          v_joins := v_joins || ' ' || v_join_json.get_string('alias');
        END IF;
        
        v_joins := v_joins || ' ON ' || v_join_json.get_string('condition');
      END LOOP;
    END IF;
    
    -- Парсинг условий (WHERE)
    v_conditions_array := p_json.get_array('conditions');
    v_conditions := parse_conditions(v_conditions_array);
    
    -- Парсинг GROUP BY
    v_group_by_array := p_json.get_array('groupBy');
    IF v_group_by_array IS NOT NULL AND v_group_by_array.get_size > 0 THEN
      v_group_by := 'GROUP BY ';
      FOR i IN 0..v_group_by_array.get_size - 1 LOOP
        IF i > 0 THEN
          v_group_by := v_group_by || ', ';
        END IF;
        v_group_by := v_group_by || v_group_by_array.get_string(i);
      END LOOP;
    END IF;
    
    -- Парсинг HAVING
    v_having_array := p_json.get_array('having');
    IF v_having_array IS NOT NULL AND v_having_array.get_size > 0 THEN
      v_having := 'HAVING ' || SUBSTR(parse_conditions(v_having_array), 7);
    END IF;
    
    -- Парсинг ORDER BY
    v_order_by_array := p_json.get_array('orderBy');
    IF v_order_by_array IS NOT NULL AND v_order_by_array.get_size > 0 THEN
      v_order_by := 'ORDER BY ';
      FOR i IN 0..v_order_by_array.get_size - 1 LOOP
        IF i > 0 THEN
          v_order_by := v_order_by || ', ';
        END IF;
        
        v_order_by_json := TREAT(v_order_by_array.get(i) AS JSON_OBJECT_T);
        v_order_by := v_order_by || v_order_by_json.get_string('column') || ' ' ||
                       v_order_by_json.get_string('direction');
      END LOOP;
    END IF;
    
    -- Сборка SQL-запроса
    v_sql := 'SELECT ' || v_columns ||
             ' FROM ' || v_tables ||
             v_joins;
    
    IF v_conditions IS NOT NULL THEN
      v_sql := v_sql || ' ' || v_conditions;
    END IF;
    
    IF v_group_by IS NOT NULL THEN
      v_sql := v_sql || ' ' || v_group_by;
    END IF;
    
    IF v_having IS NOT NULL THEN
      v_sql := v_sql || ' ' || v_having;
    END IF;
    
    IF v_order_by IS NOT NULL THEN
      v_sql := v_sql || ' ' || v_order_by;
    END IF;
    
    log_debug('Generated SQL: ' || v_sql);
    RETURN v_sql;
  END parse_select_internal;
  
  -- Функция для выполнения SELECT-запроса
  FUNCTION parse_select(p_json IN JSON_OBJECT_T) RETURN SYS_REFCURSOR IS
    v_sql VARCHAR2(32767);
    v_cursor SYS_REFCURSOR;
  BEGIN
    v_sql := parse_select_internal(p_json);
    log_debug('Executing SQL: ' || v_sql);
    
    OPEN v_cursor FOR v_sql;
    RETURN v_cursor;
  EXCEPTION
    WHEN OTHERS THEN
      log_debug('Error executing SQL: ' || v_sql);
      RAISE_APPLICATION_ERROR(-20001, 'Error executing SELECT query: ' || SQLERRM || 
                             ' SQL: ' || v_sql);
  END parse_select;
  
  -- Функция для парсинга и выполнения DML-запросов (INSERT, UPDATE, DELETE)
  FUNCTION parse_dml(p_json IN JSON_OBJECT_T) RETURN VARCHAR2 IS
    v_type VARCHAR2(10);
    v_table VARCHAR2(100);
    v_sql VARCHAR2(32767);
    v_values_array JSON_ARRAY_T;
    v_values_obj JSON_OBJECT_T;
    v_conditions_array JSON_ARRAY_T;
    v_conditions VARCHAR2(32767);
    v_columns VARCHAR2(4000);
    v_values VARCHAR2(4000);
    v_set_clause VARCHAR2(4000);
    v_keys JSON_KEY_LIST;
    v_key VARCHAR2(100);
    v_value VARCHAR2(4000);
    v_subquery_json JSON_OBJECT_T;
    v_subquery VARCHAR2(32767);
    v_columns_array JSON_ARRAY_T;
  BEGIN
    v_type := p_json.get_string('type');
    v_table := p_json.get_string('table');
    -- log_debug('Inside parse dml');
    -- log_debug('Inside parse dml: ' || v_type);
    CASE v_type
      WHEN 'INSERT' THEN
        -- Проверяем, есть ли подзапрос для INSERT
        IF p_json.has('subquery') THEN
          v_subquery_json := p_json.get_object('subquery');
          v_subquery := parse_select_internal(v_subquery_json);
          
          -- Если есть список столбцов
          IF p_json.has('columns') THEN
            v_columns_array := p_json.get_array('columns');
            
            IF v_columns_array IS NOT NULL AND v_columns_array.get_size > 0 THEN
              v_columns := '(';
              FOR i IN 0..v_columns_array.get_size - 1 LOOP
                IF i > 0 THEN
                  v_columns := v_columns || ', ';
                END IF;
                v_columns := v_columns || v_columns_array.get_string(i);
              END LOOP;
              v_columns := v_columns || ')';
            END IF;
          END IF;
          
          v_sql := 'INSERT INTO ' || v_table || COALESCE(v_columns, '') || ' ' || v_subquery;
        ELSE
          -- Обычный INSERT с VALUES
        v_values_array := p_json.get_array('values');
        IF v_values_array IS NULL OR v_values_array.get_size() = 0 THEN
            RAISE_APPLICATION_ERROR(-20023, 'Empty values array for INSERT');
        END IF;


        -- Проверка обязательных полей
        -- FOR col IN (
        --     SELECT column_name 
        --     FROM user_tab_columns 
        --     WHERE table_name = UPPER(v_table) 
        --     AND nullable = 'N'
        -- ) LOOP
        --     IF NOT v_values_obj.has(col.column_name) THEN
        --         RAISE_APPLICATION_ERROR(-20024, 'Missing required column: ' || col.column_name);
        --     END IF;
        -- END LOOP;

        -- Формируем списки столбцов и значений
        v_sql := 'INSERT ALL';
        FOR j IN 0..v_values_array.get_size() -1 LOOP
          v_columns := '';
          v_values := '';
          v_values_obj := TREAT(v_values_array.get(j) AS JSON_OBJECT_T);
          v_keys := v_values_obj.get_keys();
          FOR i IN 1..v_keys.COUNT LOOP  -- Индексация начинается с 1
              v_key := v_keys(i);        -- Получаем ключ через круглые скобки
              
              IF i > 1 THEN
                  v_columns := v_columns || ', ';
                  v_values := v_values || ', ';
              END IF;
              
              v_columns := v_columns || v_key;
              v_values := v_values || json_value_to_sql(v_values_obj, v_key);
          END LOOP;
            v_sql := v_sql || ' INTO ' || v_table || ' (' || v_columns || ') VALUES (' || v_values || ')';
        END LOOP;
        v_sql := v_sql || ' SELECT * FROM dual';
        END IF;
        log_debug(v_sql);
      WHEN 'UPDATE' THEN
        -- Проверяем, есть ли подзапрос для UPDATE
        IF p_json.has('subquery') THEN
          v_subquery_json := p_json.get_object('subquery');
          v_subquery := parse_select_internal(v_subquery_json);
          
          v_columns_array := p_json.get_array('columns');
          IF v_columns_array IS NOT NULL AND v_columns_array.get_size > 0 THEN
            v_columns := '(';
            FOR i IN 0..v_columns_array.get_size - 1 LOOP
              IF i > 0 THEN
                v_columns := v_columns || ', ';
              END IF;
              v_columns := v_columns || v_columns_array.get_string(i);
            END LOOP;
            v_columns := v_columns || ')';
          END IF;
          
          v_sql := 'UPDATE ' || v_table || ' SET ' || v_columns || ' = (' || v_subquery || ')';
        ELSE
          -- Обычный UPDATE
          v_values_obj := p_json.get_object('values');
          v_keys := v_values_obj.get_keys();
          -- Формируем SET-часть запроса
          FOR i IN 1..v_keys.count LOOP
            IF i > 1 THEN
              v_set_clause := v_set_clause || ', ';
            END IF;
            
            v_key := v_keys(i);
            v_set_clause := v_set_clause || v_key || ' = ' || json_value_to_sql(v_values_obj, v_key);
          END LOOP;
          
          v_sql := 'UPDATE ' || v_table || ' SET ' || v_set_clause;
        END IF;
        v_conditions_array := p_json.get_array('conditions');
        v_conditions := parse_conditions(v_conditions_array);
        
        IF v_conditions IS NOT NULL THEN
          v_sql := v_sql || '  ' || v_conditions;
        END IF;
        
      WHEN 'DELETE' THEN
        v_conditions_array := p_json.get_array('conditions');
        v_conditions := parse_conditions(v_conditions_array);
        
        v_sql := 'DELETE FROM ' || v_table;
        
        IF v_conditions IS NOT NULL THEN
          v_sql := v_sql || '  ' || v_conditions;
        END IF;
    END CASE;
    
    log_debug('Generated DML SQL: ' || v_sql);
    RETURN v_sql;
  END parse_dml;
  
  -- Функция для парсинга и выполнения DDL-запросов (CREATE TABLE, DROP TABLE)
  FUNCTION parse_ddl(p_json IN JSON_OBJECT_T) RETURN VARCHAR2 IS
    v_type VARCHAR2(20);
    v_table VARCHAR2(100);
    v_sql VARCHAR2(32767);
    v_columns_array JSON_ARRAY_T;
    v_column_json JSON_OBJECT_T;
    v_constraints_array JSON_ARRAY_T;
    v_column_def VARCHAR2(4000);
    v_primary_key_obj JSON_OBJECT_T;
    v_pk_columns JSON_ARRAY_T;
    v_pk_columns_str VARCHAR2(4000);
    v_generate_trigger BOOLEAN;
    v_pk_column VARCHAR2(100);
    v_pk_type VARCHAR2(100);
    v_trigger_sql VARCHAR2(32767);
    v_sequence_sql VARCHAR2(32767);
  BEGIN
    v_type := p_json.get_string('type');
    v_table := p_json.get_string('name');
    
    CASE v_type
      WHEN 'CREATE_TABLE' THEN
        v_sql := 'CREATE TABLE ' || v_table || ' (';
        
        v_columns_array := p_json.get_array('columns');
        
        -- Обработка определений столбцов
        FOR i IN 0..v_columns_array.get_size - 1 LOOP
          IF i > 0 THEN
            v_sql := v_sql || ', ';
          END IF;
          
          v_column_json := TREAT(v_columns_array.get(i) AS JSON_OBJECT_T);
          v_column_def := v_column_json.get_string('name') || ' ' || v_column_json.get_string('type');
          
          -- Обработка ограничений на уровне столбца
          v_constraints_array := v_column_json.get_array('constraints');
          IF v_constraints_array IS NOT NULL AND v_constraints_array.get_size > 0 THEN
            FOR j IN 0..v_constraints_array.get_size - 1 LOOP
              v_column_def := v_column_def || ' ' || v_constraints_array.get_string(j);
              
              -- Запоминаем первичный ключ для генерации триггера
              IF v_constraints_array.get_string(j) = 'PRIMARY KEY' THEN
                v_pk_column := v_column_json.get_string('name');
                v_pk_type := v_column_json.get_string('type');
              END IF;
            END LOOP;
          END IF;
          
          v_sql := v_sql || v_column_def;
        END LOOP;
        
        -- Обработка первичного ключа на уровне таблицы
        IF p_json.has('primaryKey') THEN
          v_primary_key_obj := p_json.get_object('primaryKey');
          v_pk_columns := v_primary_key_obj.get_array('columns');
          
          FOR i IN 0..v_pk_columns.get_size - 1 LOOP
            IF i > 0 THEN
              v_pk_columns_str := v_pk_columns_str || ', ';
            END IF;
            v_pk_columns_str := v_pk_columns_str || v_pk_columns.get_string(i);
            
            -- Запоминаем первичный ключ для генерации триггера (берем первый столбец)
            IF i = 0 THEN
              v_pk_column := v_pk_columns.get_string(i);
              
              -- Нужно найти тип столбца
              FOR j IN 0..v_columns_array.get_size - 1 LOOP
                v_column_json := TREAT(v_columns_array.get(j) AS JSON_OBJECT_T);
                IF v_column_json.get_string('name') = v_pk_column THEN
                  v_pk_type := v_column_json.get_string('type');
                  EXIT;
                END IF;
              END LOOP;
            END IF;
          END LOOP;
          
          v_sql := v_sql || ', CONSTRAINT ' || v_primary_key_obj.get_string('name') || 
                   ' PRIMARY KEY (' || v_pk_columns_str || ')';
        END IF;
        
        v_sql := v_sql || ')';
        
        -- Генерация триггера для первичного ключа, если требуется
        IF (p_json.has('generateTrigger') AND p_json.get_boolean('generateTrigger')) AND v_pk_column IS NOT NULL THEN
          v_sequence_sql := 'CREATE SEQUENCE ' || v_table || '_SEQ START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
          
          v_trigger_sql := 'CREATE OR REPLACE TRIGGER ' || v_table || '_BI_TRG ' ||
                          'BEFORE INSERT ON ' || v_table || ' ' ||
                          'FOR EACH ROW ' ||
                          'BEGIN ' ||
                          '  IF :NEW.' || v_pk_column || ' IS NULL THEN ' ||
                          '    SELECT ' || v_table || '_SEQ.NEXTVAL INTO :NEW.' || v_pk_column || ' FROM DUAL' || ';' ||
                          '  END IF' || ';' || 
                          'END' || ';';
        --   log_degug(v_trigger_sql);                
          v_sql := v_sql || '@ ' || v_sequence_sql || '@ ' || v_trigger_sql;
        END IF;
        
      WHEN 'DROP_TABLE' THEN
        v_sql := 'DROP TABLE ' || v_table || ' CASCADE CONSTRAINTS';
    END CASE;
    
    log_debug('Generated DDL SQL: ' || v_sql);
    RETURN v_sql;
  END parse_ddl;
  
  -- Основная функция для выполнения SELECT-запросов
  FUNCTION execute_query(p_json IN CLOB) RETURN SYS_REFCURSOR IS
    v_json_obj JSON_OBJECT_T;
    v_type VARCHAR2(20);
    -- v_cursor SYS_REFCURSOR;
  BEGIN
    v_json_obj := JSON_OBJECT_T.parse(p_json);
    v_type := v_json_obj.get_string('type');
    
    IF v_type = 'SELECT' THEN
      RETURN parse_select(v_json_obj);
    ELSE
      RAISE_APPLICATION_ERROR(-20001, 'Invalid query type for execute_query: ' || v_type);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      log_debug('Error in execute_query: ' || SQLERRM);
      RAISE_APPLICATION_ERROR(-20001, 'Error executing query: ' || SQLERRM);
  END execute_query;
  
  -- Процедура для выполнения DML-запросов
  PROCEDURE execute_dml(p_json IN CLOB) IS
    v_json_obj JSON_OBJECT_T;
    v_type VARCHAR2(20);
    v_sql VARCHAR2(32767);
    v_rows_affected NUMBER;
  BEGIN
    v_json_obj := JSON_OBJECT_T.parse(p_json);
    v_type := v_json_obj.get_string('type');
    log_debug('Executing type: ' || v_type);
    
    IF v_type IN ('INSERT', 'UPDATE', 'DELETE') THEN
      v_sql := parse_dml(v_json_obj);
      log_debug('Executing DML: ' || v_sql);
      
      EXECUTE IMMEDIATE v_sql;
      COMMIT;
      -- EXECUTE IMMEDIATE 'COMMIT';
      v_rows_affected := SQL%ROWCOUNT;
      
      log_debug(v_type || ' statement executed. Rows affected: ' || v_rows_affected);
    ELSE
      RAISE_APPLICATION_ERROR(-20002, 'Invalid DML type: ' || v_type);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      log_debug('Error in execute_dml: ' || SQLERRM || ' SQL: ' || v_sql);
      RAISE_APPLICATION_ERROR(-20003, 'Error executing DML: ' || SQLERRM || ' SQL: ' || v_sql);
  END execute_dml;
  
  -- Процедура для выполнения DDL-запросов
  PROCEDURE execute_ddl(p_json IN CLOB) IS
    v_json_obj JSON_OBJECT_T;
    v_type VARCHAR2(20);
    v_sql VARCHAR2(32767);
  BEGIN
    v_json_obj := JSON_OBJECT_T.parse(p_json);
    v_type := v_json_obj.get_string('type');
    
    IF v_type IN ('CREATE_TABLE', 'DROP_TABLE') THEN
      v_sql := parse_ddl(v_json_obj);
      log_debug('Executing DDL: ' || v_sql);
      
      -- Разделяем несколько DDL-запросов
      FOR sql_stmt IN (
        SELECT REGEXP_SUBSTR(v_sql, '[^@]+', 1, level) AS stmt
        FROM dual
        CONNECT BY REGEXP_SUBSTR(v_sql, '[^@]+', 1, level) IS NOT NULL
      ) LOOP
        IF TRIM(sql_stmt.stmt) IS NOT NULL THEN
          log_debug('Executing DDL part: ' || TRIM(sql_stmt.stmt));
          EXECUTE IMMEDIATE TRIM(sql_stmt.stmt);
        END IF;
      END LOOP;
      
      log_debug(v_type || ' statement executed successfully.');
      COMMIT;
    ELSE
      RAISE_APPLICATION_ERROR(-20004, 'Invalid DDL type: ' || v_type);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      log_debug('Error in execute_ddl: ' || SQLERRM || ' SQL: ' || v_sql);
      RAISE_APPLICATION_ERROR(-20005, 'Error executing DDL: ' || SQLERRM || ' SQL: ' || v_sql);
  END execute_ddl;
END orm_utils;
/