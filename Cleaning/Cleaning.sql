USE kaggle;

SET SQL_SAFE_UPDATES = 0;

SELECT *
FROM customer;

-- 1. Cleaning wrong data format & content
-- (1) customer
-- unified dt——customer date
-- step 1
UPDATE customer    
SET Dt_Customer = STR_TO_DATE(Dt_Customer, '%d-%m-%Y')
WHERE Dt_Customer LIKE'%-%';

-- step 2
UPDATE customer    
SET Dt_Customer = str_to_date(Dt_Customer, '%Y/%m/%d')
WHERE Dt_Customer LIKE'%/%';

-- 删掉之前加进去的id为1的测试数据
DELETE FROM customer
WHERE customer_id = 1;

-- (2) product
-- correct title
UPDATE product
SET  title = CONCAT(UCASE(LEFT(title, 1)), LCASE(SUBSTRING(title, 2))); 

-- correct wrong price
UPDATE product
SET  price = 10  
WHERE product_id = 9;

-- unified ReleaseDateTime
UPDATE product   
SET ReleaseDateTime = STR_TO_DATE(ReleaseDateTime, '%d-%b-%y');

-- (3) promotion
-- unified starttime & endtime
UPDATE promotion
SET starttime = STR_TO_DATE(starttime, '%d-%b-%y'),
endtime = STR_TO_DATE(endtime, '%d-%b-%y');

-- (4) purchase
-- unified purchase_date
UPDATE purchase
SET purchase_date = STR_TO_DATE(purchase_date, '%d-%b-%y');

-- (5) activity
-- unified activity_date
UPDATE activity
SET activity_date = STR_TO_DATE(activity_date, '%d-%b-%y');

-- 2. Cleaning empty cells
-- insert null value
INSERT INTO customer
VALUES (1, 2, null, null,null, 2, 0, null, 528400, 'F');

SELECT * 
FROM customer
WHERE Customer_ID IS NULL OR Year_Birth IS NULL OR Education IS NULL OR Marital_Status IS NULL OR Income IS NULL OR Kidhome IS NULL OR Teenhome IS NULL OR Dt_Customer IS NULL OR ZIP_code IS NULL OR Gender IS NULL;

SELECT *
FROM customer;

-- replace null value
WITH t1 AS(
SELECT AVG(income) AS avg_income
FROM customer)

UPDATE customer 
SET education = ( CASE WHEN IFNULL( education, 'Graduation' ) = 'Graduation' THEN 'Graduation' ELSE education END ),
	Marital_Status = ( CASE WHEN IFNULL( Marital_Status, 'Married' ) = 'Married' THEN 'Married' ELSE Marital_Status END ),
	Income = ( CASE WHEN IFNULL( Income, '7500' ) =  '7500' THEN  '7500'  ELSE Income END ), -- 如何用均值替代空值
    Dt_Customer = ( CASE WHEN IFNULL( Dt_Customer, '2012-2-11' ) = '2012-2-11' THEN '2012-2-11' ELSE Dt_Customer END )
WHERE
	education IS NULL OR Marital_Status IS NULL OR Income IS NULL OR Dt_Customer IS NULL;

-- A. CASE WHEN
WITH t1 AS(
SELECT AVG(income) AS avg_income
FROM customer)
UPDATE customer 
SET education = ( CASE WHEN education IS NULL THEN 'Graduation' ELSE education END ),
	Marital_Status = ( CASE WHEN Marital_Status IS NULL THEN 'Married' ELSE Marital_Status END ),
	Income = ( CASE WHEN Income IS NULL THEN (SELECT avg_income FROM t1) ELSE Income END ), 
    Dt_Customer = ( CASE WHEN Dt_Customer IS NULL THEN '2012-2-11' ELSE Dt_Customer END )
WHERE
	education IS NULL OR Marital_Status IS NULL OR Income IS NULL OR Dt_Customer IS NULL;

-- B. IFNULL
WITH t1 AS(
SELECT AVG(income) AS avg_income
FROM customer)
UPDATE customer 
SET education = IFNULL( education, 'Graduation' ),
	Marital_Status = IFNULL( Marital_Status, 'Married' ),
	Income = IFNULL( Income, (SELECT avg_income FROM t1)) , 
    Dt_Customer = IFNULL( Dt_Customer, '2012-2-11')
