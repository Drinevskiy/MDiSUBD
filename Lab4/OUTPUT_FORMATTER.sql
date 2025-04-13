-- ALTER SESSION SET CURRENT_SCHEMA = orm_user;
CREATE OR REPLACE PACKAGE output_formatter AS
    PROCEDURE print_cursor(p_cursor IN OUT SYS_REFCURSOR);
END output_formatter;
/

CREATE OR REPLACE PACKAGE BODY output_formatter AS
    PROCEDURE print_cursor(p_cursor IN OUT SYS_REFCURSOR) IS
        v_cursor_id  INTEGER;
        v_col_cnt    INTEGER;
        v_desc_tab   DBMS_SQL.DESC_TAB;
        v_values     DBMS_SQL.VARCHAR2_TABLE;
        v_value      VARCHAR2(4000);
    BEGIN
        v_cursor_id := DBMS_SQL.TO_CURSOR_NUMBER(p_cursor);
        
        -- Получаем метаданные
        DBMS_SQL.DESCRIBE_COLUMNS(v_cursor_id, v_col_cnt, v_desc_tab);

        -- Подготовка к чтению
        FOR i IN 1..v_col_cnt LOOP
            DBMS_SQL.DEFINE_COLUMN(v_cursor_id, i, v_value, 4000);
            DBMS_OUTPUT.PUT(RPAD(LOWER(v_desc_tab(i).col_name), 25));
        END LOOP;
        DBMS_OUTPUT.NEW_LINE();

        -- Чтение строк
        WHILE DBMS_SQL.FETCH_ROWS(v_cursor_id) > 0 LOOP
            FOR i IN 1..v_col_cnt LOOP
            DBMS_SQL.COLUMN_VALUE(v_cursor_id, i, v_value);
            
            -- Форматирование по типам данных
            CASE v_desc_tab(i).col_type
                WHEN 2 THEN -- NUMBER
                v_value := TO_CHAR(TO_NUMBER(v_value), '999999');
                WHEN 12 THEN -- DATE
                v_value := TO_CHAR(TO_DATE(v_value, 'YYYY-MM-DD'), 'DD.MM.YYYY');
                ELSE
                v_value := RPAD(NVL(v_value, 'NULL'), 25);
            END CASE;
            
            DBMS_OUTPUT.PUT(RPAD(v_value, 25));
            END LOOP;
            DBMS_OUTPUT.NEW_LINE();
        END LOOP;

        -- Закрытие курсора
        DBMS_SQL.CLOSE_CURSOR(v_cursor_id);

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
            IF DBMS_SQL.IS_OPEN(v_cursor_id) THEN
            DBMS_SQL.CLOSE_CURSOR(v_cursor_id);
            END IF;
    END print_cursor;
END output_formatter;