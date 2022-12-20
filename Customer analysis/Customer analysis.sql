USE kaggle;

-- 解决ONLY_FULL_GROUP_BY问题

set sql_mode='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';


-- 1. How many children?
-- For every family
SELECT *,
	   (Kidhome + Teenhome) AS Childrenhome
FROM customer;

-- For total children
SELECT SUM(kidhome) + SUM(teenhome) AS total_children
FROM customer;

-- 2. Is sensitive to  the promomtion?
-- sensitive是1，否则是0；rule:在promotion期间有过1次或1次以上购买记录的客户是sensitive的，否则不sensitive
SELECT c1.customer_id,
       IF(ISNULL(t2.customer_id), 0, 1) AS promotion_sensitive
       -- 判断是都在下边的规则里，在规则里就是1，否则是0
FROM customer c1 LEFT JOIN
(SELECT 
    customer_id,
    COUNT(purchase_id) AS buy_promotion_times
FROM
    (SELECT 
        c.customer_id,
        Purchase_ID
    FROM
        customer c
	    JOIN purchase p1 ON c.customer_id = p1.customer_id
		JOIN promotion p2 ON p1.product_id = p2.Promoted_Product_Id
    WHERE
         purchase_date BETWEEN starttime AND endtime
        ) AS t1
GROUP BY customer_id) AS t2
ON c1.customer_id = t2.customer_id;
        
-- 3. Most recent Purchase (R)(purchase_date after 2021-11-01)
SELECT Purchase_ID, Customer_ID, Purchase_Date, Product_ID, Purchase_Price, Currency
FROM(
	SELECT *,
			ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY purchase_date DESC) AS rn
	FROM purchase) AS t
WHERE rn = 1 AND purchase_date > '2021-11-01'
ORDER BY purchase_id;
        
 -- 4. Most recent Activity(activity_date after 2021-11-01)
 SELECT Customer_ID, Product_Id, Video_Time_Occuption, Activity_date
 FROM (
		SELECT *,
				RANK() OVER(PARTITION BY customer_id ORDER BY activity_date DESC) AS rk
		FROM activity
 ) AS t
 WHERE rk = 1 AND activity_date > '2021-11-01';
 
 -- 5. Most recent purchase times (F) (purchase_date after 2021-11-01)
 SELECT customer_id, COUNT(*) AS purchase_times
 FROM purchase
 WHERE purchase_date > '2021-11-01'
 GROUP BY customer_id;
 
 -- 6.Overall money Spent (M) (purchase_date after 2021-11-01)
SELECT customer_id, SUM(purchase_price) AS money_spent
FROM purchase
WHERE purchase_date > '2021-11-01'
GROUP BY customer_id; 
 
 -- 7. R value-- 0 OR 1
 select *
 from purchase;
 
WITH t AS (
			SELECT Purchase_ID, Customer_ID, Purchase_Date, Product_ID, Purchase_Price, Currency
			FROM(
				SELECT *,
				ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY purchase_date DESC) AS rn
				FROM purchase) AS t
			WHERE rn = 1 AND purchase_date > '2021-11-01')

 SELECT p.purchase_id,
		p.customer_id, 
        p.Purchase_Date,
        p.Product_ID,
        p.Purchase_Price,
        p.Currency,
        IF(ISNULL(t.customer_id), 0, 1) AS R_value
 FROM purchase p LEFT JOIN t USING(customer_id)
 ORDER BY purchase_id;
 
 -- 8. F value-- 0 OR 1
 WITH t AS (
			SELECT customer_id, COUNT(*) AS purchase_times
			FROM purchase
			WHERE purchase_date > '2021-11-01'
			GROUP BY customer_id
 )
 
 SELECT p.customer_id, IF(ISNULL(t.customer_id), 0, 1) AS F_value
 FROM purchase p LEFT JOIN t USING(customer_id)
 ORDER BY customer_id;
 
 -- 9. M value-- 0 OR 1
 WITH t AS (
			SELECT customer_id, SUM(purchase_price) AS money_spent
			FROM purchase
			WHERE purchase_date > '2021-11-01'
			GROUP BY customer_id)
 
 SELECT customer_id,  IF(ISNULL(t.customer_id), 0, 1) AS M_value
 FROM purchase p LEFT JOIN t USING(customer_id)
 ORDER BY customer_id;
 
 -- 10. CustomerType
 WITH t1 AS (
	SELECT customer_id, 
		   DATEDIFF(CURDATE(), purchase_date) AS R_value
	FROM purchase
 ),
 t2 AS (
 SELECT customer_id, COUNT(purchase_id) AS F_value
 FROM purchase
 GROUP BY customer_id
 ) ,
