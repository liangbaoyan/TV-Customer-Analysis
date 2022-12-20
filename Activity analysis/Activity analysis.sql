
-- Step 1. Left outer join CustomerId and Left outer join ProductId to get a large table
-- Step 2. Output this large table as excel/csv

SELECT *
FROM activity a LEFT JOIN customer c ON a.customer_id = c.customer_id
				LEFT JOIN product p ON p.product_id = a.product_id;