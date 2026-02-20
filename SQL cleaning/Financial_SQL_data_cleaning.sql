#srtep 1: creating database
create database financial_operations;

#using database
use financial_operations;

#preview_data
select * from financial_operations_raw;

#Create backup raw data
create table financial_dummy as select * from financial_operations_raw;

#checking total_rows
select count(*) as total_rows from financial_dummy;

#checking datatypes and null
desc financial_dummy;

#checking duplicates
SELECT transaction_id, COUNT(*) AS duplicate_count
FROM financial_dummy
GROUP BY transaction_id
HAVING COUNT(*) > 1;


set sql_safe_updates=0;


SELECT COUNT(*) FROM financial_dummy;

SELECT transaction_id, COUNT(*)
FROM financial_dummy
GROUP BY transaction_id
HAVING COUNT(*) > 1;


SELECT VERSION();

ALTER TABLE financial_dummy
ADD COLUMN temp_id INT AUTO_INCREMENT PRIMARY KEY;

DELETE t1
FROM financial_dummy t1
JOIN financial_dummy t2
ON t1.transaction_id = t2.transaction_id
AND t1.temp_id > t2.temp_id;

SELECT transaction_id, COUNT(*)
FROM financial_dummy
GROUP BY transaction_id
HAVING COUNT(*) > 1;




#identify blanks per column
select 
client_id, count(*) from financial_dummy where client_id='';


select 
sum(trim(transaction_id)='')AS transaction_id_blank,
sum(trim(client_id)='')AS client_id_blank,
sum(trim(industry)='')AS industry_blank,
sum(trim(region)='')AS region_blank,
sum(trim(subscription_plan)='')AS subscription_plan_blank,
sum(trim(onboarding_date)='')AS onboarding_date_blank,
sum(trim(invoice_date)='')AS invoice_date_blank,
sum(trim(revenue_amount)='')AS revenue_amount_blank,
sum(trim(service_cost)='')AS tservice_cost_blank,
sum(trim(profit)='')AS profit_blank,
sum(trim(payment_status)='')AS payment_status_blank,
sum(trim(tenure_months)='')AS tenure_months_blank,
sum(trim(last_active_date)='')AS last_active_date_blank,
sum(trim(churn_flag)='')AS churn_flag_blank
from financial_dummy;

#filling blanks with nulls
UPDATE financial_dummy
SET 
profit = NULLIF(TRIM(profit), ''),
payment_status = NULLIF(TRIM(payment_status), '');


select * from financial_dummy;

#checking for nulls
SELECT
SUM(transaction_id IS NULL) AS transaction_id_nulls,
SUM(client_id IS NULL) AS client_id_nulls,
SUM(industry IS NULL) AS industry_nulls,
SUM(region IS NULL) AS region_nulls,
SUM(subscription_plan IS NULL) AS subscription_plan_nulls,
SUM(onboarding_date IS NULL) AS onboarding_date_nulls,
SUM(invoice_date IS NULL) AS invoice_date_nulls,
SUM(revenue_amount IS NULL) AS revenue_amount_nulls,
SUM(service_cost IS NULL) AS service_cost_nulls,
SUM(profit IS NULL) AS profit_nulls,
SUM(payment_status IS NULL) AS payment_status_nulls,
SUM(tenure_months IS NULL) AS tenure_months_nulls,
SUM(last_active_date IS NULL) AS last_active_date_nulls,
SUM(churn_flag IS NULL) AS churn_flag_nulls
FROM financial_dummy;

SELECT COUNT(*) AS total_rows
FROM financial_dummy;

#Convert Date Strings to Proper Date Format
UPDATE financial_dummy
SET 
onboarding_date = STR_TO_DATE(onboarding_date, '%d-%m-%Y'),
invoice_date = STR_TO_DATE(invoice_date, '%d-%m-%Y'),
last_active_date = STR_TO_DATE(last_active_date, '%d-%m-%Y');

