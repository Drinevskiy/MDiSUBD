-- ALTER SESSION SET CURRENT_SCHEMA = KIRILL;

CREATE OR REPLACE PROCEDURE RESTORE_STUDENTS(
    target_time IN TIMESTAMP DEFAULT NULL,
    time_offset IN NUMBER DEFAULT NULL
) IS
    v_log_id NUMBER;
    v_student_id NUMBER;
    v_old_name VARCHAR2(128);
    v_new_name VARCHAR2(128);
    v_old_group_id NUMBER;
    v_new_group_id NUMBER;
    v_operation VARCHAR2(6);
    v_operation_timestamp TIMESTAMP;

    effective_target_time TIMESTAMP;

    CURSOR log_cursor IS
        SELECT log_id, student_id, old_name, new_name, old_group_id, new_group_id, operation, operation_timestamp
        FROM STUDENT_LOG
        WHERE operation_timestamp >= effective_target_time
        ORDER BY operation_timestamp DESC, log_id DESC;

BEGIN
    IF target_time IS NOT NULL THEN
        effective_target_time := target_time;
    ELSIF time_offset IS NOT NULL THEN
        effective_target_time := SYSTIMESTAMP - NUMTODSINTERVAL(time_offset, 'SECOND');
    ELSE
        DBMS_OUTPUT.PUT_LINE('No target_time or time_offset provided. Exiting procedure.');
        RETURN;
    END IF;

    FOR log_record IN log_cursor LOOP
        v_log_id := log_record.log_id;
        v_student_id := log_record.student_id;
        v_old_name := log_record.old_name;
        v_new_name := log_record.new_name;
        v_old_group_id := log_record.old_group_id;
        v_new_group_id := log_record.new_group_id;
        v_operation := log_record.operation;
        v_operation_timestamp := log_record.operation_timestamp;

        IF v_operation = 'INSERT' THEN
            DELETE FROM STUDENTS
            WHERE student_id = v_student_id;

        ELSIF v_operation = 'UPDATE' THEN
            UPDATE STUDENTS
            SET name = v_old_name,
                group_id = v_old_group_id
            WHERE student_id = v_student_id;

        ELSIF v_operation = 'DELETE' THEN
            INSERT INTO STUDENTS(student_id, name, group_id)
            VALUES (v_student_id, v_old_name, v_old_group_id);
        END IF;

        DBMS_OUTPUT.PUT_LINE('Reversed operation: ' || v_operation || ' for student_id: ' || v_student_id);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Restore completed to the target time: ' || TO_CHAR(effective_target_time, 'YYYY-MM-DD HH24:MI:SS'));
END;
/

SELECT * FROM STUDENTS;
SELECT * FROM STUDENT_LOG ORDER BY operation_timestamp ASC;
-- -- DELETE FROM STUDENTS WHERE STUDENT_ID = 5;
-- -- -- DBMS_OUTPUT.PUT_LINE(SYSTIMESTAMP - NUMTODSINTERVAL(time_offset, 'SECOND')
EXECUTE RESTORE_STUDENTS(target_time => TIMESTAMP '2025-02-12 12:47:55');
EXECUTE RESTORE_STUDENTS(time_offset => 120);
COMMIT;
ROLLBACK;