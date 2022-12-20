USE kaggle;

SELECT *,
       CASE WHEN endtime < starttime THEN 1 ELSE 0 END AS time_valid,
       CASE WHEN currency != 'CNY' THEN 1 ELSE 0 END AS currency_valid
  FROM promotion;