#MODIFY ALL DATATYPES
ALTER TABLE financial_dummy
MODIFY transaction_id INT,
MODIFY client_id INT,
MODIFY industry VARCHAR(100),
MODIFY region VARCHAR(50),
MODIFY subscription_plan VARCHAR(50),
MODIFY onboarding_date DATE,
MODIFY invoice_date DATE,
MODIFY revenue_amount DECIMAL(12,2),
MODIFY service_cost DECIMAL(12,2),
MODIFY profit DECIMAL(12,2),
MODIFY payment_status VARCHAR(50),
MODIFY tenure_months INT,
MODIFY last_active_date DATE,
MODIFY churn_flag INT;

#verifying datatypes
DESC financial_dummy;

#checking for invalid values
SELECT
SUM(tenure_months < 0) AS invalid_tenure,
SUM(revenue_amount < 0) AS invalid_revenue,
SUM(service_cost < 0) AS invalid_cost,
SUM(churn_flag NOT IN (0,1)) AS invalid_churn_flag,
SUM(payment_status NOT IN ('Paid','Overdue','Pending') 
    AND payment_status IS NOT NULL) AS invalid_payment_status,
SUM(profit <> (revenue_amount - service_cost)
    AND profit IS NOT NULL) AS invalid_profit_logic
FROM financial_dummy;


#filling invalid with nulls
UPDATE financial_dummy
SET 
    tenure_months = CASE 
                        WHEN tenure_months < 0 THEN NULL 
                        ELSE tenure_months 
                    END,

    revenue_amount = CASE 
                        WHEN revenue_amount < 0 THEN NULL 
                        ELSE revenue_amount 
                     END,

    service_cost = CASE 
                        WHEN service_cost < 0 THEN NULL 
                        ELSE service_cost 
                   END;


#checking for nulls
SELECT
SUM(transaction_id IS NULL) AS transaction_id_nulls,
SUM(client_id IS NULL) AS client_id_nulls,
SUM(industry IS NULL OR TRIM(industry) = '') AS industry_missing,
SUM(region IS NULL OR TRIM(region) = '') AS region_missing,
SUM(subscription_plan IS NULL OR TRIM(subscription_plan) = '') AS subscription_plan_missing,
SUM(onboarding_date IS NULL) AS onboarding_date_missing,
SUM(invoice_date IS NULL) AS invoice_date_missing,
SUM(last_active_date IS NULL) AS last_active_date_missing,
SUM(revenue_amount IS NULL) AS revenue_nulls,
SUM(service_cost IS NULL) AS cost_nulls,
SUM(profit IS NULL) AS profit_nulls,
SUM(payment_status IS NULL OR TRIM(payment_status) = '') AS payment_status_missing,
SUM(tenure_months IS NULL) AS tenure_nulls,
SUM(churn_flag IS NULL) AS churn_nulls
FROM financial_dummy;

#Calculate MEAN
SELECT
AVG(revenue_amount) AS mean_revenue,
AVG(service_cost) AS mean_cost,
AVG(profit) AS mean_profit,
AVG(tenure_months) AS mean_tenure
FROM financial_dummy;

#median for revenue_amount
SELECT AVG(revenue_amount) AS median_revenue
FROM (
    SELECT revenue_amount,
           @rownum := @rownum + 1 AS row_number,
           @total_rows := @rownum
    FROM financial_dummy, 
         (SELECT @rownum := 0) r
    WHERE revenue_amount IS NOT NULL
    ORDER BY revenue_amount
) AS ranked
WHERE row_number IN (FLOOR((@total_rows+1)/2), FLOOR((@total_rows+2)/2));


#median for servicecost
SELECT AVG(service_cost) AS median_cost
FROM (
    SELECT service_cost,
           @rownum := @rownum + 1 AS row_number,
           @total_rows := @rownum
    FROM financial_dummy, 
         (SELECT @rownum := 0) r
    WHERE service_cost IS NOT NULL
    ORDER BY service_cost
) AS ranked
WHERE row_number IN (FLOOR((@total_rows+1)/2), FLOOR((@total_rows+2)/2));


