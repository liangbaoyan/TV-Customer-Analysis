USE kaggle;

SELECT c.Dt_Customer,
        p.Purchase_Date,
        IF(c.Dt_Customer > p.Purchase_Date, 1, 0) AS dt_pur_valid
  FROM customer c JOIN purchase p ON P.Customer_ID = C.Customer_ID;