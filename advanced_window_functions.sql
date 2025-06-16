/* These queries are performed in PostgreSQL using a Summer Olympics dataset, which contains the results of the games between 1896 and 2012. The first Summer Olympics were held in 1896, the second in 1900, and so on. Queries are included in reverse order below.*/

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