#median for profit
SELECT AVG(profit) AS median_profit
FROM (
    SELECT profit,
           @rownum := @rownum + 1 AS row_number,
           @total_rows := @rownum
    FROM financial_dummy, 
         (SELECT @rownum := 0) r
    WHERE profit IS NOT NULL
    ORDER BY profit
) AS ranked
WHERE row_number IN (FLOOR((@total_rows+1)/2), FLOOR((@total_rows+2)/2));

#median for tenure_month
SELECT AVG(tenure_months) AS median_tenure
FROM (
    SELECT tenure_months,
           @rownum := @rownum + 1 AS row_number,
           @total_rows := @rownum
    FROM financial_dummy, 
         (SELECT @rownum := 0) r
    WHERE tenure_months IS NOT NULL
    ORDER BY tenure_months
) AS ranked
WHERE row_number IN (FLOOR((@total_rows+1)/2), FLOOR((@total_rows+2)/2));

#Verify NULL Count Before Filling
SELECT
SUM(revenue_amount IS NULL) AS revenue_nulls,
SUM(service_cost IS NULL) AS cost_nulls,
SUM(profit IS NULL) AS profit_nulls,
SUM(tenure_months IS NULL) AS tenure_nulls
FROM financial_dummy;

#Fill NULLs with MEAN
#Fill revenue_amount
UPDATE financial_dummy
SET revenue_amount = (
    SELECT ROUND(avg_revenue,2)
    FROM (
        SELECT AVG(revenue_amount) AS avg_revenue
        FROM financial_dummy
        WHERE revenue_amount IS NOT NULL
    ) AS temp
)
WHERE revenue_amount IS NULL;


#Fill NULLs in service_cost
UPDATE financial_dummy
SET service_cost = (
    SELECT ROUND(avg_cost,2)
    FROM (
        SELECT AVG(service_cost) AS avg_cost
        FROM financial_dummy
        WHERE service_cost IS NOT NULL
    ) AS temp
)
WHERE service_cost IS NULL;

#Fill NULLs in profit
UPDATE financial_dummy
SET profit = (
    SELECT ROUND(avg_profit,2)
    FROM (
        SELECT AVG(profit) AS avg_profit
        FROM financial_dummy
        WHERE profit IS NOT NULL
    ) AS temp
)
WHERE profit IS NULL;


#Fill NULLs in tenure_months
UPDATE financial_dummy
SET tenure_months = (
    SELECT ROUND(avg_tenure)
    FROM (
        SELECT AVG(tenure_months) AS avg_tenure
        FROM financial_dummy
        WHERE tenure_months IS NOT NULL
    ) AS temp
)
WHERE tenure_months IS NULL;


SELECT
SUM(revenue_amount IS NULL) AS revenue_nulls,
SUM(service_cost IS NULL) AS cost_nulls,
SUM(profit IS NULL) AS profit_nulls,
SUM(tenure_months IS NULL) AS tenure_nulls
FROM financial_dummy;

select * from financial_dummy;

select count(*) from financial_dummy;





SELECT 
COUNT(*) AS same_dates
FROM financial_dummy
WHERE invoice_date = last_active_date;

SELECT 
COUNT(*) / (SELECT COUNT(*) FROM financial_dummy) * 100 AS same_date_percentage
FROM financial_dummy
WHERE invoice_date = last_active_date;


SELECT 
COUNT(*) AS same_dates
FROM financial_dummy
WHERE payment_status = 'paid';

SELECT 
COUNT(*) AS same_dates
FROM financial_dummy
WHERE payment_status = 'overdue';

SELECT 
COUNT(*) AS same_dates
FROM financial_dummy
WHERE payment_status = 'pending';

update financial_dummy 
set
tenure_months=last_active_date-onboarding_date;


select * from financial_dummy;








 






