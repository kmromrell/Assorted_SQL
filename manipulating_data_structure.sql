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