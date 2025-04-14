ALTER SESSION SET CURRENT_SCHEMA = report_user;

CREATE OR REPLACE PACKAGE rollback_manager AS
    PROCEDURE rollback_to_timestamp(p_timestamp IN TIMESTAMP);
    
    PROCEDURE rollback_by_milliseconds(p_milliseconds IN NUMBER);
    
    FUNCTION generate_report(p_start_timestamp IN TIMESTAMP DEFAULT NULL) RETURN CLOB;
END rollback_manager;
/

CREATE OR REPLACE PACKAGE BODY rollback_manager AS
    -- Вспомогательная процедура для выполнения отката по времени
    PROCEDURE do_rollback(p_timestamp IN TIMESTAMP) IS
        -- Переменные для хранения информации о записях для восстановления
        CURSOR cur_clients_history IS
            SELECT * FROM (
                SELECT h.*, 
                       ROW_NUMBER() OVER (PARTITION BY client_id ORDER BY operation_time DESC) as rn
                FROM clients_history h
                WHERE operation_time > p_timestamp
            ) WHERE rn = 1;
            
        CURSOR cur_products_history IS
            SELECT * FROM (
                SELECT h.*, 
                       ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY operation_time DESC) as rn
                FROM products_history h
                WHERE operation_time > p_timestamp
            ) WHERE rn = 1;
            
        CURSOR cur_orders_history IS
            SELECT * FROM (
                SELECT h.*, 
                       ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY operation_time DESC) as rn
                FROM orders_history h
                WHERE operation_time > p_timestamp
            ) WHERE rn = 1;

    BEGIN
        -- Пример отключения триггеров
        EXECUTE IMMEDIATE 'ALTER TRIGGER clients_audit_trg DISABLE';
        EXECUTE IMMEDIATE 'ALTER TRIGGER products_audit_trg DISABLE';
        EXECUTE IMMEDIATE 'ALTER TRIGGER orders_audit_trg DISABLE';
        EXECUTE IMMEDIATE 'ALTER TABLE orders DISABLE CONSTRAINT fk_product';
        EXECUTE IMMEDIATE 'ALTER TABLE orders DISABLE CONSTRAINT fk_client';
        -- Откатываем изменения в таблице заказов (они содержат внешние ключи, поэтому сначала их)
        

        -- Откатываем изменения в таблице товаров
        FOR rec IN cur_products_history LOOP
            CASE rec.operation_type
                WHEN 'INSERT' THEN
                    -- Если была вставка после указанного времени, удаляем запись
                    DELETE FROM products WHERE product_id = rec.product_id;
                WHEN 'UPDATE' THEN
                    -- Если было обновление, возвращаем предыдущие значения
                    UPDATE products
                    SET name = rec.old_name,
                        description = rec.old_description,
                        price = rec.old_price,
                        stock_quantity = rec.old_stock_quantity,
                        create_date = rec.old_create_date,
                        category = rec.old_category
                    WHERE product_id = rec.product_id;
                WHEN 'DELETE' THEN
                    -- Если была удалена запись, восстанавливаем ее
                    INSERT INTO products (
                        product_id,
                        name,
                        description,
                        price,
                        stock_quantity,
                        create_date,
                        category
                    ) VALUES (
                        rec.product_id,
                        rec.old_name,
                        rec.old_description,
                        rec.old_price,
                        rec.old_stock_quantity,
                        rec.old_create_date,
                        rec.old_category
                    );
            END CASE;
        END LOOP;

        -- Откатываем изменения в таблице клиентов
        FOR rec IN cur_clients_history LOOP
            CASE rec.operation_type
                WHEN 'INSERT' THEN
                    -- Если была вставка после указанного времени, удаляем запись
                    DELETE FROM clients WHERE client_id = rec.client_id;
                WHEN 'UPDATE' THEN
                    -- Если было обновление, возвращаем предыдущие значения
                    UPDATE clients
                    SET first_name = rec.old_first_name,
                        last_name = rec.old_last_name,
                        email = rec.old_email,
                        birth_date = rec.old_birth_date,
                        registration_date = rec.old_registration_date,
                        status = rec.old_status
                    WHERE client_id = rec.client_id;
                WHEN 'DELETE' THEN
                    -- Если была удалена запись, восстанавливаем ее
                    INSERT INTO clients (
                        client_id,
                        first_name,
                        last_name,
                        email,
                        birth_date,
                        registration_date,
                        status
                    ) VALUES (
                        rec.client_id,
                        rec.old_first_name,
                        rec.old_last_name,
                        rec.old_email,
                        rec.old_birth_date,
                        rec.old_registration_date,
                        rec.old_status
                    );
            END CASE;
        END LOOP;

        FOR rec IN cur_orders_history LOOP
            CASE rec.operation_type
                WHEN 'INSERT' THEN
                    -- Если была вставка после указанного времени, удаляем запись
                    DELETE FROM orders WHERE order_id = rec.order_id;
                WHEN 'UPDATE' THEN
                    -- Если было обновление, возвращаем предыдущие значения
                    UPDATE orders
                    SET client_id = rec.old_client_id,
                        product_id = rec.old_product_id,
                        order_date = rec.old_order_date,
                        quantity = rec.old_quantity,
                        total_price = rec.old_total_price,
                        status = rec.old_status
                    WHERE order_id = rec.order_id;
                WHEN 'DELETE' THEN
                    -- Если была удалена запись, восстанавливаем ее
                    INSERT INTO orders (
                        order_id,
                        client_id,
                        product_id,
                        order_date,
                        quantity,
                        total_price,
                        status
                    ) VALUES (
                        rec.order_id,
                        rec.old_client_id,
                        rec.old_product_id,
                        rec.old_order_date,
                        rec.old_quantity,
                        rec.old_total_price,
                        rec.old_status
                    );
            END CASE;
        END LOOP;
        
        EXECUTE IMMEDIATE 'ALTER TRIGGER clients_audit_trg ENABLE';
        EXECUTE IMMEDIATE 'ALTER TRIGGER products_audit_trg ENABLE';
        EXECUTE IMMEDIATE 'ALTER TRIGGER orders_audit_trg ENABLE';
        EXECUTE IMMEDIATE 'ALTER TABLE orders ENABLE NOVALIDATE CONSTRAINT fk_product';
        EXECUTE IMMEDIATE 'ALTER TABLE orders ENABLE NOVALIDATE CONSTRAINT fk_client';
        -- Удаляем записи из журналов истории изменений, которые произошли после указанного времени
        DELETE FROM orders_history WHERE operation_time > p_timestamp;
        DELETE FROM products_history WHERE operation_time > p_timestamp;
        DELETE FROM clients_history WHERE operation_time > p_timestamp;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END do_rollback;

    -- Процедура для отката изменений по дате-времени
    PROCEDURE rollback_to_timestamp(p_timestamp IN TIMESTAMP) IS
    BEGIN
        do_rollback(p_timestamp);
    END rollback_to_timestamp;
    
    -- Процедура для отката изменений на указанное количество миллисекунд назад
    PROCEDURE rollback_by_milliseconds(p_milliseconds IN NUMBER) IS
        v_timestamp TIMESTAMP;
    BEGIN
        SELECT SYSTIMESTAMP - NUMTODSINTERVAL(p_milliseconds / 1000, 'SECOND') INTO v_timestamp FROM DUAL;
        do_rollback(v_timestamp);
    END rollback_by_milliseconds;
    
    -- Процедура для формирования отчета об изменениях
    FUNCTION generate_report(p_start_timestamp IN TIMESTAMP DEFAULT NULL) RETURN CLOB IS
        v_start_timestamp TIMESTAMP;
        v_report CLOB;
        
        v_clients_insert NUMBER := 0;
        v_clients_update NUMBER := 0;
        v_clients_delete NUMBER := 0;
        
        v_products_insert NUMBER := 0;
        v_products_update NUMBER := 0;
        v_products_delete NUMBER := 0;
        
        v_orders_insert NUMBER := 0;
        v_orders_update NUMBER := 0;
        v_orders_delete NUMBER := 0;
    BEGIN
        -- Если время начала отчета не указано, берем время последнего отчета
        IF p_start_timestamp IS NULL THEN
            SELECT report_time INTO v_start_timestamp FROM report_history ORDER BY report_time DESC FETCH NEXT 1 ROWS ONLY;
            -- WHERE report_id = (SELECT report_id FROM report_history WHERE report);
        ELSE
            v_start_timestamp := p_start_timestamp;
        END IF;
        
        SELECT COUNT(*) INTO v_clients_insert
        FROM clients_history
        WHERE operation_type = 'INSERT'
        AND operation_time > v_start_timestamp;
        
        SELECT COUNT(*) INTO v_clients_update
        FROM clients_history
        WHERE operation_type = 'UPDATE'
        AND operation_time > v_start_timestamp;
        
        SELECT COUNT(*) INTO v_clients_delete
        FROM clients_history
        WHERE operation_type = 'DELETE'
        AND operation_time > v_start_timestamp;
        
        SELECT COUNT(*) INTO v_products_insert
        FROM products_history
        WHERE operation_type = 'INSERT'
        AND operation_time > v_start_timestamp;
        
        SELECT COUNT(*) INTO v_products_update
        FROM products_history
        WHERE operation_type = 'UPDATE'
        AND operation_time > v_start_timestamp;
        
        SELECT COUNT(*) INTO v_products_delete
        FROM products_history
        WHERE operation_type = 'DELETE'
        AND operation_time > v_start_timestamp;
        
        SELECT COUNT(*) INTO v_orders_insert
        FROM orders_history
        WHERE operation_type = 'INSERT'
        AND operation_time > v_start_timestamp;
        
        SELECT COUNT(*) INTO v_orders_update
        FROM orders_history
        WHERE operation_type = 'UPDATE'
        AND operation_time > v_start_timestamp;
        
        SELECT COUNT(*) INTO v_orders_delete
        FROM orders_history
        WHERE operation_type = 'DELETE'
        AND operation_time > v_start_timestamp;
        
        v_report := '<!DOCTYPE html>
