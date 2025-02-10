CREATE OR REPLACE PROCEDURE delete_by_id_mytable(v_id NUMBER) IS
BEGIN
    DELETE FROM MYTABLE WHERE id = v_id;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE NO_DATA_FOUND; 
    END IF;
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('id not found');
        ROLLBACK;
END;
/
CREATE OR REPLACE PROCEDURE insert_val_mytable(v_val NUMBER) IS
BEGIN
    INSERT INTO MYTABLE(val) VALUES (v_val);
    COMMIT;
END;
/
CREATE OR REPLACE PROCEDURE update_val_mytable(v_id NUMBER, v_val NUMBER) IS
BEGIN
    UPDATE MYTABLE
        SET val = v_val
    WHERE id = v_id;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE NO_DATA_FOUND; 
    END IF;
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('id not found');
        ROLLBACK;
END;
/
DECLARE
        v_val NUMBER;
BEGIN
    insert_val_mytable(21);
    
    
    BEGIN
        SELECT val INTO v_val FROM MYTABLE WHERE id = 20003;
        DBMS_OUTPUT.PUT_LINE('Value: ' || v_val);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('id 20003 not found');
    END;

    update_val_mytable(20003, 1);
    
    BEGIN
        SELECT val INTO v_val FROM MYTABLE WHERE id = 20003;
        DBMS_OUTPUT.PUT_LINE('Updated Value: ' || v_val);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('id 20003 not found after update');
    END;

    delete_by_id_mytable(20003);
    
    BEGIN
        SELECT val INTO v_val FROM MYTABLE WHERE id = 20003;
        DBMS_OUTPUT.PUT_LINE('Value after delete: ' || v_val);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('id 20003 not found after delete');
    END;
END;
/