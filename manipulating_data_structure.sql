-- All data comes from the Sakila database, a fictitional DVD rental company database


-- Identify the total number of rentals across each of the days of the week

-- Method #1
SELECT 
  EXTRACT(dow FROM rental_date) AS dayofweek,
  count(*) AS total_rentals
FROM rental 
GROUP BY 1;

-- Method #2
SELECT 
  DATE_TRUNC('day', rental_date) AS rental_day,
  COUNT(*) AS rentals 
FROM rental
GROUP BY 1;

-- Now calculate a timestamp five days from measured to the second.

SELECT
	CURRENT_TIMESTAMP(0)::timestamp AS right_now,
    interval '5 days' + CURRENT_TIMESTAMP(0) AS five_days_from_now;

--Select the current timestamp without a timezone

SELECT CAST( NOW() AS TIMESTAMP);

SELECT CURRENT_TIMESTAMP::TIMESTAMP AS right_now;

-- Calculate the expected return date of each rental

SELECT
    f.title,
	r.rental_date,
    f.rental_duration,
    INTERVAL '1' day * f.rental_duration + rental_date AS expected_return_date,
    r.return_date
FROM film AS f
    INNER JOIN inventory AS i ON f.film_id = i.film_id
    INNER JOIN rental AS r ON i.inventory_id = r.inventory_id
ORDER BY f.title;

-- Exclude films that are currently checked out and also convert the rental_duration to an INTERVAL type.

SELECT
	f.title,
    INTERVAL '1' day * rental_duration,
    r.return_date - r.rental_date AS days_rented
FROM film AS f
    INNER JOIN inventory AS i ON f.film_id = i.film_id
    INNER JOIN rental AS r ON i.inventory_id = r.inventory_id
WHERE r.return_date IS NOT NULL
ORDER BY f.title;

--Determine the number of days of each rental experience using both AGE() and subtraction

-- Method #1: AGE() function
SELECT f.title, f.rental_duration,
    -- Calculate the number of days rented
	AGE(return_date, rental_date) AS days_rented
FROM film AS f
	INNER JOIN inventory AS i ON f.film_id = i.film_id
	INNER JOIN rental AS r ON i.inventory_id = r.inventory_id
ORDER BY f.title;

-- Method #2: Basic subtraction
SELECT 
    f.title,
    f.rental_duration,
    r.return_date-r.rental_date AS days_rented
FROM rental AS r 
INNER JOIN inventory AS i USING(inventory_id)
INNER JOIN film AS f USING(film_id)
ORDERY BY f.title;

-- Use the contains operator to match the text Deleted Scenes in the special_features column.

SELECT 
  title, 
  special_features 
FROM film 
WHERE special_features @> ARRAY['Deleted Scenes'];

-- Match 'Trailers' in any index of the special_features ARRAY regardless of position.

SELECT
  title, 
  special_features 
FROM film 
WHERE 'Trailers' = ANY(special_features);

-- Now let's select all films that have Deleted Scenes in the second index of the special_features ARRAY.

SELECT 
  title, 
  special_features 
FROM film
WHERE special_features[2] = 'Deleted Scenes';

-- Select all films that have a special feature Trailers by filtering on the first index of the special_features ARRAY.

SELECT 
  title, 
  special_features 
FROM film
WHERE special_features[1] = 'Trailers';

--Select the rental date and return date from the rental table. Add an INTERVAL of 3 days to the rental_date to calculate the expected return date`.

SELECT 
	rental_date,
	rental_date+INTERVAL '3 DAY' AS expected_return_date,
	return_date 
FROM 
	rental 

-- Select the column name and data type from the INFORMATION_SCHEMA.COLUMNS system database. Limit results to only include the customer table.

SELECT 
    column_name,
    data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name='customer';

-- Select all columns from the INFORMATION_SCHEMA.COLUMNS system database. Limit by table_name to actor

 SELECT * 
 FROM INFORMATION_SCHEMA.columns
 WHERE table_name = 'actor';
 
  -- Select all columns from the INFORMATION_SCHEMA.TABLES system database. Limit results that have a public table_schema.
 
 SELECT * 
 FROM INFORMATION_SCHEMA.tables
 WHERE table_schema= 'public';