USE kaggle;

SELECT *,
       CASE WHEN currency != 'CNY' THEN 1 ELSE 0 END
  FROM purchase;