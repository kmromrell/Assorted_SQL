-- Report a list of movies that received the most attention on the movie platform, (i.e. report all movies with more than 5 ratings and all movies with an average rating higher than 8).

-- My method #1 (just answering question to get list)
SELECT 
	title,
	count(*) AS ratings_count,
	round(avg(rating), 1) AS avg_rating
FROM renting
LEFT JOIN movies USING(movie_id)
GROUP BY title
HAVING count(*)>5
	AND avg(rating)>8
	
-- My method #2 (getting all movie information for movies that fit this criteria
	
SELECT *
FROM movies
WHERE movie_id IN (
	SELECT movie_id
	FROM renting 
	GROUP BY movie_id
	HAVING 
		count(*)>5
		AND avg(rating)>8
)

-- DataCamp intended method (having two different querries, assumedly to come back to later)

WITH high_rating AS(
	SELECT *
	FROM movies AS m
	WHERE 5 < 
	    (SELECT COUNT(rating)
	    FROM renting AS r
	    WHERE r.movie_id = m.movie_id)
)
    
SELECT *
FROM movies AS m
INNER JOIN high_rating AS hr
	ON hr.movie_id=m.movie_id
WHERE 8<
	(SELECT avg(rating)
	FROM renting AS r
	WHERE r.movie_id = m.movie_id);


-- Identify customers who were not satisfied with movies they watched on MovieNow. Report a list of customers with minimum rating smaller than 4.


-- My method
SELECT
    name
FROM customers
WHERE customer_id IN (
    SELECT DISTINCT customer_id
    FROM renting
    GROUP BY customer_id 
    HAVING min(rating)<4
)

-- DataCamp intended method

SELECT *
FROM customers AS c
WHERE 4 >
	(SELECT MIN(rating)
	FROM renting AS r
	WHERE r.customer_id = c.customer_id);

-- A new advertising campaign is going to focus on customers who rented fewer than 5 movies. Use a correlated query to extract all customer information for the customers of interest.


-- My method
SELECT
    name
FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM renting
    GROUP BY customer_id 
    HAVING count(*)>5
)

-- DataCamp intended method
SELECT *
FROM customers as c
WHERE 5> 
	(SELECT count(*)
	FROM renting as r
	WHERE r.customer_id = c.customer_id);

-- For the advertising campaign your manager also needs a list of popular movies with high ratings. Report a list of movies with rating above average.

SELECT title
FROM movies
WHERE movie_id IN (
	-- A list of movies that have been watched once and are above a calculated avg
    SELECT movie_id
    FROM renting
    GROUP BY movie_id
    HAVING 
        count(*) > 1
        AND avg(rating) > (
        	-- Finding the average rating
            SELECT avg(rating)
            FROM renting
        )
)

-- Report a list of customers who frequently rent movies on MovieNow.

SELECT *
FROM customers
WHERE customer_id IN 
	(SELECT customer_id
	FROM renting
	GROUP BY customer_id
	HAVING count(*)>10);
	
-- Your manager wants you to make a list of movies excluding those which are hardly ever watched. This list of movies will be used for advertising. List all movies with more than 5 views.

SELECT DISTINCT movie_id -- Select movie IDs with more than 5 views
FROM renting
WHERE movie_id IN (
    SELECT movie_id
    FROM renting
    GROUP BY movie_id
    HAVING count(*)>5
)

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