create or replace procedure cmp_func(prod in varchar2, dev in varchar2)
authid current_user
as
    v_count number;
    prod_name varchar2(100) :=upper(prod);
    dev_name varchar2(100) :=upper(dev);
    v_script varchar2(4000);
begin
    -- Если есть в dev, но нет в prod функции
    for funcs in (select distinct name 
    from all_source where owner = UPPER(dev_name) and type = 'FUNCTION'
    minus select distinct name from all_source where owner = UPPER(prod_name) and type = 'FUNCTION')
    loop
        dbms_output.put_line('No dev #' || funcs.name || '# function in prod schema');
    end loop;
    
    -- Если есть в dev, но нет в prod функции, то генерирует ddl для вставки
    for dev_func in (select object_name, dbms_metadata.get_ddl('FUNCTION', object_name, dev_name) as func_text 
    from all_objects where object_type = 'FUNCTION' and owner = dev_name)
    loop
        v_count := 0;
        select count(*) into v_count
        from all_objects
        where object_type = 'FUNCTION' and object_name = dev_func.object_name and owner = prod_name;
        if v_count = 0 then
            v_script := dev_func.func_text;
            v_script := replace(v_script, dev_name, prod_name);
            dbms_output.put_line(v_script);
        end if;
    end loop;
    
    -- Если есть в prod но нет в dev, то удаление
    for prod_func in (select object_name from all_objects where object_type = 'FUNCTION' and owner = prod_name) loop
        v_count := 0;
        select count(*) into v_count
        from all_objects
        where object_type = 'FUNCTION' and object_name = prod_func.object_name and owner = dev_name;
        if v_count = 0 then
            dbms_output.put_line('drop function ' || prod || '.' || prod_func.object_name);
            -- execute IMMEDIATE 'drop function ' || prod || '.' || prod_func.object_name;
        end if;
    end loop;
    
end;
/

create or replace procedure cmp_indx(prod in varchar2, dev in varchar2)
authid current_user
as
    v_count number;
    prod_name varchar2(100) :=upper(prod);
    dev_name varchar2(100) :=upper(dev);
    v_script varchar2(4000);
begin

    for indxs in (select distinct INDEX_NAME from ALL_INDEXES  where TABLE_OWNER = UPPER(dev_name) and INDEX_NAME not like 'SYS%'
                        minus select distinct INDEX_NAME from ALL_INDEXES where TABLE_OWNER = UPPER(prod_name) and INDEX_NAME not like 'SYS%')
    loop
        dbms_output.put_line('No dev #' || indxs.INDEX_NAME || '# index in prod schema');
    end loop;
    
    for dev_indx in (select object_name, dbms_metadata.get_ddl('INDEX', object_name, dev_name) as index_text from all_objects where object_type = 'INDEX' and OWNER = dev_name  and object_name not like 'SYS%')
    loop
        v_count := 0;
        select count(*) into v_count
        from all_objects
        where object_type = 'INDEX' and object_name = dev_indx.object_name and OWNER = prod_name;
        if v_count = 0 then
            v_script := dev_indx.index_text;
            v_script := replace(v_script, dev_name, prod_name);
            dbms_output.put_line(v_script);
        end if;
    end loop;
    
    for prod_indx in (select object_name from all_objects where object_type = 'INDEX' and owner = prod_name and object_name not like 'SYS%' and object_name not like '%_PK') loop
        v_count := 0;
        select count(*) into v_count
        from all_objects
        where object_type = 'INDEX' and object_name = prod_indx.object_name and owner = dev_name and object_name not like 'SYS%' and object_name not like '%_PK';
        if v_count = 0 then
            dbms_output.put_line('drop index ' || prod_indx.object_name);
            --execute IMMEDIATE 'drop index ' || prod || '.' || prod_indx.object_name;
        end if;
    end loop;
end;    

/

create or replace procedure cmp_prc (prod in varchar2, dev in varchar2)
authid current_user
as
    v_count number;
    prod_name varchar2(100) :=upper(prod);
    dev_name varchar2(100) :=upper(dev);
    v_script varchar2(4000);
    v_prod_arg_count number;
