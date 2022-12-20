USE kaggle;
-- validation 一般都用left join，这样可以更易于查出有问题的数据

-- 1. Customer validation
SELECT *,
       CASE WHEN YEAR(CURDATE())-Year_Birth > 100 OR YEAR(CURDATE())-Year_Birth < 18 THEN 0 ELSE 1 END AS Year_birth_valid,
       CASE WHEN ZIP_code NOT IN ('528400', '528401', '528402', '528403', '528411', '528414', '528415', '528416', '528421', '528422', '528425', '528427', '528429', '528434', '528437', '528441', '528445', '528447', '528451', '528455', '528458', '528459', '528462', '528463', '528467', '528471', '528476', '528478') THEN 0 ELSE 1 END AS zip_code_valid,
       CASE WHEN gender NOT IN ('F', 'M') THEN 0 ELSE 1 END AS gender_valid,
       CASE WHEN year_birth > YEAR(Dt_Customer) THEN 0 ELSE 1 END AS yb_dt_valid,
       IF(Dt_Customer = DATE_FORMAT(Dt_Customer, '%Y-%m-%d'), 1, 0) AS dt_valid
FROM customer;

SELECT *
FROM customer;

-- 2. Product validation
SELECT *,
	   CONCAT('20', RIGHT(ReleaseDateTime, 2)) >= YEAR AS release_valid,
       CASE WHEN currency != 'CNY' THEN 0 ELSE 1 END AS currency_valid,
       CASE WHEN price < 0 THEN 0 ELSE 1 END AS price_valid
  FROM product;
  
  -- 3. Promotion validation
  SELECT *,
         CASE WHEN DATEDIFF(STR_TO_DATE(starttime, '%d-%b-%y'),  STR_TO_DATE(endtime, '%d-%b-%y')) > 0 THEN 0 ELSE 1 END AS time_valid,
         CASE WHEN currency != 'CNY' THEN 0 ELSE 1 END AS currency_valid
  FROM promotion;
 
  -- 4. Purchase validation
  SELECT *,
       IF(currency != 'CNY', 0, 1) AS currency_valid
  FROM purchase;
  
 
  -- 5. Activity validation
SELECT 
    *,
    IF(p.type = 'movie'
            AND a.Video_Time_Occuption > 300,
        0,
        1) AS video_valid
FROM
    activity a
     LEFT JOIN
    product p ON a.product_id = p.product_id;
  
  -- 6. Cross_validation_promoted_price
  SELECT p2.Product_ID,
	     p1.Promoted_Price, 
         p2.price,
         CASE WHEN p1.promoted_price >= p2.price THEN 0 ELSE 1 END AS promote_valid
   FROM promotion p1 LEFT JOIN product p2 ON p1.Promoted_Product_Id = p2.Product_ID;
  
  -- 7. Cross_dt_date_validation
  SELECT	c.Dt_Customer,
			p.Purchase_Date,
			IF(DATEDIFF(STR_TO_DATE(c.Dt_Customer), STR_TO_DATE(p.Purchase_Date)) > 0, 0, 1) AS dt_pur_valid
  FROM customer c LEFT JOIN purchase p ON P.Customer_ID = C.Customer_ID;
  
  -- 8. Cross_validation_activity
SELECT 
    a.product_id,
    p.Purchase_Price,
    IF(a.product_id IN (SELECT 
                Product_ID
            FROM
                purchase),
        1,
        0) AS activity_valid
FROM
    activity a
        LEFT JOIN
    purchase p ON a.product_id = p.product_id
        AND a.customer_id = p.customer_id;

-- Product's titles validation
-- sql不区分大小写，这里查询不出来

WITH t AS (
	SELECT
		*, 
		UPPER(title) AS a
	FROM product)

SELECT
	*,
    IF(title = a, 1, 0) AS b
FROM t;



