/*In this chapter, we'll be working mostly with the Evanston 311 data in table evanston311. This is data on help requests submitted to the city of Evanston, IL. This data has several character and datetime columns.*/

-- Find the average number of Evanston 311 requests created per day for each month of the data. Ignore days with no requests when taking the average.

SELECT 
  date_trunc('month', day) AS month,
  avg(count)
FROM (
  SELECT 
    date_trunc('day', date_created) AS day,
    count(*)
  FROM evanston311
  GROUP BY day
) AS day_count
GROUP BY month
ORDER BY month

-- Does the time required to complete a request vary by the day of the week on which the request was created?

SELECT 
     to_char(date_created, 'day') AS day,
     avg(date_completed-date_created) AS duration 
FROM evanston311
GROUP BY day, EXTRACT(DOW FROM date_created)
ORDER BY EXTRACT(DOW FROM date_created);

-- Identify the busiest times for the Evanston 311 requests.

-- Count requests completed by hour
SELECT EXTRACT(HOUR FROM date_completed) AS hour,
       count(*)
  FROM evanston311
 GROUP BY hour
 ORDER BY hour;

-- How many requests are created in each of the 24 months during 2016-2017?
SELECT 
  EXTRACT(MONTH FROM date_created) AS month, 
  count(*)
FROM evanston311
WHERE 
  date_created>='2016-01-01'
  AND date_created<'2018-01-01'
GROUP BY month;

-- What is the most common hour of the day for requests to be created?
SELECT 
	EXTRACT(HOUR FROM date_created) AS hour,
	count(*)
FROM evanston311
GROUP BY hour
ORDER BY count(*) DESC
LIMIT 1;

-- Which category of Evanston 311 requests takes the longest to complete?

SELECT 
	category, 
	avg(date_completed-date_created) AS completion_time
FROM evanston311
GROUP BY category
ORDER BY completion_time DESC;

-- Complete the following requests for specific dates/intervals of requests

-- Select the time five minutes from now
SELECT now()+ '5 minutes'::interval;

-- Add 100 days to the current timestamp
SELECT now() + interval '100 days';

-- Add 100 days to the current timestamp
SELECT now() + '100 days'::interval;

-- How old is the most recent request?
SELECT 
  now()-max(date_created)
FROM evanston311;

-- Subtract the min date_created from the max
SELECT 
  max(date_created)-min(date_created)
FROM evanston311;

-- Count requests created on January 31, 2017
SELECT count(*) 
FROM evanston311
WHERE date_created::date='2017-01-31';

-- Count requests created on February 29, 2016
SELECT count(*)
FROM evanston311 
WHERE 
	date_created::date >= '2016-02-29' 
	AND date_created::date < '2016-03-01';
   
-- Count requests created on March 13, 2017
SELECT count(*)
FROM evanston311
WHERE 
	date_created >= '2017-03-13'
	AND date_created < '2017-03-13'::date + interval '1 day';

-- Determine whether medium and high priority requests in the evanston311 data are more likely to contain requesters' contact information: an email address or phone number.

-- Method #1: My initial attempt using CASE to create and immediately use boolean variables

 SELECT 
	priority,
	sum(CASE 
		WHEN description LIKE '%@%' THEN 1
		ELSE 0
		END)/count(*)::numeric AS phone_ratio,
	sum(CASE 
		WHEN description LIKE '%___-___-____%' THEN 1
		ELSE 0
    END)/count(*)::numeric AS email_ratio
FROM evanston311
GROUP BY priority
ORDER BY phone_ratio DESC

-- Method #2: Datacamp's intent using temporary tables and CAST

-- To clear table if it already exists
DROP TABLE IF EXISTS indicators;

-- Create the temp table
CREATE TEMP TABLE indicators AS
	SELECT id, 
		CAST (description LIKE '%@%' AS integer) AS email,
		CAST (description LIKE '%___-___-____%' AS integer) AS phone 
	FROM evanston311;

-- Compute ratio and aggregate the data
SELECT priority,
	sum(email)/count(*)::numeric AS email_prop, 
	sum(phone)/count(*)::numeric AS phone_prop
FROM evanston311
LEFT JOIN indicators
	ON evanston311.id=indicators.id
GROUP BY priority;

-- There are almost 150 distinct values of evanston311.category. But some of these categories are similar, with the form "Main Category - Details". We can get a better sense of what requests are common if we aggregate by the main category.

-- Drop table if already exists
DROP TABLE IF EXISTS recode;

-- Create table with first standardizations
CREATE TEMP TABLE recode AS
	SELECT DISTINCT 
		category, 
		rtrim(split_part(category, '-', 1)) AS standardized
	FROM evanston311;

-- Update table with additioanl standardizations
UPDATE recode 
SET standardized='Trash Cart' 
WHERE standardized LIKE 'Trash%Cart';

UPDATE recode 
SET standardized='Snow Removal' 
WHERE standardized LIKE 'Snow%Removal%';

UPDATE recode 
SET standardized='UNUSED' 
WHERE standardized IN (
	'THIS REQUEST IS INACTIVE...Trash Cart', 
	'(DO NOT USE) Water Bill',
	'DO NOT USE Trash', 
	'NO LONGER IN USE'
);

-- Join tables to use new standardized categories
SELECT 
	standardized,
	count(*)
FROM evanston311 
LEFT JOIN recode USING(category)
GROUP BY standardized 
ORDER BY count DESC;

-- Organize data by zipcode. If a zipcode comes up less than 100 times, organize it into an "Other" category

SELECT 
	CASE 
		WHEN zipcount < 100 THEN 'other'
    	ELSE zip
    END AS zip_recoded,
	sum(zipcount) AS zipsum
FROM (
	SELECT 
		zip, 
		count(*) AS zipcount
	FROM evanston311
	GROUP BY zip
) AS fullcounts
 GROUP BY zip_recoded
 ORDER BY zipsum DESC;

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