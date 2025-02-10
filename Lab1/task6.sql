CREATE OR REPLACE FUNCTION calculate_total_reward(
    p_monthly_salary NUMBER,
    p_bonus_percentage NUMBER
) RETURN NUMBER IS
    total_reward NUMBER;
BEGIN
    IF p_monthly_salary < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Месячная зарплата не может быть отрицательной');
    END IF;

    IF p_bonus_percentage < 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Процент премиальных не может быть отрицательным');
    END IF;

    total_reward := (1 + p_bonus_percentage / 100) * 12 * p_monthly_salary;

    RETURN total_reward;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Ошибка: ' || SQLERRM);
END calculate_total_reward;
/
DECLARE
    monthly_salary NUMBER := 50000; 
    bonus_percentage NUMBER := 20;    
    total_reward NUMBER;
BEGIN
    total_reward := calculate_total_reward(monthly_salary, bonus_percentage);
    DBMS_OUTPUT.PUT_LINE('Общее вознаграждение за год: ' || total_reward);
END;
/