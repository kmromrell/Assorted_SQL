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