t3 AS (
 SELECT customer_id, SUM(purchase_price) AS M_value
 FROM purchase
 GROUP BY customer_id
 )
 
 SELECT t1.customer_id,
		(CASE WHEN t1.R_value > (SELECT AVG( t1.R_value ) FROM t1) AND t2.F_value > (SELECT AVG(t2.F_value) FROM t2) AND t3.M_value > (SELECT AVG(t3.M_value) FROM t3) THEN 'High_value'
			  WHEN t1.R_value < (SELECT AVG( t1.R_value ) FROM t1) AND t2.F_value > (SELECT AVG(t2.F_value) FROM t2) AND t3.M_value > (SELECT AVG(t3.M_value) FROM t3) THEN 'Key_retention'
              WHEN t1.R_value > (SELECT AVG( t1.R_value ) FROM t1) AND t2.F_value < (SELECT AVG(t2.F_value) FROM t2) AND t3.M_value > (SELECT AVG(t3.M_value) FROM t3) THEN 'Key_development'
              WHEN t1.R_value < (SELECT AVG( t1.R_value ) FROM t1) AND t2.F_value < (SELECT AVG(t2.F_value) FROM t2) AND t3.M_value > (SELECT AVG(t3.M_value) FROM t3) THEN 'Key_retaining'
              WHEN t1.R_value > (SELECT AVG( t1.R_value ) FROM t1) AND t2.F_value > (SELECT AVG(t2.F_value) FROM t2) AND t3.M_value < (SELECT AVG(t3.M_value) FROM t3) THEN 'General_value'
			  WHEN t1.R_value < (SELECT AVG( t1.R_value ) FROM t1) AND t2.F_value > (SELECT AVG(t2.F_value) FROM t2) AND t3.M_value < (SELECT AVG(t3.M_value) FROM t3) THEN 'General_retention'
              WHEN t1.R_value > (SELECT AVG( t1.R_value ) FROM t1) AND t2.F_value < (SELECT AVG(t2.F_value) FROM t2) AND t3.M_value < (SELECT AVG(t3.M_value) FROM t3) THEN 'General_development'
			  WHEN t1.R_value < (SELECT AVG( t1.R_value ) FROM t1) AND t2.F_value < (SELECT AVG(t2.F_value) FROM t2) AND t3.M_value < (SELECT AVG(t3.M_value) FROM t3) THEN 'Potential'
              ELSE 'Other' END) AS Customer_type
FROM t1 JOIN t2 USING(customer_id) JOIN t3 USING(customer_id);

-- 11. Favorite product subtype-- 找出用户喜欢的节目的类型
-- 查找每个用户喜欢看的类型
SELECT t.customer_id, t.product_id, p.SubType, t.Watching_times
FROM (
	SELECT customer_id, product_id, COUNT(*) AS Watching_times
	FROM activity
	GROUP BY customer_id, product_id)  AS t
    JOIN product p USING(product_id)
ORDER BY Watching_times DESC, product_id;

-- 查找节目类型的受欢迎度排名（按观看超过30分钟的用户数排名）
WITH t AS (
			SELECT a.product_id, 
					p.subtype,
                   COUNT(customer_id) AS watch_pop
			FROM activity a LEFT JOIN product p USING(product_id)
            WHERE Video_Time_Occuption > 30
            GROUP BY p.subtype
) 

SELECT  product_id, 
		subtype, 
        watch_pop,
        DENSE_RANK() OVER(ORDER BY watch_pop DESC) AS popular_rank
FROM t;


-- 12. watching/purchase rate. (some customer did not watch the movie although buying it)
-- (客户在purchase表购买且在acitivity表观看了的product_id数量)/ (每个客户在purchase表购买的product_id数量)
WITH t1 AS 
(SELECT a.customer_id,
		COUNT(DISTINCT a.product_id)AS watch_cnt
FROM activity a JOIN purchase p USING(product_id) 
GROUP BY a.customer_id),
t2 AS 
(SELECT customer_id,
		COUNT(product_id) AS purchase_cnt
FROM purchase
GROUP BY customer_id)

SELECT t2.customer_id,
       IFNULL(watch_cnt/purchase_cnt*100, 0) AS watch_purchase_rate
FROM t2 LEFT JOIN t1 ON t1.customer_id = t2.customer_id
ORDER BY watch_purchase_rate DESC;

