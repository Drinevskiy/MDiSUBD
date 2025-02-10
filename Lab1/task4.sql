CREATE OR REPLACE FUNCTION generate_insert_query(v_id NUMBER) RETURN CHAR IS
    v_val NUMBER;
BEGIN
    SELECT val INTO v_val FROM MYTABLE WHERE id = v_id;
    RETURN 'INSERT INTO MYTABLE(val) VALUES (' || v_val || '); ';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'id not found';
END;
/
SELECT generate_insert_query(10214) FROM dual;