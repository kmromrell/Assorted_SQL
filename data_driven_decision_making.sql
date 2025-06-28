-- Find the oldest and youngest actors and actresses in the database, assuming they're all still alive.

SELECT 
	gender, 
	min(year_of_birth), 
	max(year_of_birth)
FROM actors
WHERE nationality='USA'
GROUP BY gender


-- What is the approximate age of each actor in the database, assuming they're all still alive?

SELECT
   name,
   EXTRACT(YEAR FROM now())-year_of_birth AS age 
FROM actors 
WHERE nationality='USA'
ORDER BY age DESC

-- How much income did each movie generate? 

SELECT 
       m.title,
       sum(renting_price) AS revenue
FROM renting AS r 
LEFT JOIN movies AS m
       USING(movie_id)
GROUP BY m.title
ORDER BY revenue DESC;

-- Create a list of actors in the database and the movies they acted in

SELECT 
    a.name,
    m.title
FROM actsin AS ai
LEFT JOIN movies AS m
ON m.movie_id = ai.movie_id
LEFT JOIN actors AS a
ON a.actor_id = ai.actor_id;

-- Find the KPIs (total revenue, total rentals, total customers) from 2018

SELECT 
	SUM(m.renting_price), 
	COUNT(*), 
	COUNT(DISTINCT r.customer_id)
FROM renting AS r
LEFT JOIN movies AS m
ON r.movie_id = m.movie_id
-- Only look at movie rentals in 2018
WHERE EXTRACT(YEAR FROM date_renting) = 2018;

--What is the average rating of customers from Belgium?

SELECT avg(rating)
FROM renting AS r
LEFT JOIN customers AS c
ON r.customer_id = c.customer_id
WHERE c.country='Belgium';

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