WHERE
	education IS NULL OR Marital_Status IS NULL OR Income IS NULL OR Dt_Customer IS NULL;

SELECT *
FROM customer;

-- 3. Remove duplicates
-- (1) customer
DELETE FROM customer
WHERE customer_id IN (
    SELECT customer_id
    FROM (
        SELECT 
            customer_id, ROW_NUMBER () OVER (PARTITION BY Year_Birth, Education, Marital_Status, Income, Kidhome, Teenhome, Dt_Customer, ZIP_code, Gender ORDER BY customer_id) as r 
        from customer
    ) t
    WHERE r > 1
);

-- revised delete remove
DELETE FROM customer
WHERE
	(year_birth, education, marital_status, income) IN (
		SELECT
			year_birth, 
            education, 
            marital_status, 
            income
		FROM
			(
				SELECT
					year_birth, 
					education, 
					marital_status, 
					income
				FROM
					customer
				GROUP BY
					year_birth, 
					education, 
					marital_status, 
					income
				HAVING
					count(*) > 1
			) t
	)
AND customer_id NOT IN (
	SELECT
		customer_id
	FROM
		(
			SELECT
				min(customer_id) AS min_customer_id
			FROM
				customer
			GROUP BY
				year_birth, 
				education, 
				marital_status, 
				income
			HAVING
				count(*) > 1
		) dt
) ;

-- 用create创建新表并把不重复的值选出来放进去以达到去重的效果
CREATE TABLE new_customer AS
SELECT DISTINCT Customer_ID, 
				Year_Birth, 
				Education, 
				Marital_Status, 
				Income, 
                Kidhome, 
                Teenhome, 
                Dt_Customer,
                ZIP_code,
                Gender
FROM customer;

select * from new_customer;

-- (2) product
CREATE TABLE product_copy2(
	Product_ID INT PRIMARY KEY AUTO_INCREMENT,
	Title VARCHAR(255) NOT NULL,
    Year INT,
    ReleaseDateTime VARCHAR(50) NOT NULL,
    Age VARCHAR(50) NOT NULL,
    Douban_rating DOUBLE,
    Type VARCHAR(50) NOT NULL,
    SubType VARCHAR(50) NOT NULL,
    Price INT,
    Currency VARCHAR(50) NOT NULL,
    Is_Series VARCHAR(50) NOT NULL
);

-- 怎么插入product_id(试试用有选择的join)
INSERT INTO product_copy2(Title, Year, ReleaseDateTime, Age, Douban_rating, Type, SubType, Price, Currency,Is_Series)
SELECT DISTINCT Title, Year, ReleaseDateTime, Age, Douban_rating, Type, SubType, Price, Currency,Is_Series
FROM product;

INSERT INTO product_copy3(Title, Year, ReleaseDateTime, Age, Douban_rating, Type, SubType, Price, Currency,Is_Series)
SELECT DISTINCT Title, Year, ReleaseDateTime, Age, Douban_rating, Type, SubType, Price, Currency,Is_Series
FROM product;

SELECT *
FROM product_copy2;

DROP TABLES product_copy2;

DROP TABLES product;
ALTER TABLE product_copy2 RENAME TO product;
SELECT * 
FROM product;

-- (3) promotion
DELETE FROM promotion
WHERE promotion_id IN (
    SELECT promotion_id
    FROM (
        SELECT 
            promotion_id, ROW_NUMBER () OVER (PARTITION BY StartTime, EndTime, Promoted_Product_Id, Promoted_Price, Currency ORDER BY promotion_id) as r 
        from promotion
    ) t
    WHERE r > 1
);
select * from promotion;

-- (4) purchase
DELETE FROM purchase
WHERE purchase_id IN (
    SELECT purchase_id
    FROM (
        SELECT 
            purchase_id, ROW_NUMBER () OVER (PARTITION BY Customer_ID, Purchase_Date, Product_ID, Purchase_Price, Currency ORDER BY purchase_id) as r 
        from purchase
    ) t
    WHERE r > 1
);
select * from purchase;

