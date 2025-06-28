-- Which customers gave hte lowest average rating, and how many rental/ratings have they had?

SELECT customer_id, 
      avg(rating), 
      count(rating), 
      count(*) 
FROM renting
GROUP BY customer_id
HAVING count(*)>7 
ORDER BY avg(rating); 

-- What is the average rating of each movie rental, and how many views/ratings does it have?

SELECT movie_id, 
       AVG(rating) AS avg_rating,
       COUNT(rating) AS number_ratings,
       COUNT(*) AS number_renting
FROM renting
GROUP BY movie_id
ORDER BY avg_rating DESC;

-- When did MovieNow break into each company?

SELECT 
	country,
	min(date_account_start) AS first_account
FROM customers
GROUP BY country
ORDER BY first_account;