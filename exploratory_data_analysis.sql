-- All data is coming from a fortune500 database with information from 2017.


-- Compute the correlations between each pair of profits, profits_change, and revenues_change from the Fortune 500 data, creating a correlation matrix. For some reason, don't do this in R, where this would be super easy, but instead make an overly complicated query in SQL to try to mimic the results.

DROP TABLE IF EXISTS correlations;

CREATE TEMP TABLE correlations AS
SELECT 'profits'::varchar AS measure,
       corr(profits, profits) AS profits,
       corr(profits, profits_change) AS profits_change,
       corr(profits, revenues_change) AS revenues_change
  FROM fortune500;

INSERT INTO correlations
SELECT 'profits_change'::varchar AS measure,
       corr(profits_change, profits) AS profits,
       corr(profits_change, profits_change) AS profits_change,
       corr(profits_change, revenues_change) AS revenues_change
  FROM fortune500;

INSERT INTO correlations
SELECT 'revenues_change'::varchar AS measure,
       corr(revenues_change, profits) AS profits,
       corr(revenues_change, profits_change) AS profits_change,
       corr(revenues_change, revenues_change) AS revenues_change
  FROM fortune500;

SELECT measure, 
       round(profits::numeric, 2) AS profits,
       round(profits_change::numeric, 2) AS profits_change,
       round(revenues_change::numeric, 2) AS revenues_change
  FROM correlations;

-- Find out how many questions had each tag on the first date for which data for the tag is available, as well as how many questions had the tag on the last day. 

-- Method #1: My initial work; use CTE to give mindate/maxdate to filter by; pivot data using CROSSTAB
CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT *
FROM CROSSTAB($$ 
  WITH dates AS(
    SELECT
      tag,
      min(date) AS mindate,
      max(date) AS maxdate
    FROM stackoverflow
    GROUP BY tag
  )

  SELECT
    tag,
    date,
    question_count
  FROM stackoverflow
  LEFT JOIN dates USING(tag)
  WHERE 
    date=mindate
    OR date=maxdate
  ORDER BY tag, date 
$$) AS pivoted_date 
        (tag VARCHAR, 
        "mindate" integer, 
        "maxdate" integer);
        
-- Method #2: What DataCamp was going for

DROP TABLE IF EXISTS startdates;

CREATE TEMP TABLE startdates AS
SELECT tag, min(date) AS mindate
  FROM stackoverflow
 GROUP BY tag;
 
SELECT startdates.tag, 
       startdates.mindate, 
	   so_min.question_count AS min_date_question_count,
       so_max.question_count AS max_date_question_count,
       so_max.question_count - so_min.question_count AS change
  FROM startdates
       INNER JOIN stackoverflow AS so_min
          ON startdates.tag = so_min.tag
         AND startdates.mindate = so_min.date
       INNER JOIN stackoverflow AS so_max
          ON startdates.tag = so_max.tag
         AND so_max.date = '2018-09-25';


-- Use a temporary table to find the Fortune 500 companies that have profits in the top 20% for their sector (compared to other Fortune 500 companies). Include a ratio of the company's profits to the 80th percentile.

CREATE TEMPORARY TABLE profit80 AS
  SELECT 
    sector,
    percentile_disc(.8) WITHIN GROUP (ORDER BY profits) AS profit_at_80
  FROM fortune500
  GROUP BY sector;

SELECT 
  f.title,
  f.sector,
  f.profits,
  profits/profit_at_80 AS ratio
FROM fortune500 AS f 
LEFT JOIN profit80 AS p80 
  USING(sector)
WHERE f.profits>=p80.profit_at_80
ORDER BY ratio DESC;

-- Compute the mean and median assets of Fortune 500 companies by sector.

SELECT 
	sector,
	avg(assets) AS mean,
	percentile_cont(.5) WITHIN GROUP (ORDER BY assets) AS median
FROM fortune500
GROUP BY sector
ORDER BY mean;

-- Find the two-way correlations between revenues, profits, and assets

SELECT corr(revenues, profits) AS rev_profits,
       corr(revenues, assets) AS rev_assets,
       corr(revenues, equity) AS rev_equity 
  FROM fortune500;

-- Summarize the distribution of the number of questions with the tag "dropbox" on Stack Overflow per day by binning the data. 

-- Method #1: My way of going about it

-- Exploring the data to get actionable ranges
SELECT 
     count(*),
     min(question_count),
     max(question_count),
     avg(question_count)
FROM stackoverflow
WHERE tag='dropbox'

-- Creating bins
WITH bins AS(
     SELECT 
     	-- intentionally including an empty bin above and below to show that this is the full range
		generate_series(2200, 3100, 100) AS lower,
		generate_series(2300, 3200, 100) AS upper
),

filtered_questions AS(
	SELECT question_count 
	FROM stackoverflow 
	WHERE tag='dropbox'
)

-- Organizing the data by bins
SELECT
     lower,
     upper,
     count(question_count)
FROM filtered_questions
LEFT JOIN bins
     ON question_count>=lower 
     AND question_count<upper
GROUP BY lower, upper
ORDER BY lower;


-- Method #2: DataCamp's desired outcome

WITH bins AS (
      SELECT generate_series(2200, 3050, 50) AS lower,
             generate_series(2250, 3100, 50) AS upper),
     dropbox AS (
      SELECT question_count 
        FROM stackoverflow
       WHERE tag='dropbox') 
SELECT lower, upper, count(question_count) 
  FROM bins
       LEFT JOIN dropbox
         ON question_count>=lower 
        AND question_count<upper
 GROUP BY lower, upper
 ORDER BY lower;


-- Use trunc() to examine the distributions of employees in the Fortune 500 companies. What range do most companies fall into?

SELECT 
  trunc(employees, -5) AS employee_bin_100k,
  count(trunc(employees, -5)) AS count
FROM fortune500
GROUP BY 1
ORDER BY 1;

SELECT 
  trunc(employees, -4) AS employee_bin_10k,
  count(trunc(employees, -4)) AS count
FROM fortune500
WHERE employees<100000
GROUP BY 1
ORDER BY 1; 


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