-- (5) activity
DELETE FROM activity
WHERE customer_id IN (
    SELECT customer_id
    FROM (
        SELECT 
            customer_id, ROW_NUMBER () OVER (PARTITION BY customer_id, product_id,Video_Time_Occuption) as r 
        from activity
    ) t
    WHERE r > 1
);
select * from activity;

-- 4.Accurate value rate & Null value rate
-- 4.1 Accurate value rate--一般都是每一列的accurate rate
-- （1）customer
SELECT *
FROM customer_validation;

SELECT SUM(Year_birth_valid) / COUNT(*) AS yb_accurate_rate,
	   SUM(zip_code_valid) / COUNT(*) AS zip_accurate_rate,
       SUM(gender_valid) / COUNT(*) AS gender_accurate_rate,
       SUM(yb_dt_valid) / COUNT(*) AS yb_dt_accurate_rate,
       SUM(dt_valida) / COUNT(*) AS dt_accurate_rate
FROM customer_validation;

-- (2) product
SELECT *
FROM product_validation;

SELECT SUM(release_valid) / COUNT(*) AS release_accurate_rate,
	   SUM(currency_valid) / COUNT(*) AS currency_accurate_rate,
       SUM(price_valid) / COUNT(*) AS price_accurate_rate
FROM product_validation;

-- (3) promotion
SELECT *
FROM promotion_validation;

SELECT (time_accurate_rate + currency_accurate_rate ) / 2 * 100 AS total_accurate_rate
FROM(
SELECT SUM(time_valid) / COUNT(*) AS time_accurate_rate,
	   SUM(currency_valid) / COUNT(*) AS currency_accurate_rate
FROM promotion_validation) AS t;

-- (4) purchase
SELECT *
FROM purchase_validation;

SELECT 
	   SUM(currency_valid) / COUNT(*) * 100 AS currency_accurate_rate
FROM purchase_validation;

-- (5) activity
SELECT 
    SUM(IF(p.type = 'movie'
            AND a.Video_Time_Occuption > 300,0,1)) / COUNT(*) * 100 AS video_accurate_rate
FROM
    activity a
        JOIN
    product p ON a.product_id = p.product_id;
    
    -- 4.2 Null value rate--一般计算每一列的null value rate
INSERT INTO customer
VALUES (1, 2, null, null,null, 2, 0, null, 528400, 'F');

SELECT *
FROM customer;

SELECT SUM(CASE WHEN Customer_ID IS NULL OR Year_Birth IS NULL OR Education IS NULL OR Marital_Status IS NULL OR Income IS NULL OR Kidhome IS NULL OR Teenhome IS NULL OR Dt_Customer IS NULL OR ZIP_code IS NULL OR Gender IS NULL THEN 1 ELSE 0 END ) / COUNT(*)  AS null_value_rate
FROM customer;

-- 后边可以考虑把这个比率变成text,然后加上百分号%（改变单位要加上单位在列名）
SELECT (SUM(IF(customer_id IS NULL, 1, 0)) / COUNT(*)) *100 AS customer_id_NA_rate_percentage,
	   (SUM(IF(year_birth IS NULL, 1, 0)) / COUNT(*)) *100  AS year_birth_NA_rate_percentage,
       (SUM(IF(education IS NULL, 1, 0)) / COUNT(*)) *100  AS education_NA_rate_percentage,
       (SUM(IF(marital_status IS NULL, 1, 0)) / COUNT(*)) *100  AS marital_status_NA_rate_percentage,
       (SUM(IF(kidhome IS NULL, 1, 0)) / COUNT(*))*100  AS kidhome_NA_rate_percentage,
       (SUM(IF(Teenhome IS NULL, 1, 0)) / COUNT(*))*100  AS Teenhome_NA_rate_percentage,
       (SUM(IF(Dt_Customer IS NULL, 1, 0)) / COUNT(*)) *100  AS Dt_Customer_NA_rate_percentage,
       (SUM(IF(ZIP_code IS NULL, 1, 0)) / COUNT(*)) *100  AS ZIP_code_NA_rate_percentage,
       (SUM(IF(gender IS NULL, 1, 0)) / COUNT(*))*100  AS gender_NA_rate_percentage
FROM customer;