begin
  for proc in (select object_name
               from all_procedures 
               where owner = dev_name and OBJECT_TYPE='PROCEDURE'
               minus
               select object_name
               from all_procedures
               where owner = prod_name and OBJECT_TYPE='PROCEDURE')
  loop
    dbms_output.put_line('No dev #' || proc.object_name || '# procedure in prod schema');
  end loop;

    -- create in prod from dev
    for dev_proc in (select object_name, dbms_metadata.get_ddl('PROCEDURE', object_name, dev_name) as proc_text 
    from all_objects 
    where object_type = 'PROCEDURE' and owner = dev_name)
    loop
        v_count := 0;
        select count(*) into v_count from all_objects where object_type = 'PROCEDURE' and object_name = dev_proc.object_name and owner = prod_name;
        if v_count = 0 then
            v_script := dev_proc.proc_text;
            v_script := replace(v_script, dev_name, prod_name);
            dbms_output.put_line(v_script);
        end if;
    end loop;

    -- delete prod if not in dev
    for prod_proc in (select object_name from all_objects where object_type = 'PROCEDURE' and owner = prod_name) loop
        v_count := 0;
        select count(*) into v_count from all_objects where object_type = 'PROCEDURE' and object_name = prod_proc.object_name and owner = dev_name;
        if v_count = 0 then
            dbms_output.put_line('drop procedure ' || prod_name || '.' || prod_proc.object_name);
        end if;
    end loop;
    
    -- check arg if both create
    for dev_proc in (select object_name, dbms_metadata.get_ddl('PROCEDURE', object_name, dev_name) as proc_text from all_objects where object_type = 'PROCEDURE' and owner = dev_name)
    loop
        v_count := 0;
        select count(*) into v_count from all_objects where object_type = 'PROCEDURE' and object_name = dev_proc.object_name and owner = prod_name;
        if v_count > 0 then
            for tmp in (SELECT argument_name, position, data_type, in_out
                FROM all_arguments
                WHERE owner = dev_name
                AND object_name = dev_proc.object_name) loop
        
                select count(*) into v_prod_arg_count from all_arguments
                                                            WHERE owner = prod_name
                                                            AND object_name = dev_proc.object_name
                                                            and argument_name = tmp.argument_name
                                                            and position = tmp.position
                                                            and data_type = tmp.data_type
                                                            and in_out = tmp.in_out;
                if v_prod_arg_count = 0 then
                    dbms_output.put_line('incorrect dev proc #' || dev_proc.object_name || '# declaration in ' || prod_name || 'schema');
                    dbms_output.put_line('drop procedure ' || prod_name || '.' || dev_proc.object_name);
                    v_script := dev_proc.proc_text;
                    v_script := replace(v_script, dev_name, prod_name);
                    dbms_output.put_line(v_script);
                end if;
              end loop;
        end if;
    end loop;
end;

/

create or replace procedure cmp_pkg(prod in varchar2, dev in varchar2)
authid current_user
as
    v_count number;
    prod_name varchar2(100) := upper(prod);
    dev_name varchar2(100) := upper(dev);
    v_script varchar2(4000);
begin
    -- Найти пакеты, которые есть в dev, но отсутствуют в prod
    for pkg in (select object_name
                from all_objects
                where owner = dev_name and object_type = 'PACKAGE'
                minus
                select object_name
                from all_objects
                where owner = prod_name and object_type = 'PACKAGE')
    loop
        dbms_output.put_line('No dev #' || pkg.object_name || '# package in prod schema');
    end loop;

    -- Генерировать DDL для пакетов, которых нет в prod
    for dev_pkg in (select object_name, dbms_metadata.get_ddl('PACKAGE', object_name, dev_name) as pkg_text
                    from all_objects
                    where object_type = 'PACKAGE' and owner = dev_name)
    loop
        v_count := 0;
        select count(*) into v_count 
        from all_objects
        where object_type = 'PACKAGE' and object_name = dev_pkg.object_name and owner = prod_name;
        
        if v_count = 0 then
            v_script := dev_pkg.pkg_text;
            v_script := replace(v_script, dev_name, prod_name);
            dbms_output.put_line(v_script);
        end if;
    end loop;

    -- Найти пакеты, которые есть в prod, но отсутствуют в dev (удалить)
    for prod_pkg in (select object_name
                     from all_objects
                     where object_type = 'PACKAGE' and owner = prod_name)
    loop
        v_count := 0;
        select count(*) into v_count 
        from all_objects
        where object_type = 'PACKAGE' and object_name = prod_pkg.object_name and owner = dev_name;
        
        if v_count = 0 then
            dbms_output.put_line('drop package ' || prod_name || '.' || prod_pkg.object_name);
        end if;
    end loop;

    end;
    
/

