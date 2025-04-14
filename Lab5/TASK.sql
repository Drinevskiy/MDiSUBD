ALTER SESSION SET CURRENT_SCHEMA = report_user;
ALTER SESSION SET CURRENT_SCHEMA = sys;
-- DROP DIRECTORY MY_DIR;
CREATE OR REPLACE DIRECTORY MY_DIR AS 'C:\DB';
GRANT READ ON DIRECTORY MY_DIR TO PUBLIC; 
GRANT WRITE ON DIRECTORY MY_DIR TO PUBLIC;
-- GRANT DBA TO REPORT_USER;

SELECT * FROM ALL_DIRECTORIES WHERE DIRECTORY_NAME = 'MY_DIR';

SELECT * FROM USER_TAB_PRIVS WHERE TABLE_NAME = 'MY_DIR';

EXEC fill_all_tables;

EXEC make_test_changes;
--  SET SERVEROUTPUT ON;
SELECT * FROM clients;
SELECT * FROM report_history;

-- Формирование отчета о произведенных изменениях
DECLARE
    v_report CLOB;
    v_file UTL_FILE.FILE_TYPE;
    v_buffer VARCHAR2(32767); -- Буфер для чтения CLOB
    v_amount NUMBER := 32767; -- Размер буфера
    v_pos NUMBER := 1; -- Позиция в CLOB
BEGIN
    -- Генерация отчета
    -- v_report := rollback_manager.generate_report(SYSTIMESTAMP - NUMTODSINTERVAL(150, 'SECOND'));
    v_report := rollback_manager.generate_report();
    
    -- Открытие файла для записи
    v_file := UTL_FILE.FOPEN('MY_DIR', 'report.html', 'w', 32767);
    
    -- Запись CLOB в файл по частям
    LOOP
        DBMS_LOB.READ(v_report, v_amount, v_pos, v_buffer);
        UTL_FILE.PUT(v_file, v_buffer);
        v_pos := v_pos + v_amount;
    END LOOP;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Закрытие файла после записи
        UTL_FILE.FCLOSE(v_file);
        DBMS_OUTPUT.PUT_LINE('Отчет сохранен в файл report.html');
        -- COMMIT;
END;
/

DECLARE
    v_milliseconds NUMBER := 60 * 5 * 1000; -- 1 час в миллисекундах
BEGIN
    rollback_manager.rollback_by_milliseconds(v_milliseconds);
    DBMS_OUTPUT.PUT_LINE('Изменения отменены на 1 час назад.');
END;
/

DECLARE
    v_timestamp TIMESTAMP;
BEGIN
    v_timestamp := TO_TIMESTAMP('2025-04-14 16:50:50', 'YYYY-MM-DD HH24:MI:SS');
    
    rollback_manager.rollback_to_timestamp(v_timestamp);
    DBMS_OUTPUT.PUT_LINE('Изменения отменены до ' || TO_CHAR(v_timestamp, 'DD.MM.YYYY HH24:MI:SS'));
END;
/