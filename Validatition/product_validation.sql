USE kaggle;

SELECT *,
       CASE WHEN YEAR(ReleaseDateTime) < year THEN 1 ELSE 0 END AS release_valid,
       CASE WHEN currency != 'CNY' THEN 1 ELSE 0 END AS currency_valid,
       CASE WHEN price < 0 THEN 1 ELSE 0 END AS price_valid
  FROM product;