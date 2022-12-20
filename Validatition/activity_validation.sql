USE kaggle;

SELECT *,
       IF(
       (SELECT Video_Time_Occuption 
         FROM activity a JOIN product p ON a.product_id = p.product_id
		 WHERE p.type = 'movie') > 300, 1, 0 ) AS video_valid
  FROM activity;