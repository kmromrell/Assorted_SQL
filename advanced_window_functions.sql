/* These queries are performed in PostgreSQL using a Summer Olympics dataset, which contains the results of the games between 1896 and 2012. The first Summer Olympics were held in 1896, the second in 1900, and so on. */
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