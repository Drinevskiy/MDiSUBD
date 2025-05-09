-- ALTER SESSION SET CURRENT_SCHEMA = KIRILL;

-- CREATE TABLE STUDENT_LOG(
--     log_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
--     student_id NUMBER,
--     old_name VARCHAR(128) DEFAULT '',
--     new_name VARCHAR(128) DEFAULT '',
--     old_group_id NUMBER DEFAULT 0,
--     new_group_id NUMBER DEFAULT 0,
--     operation VARCHAR2(6),
--     operation_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );
-- DROP TABLE STUDENT_LOG;
-- DROP TRIGGER log_students_audit;
CREATE OR REPLACE TRIGGER log_students_audit
AFTER INSERT OR UPDATE OR DELETE ON STUDENTS
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO STUDENT_LOG(student_id, new_name, new_group_id, operation)
        VALUES (:NEW.student_id, :NEW.name, :NEW.group_id, 'INSERT');
    ELSIF UPDATING THEN
        INSERT INTO STUDENT_LOG(student_id, old_name, new_name, old_group_id, new_group_id, operation)
        VALUES (:NEW.student_id, :OLD.name, :NEW.name, :OLD.group_id, :NEW.group_id, 'UPDATE');
    ELSIF DELETING THEN
        INSERT INTO STUDENT_LOG(student_id, old_name, old_group_id, operation)
        VALUES (:OLD.student_id, :OLD.name, :OLD.group_id, 'DELETE');
    END IF;
END;
/
-- INSERT INTO GROUPS(name, c_val) VALUES('253505', 17);
-- INSERT INTO STUDENTS(name, group_id) VALUES('Sniazhko', 2);
-- INSERT INTO STUDENTS(name, group_id) VALUES('Sniazhko', 2);
-- UPDATE STUDENTS SET name = 'Snia' WHERE name = 'Sniazhko';
UPDATE STUDENTS SET name = 'Marat' WHERE name = 'Schcur';
-- UPDATE STUDENTS SET name = 'Kirill' WHERE name = 'Drinevskiy';
DELETE FROM STUDENTS WHERE name = 'Drinevskiy';
-- -- DELETE FROM STUDENT_LOG;
SELECT * FROM STUDENT_LOG ORDER BY operation_timestamp ASC;
SELECT * FROM STUDENTS;
SELECT * FROM GROUPS;



COMMIT;
