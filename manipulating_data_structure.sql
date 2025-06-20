



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