create or replace procedure cmp_tbl (prod in varchar2, dev in varchar2
) authid current_user is
    v_dev_table_name all_tables.table_name%type;
    v_table_count integer;
    v_dev_col_count integer;
    v_prod_col_count integer;
    v_script varchar2(4000);
    v_count_circular number;
    v_missing_cols_in_prod_count number;
    prod_name varchar2(100) := upper(prod);
    dev_name varchar2(100) := upper(dev);
    v_sql varchar2(4000);
    v_fk_cons_name varchar2(30);
    v_table_name varchar2(30);
    v_column_name varchar2(30);
    ddl_script varchar2(10000);
    TYPE string_list_t IS
        TABLE OF VARCHAR2(100);
    dev_constraints_set  string_list_t;
        prod_constraints_set string_list_t;

    type table_list_type is table of varchar2(100);
    v_table_list table_list_type := table_list_type();
    v_processed_tables table_list_type := table_list_type();
    cur_dev_table_name varchar2(100);
    
    cursor cur_fk_cons is
        select distinct cons.constraint_name, cols.table_name, cols.column_name
        from all_constraints cons
        join all_cons_columns cols on cons.owner = cols.owner and cons.table_name = cols.table_name and cons.constraint_name = cols.constraint_name
        where cons.constraint_type = 'R' and cols.owner = dev_name;
        
    cursor cur_pk_cons is
        select distinct cons.constraint_name, cols.table_name, cols.column_name
        from all_constraints cons
        join all_cons_columns cols on cons.owner = cols.owner and cons.table_name = cols.table_name and cons.constraint_name = cols.constraint_name
        where cons.constraint_type = 'P' and cols.owner = dev_name;

    procedure process_table(
        p_table_name in varchar2
    ) is
        cursor fk_cur is 
            select cc.table_name as child_table
            from all_constraints pc
            join all_constraints cc on pc.constraint_name = cc.r_constraint_name
            where pc.constraint_type = 'P'
            and cc.constraint_type = 'R'
            and pc.owner = dev_name
            and cc.owner = dev_name
            and pc.table_name = p_table_name;
        v_child_table varchar2(100);
    begin
        if p_table_name not member of v_processed_tables then
        v_processed_tables.extend;
        v_processed_tables(v_processed_tables.last) := p_table_name;
        -- Обрабатываем все дочерние таблицы (таблицы, которые зависят от текущей через Foreign Key)
        for fk_rec in fk_cur loop
            v_child_table := fk_rec.child_table;
            process_table(v_child_table);
        end loop;

        v_table_list.extend;
        v_table_list(v_table_list.last) := p_table_name;
        end if;
    end process_table;

