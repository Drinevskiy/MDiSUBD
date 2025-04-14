ALTER SESSION SET CURRENT_SCHEMA = report_user;

-- Последовательности для основных таблиц


CREATE OR REPLACE PROCEDURE fill_clients_table IS
BEGIN
    DELETE FROM clients;
    
    INSERT INTO clients (client_id, first_name, last_name, email, birth_date, registration_date, status)
    VALUES (clients_seq.NEXTVAL, 'Иван', 'Иванов', 'ivanov@example.com', TO_DATE('1980-05-15', 'YYYY-MM-DD'), SYSTIMESTAMP, 'ACTIVE');
    
    INSERT INTO clients (client_id, first_name, last_name, email, birth_date, registration_date, status)
    VALUES (clients_seq.NEXTVAL, 'Петр', 'Петров', 'petrov@example.com', TO_DATE('1985-07-22', 'YYYY-MM-DD'), SYSTIMESTAMP, 'ACTIVE');
    
    INSERT INTO clients (client_id, first_name, last_name, email, birth_date, registration_date, status)
    VALUES (clients_seq.NEXTVAL, 'Анна', 'Сидорова', 'sidorova@example.com', TO_DATE('1990-03-10', 'YYYY-MM-DD'), SYSTIMESTAMP, 'ACTIVE');
    
    INSERT INTO clients (client_id, first_name, last_name, email, birth_date, registration_date, status)
    VALUES (clients_seq.NEXTVAL, 'Елена', 'Козлова', 'kozlova@example.com', TO_DATE('1975-11-30', 'YYYY-MM-DD'), SYSTIMESTAMP, 'INACTIVE');
    
    INSERT INTO clients (client_id, first_name, last_name, email, birth_date, registration_date, status)
    VALUES (clients_seq.NEXTVAL, 'Алексей', 'Смирнов', 'smirnov@example.com', TO_DATE('1988-09-25', 'YYYY-MM-DD'), SYSTIMESTAMP, 'ACTIVE');
    
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE fill_products_table IS
BEGIN
    DELETE FROM products;
    
    INSERT INTO products (product_id, name, description, price, stock_quantity, create_date, category)
    VALUES (products_seq.NEXTVAL, 'Ноутбук', 'Мощный ноутбук для работы и игр', 75000.00, 20, SYSTIMESTAMP, 'Электроника');
    
    INSERT INTO products (product_id, name, description, price, stock_quantity, create_date, category)
    VALUES (products_seq.NEXTVAL, 'Смартфон', 'Современный смартфон с большим экраном', 45000.00, 50, SYSTIMESTAMP, 'Электроника');
    
    INSERT INTO products (product_id, name, description, price, stock_quantity, create_date, category)
    VALUES (products_seq.NEXTVAL, 'Кофемашина', 'Автоматическая кофемашина для дома', 25000.00, 15, SYSTIMESTAMP, 'Бытовая техника');
    
    INSERT INTO products (product_id, name, description, price, stock_quantity, create_date, category)
    VALUES (products_seq.NEXTVAL, 'Книга', 'Бестселлер современной литературы', 800.00, 100, SYSTIMESTAMP, 'Книги');
    
    INSERT INTO products (product_id, name, description, price, stock_quantity, create_date, category)
    VALUES (products_seq.NEXTVAL, 'Кроссовки', 'Спортивные кроссовки для бега', 6500.00, 30, SYSTIMESTAMP, 'Одежда и обувь');
    
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE fill_orders_table IS
BEGIN
    DELETE FROM orders;
    
    INSERT INTO orders (order_id, client_id, product_id, order_date, quantity, total_price, status)
    VALUES (orders_seq.NEXTVAL, 1, 1, SYSTIMESTAMP, 1, 75000.00, 'NEW');
    
    INSERT INTO orders (order_id, client_id, product_id, order_date, quantity, total_price, status)
    VALUES (orders_seq.NEXTVAL, 2, 3, SYSTIMESTAMP, 1, 25000.00, 'PROCESSING');
    
    INSERT INTO orders (order_id, client_id, product_id, order_date, quantity, total_price, status)
    VALUES (orders_seq.NEXTVAL, 3, 4, SYSTIMESTAMP, 2, 1600.00, 'COMPLETED');
    
    INSERT INTO orders (order_id, client_id, product_id, order_date, quantity, total_price, status)
    VALUES (orders_seq.NEXTVAL, 1, 2, SYSTIMESTAMP, 1, 45000.00, 'NEW');
    
    INSERT INTO orders (order_id, client_id, product_id, order_date, quantity, total_price, status)
    VALUES (orders_seq.NEXTVAL, 5, 5, SYSTIMESTAMP, 1, 6500.00, 'PROCESSING');
    
    COMMIT;
