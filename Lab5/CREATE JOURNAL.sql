ALTER SESSION SET CURRENT_SCHEMA = report_user;
-- ALTER SESSION SET CURRENT_SCHEMA = SYS;
-- ALTER USER report_user QUOTA UNLIMITED ON USERS;

-- Последовательности для таблиц истории
DROP SEQUENCE clients_history_seq;
DROP SEQUENCE products_history_seq;
DROP SEQUENCE orders_history_seq;

CREATE SEQUENCE clients_history_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE products_history_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE orders_history_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

DROP TABLE clients_history;
DROP TABLE products_history;
DROP TABLE orders_history;

CREATE TABLE clients_history (
    history_id NUMBER PRIMARY KEY,
    operation_type VARCHAR2(10) NOT NULL, -- INSERT, UPDATE, DELETE
    operation_time TIMESTAMP DEFAULT SYSTIMESTAMP,
    client_id NUMBER,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    email VARCHAR2(100),
    birth_date DATE,
    registration_date TIMESTAMP,
    status VARCHAR2(20),
    old_first_name VARCHAR2(50),
    old_last_name VARCHAR2(50),
    old_email VARCHAR2(100),
    old_birth_date DATE,
    old_registration_date TIMESTAMP,
    old_status VARCHAR2(20)
);

CREATE TABLE products_history (
    history_id NUMBER PRIMARY KEY,
    operation_type VARCHAR2(10) NOT NULL, -- INSERT, UPDATE, DELETE
    operation_time TIMESTAMP DEFAULT SYSTIMESTAMP,
    product_id NUMBER,
    name VARCHAR2(100),
    description VARCHAR2(500),
    price NUMBER(10,2),
    stock_quantity NUMBER,
    create_date TIMESTAMP,
    category VARCHAR2(50),
    old_name VARCHAR2(100),
    old_description VARCHAR2(500),
    old_price NUMBER(10,2),
    old_stock_quantity NUMBER,
    old_create_date TIMESTAMP,
    old_category VARCHAR2(50)
);

CREATE TABLE orders_history (
    history_id NUMBER PRIMARY KEY,
    operation_type VARCHAR2(10) NOT NULL, -- INSERT, UPDATE, DELETE
    operation_time TIMESTAMP DEFAULT SYSTIMESTAMP,
    order_id NUMBER,
    client_id NUMBER,
    product_id NUMBER,
    order_date TIMESTAMP,
    quantity NUMBER,
    total_price NUMBER(10,2),
    status VARCHAR2(20),
    old_client_id NUMBER,
    old_product_id NUMBER,
    old_order_date TIMESTAMP,
    old_quantity NUMBER,
    old_total_price NUMBER(10,2),
    old_status VARCHAR2(20)
);

CREATE TABLE report_history (
    report_id NUMBER PRIMARY KEY,
    report_time TIMESTAMP DEFAULT SYSTIMESTAMP
);
DROP TABLE report_history;
DELETE FROM report_history;
DROP SEQUENCE report_history_seq;
CREATE SEQUENCE report_history_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

INSERT INTO report_history (report_id) VALUES (report_history_seq.NEXTVAL);
COMMIT;