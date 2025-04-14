ALTER SESSION SET CURRENT_SCHEMA = report_user;

CREATE OR REPLACE TRIGGER clients_audit_trg
AFTER INSERT OR UPDATE OR DELETE ON clients
FOR EACH ROW
DECLARE
    v_operation_type VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_operation_type := 'INSERT';
    ELSIF UPDATING THEN
        v_operation_type := 'UPDATE';
    ELSIF DELETING THEN
        v_operation_type := 'DELETE';
    END IF;
    
    INSERT INTO clients_history (
        history_id,
        operation_type,
        operation_time,
        client_id,
        first_name,
        last_name,
        email,
        birth_date,
        registration_date,
        status,
        old_first_name,
        old_last_name,
        old_email,
        old_birth_date,
        old_registration_date,
        old_status
    ) VALUES (
        clients_history_seq.NEXTVAL,
        v_operation_type,
        SYSTIMESTAMP,
        CASE 
            WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.client_id
            ELSE :OLD.client_id
        END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.first_name ELSE NULL END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.last_name ELSE NULL END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.email ELSE NULL END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.birth_date ELSE NULL END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.registration_date ELSE NULL END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.status ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.first_name ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.last_name ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.email ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.birth_date ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.registration_date ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.status ELSE NULL END
    );
END;
/

CREATE OR REPLACE TRIGGER products_audit_trg
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH ROW
DECLARE
    v_operation_type VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_operation_type := 'INSERT';
    ELSIF UPDATING THEN
        v_operation_type := 'UPDATE';
    ELSIF DELETING THEN
        v_operation_type := 'DELETE';
    END IF;
    
    INSERT INTO products_history (
        history_id,
        operation_type,
        operation_time,
        product_id,
        name,
        description,
        price,
        stock_quantity,
        create_date,
        category,
        old_name,
        old_description,
        old_price,
        old_stock_quantity,
        old_create_date,
        old_category
    ) VALUES (
        products_history_seq.NEXTVAL,
        v_operation_type,
        SYSTIMESTAMP,
        CASE 
            WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.product_id
            ELSE :OLD.product_id
        END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.name ELSE NULL END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.description ELSE NULL END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.price ELSE NULL END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.stock_quantity ELSE NULL END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.create_date ELSE NULL END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.category ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.name ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.description ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.price ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.stock_quantity ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.create_date ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.category ELSE NULL END
    );
END;
/

CREATE OR REPLACE TRIGGER orders_audit_trg
AFTER INSERT OR UPDATE OR DELETE ON orders
FOR EACH ROW
DECLARE
    v_operation_type VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_operation_type := 'INSERT';
    ELSIF UPDATING THEN
        v_operation_type := 'UPDATE';
    ELSIF DELETING THEN
        v_operation_type := 'DELETE';
    END IF;
    
    INSERT INTO orders_history (
        history_id,
        operation_type,
        operation_time,
        order_id,
        client_id,
        product_id,
        order_date,
        quantity,
        total_price,
        status,
        old_client_id,
        old_product_id,
        old_order_date,
        old_quantity,
        old_total_price,
        old_status
    ) VALUES (
        orders_history_seq.NEXTVAL,
        v_operation_type,
        SYSTIMESTAMP,
        CASE 
            WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.order_id
            ELSE :OLD.order_id
        END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.client_id ELSE NULL END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.product_id ELSE NULL END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.order_date ELSE NULL END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.quantity ELSE NULL END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.total_price ELSE NULL END,
        CASE WHEN v_operation_type IN ('INSERT', 'UPDATE') THEN :NEW.status ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.client_id ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.product_id ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.order_date ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.quantity ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.total_price ELSE NULL END,
        CASE WHEN v_operation_type IN ('UPDATE', 'DELETE') THEN :OLD.status ELSE NULL END
    );
END;
/