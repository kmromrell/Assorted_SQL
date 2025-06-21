-- All data comes from the Sakila database, a fictitional DVD rental company database
-- Select all columns from the pg_type table where the type name is equal to mpaa_rating.

SELECT *
FROM pg_type 
WHERE typname='mpaa_rating'

-- Select the column name, data type and udt name columns and filter by the rating column in the film table
SELECT column_name, data_type, udt_name
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_name ='film' AND column_name='rating';

-- Create an enumerated data type, compass_position, and then confirm that it's in the pg_type system table
CREATE TYPE compass_position AS ENUM (
  	'North', 
  	'South',
  	'East', 
  	'West'
);

SELECT typname, typcategory
FROM pg_type
WHERE typname='compass_position';

-- Search for "elf" in the title, retrieving those titles and descriptions

SELECT title, description
FROM film
WHERE to_tsvector(title) @@ to_tsquery('elf');


-- Select the film description as a tsvector

SELECT to_tsvector(description)
FROM film;


-- Concatenate the film and category. Generate a shortened description that doesn't go beyond 50 characters but also doesn't cut off any words.

SELECT 
  CONCAT(name, ' ', title) AS film_category,
  LEFT(description, 50 - 
    POSITION(
      ' ' IN REVERSE(
        LEFT(description, 50)
      )
    )
  )
FROM 
  film AS f 
INNER JOIN film_category AS fc 
 	ON f.film_id = fc.film_id 
 INNER JOIN category AS c 
 	ON fc.category_id = c.category_id;

-- Convert the film category name to uppercase and combine it with the title. Truncate the description 50 characters, getting rid of any leading/trailing white spaces.

SELECT 
  CONCAT(UPPER(c.name), ': ', f.title) AS film_category,
  TRIM(LEFT(f.description, 50)) AS film_desc
FROM 
  film AS f 
  INNER JOIN film_category AS fc 
  	ON f.film_id = fc.film_id 
  INNER JOIN category AS c 
  	ON fc.category_id = c.category_id;

-- Generate a combine first/last name using padded text 

-- Method #1
SELECT 
	RPAD(first_name, LENGTH(first_name)+1) || last_name AS full_name
FROM customer;

-- Method #2
SELECT 
	first_name || LPAD(last_name, LENGTH(last_name)+1) AS full_name
FROM customer; 

-- Split the email addresses into the username and the domain name

SELECT 
  SUBSTR(email, 1, POSITION('@' IN email)-1) AS username,
  SUBSTR(email, POSITION('@' IN email)+1, LENGTH(email)) AS domain
FROM customer;

-- Identify only the street name (not including the house address) from address column

SELECT 
  -- Select only the street name from the address table
  SUBSTRING(address, POSITION(' ' IN address)+1, LENGTH(address))
FROM 
  address;

-- Shorter the movie descriptions to just the first 50 characters

SELECT 
  LEFT(description, 50) AS short_desc
FROM 
  film AS f
  
-- Identify the number of characters in each film description

SELECT 
  title,
  description,
  LENGTH(description) AS desc_len
FROM film;

-- Replace whitespace in the film title with an underscore

SELECT 
  REPLACE(title, ' ', '_') AS title
FROM film; 

-- Adjust the case of the genre, title, and description, combining the genre and title into one concatenated cell.

-- Method #1: PostgreSQL only
SELECT 
  UPPER(c.name)  || ': ' || INITCAP(f.title) AS film_category, 
  LOWER(f.description) AS description
FROM 
  film AS f 
  INNER JOIN film_category AS fc 
  	ON f.film_id = fc.film_id 
  INNER JOIN category AS c 
  	ON fc.category_id = c.category_id;
  	
 -- Method #2: General SQL
 SELECT 
  CONCAT(UPPER(c.name), ': ', INITCAP(f.title)) AS film_category, 
  LOWER(f.description) AS description
FROM 
  film AS f 
  INNER JOIN film_category AS fc 
  	ON f.film_id = fc.film_id 
  INNER JOIN category AS c 
  	ON fc.category_id = c.category_id;


-- Put this all together. For each rental, identify the full name of the customer, the movie title, the rental date, the day of the week, the number of days rented, and whether or not the movie was overdue when it was turned in. All of this should apply to the same 90 day range from May 1 2005.

SELECT 
  CONCAT(c.first_name, ' ',c.last_name) AS full_name,
  f.title,
  r.rental_date,
  EXTRACT(dow FROM r.rental_date) AS dayofweek,
  AGE(r.return_date, r.rental_date) AS rental_days,
  CASE 
    WHEN DATE_TRUNC('day', AGE(return_date, rental_date))>f.rental_duration * INTERVAL '1 day' THEN 'True'
    ELSE 'False'
  END AS past_due
FROM film AS f
INNER JOIN inventory AS i 
  ON f.film_id=i.film_id
INNER JOIN rental AS r 
  ON i.inventory_id=r.inventory_id
INNER JOIN customer AS c 
  ON r.customer_id=c.customer_id
WHERE r.rental_date BETWEEN CAST('2005-05-01' AS date) AND CAST('2005-05-01' AS date) + INTERVAL '90 days';

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