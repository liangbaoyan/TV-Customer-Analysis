USE kaggle;

SELECT a.product_id,
       p.Purchase_Price,
       IF(a.product_id IN (SELECT Product_ID FROM purchase), 1, 0) AS activity_valid
   FROM activity a LEFT JOIN purchase p USING(product_id);