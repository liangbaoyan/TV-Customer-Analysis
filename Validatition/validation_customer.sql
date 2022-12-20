USE kaggle;

SELECT *,
       CASE WHEN timestampdiff(YEAR, year_birth, NOW()) > 100 OR timestampdiff(YEAR, year_birth, NOW()) < 18 THEN 1 ELSE 0 END AS Year_birth_valid, 
       CASE WHEN ZIP code NOT IN ('528400', '528401', '528402', '528403', '528411', '528414', '528415', '528416', '528421', '528422', '528425', '528427', '528429', '528434', '528437', '528441', '528445', '528447', '528451', '528455', '528458', '528459', '528462', '528463', '528467', '528471', '528476', '528478') THEN 1 ELSE 0 END AS zipcode_valid,
       CASE WHEN gender != 'F' OR gender != 'M' THEN 1 ELSE 0 END AS gender_valid,
       CASE WHEN year_birth > DATEFOTMAT(Dt_Customer, '%Y') THEN 1 ELSE 0 END AS yb_dt_valid
FROM customer;