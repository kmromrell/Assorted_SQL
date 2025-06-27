/*In this chapter, we'll be working mostly with the Evanston 311 data in table evanston311. This is data on help requests submitted to the city of Evanston, IL. This data has several character columns.*/


-- Select the first 50 characters of description when description starts with the word "I".


-- Option 1: Universal, including MySQL
SELECT 
     CASE 
          WHEN length(description)>50 THEN left(description, 50) || '...'
          ELSE description 
     END
FROM evanston311
WHERE description LIKE 'I %'
ORDER BY description;

-- Option 2: Usable for most dialects, including PgSQL
SELECT 
     CASE 
          WHEN length(description)>50 THEN concat(left(description, 50), '...')
          ELSE description 
     END
FROM evanston311
WHERE description LIKE 'I %'
ORDER BY description;

-- Select the first word of the street value
SELECT split_part(street, ' ', 1) AS street_name, 
       count(*)
  FROM evanston311
 GROUP BY 1
 ORDER BY count DESC
 LIMIT 20;

-- Concatenate house_num, a space, and street and trim spaces from the start of the result
SELECT ltrim(concat(house_num, ' ', street)) AS address
  FROM evanston311;

-- How well does the category capture what's in the description? Determine this by finding, for the descriptions that mention trash/garbage but aren't categorized by trash/garbage, what they are most frequently categorized as?

-- Count rows with each category
SELECT category, count(*)
  FROM evanston311 
 WHERE (description ILIKE '%trash%'
    OR description ILIKE '%garbage%') 
   AND category NOT LIKE '%Trash%'
   AND category NOT LIKE '%Garbage%'
 -- What are you counting?
 GROUP BY category
 ORDER BY count DESC
 LIMIT 10;

-- Trim digits 0-9, #, /, ., and spaces from the beginning and end of street.

SELECT DISTINCT 
	street,
    trim(street, '0123456789 #/.,') AS cleaned_street
FROM evanston311
ORDER BY street;

-- Start by examining the most frequent values in some of these columns to get familiar with the common categories.

-- How many rows does each priority level have?
SELECT 
	priority, 
	count(*)
FROM evanston311
GROUP BY priority;

-- How many distinct values of zip appear in at least 100 rows?
SELECT
  zip,
  count(*)
FROM evanston311
GROUP BY zip
  HAVING(count(*)>=100);
  
-- How many distinct values of source appear in at least 100 rows?
SELECT
  source,
  count(*)
FROM evanston311
GROUP BY source
  HAVING(count(*)>=100); 
  
-- Select the five most common values of street and the count of each.
  SELECT 
  street,
  count(*) 
FROM evanston311 
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;