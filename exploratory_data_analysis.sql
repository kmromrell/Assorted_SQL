-- All data is coming from a fortune500 database with information from 2017.

-- For example, how does the maximum value per group vary across groups? To find out, first summarize by group, and then compute summary statistics of the group results.

SELECT
	stddev(maxval),
	min(maxval),
	max(maxval),
	avg(maxval)
FROM(
	SELECT 
		tag,
		max(question_count) AS maxval 
	FROM stackoverflow
	GROUP BY tag
) AS maxresults;

-- Summarize each sector's profit column in the fortune500 table using the functions you've learned.

SELECT 
	sector,
	min(profits),
	avg(profits),
	max(profits),
	stddev(profits)
FROM fortune500
GROUP BY sector
ORDER BY avg DESC;

-- Determine if unanswered_pct is the percent of questions with the tag that are unanswered (unanswered ?s with tag/all ?s with tag) or if it's something else.

-- Method #1: Universal
SELECT 
     cast(unanswered_count AS numeric)/question_count  AS computed_pct,
     unanswered_pct
FROM stackoverflow
WHERE question_count !=0;

-- Method #2: PgSQL only
SELECT 
	sector, 
	avg(cast(revenues AS numeric)/employees) AS avg_rev_employee
FROM fortune500
GROUP BY sector
ORDER BY avg_rev_employee DESC;

-- Compute the average revenue per employee for Fortune 500 companies by sector.

-- Method #1: Universal
SELECT 
	sector, 
	avg(cast(revenues AS numeric)/employees) AS avg_rev_employee
FROM fortune500
GROUP BY sector
ORDER BY avg_rev_employee DESC;

-- Method #2: PgSQL only
SELECT 
	sector, 
	avg(revenues/employees::numeric) AS avg_rev_employee
FROM fortune500
GROUP BY sector
ORDER BY avg_rev_employee DESC;


-- Was 2017 a good or bad year for revenue of Fortune 500 companies? Examine how revenue changed from 2016 to 2017 to determine your answer.

-- Method #1: My answer

SELECT
  count(*) AS count,
  avg(revenues_change) AS avg,
  CASE
    WHEN revenues_change<0 THEN 'decrease'
    WHEN revenues_change>0 THEN 'increase'
    ELSE 'no change'
  END AS change
FROM fortune500
GROUP BY change
ORDER BY avg;

-- Method #2: Datacamp's response

SELECT revenues_change::integer, count(revenues_change::integer)
  FROM fortune500
 GROUP BY revenues_change::integer
 ORDER BY revenues_change::integer;

SELECT count(*)
  FROM fortune500
 WHERE revenues_change>0;

-- Identify the difference between dividing an integer by 10 and dividing the original numeric data by 10

WITH casted_profits AS (
     SELECT   
          profits_change,
          CAST(profits_change AS integer) AS profits_change_int
     FROM fortune500
) 

SELECT
     profits_change/10 AS division,
     profits_change_int/10 AS int_division
FROM casted_profits

-- In the fortune500 data, industry contains some missing values. Replace any missing data in industry with the data from sector. Then find the most common industry.

SELECT 
	coalesce(industry, sector, 'Unknown') AS industry2,
    count(*) AS count 
FROM fortune500 
GROUP BY industry2
ORDER BY count DESC
LIMIT 1;

-- First, using the tag_type table, count the number of tags with each type. Order the results to find the most common tag type. Then enerate a list of companies using the most common tag type, joining together the necessary tables

SELECT  
  type,
  count(*) AS total
FROM tag_type
GROUP BY type
ORDER BY total DESC;

SELECT 
  c.name,
  tt.tag,
  tt.type
FROM company AS c
  INNER JOIN tag_company AS tc 
    ON c.id=tc.company_id
  INNER JOIN tag_type AS tt 
    ON tc.tag=tt.tag
WHERE type='cloud'; 

-- Using the entity relationship diagram, find the foreign key(s) aligning fortune500 to company and join them to show records that show up in both tables

SELECT *
FROM fortune500 
INNER JOIN company USING(ticker)


-- Does column ticker or industry have more missing values?

SELECT 
	count(*)-count(ticker) AS missing_ticker,
	count(*)-count(industry) AS missing_industry
FROM fortune500