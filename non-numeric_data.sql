/*In this chapter, we'll be working mostly with the Evanston 311 data in table evanston311. This is data on help requests submitted to the city of Evanston, IL. This data has several character and datetime columns.*/


-- Requests in category "Rodents- Rats" average over 64 days to resolve. Why? Investigate using a variety of methods and report back.

-- Explore the data
SELECT *
FROM evanston311 
WHERE category='Rodents- Rats';

-- Is there one huge infestation that's throwing off the average? Not really, though there are waves.
SELECT 
  date_trunc('month', date_created)::date AS month,
  count(*)
FROM evanston311 
WHERE category='Rodents- Rats'
GROUP BY month, category
ORDER BY month

-- Are there a small portion of extremely delayed completions that are throwing things off? Yes (average sans top 5% is 11 days rather than 64. 
SELECT  
  category,
  avg(date_completed-date_created) AS avg_completion_time
FROM evanston311
WHERE date_completed-date_created < (
  SELECT
    percentile_disc(.95) WITHIN GROUP (ORDER BY (date_completed-date_created))
  FROM evanston311
)    
GROUP BY category
ORDER BY avg_completion_time DESC;

-- Do requests made in busy months take longer to complete? Not particularly -- small but positive correlation.

-- Method #1: My instincts
WITH monthly_avgs AS(
  SELECT
    date_trunc('month', date_created) AS month,
    count(*) AS requests_per_month,
    EXTRACT(EPOCH FROM (avg(date_completed-date_created))) AS avg_completion_time
  FROM evanston311
  WHERE category='Rodents- Rats'
  GROUP BY month
)

SELECT 
    corr(avg_completion_time, requests_per_month) AS busy_rates
FROM monthly_avgs

-- Method #2: DataCamp method

SELECT 
	corr(avg_completion, count)
FROM (
	-- Subquery to create the needed variables
 	SELECT date_trunc('month', date_created) AS month, 
		avg(EXTRACT(epoch FROM date_completed - date_created)) AS avg_completion, 
		count(*) AS count
	FROM evanston311
	WHERE category='Rodents- Rats' 
	GROUP BY month
) AS monthly_avgs;


-- Are the number of requests completed constant or ever-fluctuating? More the second -- a couple of dry months and some higher months.

WITH creations AS(
     SELECT 
          date_trunc('month', date_created) AS month,
          count(*) AS num_created
     FROM evanston311
     WHERE category='Rodents- Rats'
     GROUP BY month 
),

completions AS(
     SELECT 
          date_trunc('month', date_completed) AS month,
          count(*) AS num_completed
     FROM evanston311
     WHERE category='Rodents- Rats'
     GROUP BY month 
)

SELECT 
     month::date,
     num_created,
     num_completed
FROM creations
LEFT JOIN completions
     USING(month)
ORDER BY month

-- Is it because we often do them in bulk? Yes, that's likely a factor.

SELECT 
  avg(count) AS avg,
  min(count) AS min,
  max(count) AS max
FROM (
  SELECT 
    date_trunc('day', date_completed) AS completion_date,
    count(*) AS count
  FROM evanston311
  WHERE category='Rodents- Rats'
  GROUP BY completion_date
) AS requests_per_completion

















-- What is the longest time between Evanston 311 requests being submitted?

-- Method #1: My method; technically requires you to bypass a null, but quick and easy
SELECT 
	date_created,
	date_created-lag(date_created) OVER (ORDER BY date_created) AS gap
FROM evanston311
ORDER BY gap DESC

-- Method #2: DataCamp's method; 

WITH request_gaps AS (
	SELECT date_created,
		LAG(date_created) OVER (ORDER BY date_created) AS previous,
		date_created - LAG(date_created) OVER (ORDER BY date_created) AS gap
	FROM evanston311
)

SELECT *
FROM request_gaps
-- Subquery to select maximum gap from request_gaps
 WHERE gap = (SELECT max(gap)
                FROM request_gaps);

-- Find the average number of Evanston 311 requests created per day for each month of the data. This time, do not ignore dates with no requests.

-- Method #1: My method, using one CTE with join to handle NULL values
WITH all_days AS(
	SELECT 
		a.day,
		count(e.id) AS count
	FROM (
     	-- Subquery to ensure that days with 0 requests also appear
		SELECT generate_series('2016-01-01', '2018-06-30', '1 day'::interval)::date AS day
	) AS a
	LEFT JOIN evanston311 AS e
		ON a.day=e.date_created::date
	GROUP BY day
)

SELECT 
	date_trunc('month', day)::date AS month,
	round(avg(count), 2) AS avg
FROM all_days
GROUP BY month 
ORDER BY month;

-- Method #2: DataCamp method; using two CTEs and COALESCE to handle NULL values

WITH all_days AS(
	SELECT 
		generate_series('2016-01-01', '2018-06-30', '1 day'::interval) AS date
),

daily_count AS (
	SELECT 
		date_trunc('day', date_created) AS day, 
		count(*) AS count
	FROM evanston311
	GROUP BY day
)

SELECT date_trunc('month', date) AS month,
       avg(coalesce(count, 0)) AS average
  FROM all_days
       LEFT JOIN daily_count
       ON all_days.date=daily_count.day
 GROUP BY month
 ORDER BY month;

-- Find the median number of Evanston 311 requests per day in each six month period from 2016-01-01 to 2018-06-30.

-- Creating bins of 6 month intervals
WITH time_span AS(
	SELECT
		generate_series('2016-01-01', '2018-01-01', '6 months'::interval)::date AS lower,
		generate_series('2016-07-01', '2018-07-01', '6 months'::interval)::date AS upper
),

-- Finding the total number of requests each day, including days with no requests
requests_per_day AS(
	SELECT
		d.day,
		count(e.id) AS count
	FROM (
		-- Subquery to make sure days with 0 requests are included
		SELECT generate_series('2016-01-01', '2018-06-30', '1 day'::interval)::date AS day
	) AS d
	LEFT JOIN evanston311 AS e
		ON d.day=e.date_created::date
	GROUP BY day
)

-- Finding the median number of requests across those bins
SELECT
	lower,
    upper,
    percentile_disc(.5) WITHIN GROUP(ORDER BY r.count) AS median
FROM time_span AS t
LEFT JOIN requests_per_day AS r
	ON r.day>=lower
	AND r.day<upper
GROUP BY lower, upper
ORDER BY lower;

-- Are there any days in the Evanston 311 data where no requests were created?

-- Method #1: My method, using CTE to create a series then joining it with the dataset and grouping/filtering to show only the days without requests

WITH date_range AS(
	SELECT
		generate_series(min(date_created), max(date_created), '1 day')::date AS day
	FROM evanston311
)

SELECT 
	day AS no_requests
FROM date_range AS dr 
LEFT JOIN evanston311 AS e 
	
	ON dr.day=e.date_created::date
GROUP BY day
HAVING count(id)=0;

-- Method #2: DataCamp desired outcome, using two subqueries to align data

SELECT 
	day
FROM (
	-- Subquery to generate series of all dates from min to max date
	SELECT
		generate_series(min(date_created), max(date_created), '1 day')::date AS day
		FROM evanston311
) AS all_dates
WHERE day NOT IN (
	-- Subquery to generate list of all dates in evanston in order to compare against previous list
	SELECT date_created::date FROM evanston311
)

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