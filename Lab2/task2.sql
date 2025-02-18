-- ALTER SESSION SET CURRENT_SCHEMA = KIRILL;


CREATE OR REPLACE TRIGGER check_unique_id_group
BEFORE INSERT ON GROUPS
FOR EACH ROW
FOLLOWS generate_autoincrement_key_group
DECLARE
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('check_unique_id_group');
    SELECT COUNT(*) INTO v_count FROM GROUPS WHERE :NEW.group_id = group_id;
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'ID must be unique');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER check_unique_id_student
BEFORE INSERT ON STUDENTS
FOR EACH ROW
FOLLOWS generate_autoincrement_key_student
DECLARE
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('check_unique_id_student');
    SELECT COUNT(*) INTO v_count FROM STUDENTS WHERE :NEW.student_id = student_id;
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'ID must be unique');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER generate_autoincrement_key_group
BEFORE INSERT ON GROUPS
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('generate_autoincrement_key_group');
    IF :NEW.group_id IS NULL THEN
       SELECT NVL(MAX(group_id), 0) + 1 INTO :NEW.group_id FROM GROUPS;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER generate_autoincrement_key_student
BEFORE INSERT ON STUDENTS
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('generate_autoincrement_key_student');
    IF :NEW.student_id IS NULL THEN
        SELECT NVL(MAX(student_id), 0) + 1 INTO :NEW.student_id FROM STUDENTS;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER check_group_unique_name
BEFORE INSERT ON GROUPS
FOR EACH ROW
FOLLOWS check_unique_id_group
DECLARE
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('check_group_unique_name');
    SELECT COUNT(*) INTO v_count FROM GROUPS WHERE name = :NEW.name;
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Group name must be unique.');
    END IF;
END;
/
INSERT INTO GROUPS(name, c_val) VALUES('253502', 0);
INSERT INTO GROUPS(name, c_val) VALUES('253505', 0);

INSERT INTO STUDENTS(name, group_id) VALUES('Drinevskiy', 1);
INSERT INTO STUDENTS(name, group_id) VALUES('Schcurka ma', 2);
INSERT INTO STUDENTS(name, group_id) VALUES('Schcua', 2);
INSERT INTO STUDENTS(name, group_id) VALUES('Sniazhko', 1);

UPDATE STUDENTS 
    SET group_id = 2
    WHERE name = 'Drinevskiy';
SELECT * FROM GROUPS;
SELECT * FROM STUDENTS;
COMMIT;
ROLLBACK;
