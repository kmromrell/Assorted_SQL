/* These queries are performed in PostgreSQL using a Summer Olympics dataset, which contains the results of the games between 1896 and 2012. The first Summer Olympics were held in 1896, the second in 1900, and so on. Queries are included in reverse order below.*/


-- Generate a breakdown of the medals awarded to Russia per gender and medal type in 2012, including all group-level subtotals and a grand total.


SELECT
  gender,
  medal,
  count(*) AS medals
FROM summer_medals
WHERE
  Year = 2012
  AND country = 'RUS'
GROUP BY CUBE(gender, medal)
ORDER BY gender ASC, medal ASC;

-- Identify the number of gold medals earned by three Scandinavian countries by gender in the year 2004. Retrieve totals grouped by country and gender as well as country totals.

SELECT 
  coalesce(country, 'All') AS country,
  coalesce(gender, 'Total') AS gender,
  count(*) AS gold_medals
FROM summer_medals 
WHERE 
  year=2004
  AND medal='Gold'
  AND country IN ('DEN', 'NOR', 'SWE')
GROUP BY country, ROLLUP(gender)
ORDER BY country, gender;

-- Produce a table of the rankings of the three most populous EU countries by how many gold medals they've earned in the 2004 through 2012 Olympic games. The table should be in a wide data format, with the years as columns.

CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT *
FROM CROSSTAB($$
  WITH country_medals AS ( 
    SELECT
      country,
      year,
      count(medal) AS medals
    FROM summer_medals 
    WHERE 
      country IN ('FRA', 'GBR', 'GER')
      AND medal='Gold'
      AND year IN (2004, 2008, 2012)
    GROUP BY country, year
  )

  SELECT 
    country,
    year,
    RANK() OVER(PARTITION BY year ORDER BY medals DESC) AS ranked_medals
  FROM country_medals
  ORDER BY country, year
$$) AS ct (country VARCHAR,
          "2004" BIGINT,
          "2008" BIGINT,
          "2012" BIGINT)

-- Create a table that show the gold medal-winning countries of 2008 and 2012 in the Pole Vault. Then pivtor that table to format the data in a wide table with years as columns.

CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT *
FROM CROSSTAB($$
  SELECT
    gender,
    year,
    country
  FROM summer_medals
  WHERE 
    event='Pole Vault'
    AND medal='Gold'
    AND year IN ('2008', '2012')
  ORDER BY gender, year
$$) AS ct (gender VARCHAR,
          "2008" VARCHAR,
          "2012" VARCHAR)
ORDER BY gender;


-- Calculate the 3-year moving sum of medals earned per country ordered by country and year

WITH country_medals AS (
  SELECT 
    year,
    country,
    count(*) AS medals
  FROM summer_medals
  GROUP BY year, country 
)

SELECT 
  year,
  country,
  medals,
  SUM(medals) OVER(
    PARTITION BY country 
    ORDER BY year 
    ROWS BETWEEN 2 PRECEDING 
    AND CURRENT ROW
  ) AS medals_ms
FROM country_medals 
ORDER BY country, year;

-- Calculate the 3-year moving average of Gold medals earned by Russia since 1980.

WITH russian_medals AS (
  SELECT 
    year,
    count(*) AS medals 
  FROM summer_medals 
  WHERE 
    country='RUS'
    AND medal='Gold'
    AND year>=1980
  GROUP BY year 
)

SELECT 
  year,
  medals,
  ROUND(AVG(medals) OVER(ORDER BY year
    ROWS BETWEEN 2 PRECEDING
    AND CURRENT ROW), 1) AS medals_ma
FROM russian_medals 
ORDER BY year;

-- Return the year, medals earned, and the maximum gold medals earned for Chinese athletes since 2000, considering only the current row and previous two rows

WITH chinese_medals AS(
  SELECT 
    athlete,
    count(*) AS medals
  FROM summer_medals 
  WHERE 
    country='CHN'
    AND medal = 'Gold'
    AND year >= 2000
  GROUP BY athlete
)