begin

    -- find circular
    select count(*) into v_count_circular from (
        with table_hierarchy as (
            select child_owner, child_table, parent_owner, parent_table
            from (
                select owner child_owner, table_name child_table, r_owner parent_owner, r_constraint_name constraint_name
                from all_constraints
                where constraint_type = 'R' and owner = dev_name
            ) join (
                select owner parent_owner, constraint_name, table_name parent_table
                from all_constraints
                where constraint_type = 'P' and owner = dev_name
            ) using (parent_owner, constraint_name)
        )
        select distinct child_owner, child_table
        from (
            select *
            from table_hierarchy
            where (child_owner, child_table) in (
                select parent_owner, parent_table
                from table_hierarchy
            )
        ) a
        where connect_by_iscycle = 1
        connect by nocycle (prior child_owner, prior child_table) = ((parent_owner, parent_table))
    );

    -- find dev table that doesn't exist in prod
    if v_count_circular > 0 then
        dbms_output.put_line('circular foreign key reference detected in DEV schema.');
        -- return;
    end if;

    for table_rec in (select table_name from all_tables where owner = dev_name order by table_name) loop
        process_table(table_rec.table_name);
    end loop;
      
    -- Напечатать пропущенные столбцы
    for i in reverse 1..v_table_list.count loop
    -- for dev_tab_rec in (select table_name from all_tables where owner = dev_name) loop
        v_dev_table_name := v_table_list(i);

        select count(*) into v_table_count
        from all_tables
        where owner = prod_name
        and table_name = v_dev_table_name;

        if v_table_count = 0 then
            dbms_output.put_line('No dev table #' || v_dev_table_name || '# is in prod schema.');
        else
            -- Сравнение структуры таблиц
            select count(*) into v_dev_col_count from all_tab_cols where owner = dev_name and table_name = v_dev_table_name;

            select count(*) into v_prod_col_count from all_tab_cols where owner = prod_name and table_name = v_dev_table_name;

            -- dbms_output.put_line('table ' || v_dev_table_name || ' dev: ' || to_char(v_dev_col_count));
            -- dbms_output.put_line('table ' || v_dev_table_name || ' prod: ' || to_char(v_prod_col_count));

            if v_dev_col_count > v_prod_col_count then
                dbms_output.put_line('Table ' || v_dev_table_name || ' has ' || (v_dev_col_count - v_prod_col_count) || ' more columns in development schema.');
            end if;

            for dev_col_rec in (select column_name from all_tab_cols where owner = dev_name and table_name = v_dev_table_name and column_name not like 'SYS%') loop
                select count(*) into v_table_count from all_tab_cols where owner = prod_name and table_name = v_dev_table_name and column_name = dev_col_rec.column_name;

                if v_table_count = 0 then
                    dbms_output.put_line('No dev column #' || dev_col_rec.column_name || '# in dev table ' || v_dev_table_name || ' in production schema.');
                end if;
            end loop;
        end if;
    end loop;

    for i in reverse 1..v_table_list.count loop
        v_dev_table_name := v_table_list(i);

        select count(*) into v_table_count from all_tables where owner = prod_name and table_name = v_dev_table_name;

        if v_table_count = 0 then
            -- no dev table in prod, generate script
            select dbms_metadata.get_ddl('TABLE', v_dev_table_name, dev_name) into v_script from dual;
            v_script := replace(v_script, ' SHARING=METADATA', '');
            
            v_script := replace(v_script, dev_name, prod_name);
            dbms_output.put_line(v_script);
        else
            -- compare table struct
            select count(*) into v_dev_col_count from all_tab_cols where owner = dev_name and table_name = v_dev_table_name;

            select count(*) into v_prod_col_count from all_tab_cols where owner = prod_name and table_name = v_dev_table_name;

            -- if v_dev_col_count > v_prod_col_count then
                -- script to add missing cols
            v_missing_cols_in_prod_count := 0;
            v_script := 'alter table ' || prod_name || '.' || v_dev_table_name || ' add (';
            for dev_col_rec in (
                select column_name, data_type, data_length, data_precision, data_scale
                from all_tab_cols
                where owner = dev_name and table_name = v_dev_table_name
            ) loop
                select count(*) into v_table_count
                from all_tab_cols
                where owner = prod_name and table_name = v_dev_table_name and column_name = dev_col_rec.column_name;
            
                if v_table_count = 0 and dev_col_rec.column_name not like 'SYS%' then
                    v_missing_cols_in_prod_count := v_missing_cols_in_prod_count + 1;
                    v_script := v_script || dev_col_rec.column_name || ' ' || dev_col_rec.data_type;
                    if dev_col_rec.data_type in ('VARCHAR2', 'NVARCHAR2', 'RAW') then
                        v_script := v_script || '(' || dev_col_rec.data_length || ')';
                    elsif dev_col_rec.data_type in ('NUMBER') then
                        if (dev_col_rec.data_precision is not null) then
                            v_script := v_script || '(' || dev_col_rec.data_precision || ')';
                        end if;
                        if (dev_col_rec.data_scale is not null) then
                            v_script := v_script || ', ' || dev_col_rec.data_scale || ')';
                        end if;
                    end if;
                    v_script := v_script || ', ';
                end if;
            end loop;
            v_script := rtrim(v_script, ', ') || ')';
            if (v_missing_cols_in_prod_count > 0) then
                dbms_output.put_line(v_script);
            end if;
            
            
            -- else
                -- script to rem extra cols
            for prod_col_rec in (
                select column_name, data_type, data_length, data_precision, data_scale
                from all_tab_cols
                where owner = prod_name and table_name = v_dev_table_name and column_name not like 'SYS%'
            ) loop
                select count(*) into v_table_count
                from all_tab_cols
                where owner = dev_name and table_name = v_dev_table_name and column_name = prod_col_rec.column_name;
            
                if v_table_count = 0 then
                    v_script := 'alter table ' || prod_name || '.' || v_dev_table_name || ' drop column ' || upper(prod_col_rec.column_name);
                    dbms_output.put_line(v_script);
                end if;
            end loop;
        end if;
    end loop;

        -- Проверить лишние таблицы в Prod
        for prod_tab_rec in (select table_name from all_tables where owner = prod_name) loop
            select count(*) into v_table_count from all_tables where owner = dev_name and table_name = prod_tab_rec.table_name;

            if v_table_count = 0 then
                -- gen script
                dbms_output.put_line('drop table ' || prod_name || '.' || prod_tab_rec.table_name);
            end if;
        end loop;   
        
        -- drop constraint from prod
        FOR i IN REVERSE 1..v_table_list.COUNT LOOP
            v_dev_table_name := v_table_list(i);
            
            -- Получить все ограничения из схемы PROD для текущей таблицы
            FOR rec_fk_cons IN (
                SELECT DISTINCT cons.constraint_name, cols.table_name, cols.column_name
                FROM all_constraints cons
                JOIN all_cons_columns cols 
                ON cons.owner = cols.owner 
                   AND cons.table_name = cols.table_name 
                   AND cons.constraint_name = cols.constraint_name
                WHERE cols.owner = prod_name 
                  AND cols.table_name = v_dev_table_name
            ) LOOP
                BEGIN
                    DECLARE
                        v_exists NUMBER;
                    BEGIN
                        SELECT COUNT(*)
                        INTO v_exists
                        FROM all_constraints cons
                        JOIN all_cons_columns cols 
                        ON cons.owner = cols.owner 
                           AND cons.table_name = cols.table_name 
                           AND cons.constraint_name = cols.constraint_name
                        WHERE cols.owner = dev_name 
                          AND cols.table_name = v_dev_table_name 
                          AND cons.constraint_name = rec_fk_cons.constraint_name;
        
                        -- Если ограничение не существует в DEV, удалить его из PROD
                        IF v_exists = 0 THEN
                            IF rec_fk_cons.constraint_name IS NOT NULL 
                               AND rec_fk_cons.constraint_name NOT LIKE 'SYS%' THEN
                                v_sql := 'ALTER TABLE ' || prod_name || '.' || rec_fk_cons.table_name ||
                                         ' DROP CONSTRAINT ' || rec_fk_cons.constraint_name;
                                dbms_output.put_line(v_sql);
                            END IF;
                        END IF;
                    END;
                EXCEPTION
                    WHEN OTHERS THEN
                        IF rec_fk_cons.constraint_name NOT LIKE 'SYS%' THEN
                            dbms_output.put_line('Error removing foreign key ' || rec_fk_cons.constraint_name || 
                                                 ' from table ' || rec_fk_cons.table_name || ': ' || SQLERRM);
                        END IF;
                END;
            END LOOP;
        END LOOP;
        
    -- add missing constr in prod
    for i in reverse 1..v_table_list.count loop
        v_dev_table_name := v_table_list(i);
    
        SELECT constraint_name BULK COLLECT INTO dev_constraints_set
            FROM all_constraints
            WHERE owner = dev_name
                AND table_name = v_dev_table_name
                AND constraint_name NOT LIKE 'SYS%'
            ORDER BY constraint_name;
        SELECT constraint_name BULK COLLECT INTO prod_constraints_set
        FROM all_constraints
        WHERE owner = prod_name
            AND table_name = v_dev_table_name
            AND constraint_name NOT LIKE 'SYS%'
        ORDER BY constraint_name;
            
    
        FOR i IN 1..dev_constraints_set.count LOOP
            IF dev_constraints_set(i) NOT MEMBER OF prod_constraints_set THEN
                DECLARE
                    ddl_script      CLOB;
                    constraint_type VARCHAR2(20);
                BEGIN
                    SELECT constraint_type INTO constraint_type
                    FROM all_constraints
                    WHERE owner = dev_name
                        AND table_name = v_dev_table_name
                        AND constraint_name = dev_constraints_set(i);
                    ddl_script := dbms_metadata.get_ddl(CASE WHEN constraint_type = 'R' THEN 'REF_CONSTRAINT' ELSE 'CONSTRAINT' END, dev_constraints_set(i), dev_name);
                    ddl_script:=replace(ddl_script, dev_name, prod_name);
                    dbms_output.put_line(ddl_script);
                END;
            END IF;
        END LOOP;
    end loop;
end;
/

call cmp_func('PROD_SCHEMA', 'DEV_SCHEMA');
/
call cmp_indx('PROD_SCHEMA', 'DEV_SCHEMA');
/
call cmp_prc('PROD_SCHEMA', 'DEV_SCHEMA');
/
call cmp_pkg('PROD_SCHEMA', 'DEV_SCHEMA');
/
call cmp_tbl('PROD_SCHEMA', 'DEV_SCHEMA');
/