END;
/
CREATE OR REPLACE PROCEDURE reset_table_seq IS
BEGIN
    EXECUTE IMMEDIATE 'ALTER SEQUENCE clients_seq RESTART START WITH 1';
    EXECUTE IMMEDIATE 'ALTER SEQUENCE products_seq RESTART START WITH 1';
    EXECUTE IMMEDIATE 'ALTER SEQUENCE orders_seq RESTART START WITH 1';
    -- -- Удаление последовательностей (если существуют)
    -- BEGIN
    --     EXECUTE IMMEDIATE 'DROP SEQUENCE clients_seq';
    -- EXCEPTION
    --     WHEN OTHERS THEN
    --         IF SQLCODE != -2289 THEN -- Игнорировать ошибку "sequence does not exist"
    --             RAISE;
    --         END IF;
    -- END;

    -- BEGIN
    --     EXECUTE IMMEDIATE 'DROP SEQUENCE products_seq';
    -- EXCEPTION
    --     WHEN OTHERS THEN
    --         IF SQLCODE != -2289 THEN
    --             RAISE;
    --         END IF;
    -- END;

    -- BEGIN
    --     EXECUTE IMMEDIATE 'DROP SEQUENCE orders_seq';
    -- EXCEPTION
    --     WHEN OTHERS THEN
    --         IF SQLCODE != -2289 THEN
    --             RAISE;
    --         END IF;
    -- END;

    -- -- Создание последовательностей с явными параметрами
    -- EXECUTE IMMEDIATE 'CREATE SEQUENCE clients_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
    -- EXECUTE IMMEDIATE 'CREATE SEQUENCE products_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
    -- EXECUTE IMMEDIATE 'CREATE SEQUENCE orders_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE';
    
    -- DBMS_OUTPUT.PUT_LINE('Последовательности пересозданы');
END;
/

CREATE OR REPLACE PROCEDURE fill_all_tables IS
BEGIN
    reset_table_seq;
    fill_clients_table;
    fill_products_table;
    fill_orders_table;
END;
/

CREATE OR REPLACE PROCEDURE make_test_changes IS
BEGIN
    -- Изменение в таблице КЛИЕНТЫ
    UPDATE clients SET status = 'VIP' WHERE client_id = 1;
    DELETE FROM clients WHERE client_id = 4;
    INSERT INTO clients (client_id, first_name, last_name, email, birth_date, registration_date, status)
    VALUES (clients_seq.NEXTVAL, 'Дмитрий', 'Новиков', 'novikov@example.com', TO_DATE('1992-02-18', 'YYYY-MM-DD'), SYSTIMESTAMP, 'ACTIVE');
    
    -- Изменение в таблице ТОВАРЫ
    UPDATE products SET price = price * 1.1 WHERE category = 'Электроника';
    -- DELETE FROM orders WHERE product_id = 5;
    DELETE FROM products WHERE product_id = 5;
    INSERT INTO products (product_id, name, description, price, stock_quantity, create_date, category)
    VALUES (products_seq.NEXTVAL, 'Планшет', 'Планшет для работы и учебы', 35000.00, 25, SYSTIMESTAMP, 'Электроника');
    
    -- Изменение в таблице ЗАКАЗЫ
    UPDATE orders SET status = 'COMPLETED' WHERE status = 'PROCESSING';
    DELETE FROM orders WHERE order_id = 3;
    INSERT INTO orders (order_id, client_id, product_id, order_date, quantity, total_price, status)
    VALUES (orders_seq.NEXTVAL, 3, 2, SYSTIMESTAMP, 1, 45000.00, 'NEW');
    
    COMMIT;
END;
/