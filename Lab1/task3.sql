CREATE OR REPLACE FUNCTION odd_even RETURN CHAR IS
    count_even INTEGER;
    count_odd INTEGER;
BEGIN
    SELECT COUNT(*) INTO count_even 
    FROM MYTABLE
    WHERE MOD(val, 2) = 0;
    
    SELECT COUNT(*) INTO count_odd 
    FROM MYTABLE
    WHERE MOD(val, 2) = 1;

    IF count_even > count_odd THEN
        RETURN 'четных больше';
    ELSIF count_even < count_odd THEN
        RETURN 'нечетных больше';
    ELSE
        RETURN 'равно';
    END IF;
END odd_even;
/
SELECT odd_even() FROM dual;