<html>
<head>
    <title>Отчет об изменениях в базе данных</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
        }
        h1 {
            color: #333;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-top: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
    </style>
</head>
<body>
    <h1>Отчет об изменениях в базе данных</h1>
    <p>Период: с ' || TO_CHAR(v_start_timestamp, 'DD.MM.YYYY HH24:MI:SS.FF') || ' по ' || TO_CHAR(SYSTIMESTAMP, 'DD.MM.YYYY HH24:MI:SS.FF') || '</p>
    
    <table>
        <tr>
            <th>Таблица</th>
            <th>INSERT</th>
            <th>UPDATE</th>
            <th>DELETE</th>
            <th>Всего</th>
        </tr>
        <tr>
            <td>CLIENTS</td>
            <td>' || v_clients_insert || '</td>
            <td>' || v_clients_update || '</td>
            <td>' || v_clients_delete || '</td>
            <td>' || (v_clients_insert + v_clients_update + v_clients_delete) || '</td>
        </tr>
        <tr>
            <td>PRODUCTS</td>
            <td>' || v_products_insert || '</td>
            <td>' || v_products_update || '</td>
            <td>' || v_products_delete || '</td>
            <td>' || (v_products_insert + v_products_update + v_products_delete) || '</td>
        </tr>
        <tr>
            <td>ORDERS</td>
            <td>' || v_orders_insert || '</td>
            <td>' || v_orders_update || '</td>
            <td>' || v_orders_delete || '</td>
            <td>' || (v_orders_insert + v_orders_update + v_orders_delete) || '</td>
        </tr>
        <tr>
            <td><strong>Всего</strong></td>
            <td>' || (v_clients_insert + v_products_insert + v_orders_insert) || '</td>
            <td>' || (v_clients_update + v_products_update + v_orders_update) || '</td>
            <td>' || (v_clients_delete + v_products_delete + v_orders_delete) || '</td>
            <td>' || (v_clients_insert + v_clients_update + v_clients_delete + 
                       v_products_insert + v_products_update + v_products_delete + 
                       v_orders_insert + v_orders_update + v_orders_delete) || '</td>
        </tr>
    </table>
</body>
</html>';

        INSERT INTO report_history (report_id) 
        VALUES (report_history_seq.NEXTVAL);
        
        RETURN v_report;
    END generate_report;
END rollback_manager;
/