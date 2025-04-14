-- CREATE USER report_user IDENTIFIED BY 1234;
-- GRANT CONNECT, RESOURCE, CREATE TRIGGER TO report_user;
-- GRANT CREATE TABLE TO report_user;
-- GRANT CREATE SEQUENCE TO report_user;
-- GRANT CREATE TRIGGER TO report_user;
-- ALTER SESSION SET CURRENT_SCHEMA = report_user;
DROP TABLE orders;
DROP TABLE clients;
DROP TABLE products;
CREATE TABLE clients (
    client_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE,
    birth_date DATE,
    registration_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    status VARCHAR2(20) DEFAULT 'ACTIVE'
);

CREATE TABLE products (
    product_id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    description VARCHAR2(500),
    price NUMBER(10,2) NOT NULL,
    stock_quantity NUMBER DEFAULT 0,
    create_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    category VARCHAR2(50)
);

CREATE TABLE orders (
    order_id NUMBER PRIMARY KEY,
    client_id NUMBER NOT NULL,
    product_id NUMBER NOT NULL,
    order_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    quantity NUMBER NOT NULL,
    total_price NUMBER(10,2),
    status VARCHAR2(20) DEFAULT 'NEW',
    CONSTRAINT fk_client FOREIGN KEY (client_id) REFERENCES clients(client_id) ON DELETE CASCADE,
    CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);