-- Find the currencies used by the countries in Oceania

SELECT basic_unit
FROM currencies
WHERE code IN   (
    SELECT code
    FROM countries
    WHERE continent='Oceania'
);

-- Identify Oceanic countries listed in countries table but not in currencies table

SELECT 
	code, 
	name
FROM countries
WHERE continent = 'Oceania'
  AND code NOT IN (
  	SELECT code
    FROM currencies
);

-- Identify which countries had higher average life expectancies (more than 1.15x) in 2015
SELECT *
FROM populations
WHERE year = 2015
  AND life_expectancy > 1.15 *
  (SELECT AVG(life_expectancy)
   FROM populations
   WHERE year = 2015) ;
	
-- Identify the largest city populations of only capital cities
SELECT 
    name, 
    urbanarea_pop
FROM cities
WHERE name IN (
    SELECT capital
    FROM countries
)
ORDER BY urbanarea_pop DESC;

-- Identify the countries with the most documented city populations in them

--Method 1: Joins

SELECT
   c1.name AS country,
   count(c2.name) AS cities_num
FROM countries AS c1 
LEFT JOIN cities AS c2
    ON c1.code=c2.country_code
GROUP BY c1.name
ORDER BY 
    cities_num DESC, 
    country
LIMIT 9;

--Method 2: Subquery

SELECT 
  countries.name AS country,
  (
    SELECT count(*)
    FROM cities
    WHERE cities.country_code=countries.code
  ) AS cities_num
FROM countries
ORDER BY cities_num DESC, country
LIMIT 9;

-- Identify the number of languages spoken in each country, identifying with its local name

--Method #1: Subquery within SELECT (same answer but more processing power)

SELECT 
    (
        SELECT local_name 
        FROM countries
        WHERE languages.code=countries.code
    ),
    count(name) AS lang_num  
FROM languages
GROUP BY code
ORDER BY lang_num DESC

--Method #2: Subquery within SELECT
SELECT
  local_name,
  lang_num
FROM 
  countries,
  (SELECT code, COUNT(*) AS lang_num
  FROM languages
  GROUP BY code) AS sub
-- Where codes match
WHERE countries.code=sub.code
ORDER BY lang_num DESC

-- Identify the 2015 inflation and unemployment rate for Republics and Monarchies

-- Method #1: Subquery in FROM statement (my solution)

SELECT
  economies.code,
  inflation_rate,
  unemployment_rate
FROM
  economies,
  (
    SELECT *
    FROM countries
    WHERE 
      gov_form IN ('Republic','Monarchy')
  ) AS sub
WHERE economies.code=sub.code
  AND year=2015
ORDER BY inflation_rate;

-- Method #2: Subquery in WHERE (their solution, which I came to once hearing the "WHERE" part)

 SELECt
  code,
  inflation_rate,
  unemployment_rate
FROM economies
WHERE year = 2015 
  AND code IN
	(
    SELECT code 
    FROM countries
    WHERE gov_form LIKE '%Republic%'
    OR gov_form LIKE '%Monarchy%'
  )
ORDER BY inflation_rate;