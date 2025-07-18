-- Data-driven decision making. 

/*Data for the following queries comes from a fictious online movie rental company, MovieNow, in which customers can rent a movie for 24 hours. It contains tables with information about the movies, customers, rentals, and actors. All queries are listed in reverse order below to show more advanced queries at the top.*/

-- The last aspect you have to analyze are customer preferences for certain actors.

SELECT 
	a.nationality,
	a.gender,
	avg(r.rating) AS avg_rating,
	count(r.rating) AS n_rating,
	count(*) AS n_rentals,
	count(DISTINCT a.actor_id) AS n_actors
FROM renting AS r
LEFT JOIN actsin AS ai
	ON ai.movie_id = r.movie_id
LEFT JOIN actors AS a
	ON ai.actor_id = a.actor_id
WHERE r.movie_id IN ( 
	SELECT movie_id
	FROM renting
	GROUP BY movie_id
	HAVING COUNT(rating) >=4 )
AND r.date_renting >= '2018-04-01'
GROUP BY CUBE(nationality, gender);

--  Now the management considers investing money in movies of the best rated genres.

SELECT 
	genre,
	AVG(rating) AS avg_rating,
	COUNT(rating) AS n_rating,
	COUNT(*) AS n_rentals,     
	COUNT(DISTINCT m.movie_id) AS n_movies 
FROM renting AS r
LEFT JOIN movies AS m
	ON m.movie_id = r.movie_id
WHERE r.movie_id IN ( 
	SELECT movie_id
	FROM renting
	GROUP BY movie_id
	HAVING COUNT(rating) >= 3 )
AND r.date_renting >= '2018-01-01'
GROUP BY genre
ORDER BY avg_rating DESC;

-- Now you will investigate the average rating of customers aggregated by country and gender.

SELECT 
	c.country, 
    c.gender,
	AVG(r.rating)
FROM renting AS r
LEFT JOIN customers AS c
	ON r.customer_id = c.customer_id
GROUP BY GROUPING SETS ((country, gender), (country), (gender), ());


-- We are interested in how much diversity there is in the nationalities of the actors and how many actors and actresses are in the list.

SELECT 
    gender,
    nationality,
    count(*)
FROM actors
GROUP BY GROUPING SETS ((nationality), (gender), ())


-- You are asked to study the preferences of genres across countries. Are there particular genres which are more popular in specific countries? Evaluate the preferences of customers by averaging their ratings and counting the number of movies rented from each genre.

SELECT 
    country,
    genre,
    avg(rating),
    count(*)
FROM renting 
JOIN movies
    USING(movie_id)
JOIN customers
    USING(customer_id)
GROUP BY ROLLUP (country, genre)
ORDER BY country, genre

-- You have to give an overview of the number of customers for a presentation. Generate a table with the total number of customers, the number of customers for each country, and the number of female and male customers for each country.

SELECT 
	country,
	gender,
	COUNT(*)
FROM customers
GROUP BY ROLLUP(country, gender)
ORDER BY country, gender; -- Order the result by country and gender


-- Give an overview on the movies available on MovieNow. List the number of movies for different genres and release years.

SELECT 
	c.country, 
	m.genre, 
	AVG(r.rating) AS avg_rating
FROM renting AS r
LEFT JOIN movies AS m
ON m.movie_id = r.movie_id
LEFT JOIN customers AS c
ON r.customer_id = c.customer_id
GROUP BY CUBE(country, genre);

-- Give an overview on the movies available on MovieNow. List the number of movies for different genres and release years.

SELECT 
	genre,
	year_of_release,
	count(*)
FROM movies
GROUP BY CUBE(genre, year_of_release)
ORDER BY year_of_release;

-- The advertising team has a new focus. They want to draw the attention of the customers to dramas. Make a list of all movies that are in the drama genre and have an average rating higher than 9. Give the full movie information.

-- Method #1: My instinctual method

SELECT *
FROM movies
WHERE 
	genre='Drama'
	AND movie_id IN (
	SELECT
		movie_id
	FROM renting
	GROUP BY movie_id
	HAVING avg(rating)>9
)

-- Method #2: DataCamp's intended method

SELECT *
FROM movies
WHERE movie_id IN -- Select all movies of genre drama with average rating higher than 9
   (SELECT movie_id
    FROM movies
    WHERE genre = 'Drama'
    INTERSECT
    SELECT movie_id
    FROM renting
    GROUP BY movie_id
    HAVING AVG(rating)>9);

-- Identify actors who are not from the USA or who were born after 1990.

-- Method #1: My instinctual method
SELECT 
	name,
	nationality,
	year_of_birth
FROM actors 
WHERE 
	nationality!='USA'
	OR year_of_birth>1990
     
-- Method #2: DataCamp's intended method
SELECT 
	name, 
	nationality, 
	year_of_birth
FROM actors
WHERE nationality <> 'USA'
UNION
SELECT 
	name, 
	nationality, 
	year_of_birth
FROM actors
WHERE year_of_birth > 1990;

-- In order to analyze the diversity of actors in comedies, first, report a list of actors who play in comedies and then the number of actors for each nationality playing in comedies.

-- My method

SELECT 
    nationality,
    count(*)
FROM actors 
WHERE actor_id IN (
    SELECT actor_id
    FROM actsin
    LEFT JOIN movies 
        USING(movie_id)
    WHERE genre='Comedy'
)
GROUP BY nationality
ORDER BY count DESC;

-- DataCamp intended method

SELECT 
    a.nationality,
    count(*)
FROM actors AS a
WHERE EXISTS(
    SELECT *
    FROM actsin AS ai
    LEFT JOIN movies 
        USING(movie_id)
    WHERE genre='Comedy'
    AND ai.actor_id=a.actor_id
)
GROUP BY a.nationality
ORDER BY count DESC;

-- Having active customers is a key performance indicator for MovieNow. Make a list of customers who gave at least one rating.

SELECT *
FROM customers AS c
WHERE EXISTS (
    SELECT *
    FROM renting AS r
    WHERE rating IS NOT NULL
    AND c.customer_id=r.customer_id
)

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