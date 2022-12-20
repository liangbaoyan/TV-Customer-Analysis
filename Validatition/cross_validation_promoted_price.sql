USE kaggle;

SELECT p1.Promoted_Price, 
       p2.price,
   CASE WHEN p1.promoted_price > p2.price THEN 1 ELSE 0 END AS promote_valid
   FROM promotion p1 LEFT JOIN product p2 ON p1.Promoted_Product_Id = p2.Product_ID;