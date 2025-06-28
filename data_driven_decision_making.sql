-- Prepare a  report with KPIs for each country separately. Your manager is interested in the total number of movie rentals, the average rating of all movies and the total revenue for each country since the beginning of 2019.

SELECT 
	country, 
	count(*) AS number_renting,
	roun(avg(rating), 1) AS average_rating,
	sum(renting_price) AS revenue 
FROM renting AS r
LEFT JOIN customers AS c
ON c.customer_id = r.customer_id
LEFT JOIN movies AS m
ON m.movie_id = r.movie_id
WHERE date_renting >= '2019-01-01'
GROUP BY country
ORDER BY average_rating;

-- WHich actors are the Spanish customers watching most often?

SELECT 
    a.name,
    count(*)
FROM renting AS r 
JOIN customers AS c 
    USING (customer_id)
JOIN actsin AS ai
    USING (movie_id)
JOIN actors AS a 
    USING(actor_id)
WHERE c.country='Spain'
GROUP BY a.name 
ORDER BY count(*) DESC;

-- Which is the favorite movie on MovieNow? Answer this question for a specific group of customers: for all customers born in the 70s.

SELECT 
    m.title,
    round(avg(rating), 2) AS avg_rating,
    count(rating) AS count_ratings,
    count(*) AS count_rentals
FROM renting AS r 
LEFT JOIN movies AS m 
    USING(movie_id)
LEFT JOIN customers AS c 
    USING (customer_id)
WHERE EXTRACT(YEAR FROM c.date_of_birth) BETWEEN 1970 AND 1979
GROUP BY m.title
HAVING avg(rating) IS NOT NULL
ORDER BY avg_rating DESC


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