SELECT 
  athlete,
  medals,
  max(medals) OVER(ORDER BY athlete ASC ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS max_medals 
FROM chinese_medals 
ORDER BY athlete;

-- Return the year, medals earned, and the maximum gold medals earned for Scandinavian countries, comparing only the current year and the next year.


WITH scandinavian_medals AS (
  SELECT 
    year,
    count(*) AS medals
  FROM summer_medals
  WHERE 
    country IN ('DEN', 'NOR', 'FIN', 'SWE', 'ISL')
    AND medal = 'Gold' 
  GROUP BY year
)

SELECT 
  year,
  medals,
  max(medals) OVER(ORDER BY year ASC
  	ROWS BETWEEN CURRENT ROW
    AND 1 FOLLOWING) AS max_medals
FROM scandinavian_medals
ORDER BY year;

-- Identify France's running minimum gold medals since 2000. Return the year, medals earned, and minimum medals earned so far.

WITH france_medals AS (
  SELECT 
    year,
    count(*) AS medals
  FROM summer_medals 
  WHERE 
    country='FRA'
    AND medal='Gold'
    AND year>=2000
  GROUP BY year
)

SELECT 
  year,
  medals,
  MIN(medals) OVER (ORDER BY year) AS min_medals 
FROM france_medals 
ORDER BY year;


-- Return the year, country, medals, and the maximum medals earned so far for each country (Korea, Japan, and China), ordered by year in ascending order.

WITH country_medals AS (
  SELECT 
    year,
    country,
    count(*) AS medals
  FROM summer_medals 
  WHERE 
    country IN ('CHN', 'KOR', 'JPN')
    AND medal = 'Gold' 
    AND year >= 2000
  GROUP BY country, year
)

SELECT 
  year,
  country, 
  medals,
  MAX(medals) OVER(PARTITION BY country 
    ORDER BY country, year) AS running_record
FROM country_medals 
ORDER BY country, year;

-- Identify American gold medalists from 2000 on, the total number of medals won by each athlete, and the total medals (sorted by athlete's name in alphabetical order).

WITH athlete_medals AS (
  SELECT
    athlete,
    count(medal) AS medals
  FROM summer_medals 
  WHERE
    Country = 'USA' 
    AND Medal = 'Gold'
    AND Year >= 2000
  GROUP BY athlete
)

SELECT 
  athlete,
  medals,
  SUM(medals) OVER(ORDER BY athlete ASC)  AS total_medals
FROM athlete_medals 
ORDER BY athlete ASC; 

-- Find aggregated average of each third of the highest medal-winning Olympians who have won more than one model

WITH athlete_medals AS (
  SELECT 
    athlete, 
    COUNT(*) AS medals
  FROM summer_medals
  GROUP BY athlete
  HAVING COUNT(*) > 1
),
  
thirds AS (
  SELECT
    athlete,
    medals,
    NTILE(3) OVER (ORDER BY medals DESC) AS Third
  FROM athlete_medals
)
  
SELECT
  -- Get the average medals earned in each third
  third,
  avg(medals) AS Avg_Medals
FROM thirds
GROUP BY third
ORDER BY third ASC;

-- Label a distinct list of all events into three pages by alphabetical event

-- Method #1 (my way, subquery in FROM)

SELECT
  event,
  NTILE(3) OVER(ORDER BY event) AS page
FROM (
  SELECT DISTINCT event FROM summer_medals
) AS events 
ORDER BY event;

-- Method #2 (datacamp, CTE)

WITH Events AS (
  SELECT DISTINCT Event
  FROM Summer_Medals)
  
SELECT
  event,
  NTILE(3) OVER (ORDER BY event ASC) AS Page
FROM Events
ORDER BY Event ASC;


-- Rank medalists in Japan and Korea by number of medals they wons ince 2000

WITH athlete_medals AS (
  SELECT
    country, 
    athlete, 
    COUNT(*) AS medals
  FROM summer_medals
  WHERE
    country IN ('JPN', 'KOR')
    AND year >= 2000
  GROUP BY country, athlete
  HAVING COUNT(*) > 1)

SELECT
  country,
  athlete, 
  DENSE_RANK() OVER (PARTITION BY country
    ORDER BY medals DESC) AS rank_n
FROM athlete_medals
ORDER BY country ASC, rank_n ASC;

-- Return all male gold medalists and the first athlete ordered by alphabetical order.

WITH all_male_medalists AS (
  SELECT DISTINCT
    athlete
  FROM summer_medals
  WHERE 
    gender='Men'
    AND medal='Gold'
)

SELECT 
  athlete,
  FIRST_VALUE(athlete) OVER(
    ORDER BY athlete ASC
  ) AS first_athlete
FROM all_male_medalists;

-- Use LEAD to show the current discus champion and the champion 3 Olympics from then

WITH discus_medalist AS (
  SELECT 
    year,
    athlete AS champion
  FROM summer_medals
  WHERE 
    medal='Gold'
    AND Event = 'Discus Throw'
    AND Gender = 'Women'
    AND Year >= 2000
)

SELECT
  year,
  champion,
  LEAD(champion, 3) OVER(ORDER BY year) AS future_champion
FROM discus_medalist
ORDER BY year;


-- Identify reigning champions (champion countries who win multiple olympics in a row) for tennis, partitioned by gender and event

WITH last_year_champion AS (
  SELECT  
    year,
    champion,
    gender,
    event,
    LAG(champion, 1) OVER(PARTITION BY gender, event ORDER BY year) AS last_champion
  FROM (
    SELECT DISTINCT
      year,
      gender,
      event,
      country AS champion
    FROM summer_medals 
    WHERE sport='Tennis'
    AND medal='Gold'
  ) AS tennis_gold
) 

SELECT 
  year,
  gender,
  event,
  champion,
  CASE 
    WHEN champion=last_champion THEN 'Reigning Champ'
    ELSE NULL
  END AS reigning_champ 
FROM last_year_champion
ORDER BY gender, event, year;


-- Identify reigning champions (champion countries who win multiple olympics in a row) for the 60kg men's weighlifting event

WITH last_year_champion AS(
  SELECT
    year,
    champion,
    LAG(champion, 1) OVER(ORDER BY year ASC) AS last_champion
  FROM(
    SELECT 
    year,
    country AS champion
  FROM summer_medals 
  WHERE 
    sport = 'Weightlifting'
    AND event = '69KG'
    AND gender='Men'
    AND medal='Gold'
  ) AS weightlifting_gold
)

SELECT 
  year,
  champion,
  CASE 
    WHEN champion=last_champion THEN 'Reigning Champ'
    ELSE NULL
  END AS reigning_champ 
FROM last_year_champion
ORDER BY year


-- Identify and rank the athletes who have earned the most medals in the summer olympics

-- Method #1: My way (subquery in FROM, RANK)

SELECT 
  athlete,
  medals,
  RANK() OVER(ORDER BY medals DESC)
FROM (
  SELECT 
    athlete,
    COUNT(medal) AS medals
  FROM summer_medals 
  GROUP BY athlete
) AS athlete_medals;

-- Method #2: DataCamp method (CTE, ROW_NUMBER)

WITH athlete_medals AS (
  SELECT 
    athlete,
    count(medal) AS medals
  FROM summer_medals
  GROUP BY athlete
)

SELECT 
  athlete,
  ROW_NUMBER() OVER(ORDER BY medals DESC) AS row_n,
  medals
FROM athlete_medals;

-- Write a query to number each distinct summer olympics in reverse order.

SELECT
  year,
  ROW_NUMBER() OVER (ORDER BY year DESC) AS Row_N
FROM (
  SELECT DISTINCT year
  FROM summer_medals
) AS years
ORDER BY year;


-- Write a query to number each distinctive summer olympics so far.

SELECT DISTINCT
  year,
  ROW_NUMBER() OVER () AS row_n
FROM (
  SELECT DISTINCT year
  FROM summer_medals
  ORDER BY year
) AS years
ORDER BY year ASC;

-- Write a query to add row numbers to each row in the table.

SELECT
  *,
 ROW_NUMBER() OVER() AS row_n
FROM summer_medals
ORDER BY row_n ASC;