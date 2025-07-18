
/* The following questions are queried using data collected about soccer matches in Europe. 
There are three tables in the data set: country (with just the country code to country), teams (giving the team code and long/short names), and matches (with all the match data, including who's playing (by code), home/away score, etc.). 
This data was then partitioned off by country, resulting in tables for each country (e.g., matches_spain, teams_germany, etc.). 
The following queries were used to answer the given questions. 
I've listed the queries in reverse order of difficulty (focusing on the full-data queries first and then looking at the country based ones). */

-- Identify the number of matches played by each country during the three different seasons.

-- Method #1: Using CASE (all dialects)

SELECT
	c.name AS country,
	COUNT(
		CASE
			WHEN m.season='2012/2013' THEN m.ID
			ELSE NULL
		END 
	) AS matches_2012_2013,
	COUNT(
		CASE
			WHEN m.season='2013/2014' THEN m.ID
			ELSE NULL
		END 
	) AS matches_2013_2014,COUNT(
		CASE
			WHEN m.season='2014/2015' THEN m.ID
			ELSE NULL
		END 
	) AS matches_2014_2015
FROM country AS c 
LEFT JOIN matches AS m 
	ON c.id=m.country_id
GROUP BY country

-- Method #2: Using FILTER (not available in MySQL)

SELECT
	c.name AS country,
	COUNT(m.season) FILTER(WHERE m.season='2012/2013') AS matches_2012_2013,
	COUNT(m.season) FILTER(WHERE m.season='2013/2014') AS matches_2013_2014,
	COUNT(m.season) FILTER(WHERE m.season='2014/2015') AS matches_2014_2015
FROM country AS c 
LEFT JOIN match AS m 
	ON c.id=m.country_id
GROUP BY country;

-- Count of home wins, away wins, and ties in each country

SELECT 
    c.name AS country,
	COUNT(
		CASE 
			WHEN m.home_goal > m.away_goal THEN m.id 
       	END) AS home_wins,
	COUNT(
		CASE 
			WHEN m.home_goal < m.away_goal THEN m.id 
        END) AS away_wins,
	COUNT(
		CASE 
			WHEN m.home_goal = m.away_goal THEN m.id 
        END) AS ties
FROM country AS c
LEFT JOIN matches AS m
	ON c.id = m.country_id
GROUP BY country;

-- Calculate the percentage of ties the occur in each country, separated by the 2013-14 and 2014-15 seasons.

SELECT 
	c.name AS country,
	ROUND(AVG(
		CASE 
			WHEN m.season='2013/2014' AND m.home_goal = m.away_goal THEN 1
			WHEN m.season='2013/2014' AND m.home_goal != m.away_goal THEN 0
		END), 2) AS pct_ties_2013_2014,
	ROUND(AVG(
		CASE 
			WHEN m.season='2014/2015' AND m.home_goal = m.away_goal THEN 1
			WHEN m.season='2014/2015' AND m.home_goal != m.away_goal THEN 0
		END), 2) AS pct_ties_2014_2015
FROM country AS c
LEFT JOIN matches AS m
	ON c.id = m.country_id
GROUP BY country;

-- Now total only the home games within each country

SELECT
    c.name AS country,
    SUM(
        CASE
            WHEN home_goal>away_goal AND season='2012/2013' THEN 1
            ELSE 0
        END) AS home_wins_2012_2013,
    SUM(
        CASE
            WHEN home_goal>away_goal AND season='2013/2014' THEN 1
            ELSE 0
        END) AS home_wins_2013_2014,
    SUM(
        CASE
            WHEN home_goal>away_goal AND season='2014/2015' THEN 1
            ELSE 0
        END) AS home_wins_2014_2015
FROM match AS m 
LEFT JOIN country AS c 
    ON m.country_id=c.id
GROUP BY country


-- Identify matches in which Bologna won and specify if it was at home or away


-- Identify Bologna's ID
SELECT
	team_long_name,
	team_api_id
FROM teams_italy
WHERE team_long_name='Bologna';

-- Identify the date/season of Balogna's winning matches

-- Method #1: Using CASE as directed
SELECT 
	season,
    date,
	home_goal,
	away_goal
FROM matches_italy
WHERE 
-- Exclude games not won by Bologna
	CASE WHEN hometeam_id = 9857 AND home_goal > away_goal THEN 'Bologna Win'
		WHEN awayteam_id = 9857 AND away_goal > home_goal THEN 'Bologna Win' 
		END IS NOT NULL;


-- Method #2: Clearer way to code it with just boolean operators

SELECT 
    season,
    date,
    home_goal,
    away_goal
FROM matches_italy
WHERE 
    home_goal>away_goal AND hometeam_id=9857 
    OR home_goal<away_goal AND awayteam_id=9857

-- Query a list of matches played between the two rivals, Barcelona and Real Madrid, in El Clásico matches, indicating who was home/away, and won in each.

WITH el_clasico AS (
  SELECT 
    date,
    CASE 
        WHEN hometeam_id = 8634 THEN 'FC Barcelona' 
        ELSE 'Real Madrid CF'
    END AS home,
    CASE 
        WHEN awayteam_id = 8634 THEN 'FC Barcelona' 
        ELSE 'Real Madrid CF'
    END AS away,
    home_goal,
    away_goal
  FROM matches_spain
  WHERE (awayteam_id = 8634 OR hometeam_id = 8634)
      AND (awayteam_id = 8633 OR hometeam_id = 8633))

SELECT
  date,
  home,
  away,
  CASE
    WHEN home_goal > away_goal THEN home
    WHEN away_goal > home_goal THEN away
    ELSE 'Tie'
  END AS victor
FROM el_clasico
ORDER BY date;

-- Identify the win/loss status of Barcelona's matches.

SELECT
	m.date,
	t.team_long_name AS opponent,
	CASE
		WHEN m.home_goal>m.away_goal THEN 'Barcelona win'
		WHEN m.home_goal<m.away_goal THEN 'Barcelona loss'
		ELSE 'Tie'
	END AS outcome
FROM matches_spain AS m
LEFT JOIN teams_spain AS t
	ON m.awayteam_Id=t.team_api_Id
WHERE m.hometeam_Id=8634

UNION

SELECT
	m.date,
	t.team_long_name AS opponent,
	CASE
		WHEN m.home_goal<m.away_goal THEN 'Barcelona win'
		WHEN m.home_goal>m.away_goal THEN 'Barcelona loss'			
		ELSE 'Tie'
	END AS outcome
FROM matches_spain AS m
LEFT JOIN teams_spain AS t
	ON m.hometeam_id=t.team_api_Id
WHERE m.awayteam_id=8634;

-- Count the number of matches that FC Schalke 04 and FC Bayern Munich have each played at home using the data split across the filtered teams_germany and matches_germany datasets.

-- Identifying the corresponding API id

SELECT
	team_api_id,
	team_long_name
FROM teams_germany
WHERE team_long_name IN ('FC Schalke 04', 'FC Bayern Munich');

-- Counting the numbers of each team's home games

SELECT
    CASE 
        WHEN hometeam_id=10189 THEN 'FC Schalke 04'
        WHEN hometeam_id=9823 THEN 'FC Bayern Munich'
        ELSE 'Other'
    END AS home_team,
    COUNT(id) AS total_matches
FROM matches_germany
GROUP BY home_team;

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
ORDER BY lang_num DESC;

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
ORDER BY lang_num DESC;

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

 -- Your task is to determine the top 10 capital cities in Europe and the Americas by city_perc, a metric you'll calculate. city_perc is a percentage that calculates the "proper" population in a city as a percentage of the total population in the wider metro area, as follows: city_proper_pop / metroarea_pop * 100

SELECT
    name AS city,
    country_code,
    city_proper_pop,
    metroarea_pop,
    city_proper_pop/metroarea_pop * 100 AS city_perc
FROM
    cities
WHERE name IN (
    SELECT capital
    FROM countries
    WHERE
        continent = 'Europe' 
        OR continent LIKE '%America'
) AND metroarea_pop IS NOT NULL
ORDER BY city_perc DESC
LIMIT 10;

/* The following questions are queried using data collected about soccer matches in Europe. 
There are four tables in the data set: country (with just the country code to country), teams (giving the team code and long/short names), leagues (giving the league inforamtion for the teams), and matches (with all the match data, including who's playing (by code), home/away score, etc.). 
The following queries were used to answer the given questions. 
I've listed the queries in reverse order of completion in order to show more advance queries first */



-- Choosing between JOINs, subqueries, nested subqueries, and CTEs



 -- Create a table that includes the date, both team names, and both team scores using all the various methods you know (JOINs, subqueries, correlated subqueries, CTEs)

-- My Method: Two JOINs together -- seems easiest? Less code, less computing?

SELECT
    m.date,
    home.team_long_name AS hometeam,
    away.team_long_name AS awayteam,
    m.home_goal,
    m.away_goal
FROM match AS m 
LEFT JOIN team AS home
    ON m.hometeam_id=home.team_api_id
LEFT JOIN team AS away
    ON m.awayteam_id=away.team_api_id;

-- Method #1: Subqueries (with JOINs within) -- more complicated writing, simple computing

SELECT 
  m.date,
  home.hometeam,
  away.awayteam,
  m.home_goal,
  m.away_goal
FROM match AS m
LEFT JOIN (
-- Using subquery to get hometeam names
  SELECT 
    m.id,
    t.team_long_name AS hometeam
  FROM match AS m 
  LEFT JOIN team AS t 
    ON m.hometeam_id = t.team_api_id
) AS home
  ON m.id=home.id
LEFT JOIN (
-- Using subquery to get awayteam names
  SELECT 
    m.id,
    t.team_long_name AS awayteam
  FROM match AS m 
  LEFT JOIN team AS t 
    ON m.awayteam_id = t.team_api_id
) AS away
  ON m.id=away.id;

-- Method #2: Correlated subquery (more clearly written, more computing power needed)

SELECT
    m.date,
    (
        SELECT t.team_long_name 
        FROM team AS t
        WHERE t.team_api_id=m.hometeam_id
    ) AS hometeam,
    (
        SELECT t.team_long_name 
        FROM team AS t
        WHERE t.team_api_id=m.awayteam_id
    ) AS awayteam,
    m.home_goal,
    m.away_goal
FROM match AS m;

-- Method #3: CTEs

WITH home AS (
    SELECT 
        m.id,
        team_long_name AS hometeam
    FROM team AS t 
    INNER JOIN match AS m 
        ON t.team_api_id=m.hometeam_id
),
away AS(
   SELECT 
        m.id,
        team_long_name AS awayteam
    FROM team AS t 
    INNER JOIN match AS m 
        ON t.team_api_id=m.awayteam_id 
)

SELECT
    m.date,
    home.hometeam AS hometeam,
    away.awayteam AS awayteam,
    m.home_goal,
    m.away_goal
FROM match AS m 
LEFT JOIN home
    USING(id)
LEFT JOIN away
    USING(id);



-- CTEs



-- Use a CTE to find the average number of total goals scored in games in August of the 2013-2014 season by league

-- Method #1: Clearer way

WITH match_list AS (
  SELECT country_id,
  (home_goal+away_goal) AS total_goals
  FROM match
  WHERE 
    EXTRACT(MONTH FROM date)=08
    AND season='2013/2014'
)

SELECT 
  l.name AS league,
  round(avg(total_goals), 2) AS aug_2013_avg_goals
FROM match_list
LEFT JOIN league AS l 
  USING(country_id)
GROUP BY l.name;

-- Method #2: CTE with subquery (what datacamp wanted me to do)

WITH match_list AS (
  SELECT country_id,
  (home_goal+away_goal) AS total_goals
  FROM match
  WHERE id IN (
       SELECT id
       FROM match
       WHERE season='2013/2014' AND EXTRACT(MONTH FROM date)=08)
)

SELECT 
  l.name AS league,
  round(avg(total_goals), 2) AS aug_2013_avg_goals
FROM match_list
LEFT JOIN league AS l 
  USING(country_id)
GROUP BY l.name;

-- Use a CTE to find the number of times each league has played in matches with 10 or more goals

-- Method #1: Join in the main query

WITH match_list AS (
    SELECT country_id, id
    FROM match
    WHERE (home_goal+away_goal)>=10
)

SELECT
    l.name AS league,
    COUNT(match_list.id) AS matches
FROM league AS l
LEFT JOIN match_list
    ON l.country_id=match_list.country_id
GROUP BY l.name;

-- METHOD #2: Join in the CTE

WITH match_list AS (
  SELECT
    l.name AS league,
    date,
    home_goal,
    away_goal,
    (home_goal+away_goal) AS total_goals
  FROM match AS m 
  LEFT JOIN league AS l 
    USING(country_id)
)

SELECT 
  league,
  date,
  home_goal,
  away_goal
FROM match_list
WHERE total_goals>=10;



-- NESTED SUBQUERIES



-- Use nested subqueries to answer this question: How do the average number of matches per season where a team scored 5 or more goals differ by country?

SELECT
  c.name AS country,
  round(avg(outer_s.matches),2) AS avg_seasonal_high_scores
FROM country AS c	
LEFT JOIN (
-- Use subquery to create derived table of a count of each country's total number of high scoring games
  SELECT
    country_id,
    season,
    count(id) AS matches
  FROM (
-- Use nested subquery to create derived table of matches with one side's score as 5 or more
    SELECT 
      country_id,
      season,
      id
    FROM match
    WHERE 
      home_goal>=5
      OR away_goal>=5
  ) AS sub
  GROUP BY 
    country_id,
    season
) AS outer_s
  ON c.id=outer_s.country_id
GROUP BY c.name;

-- Use nested subqueries to identify the max number of goals in each season, the max number of goals overall, and the max number goals scored in July.

SELECT
    season,
    MAX(home_goal+away_goal) AS max_goals,
-- Get max goals for all matches
    (SELECT MAX(home_goal+away_goal) FROM match) AS overall_max_goals,
-- Get max goals for matches in July
    (
        SELECT MAX(home_goal+away_goal) 
        FROM match 
        WHERE id IN (
            SELECT id
            FROM match
            WHERE EXTRACT(MONTH FROM date)=07
        )
    ) AS july_max_goals
FROM match
GROUP BY season;




-- CORRELATED SUBQUERIES




-- Use a correlated subquery to identify matches with total scores equaling the max number of goals in a match

SELECT
    main.country_id,
    main.date,
    main.home_goal,
    main.away_goal
FROM match AS main
WHERE (main.home_goal+main.away_goal)=(
-- Correlated subquery to find the matches whose total goals equal the max goals of the table
    SELECT MAX(sub.home_goal+sub.away_goal)
    FROM match AS sub
    WHERE 
        main.country_id=sub.country_id
        AND main.season=sub.season
);


-- Use a correlated subquery to identify matches with scores that are abnormally high -- more than three times the average match score

SELECT
    main.country_id,
    main.date,
    main.home_goal,
    main.away_goal
FROM match AS main 
WHERE (home_goal+away_goal)>(
-- Correlated subquery to find the matches whose total goals were more than three times the average total goals
    SELECT avg((sub.home_goal+sub.away_goal)*3)
    FROM match AS sub
    WHERE main.country_id=sub.country_id
);



-- SUBQUERIES IN ALL CLAUSES



-- Calculate the average goals scored in each stage as compared to the overall average, keeping only the stages in which the stage's average goals is greater than overall average goals

SELECT
    s.stage,
    ROUND(s.avg_goals, 2) AS avg_goals,
-- Subquery to also list the overall average not aggregated by stage
    ROUND((
		SELECT AVG(home_goal+away_goal) AS overall_avg 
		FROM match 
		WHERE season='2012/2013'
	), 2)
FROM (
-- Subquery to pull from an aggregated table
	SELECT 
		stage,
		AVG(home_goal+away_goal) AS avg_goals
	FROM match 
	WHERE season='2012/2013'
	GROUP BY stage 
) AS s
WHERE s.avg_goals>(
-- Subquery to filter to only stages that are above the average
	SELECT avg(home_goal+away_goal)
	FROM match 
	WHERE season='2012/2013'
)
ORDER BY s.stage ASC;

-- Calculate the average goals scored in each stage, keeping only the stages in which the stage's average goals is greater than overall average goals

SELECT
    s.stage,
    ROUND(s.avg_goals, 2) AS avg_goals,
FROM (
-- Subquery to pull from an aggregated table
	SELECT 
		stage,
		AVG(home_goal+away_goal) AS avg_goals
	FROM match 
	WHERE season='2012/2013'
	GROUP BY stage 
) AS s
WHERE s.avg_goals>(
-- Subquery to filter to only stages that are above the average
	SELECT avg(home_goal+away_goal)
	FROM match 
	WHERE season='2012/2013'
)
ORDER BY s.stage ASC;

-- Create a data set listing the average total of goals in each match stage in the 2012/2013 season as compared to the overall goals

SELECT
    stage,
    ROUND(avg(home_goal+away_goal), 2) AS avg_goals,
    ROUND((
-- Subquery to get overall average outside of group by
        SELECT avg(home_goal+away_goal) 
        FROM match 
        WHERE season='2012/2013'), 2) AS overall_goals
FROM match
WHERE season='2012/2013'
GROUP BY stage
ORDER BY stage;





-- SUBQUERIES IN SELECT CLAUSE

-- Calculate the average number of goals per match in each country's league and its difference from the overall average, both in 2013-2014

SELECT
    l.name AS league,
    round(avg(m.home_goal+m.away_goal), 2) AS avg_goals,
    round(avg(m.home_goal+m.away_goal)-(    
-- Subquery calculates average total goals for 2013-14 season
        SELECT
            (avg(home_goal+away_goal))
        FROM match
        WHERE season='2013/2014'
    ), 2) AS diff
FROM league AS l 
LEFT JOIN match AS m 
    ON l.country_id=m.country_id
WHERE season='2013/2014' 
GROUP BY l.name;

-- Calculate the average number of goals per match in each country's league as compared to the overall average

SELECT
    l.name AS league,
    round(avg(m.home_goal+m.away_goal), 2) AS avg_goals,
    round(avg(m.home_goal+m.away_goal)-(  
-- Subquery calculates average total goals for 2013-14 season
        SELECT
            (avg(home_goal+away_goal))
        FROM match
        WHERE season='2013/2014'
    ), 2) AS diff
FROM league AS l 
LEFT JOIN match AS m 
    ON l.country_id=m.country_id
WHERE season='2013/2014' 
GROUP BY l.name;



-- SUBQUERIES IN SELECT CLAUSE



-- Identify the number of matches played by each country in which there were a total of 10 or more goals.

SELECT
    name AS country_name,
    count(name) AS matches
FROM country AS c 
INNER JOIN (
-- Subquery filters out any games without total scores of more than or equal to 10 goals
    SELECT 
        country_id
    FROM match
    WHERE (home_goal+away_goal)>=10
) AS sub
ON c.id=sub.country_id
GROUP BY country_name;

-- Identify the country, date, and respective goals from matches in which the total score was above 10.

-- Method #1: Using subquery in the FROM (datacamp method)

SELECT
    country,
    date,
    home_goal,
    away_goal
FROM 
-- Subquery calculates/saves the total_goals for each match so the outside WHERE statement can use it
	(SELECT c.name AS country, 
     	    m.date, 
     		m.home_goal, 
     		m.away_goal,
           (m.home_goal + m.away_goal) AS total_goals
    FROM match AS m
    LEFT JOIN country AS c
    ON m.country_id = c.id) AS sub
WHERE total_goals >=10;

-- Method #2: Just putting the calculation in the WHERE clause

SELECT c.name AS country, 
    m.date, 
    m.home_goal, 
    m.away_goal
FROM match AS m
LEFT JOIN country AS c
    ON m.country_id = c.id
WHERE (m.home_goal + m.away_goal) >=10;



-- SUBQUERIES IN WHERE CLAUSE



-- Identify the teams who have, in a single home game, scored 8 or more points

SELECT 
	team_long_name,
	team_short_name
FROM team
WHERE team_api_id IN (
-- Subquery filters for teams who have scored more than 8 goals at home
	SELECT hometeam_id
	FROM match 
	WHERE home_goal>=8
)
	

-- Identify the teams who have never played a game at home

SELECT
	team_long_name,
	team_short_name
FROM team
WHERE team_api_id<> NOT IN (
 -- Subquery filters to show teams that have played home games according to the match table
	SELECT DISTINCT hometeam_id
	FROM match
);

-- Identify the games played in which the total score was three times the average total score.

SELECT
	date,
	home_goal,
	away_goal
FROM matches_2013_2014
WHERE (home_goal+away_goal)>(
-- Subquery filters to show matches where the total score was over 3 times the average total score
	SELECT avg(home_goal+away_goal)*3
	FROM matches_2013_2014
);

/* The following questions are queried using data collected about soccer matches in Europe. 
There are four tables in the data set: country (with just the country code to country), teams (giving the team code and long/short names), leagues (giving the league inforamtion for the teams), and matches (with all the match data, including who's playing (by code), home/away score, etc.). 
The following queries were used to answer the given questions. 
I've listed the queries in reverse order of completion in order to show more advance queries first */
'
-- CASE STUDY: Identify Manchester United's losses in the 2014/2015 season and rank the losses by how much they lost by

-- My method: Use CTE, UNION home and away games, filter for losses, RANK by severity of loss

WITH mu_matches AS (
	
	SELECT
		m.date,
		m.id,
		awayteam_id AS opponent_id,
		t.team_long_name,
		home_goal AS mu_goal,
		away_goal AS opponent_goal,
		CASE
			WHEN t.team_long_name='Manchester United' THEN 'home'
			ELSE 'error'
		END AS home_or_away,
		CASE
			WHEN home_goal>away_goal THEN 'MU Win'
			WHEN home_goal<away_goal THEN 'MU Loss'
			ELSE 'MU Tie'
		END AS outcome
	FROM match AS m 
	LEFT JOIN team AS t
		ON m.hometeam_id=t.team_api_id
	WHERE 
		season='2014/2015'
		AND t.team_long_name='Manchester United'
		
	UNION
	
	SELECT
		m.date,
		m.id,
		hometeam_id AS opponent_id,
		t.team_long_name,
		away_goal AS mu_goal,
		home_goal AS opponent_goal,
		CASE
			WHEN t.team_long_name='Manchester United' THEN 'away'
			ELSE 'error'
		END AS home_or_away,
		CASE
			WHEN home_goal<away_goal THEN 'MU Win'
			WHEN home_goal>away_goal THEN 'MU Loss'
			ELSE 'MU Tie'
		END AS outcome
	FROM match AS m 
	LEFT JOIN team AS t
		ON m.awayteam_id=t.team_api_id
	WHERE 
		season='2014/2015'
		AND t.team_long_name='Manchester United'
)
		
SELECT DISTINCT
	date,
	t.team_long_name,
	home_or_away,
	mu_goal,
	opponent_goal,
	RANK() OVER (
		ORDER BY opponent_goal-mu_goal DESC
	) AS loss_severity
FROM mu_matches AS mu
LEFT JOIN team AS t
	ON mu.opponent_id=t.team_api_id
WHERE outcome='MU Loss';

-- As directed by datacamp (two different CTEs, join with both of them)


-- Set up the home team CTE
WITH home AS (
  SELECT m.id, 
  t.team_long_name,
	  CASE WHEN m.home_goal > m.away_goal THEN 'MU Win'
		   WHEN m.home_goal < m.away_goal THEN 'MU Loss' 
  		   ELSE 'Tie' END AS outcome
  FROM match AS m
  LEFT JOIN team AS t ON m.hometeam_id = t.team_api_id),
-- Set up the away team CTE
away AS (
  SELECT m.id, 
  t.team_long_name,
	  CASE WHEN m.home_goal > m.away_goal THEN 'MU Loss'
		   WHEN m.home_goal < m.away_goal THEN 'MU Win' 
  		   ELSE 'Tie' END AS outcome
  FROM match AS m
  LEFT JOIN team AS t ON m.awayteam_id = t.team_api_id)
-- Select columns and and rank the matches by goal difference
SELECT DISTINCT
    m.date,
    home.team_long_name AS home_team,
    away.team_long_name AS away_team,
    m.home_goal, 
    m.away_goal,
    RANK() OVER(ORDER BY ABS(home_goal - away_goal) DESC) as match_rank
-- Join the CTEs onto the match table
FROM match AS m
LEFT JOIN home ON m.id = home.id
LEFT JOIN away ON m.id = away.id
WHERE m.season = '2014/2015'
      AND ((home.team_long_name = 'Manchester United' AND home.outcome = 'MU Loss')
      OR (away.team_long_name = 'Manchester United' AND away.outcome = 'MU Loss'));


-- Calculate running totals and running averages for FC Utrecht (id 9908) across the 2011/2012 away games, listing it so the most recent and sum total comes first.

SELECT   
     date,
     away_goal,
     SUM(away_goal) OVER(
          ORDER BY date DESC
          ROWS BETWEEN CURRENT ROW and UNBOUNDED FOLLOWING
     ) AS running_total,

     AVG(away_goal) OVER(
          ORDER BY date DESC
          ROWS BETWEEN CURRENT ROW and UNBOUNDED FOLLOWING
     ) AS running_avg   
FROM match
WHERE 
	awayteam_id = 9908 
    AND season = '2011/2012';
    
    
-- Calculate running totals and running averages for FC Utrecht (id 9908) across the 2011/2012 home games.

SELECT 
	date,
	home_goal,
    -- Create a running total and running average of home goals
    SUM(home_goal) OVER(ORDER BY date 
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
    round(AVG(home_goal) OVER(ORDER BY date 
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS running_avg
FROM match
WHERE 
	hometeam_id = 9908 
	AND season = '2011/2012';


-- Calculate the average number home and away goals scored Legia Warszawa, and their opponents, partitioned by the month in each season

SELECT 
	date,
	season,
	home_goal,
	away_goal,
	CASE WHEN hometeam_id = 8673 THEN 'home' 
         ELSE 'away' END AS warsaw_location,
	-- Calculate average goals partitioned by season and month
    avg(home_goal) OVER(PARTITION BY season, 
         	EXTRACT(MONTH FROM date)) AS season_mo_home,
    avg(away_goal) OVER(PARTITION BY season, 
         	EXTRACT(MONTH FROM date)) AS  season_mo_away
FROM match
WHERE 
	hometeam_id = 8673
    OR awayteam_id = 8673
ORDER BY (home_goal + away_goal) DESC;

-- Create a dataset to compare Legia Warszawa's match scores against their average score, partitioned by both home/away and season.

-- Method #1: Using CASE to give LW's score, regardless of home or away, but then tell us if it's home/away

SELECT 
	date,
	season,
	CASE
		WHEN hometeam_id=8673 THEN 'home'
		WHEN awayteam_id=8673 THEN 'away'
		END AS location,
	CASE
		WHEN hometeam_id=8673 THEN home_goal
		WHEN awayteam_id=8673 THEN away_goal
		END AS lw_score,
	CASE
    -- Calculate the average goals scored partitioned by season, only including LW's scores
		WHEN hometeam_id=8673 
			THEN round(avg(home_goal) OVER(PARTITION BY hometeam_id, season), 2)
		WHEN awayteam_id=8673 
			THEN round(avg(away_goal) OVER(PARTITION BY awayteam_id, season), 2)
		END AS avg_score
FROM match
WHERE 
	hometeam_id=8673
	OR awayteam_id=8673
ORDER BY lw_score DESC, avg_score DESC;

-- Method #2 (datacamp correct answer): Gives extraneous data about opponents' scores; partitioned data is corrupted by opponent's home/away score

SELECT
	date,
	season,
	home_goal,
	away_goal,
	CASE WHEN hometeam_id = 8673 THEN 'home' 
		 ELSE 'away' END AS warsaw_location,
    -- Calculate the average goals scored partitioned by season (including home/away teams that are opponents to LW)
    avg(home_goal) OVER(PARTITION BY season) AS season_homeavg,
    avg(away_goal) OVER(PARTITION BY season) AS season_awayavg
FROM match
-- Filter the data set for Legia Warszawa matches only
WHERE 
	hometeam_id=8673
	OR awayteam_id=8673
ORDER BY (home_goal + away_goal) DESC;


-- Create a data set of ranked matches according to which leagues, on average, score the most goals in a match.

SELECT 
    l.name AS league,
    round(avg(m.home_goal+m.away_goal), 2) AS avg_goals,
    RANK() OVER(ORDER BY avg(m.home_goal+m.away_goal) DESC) AS league_rank
FROM league AS l 
LEFT JOIN match AS m
    USING(country_id)
WHERE m.season='2011/2012'
GROUP BY l.name;

-- Identify the overall average match score along with the match id, country name, season, and home/away scores.

SELECT
	m.id,
	c.name AS country,
	m.season,
	m.home_goal,
	m.away_goal,
	round(avg(m.home_goal+m.away_goal) OVER(), 2) AS overall_avg
FROM match AS m 
LEFT JOIN country AS c 
	ON m.country_id=c.id;

/* These queries are performed in PostgreSQL using a Summer Olympics dataset, which contains the results of the games between 1896 and 2012. The first Summer Olympics were held in 1896, the second in 1900, and so on. Queries are included in reverse order below.*/

-- Ranking each country in the 2000 Olympics by gold medals awarded, then return the top 3 countries in one row, as a comma-separated string. 

WITH country_medals AS (
  SELECT
    country,
    COUNT(*) AS medals
  FROM summer_medals
  WHERE Year = 2000
    AND medal = 'Gold'
  GROUP BY country
),

country_ranks AS (
  SELECT
    country,
    RANK() OVER (ORDER BY medals DESC) AS Rank
  FROM country_medals
  ORDER BY Rank ASC
)

SELECT STRING_AGG(country, ', ')
FROM country_ranks
WHERE rank<=3;


-- Generate a breakdown of the medals awarded to Russia per gender and medal type in 2012, including all group-level subtotals and a grand total.


SELECT
  coalesce(gender, 'ALL GENDERS') AS gender,
  coalesce(medal, 'ALL MEDAL TYPES') AS medals,
  count(*) AS medals
FROM summer_medals
WHERE
  Year = 2012
  AND country = 'RUS'
GROUP BY CUBE(gender, medal)
ORDER BY gender ASC, medal ASC;

-- Identify the number of gold medals earned by three Scandinavian countries by gender in the year 2004. Retrieve totals grouped by country and gender as well as country totals.

SELECT 
  country,
  coalesce(gender, 'All Genders') AS gender,
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

-- All data comes from the Sakila database, a fictitional DVD rental company database. Many of these functions are postgreSQL-specific.




-- Generate a data set that we could use to predict whether the words and phrases used to describe a film have an impact on the number of rentals.

SELECT 
  title, 
  description, 
  -- Calculate the similarity
  similarity(description, 'Astounding & Drama')
FROM 
  film 
WHERE 
  to_tsvector(description) @@ 
  to_tsquery('Astounding & Drama') 
ORDER BY 
	similarity(description, 'Astounding & Drama') DESC;

-- Use levenshtein comparison to find the closest match to "JET NEIGHBOR"
SELECT  
  title, 
  description, 
  levenshtein(title, 'JET NEIGHBOR') AS distance
FROM 
  film
ORDER BY 3

--Check similarity between title and description columns

-- Method #1: similarity
SELECT 
  title, 
  description, 
  similarity(title, description)
FROM 
  film
  
-- Load the pg_trgm extension and then verify that it's loaded

CREATE EXTENSION IF NOT EXISTS pg_trgm;

SELECT * 
FROM pg_extension;

-- Use the user-created function "inventory_held_by_customer" to create a query to check which movies are currently checked out by a customer

SELECT 
	f.title, 
    i.inventory_id,
    inventory_held_by_customer(i.inventory_id) as held_by_cust
FROM film as f 
	INNER JOIN inventory AS i ON f.film_id=i.film_id 
WHERE
    inventory_held_by_customer(i.inventory_id) IS NOT NULL

-- Select all columns from the pg_type table where the type name is equal to mpaa_rating.

SELECT *
FROM pg_type 
WHERE typname='mpaa_rating'

-- Select the column name, data type and udt name columns and filter by the rating column in the film table
SELECT column_name, data_type, udt_name
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_name ='film' AND column_name='rating';

-- Create an enumerated data type, compass_position, and then confirm that it's in the pg_type system table
CREATE TYPE compass_position AS ENUM (
  	'North', 
  	'South',
  	'East', 
  	'West'
);

SELECT typname, typcategory
FROM pg_type
WHERE typname='compass_position';

-- Search for "elf" in the title, retrieving those titles and descriptions

SELECT title, description
FROM film
WHERE to_tsvector(title) @@ to_tsquery('elf');

-- Select the film description as a tsvector

SELECT to_tsvector(description)
FROM film;

-- Concatenate the film and category. Generate a shortened description that doesn't go beyond 50 characters but also doesn't cut off any words.

SELECT 
  CONCAT(name, ' ', title) AS film_category,
  LEFT(description, 50 - 
    POSITION(
      ' ' IN REVERSE(
        LEFT(description, 50)
      )
    )
  )
FROM 
  film AS f 
INNER JOIN film_category AS fc 
 	ON f.film_id = fc.film_id 
 INNER JOIN category AS c 
 	ON fc.category_id = c.category_id;

-- Convert the film category name to uppercase and combine it with the title. Truncate the description 50 characters, getting rid of any leading/trailing white spaces.

SELECT 
  CONCAT(UPPER(c.name), ': ', f.title) AS film_category,
  TRIM(LEFT(f.description, 50)) AS film_desc
FROM 
  film AS f 
  INNER JOIN film_category AS fc 
  	ON f.film_id = fc.film_id 
  INNER JOIN category AS c 
  	ON fc.category_id = c.category_id;

-- Generate a combine first/last name using padded text 

-- Method #1
SELECT 
	RPAD(first_name, LENGTH(first_name)+1) || last_name AS full_name
FROM customer;

-- Method #2
SELECT 
	first_name || LPAD(last_name, LENGTH(last_name)+1) AS full_name
FROM customer; 

-- Split the email addresses into the username and the domain name

SELECT 
  SUBSTR(email, 1, POSITION('@' IN email)-1) AS username,
  SUBSTR(email, POSITION('@' IN email)+1, LENGTH(email)) AS domain
FROM customer;

-- Identify only the street name (not including the house address) from address column

SELECT 
  -- Select only the street name from the address table
  SUBSTRING(address, POSITION(' ' IN address)+1, LENGTH(address))
FROM 
  address;

-- Shorter the movie descriptions to just the first 50 characters

SELECT 
  LEFT(description, 50) AS short_desc
FROM 
  film AS f
  
-- Identify the number of characters in each film description

SELECT 
  title,
  description,
  LENGTH(description) AS desc_len
FROM film;

-- Replace whitespace in the film title with an underscore

SELECT 
  REPLACE(title, ' ', '_') AS title
FROM film; 

-- Adjust the case of the genre, title, and description, combining the genre and title into one concatenated cell.

-- Method #1: PostgreSQL only
SELECT 
  UPPER(c.name)  || ': ' || INITCAP(f.title) AS film_category, 
  LOWER(f.description) AS description
FROM 
  film AS f 
  INNER JOIN film_category AS fc 
  	ON f.film_id = fc.film_id 
  INNER JOIN category AS c 
  	ON fc.category_id = c.category_id;
  	
 -- Method #2: General SQL
 SELECT 
  CONCAT(UPPER(c.name), ': ', INITCAP(f.title)) AS film_category, 
  LOWER(f.description) AS description
FROM 
  film AS f 
  INNER JOIN film_category AS fc 
  	ON f.film_id = fc.film_id 
  INNER JOIN category AS c 
  	ON fc.category_id = c.category_id;


-- Put this all together. For each rental, identify the full name of the customer, the movie title, the rental date, the day of the week, the number of days rented, and whether or not the movie was overdue when it was turned in. All of this should apply to the same 90 day range from May 1 2005.

SELECT 
  CONCAT(c.first_name, ' ',c.last_name) AS full_name,
  f.title,
  r.rental_date,
  EXTRACT(dow FROM r.rental_date) AS dayofweek,
  AGE(r.return_date, r.rental_date) AS rental_days,
  CASE 
    WHEN DATE_TRUNC('day', AGE(return_date, rental_date))>f.rental_duration * INTERVAL '1 day' THEN 'True'
    ELSE 'False'
  END AS past_due
FROM film AS f
INNER JOIN inventory AS i 
  ON f.film_id=i.film_id
INNER JOIN rental AS r 
  ON i.inventory_id=r.inventory_id
INNER JOIN customer AS c 
  ON r.customer_id=c.customer_id
WHERE r.rental_date BETWEEN CAST('2005-05-01' AS date) AND CAST('2005-05-01' AS date) + INTERVAL '90 days';

-- Identify the total number of rentals across each of the days of the week

-- Method #1
SELECT 
  EXTRACT(dow FROM rental_date) AS dayofweek,
  count(*) AS total_rentals
FROM rental 
GROUP BY 1;

-- Method #2
SELECT 
  DATE_TRUNC('day', rental_date) AS rental_day,
  COUNT(*) AS rentals 
FROM rental
GROUP BY 1;

-- Now calculate a timestamp five days from measured to the second.

SELECT
	CURRENT_TIMESTAMP(0)::timestamp AS right_now,
    interval '5 days' + CURRENT_TIMESTAMP(0) AS five_days_from_now;

--Select the current timestamp without a timezone

SELECT CAST( NOW() AS TIMESTAMP);

SELECT CURRENT_TIMESTAMP::TIMESTAMP AS right_now;

-- Calculate the expected return date of each rental

SELECT
    f.title,
	r.rental_date,
    f.rental_duration,
    INTERVAL '1' day * f.rental_duration + rental_date AS expected_return_date,
    r.return_date
FROM film AS f
    INNER JOIN inventory AS i ON f.film_id = i.film_id
    INNER JOIN rental AS r ON i.inventory_id = r.inventory_id
ORDER BY f.title;

-- Exclude films that are currently checked out and also convert the rental_duration to an INTERVAL type.

SELECT
	f.title,
    INTERVAL '1' day * rental_duration,
    r.return_date - r.rental_date AS days_rented
FROM film AS f
    INNER JOIN inventory AS i ON f.film_id = i.film_id
    INNER JOIN rental AS r ON i.inventory_id = r.inventory_id
WHERE r.return_date IS NOT NULL
ORDER BY f.title;

--Determine the number of days of each rental experience using both AGE() and subtraction

-- Method #1: AGE() function
SELECT f.title, f.rental_duration,
    -- Calculate the number of days rented
	AGE(return_date, rental_date) AS days_rented
FROM film AS f
	INNER JOIN inventory AS i ON f.film_id = i.film_id
	INNER JOIN rental AS r ON i.inventory_id = r.inventory_id
ORDER BY f.title;

-- Method #2: Basic subtraction
SELECT 
    f.title,
    f.rental_duration,
    r.return_date-r.rental_date AS days_rented
FROM rental AS r 
INNER JOIN inventory AS i USING(inventory_id)
INNER JOIN film AS f USING(film_id)
ORDERY BY f.title;

-- Use the contains operator to match the text Deleted Scenes in the special_features column.

SELECT 
  title, 
  special_features 
FROM film 
WHERE special_features @> ARRAY['Deleted Scenes'];

-- Match 'Trailers' in any index of the special_features ARRAY regardless of position.

SELECT
  title, 
  special_features 
FROM film 
WHERE 'Trailers' = ANY(special_features);

-- Now let's select all films that have Deleted Scenes in the second index of the special_features ARRAY.

SELECT 
  title, 
  special_features 
FROM film
WHERE special_features[2] = 'Deleted Scenes';

-- Select all films that have a special feature Trailers by filtering on the first index of the special_features ARRAY.

SELECT 
  title, 
  special_features 
FROM film
WHERE special_features[1] = 'Trailers';

--Select the rental date and return date from the rental table. Add an INTERVAL of 3 days to the rental_date to calculate the expected return date`.

SELECT 
	rental_date,
	rental_date+INTERVAL '3 DAY' AS expected_return_date,
	return_date 
FROM 
	rental 

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

-- Data-driven decision making. 

/*Data for the following queries comes from a fictious online movie rental company, MovieNow, in which customers can rent a movie for 24 hours. It contains tables with information about the movies, customers, rentals, and actors. All queries are listed in reverse order below to show more advanced queries at the top.*/

-- The last aspect you have to analyze are customer preferences for certain actors.

SELECT 
	a.nationality,
	a.gender,
	avg(r.rating) AS avg_rating,
	count(r.rating) AS n_rating,
	count(*) AS n_rentals,
	count(DISTINCT a.actor_id) AS n_actors
FROM renting AS r
LEFT JOIN actsin AS ai
	ON ai.movie_id = r.movie_id
LEFT JOIN actors AS a
	ON ai.actor_id = a.actor_id
WHERE r.movie_id IN ( 
	SELECT movie_id
	FROM renting
	GROUP BY movie_id
	HAVING COUNT(rating) >=4 )
AND r.date_renting >= '2018-04-01'
GROUP BY CUBE(nationality, gender);

--  Now the management considers investing money in movies of the best rated genres.

SELECT 
	genre,
	AVG(rating) AS avg_rating,
	COUNT(rating) AS n_rating,
	COUNT(*) AS n_rentals,     
	COUNT(DISTINCT m.movie_id) AS n_movies 
FROM renting AS r
LEFT JOIN movies AS m
	ON m.movie_id = r.movie_id
WHERE r.movie_id IN ( 
	SELECT movie_id
	FROM renting
	GROUP BY movie_id
	HAVING COUNT(rating) >= 3 )
AND r.date_renting >= '2018-01-01'
GROUP BY genre
ORDER BY avg_rating DESC;

-- Now you will investigate the average rating of customers aggregated by country and gender.

SELECT 
	c.country, 
    c.gender,
	AVG(r.rating)
FROM renting AS r
LEFT JOIN customers AS c
	ON r.customer_id = c.customer_id
GROUP BY GROUPING SETS ((country, gender), (country), (gender), ());


-- We are interested in how much diversity there is in the nationalities of the actors and how many actors and actresses are in the list.

SELECT 
    gender,
    nationality,
    count(*)
FROM actors
GROUP BY GROUPING SETS ((nationality), (gender), ())


-- You are asked to study the preferences of genres across countries. Are there particular genres which are more popular in specific countries? Evaluate the preferences of customers by averaging their ratings and counting the number of movies rented from each genre.

SELECT 
    country,
    genre,
    avg(rating),
    count(*)
FROM renting 
JOIN movies
    USING(movie_id)
JOIN customers
    USING(customer_id)
GROUP BY ROLLUP (country, genre)
ORDER BY country, genre

-- You have to give an overview of the number of customers for a presentation. Generate a table with the total number of customers, the number of customers for each country, and the number of female and male customers for each country.

SELECT 
	country,
	gender,
	COUNT(*)
FROM customers
GROUP BY ROLLUP(country, gender)
ORDER BY country, gender; -- Order the result by country and gender


-- Give an overview on the movies available on MovieNow. List the number of movies for different genres and release years.

SELECT 
	c.country, 
	m.genre, 
	AVG(r.rating) AS avg_rating
FROM renting AS r
LEFT JOIN movies AS m
ON m.movie_id = r.movie_id
LEFT JOIN customers AS c
ON r.customer_id = c.customer_id
GROUP BY CUBE(country, genre);

-- Give an overview on the movies available on MovieNow. List the number of movies for different genres and release years.

SELECT 
	genre,
	year_of_release,
	count(*)
FROM movies
GROUP BY CUBE(genre, year_of_release)
ORDER BY year_of_release;

-- The advertising team has a new focus. They want to draw the attention of the customers to dramas. Make a list of all movies that are in the drama genre and have an average rating higher than 9. Give the full movie information.

-- Method #1: My instinctual method

SELECT *
FROM movies
WHERE 
	genre='Drama'
	AND movie_id IN (
	SELECT
		movie_id
	FROM renting
	GROUP BY movie_id
	HAVING avg(rating)>9
)

-- Method #2: DataCamp's intended method

SELECT *
FROM movies
WHERE movie_id IN -- Select all movies of genre drama with average rating higher than 9
   (SELECT movie_id
    FROM movies
    WHERE genre = 'Drama'
    INTERSECT
    SELECT movie_id
    FROM renting
    GROUP BY movie_id
    HAVING AVG(rating)>9);

-- Identify actors who are not from the USA or who were born after 1990.

-- Method #1: My instinctual method
SELECT 
	name,
	nationality,
	year_of_birth
FROM actors 
WHERE 
	nationality!='USA'
	OR year_of_birth>1990
     
-- Method #2: DataCamp's intended method
SELECT 
	name, 
	nationality, 
	year_of_birth
FROM actors
WHERE nationality <> 'USA'
UNION
SELECT 
	name, 
	nationality, 
	year_of_birth
FROM actors
WHERE year_of_birth > 1990;

-- In order to analyze the diversity of actors in comedies, first, report a list of actors who play in comedies and then the number of actors for each nationality playing in comedies.

-- My method

SELECT 
    nationality,
    count(*)
FROM actors 
WHERE actor_id IN (
    SELECT actor_id
    FROM actsin
    LEFT JOIN movies 
        USING(movie_id)
    WHERE genre='Comedy'
)
GROUP BY nationality
ORDER BY count DESC;

-- DataCamp intended method

SELECT 
    a.nationality,
    count(*)
FROM actors AS a
WHERE EXISTS(
    SELECT *
    FROM actsin AS ai
    LEFT JOIN movies 
        USING(movie_id)
    WHERE genre='Comedy'
    AND ai.actor_id=a.actor_id
)
GROUP BY a.nationality
ORDER BY count DESC;

-- Having active customers is a key performance indicator for MovieNow. Make a list of customers who gave at least one rating.

SELECT *
FROM customers AS c
WHERE EXISTS (
    SELECT *
    FROM renting AS r
    WHERE rating IS NOT NULL
    AND c.customer_id=r.customer_id
)

-- Report a list of movies that received the most attention on the movie platform, (i.e. report all movies with more than 5 ratings and all movies with an average rating higher than 8).

-- My method #1 (just answering question to get list)
SELECT 
	title,
	count(*) AS ratings_count,
	round(avg(rating), 1) AS avg_rating
FROM renting
LEFT JOIN movies USING(movie_id)
GROUP BY title
HAVING count(*)>5
	AND avg(rating)>8
	
-- My method #2 (getting all movie information for movies that fit this criteria
	
SELECT *
FROM movies
WHERE movie_id IN (
	SELECT movie_id
	FROM renting 
	GROUP BY movie_id
	HAVING 
		count(*)>5
		AND avg(rating)>8
)

-- DataCamp intended method (having two different querries, assumedly to come back to later)

WITH high_rating AS(
	SELECT *
	FROM movies AS m
	WHERE 5 < 
	    (SELECT COUNT(rating)
	    FROM renting AS r
	    WHERE r.movie_id = m.movie_id)
)
    
SELECT *
FROM movies AS m
INNER JOIN high_rating AS hr
	ON hr.movie_id=m.movie_id
WHERE 8<
	(SELECT avg(rating)
	FROM renting AS r
	WHERE r.movie_id = m.movie_id);


-- Identify customers who were not satisfied with movies they watched on MovieNow. Report a list of customers with minimum rating smaller than 4.


-- My method
SELECT
    name
FROM customers
WHERE customer_id IN (
    SELECT DISTINCT customer_id
    FROM renting
    GROUP BY customer_id 
    HAVING min(rating)<4
)

-- DataCamp intended method

SELECT *
FROM customers AS c
WHERE 4 >
	(SELECT MIN(rating)
	FROM renting AS r
	WHERE r.customer_id = c.customer_id);

-- A new advertising campaign is going to focus on customers who rented fewer than 5 movies. Use a correlated query to extract all customer information for the customers of interest.


-- My method
SELECT
    name
FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM renting
    GROUP BY customer_id 
    HAVING count(*)>5
)

-- DataCamp intended method
SELECT *
FROM customers as c
WHERE 5> 
	(SELECT count(*)
	FROM renting as r
	WHERE r.customer_id = c.customer_id);

-- For the advertising campaign your manager also needs a list of popular movies with high ratings. Report a list of movies with rating above average.

SELECT title
FROM movies
WHERE movie_id IN (
	-- A list of movies that have been watched once and are above a calculated avg
    SELECT movie_id
    FROM renting
    GROUP BY movie_id
    HAVING 
        count(*) > 1
        AND avg(rating) > (
        	-- Finding the average rating
            SELECT avg(rating)
            FROM renting
        )
)

-- Report a list of customers who frequently rent movies on MovieNow.

SELECT *
FROM customers
WHERE customer_id IN 
	(SELECT customer_id
	FROM renting
	GROUP BY customer_id
	HAVING count(*)>10);
	
-- Your manager wants you to make a list of movies excluding those which are hardly ever watched. This list of movies will be used for advertising. List all movies with more than 5 views.

SELECT DISTINCT movie_id -- Select movie IDs with more than 5 views
FROM renting
WHERE movie_id IN (
    SELECT movie_id
    FROM renting
    GROUP BY movie_id
    HAVING count(*)>5
)

-- Prepare a  report with KPIs for each country separately. Your manager is interested in the total number of movie rentals, the average rating of all movies and the total revenue for each country since the beginning of 2019.

SELECT 
	country, 
	count(*) AS number_renting,
	roun(avg(rating), 1) AS average_rating,
	sum(renting_price) AS revenue 
FROM renting AS r
LEFT JOIN customers AS c
ON c.customer_id = r.customer_id
LEFT JOIN movies AS m
ON m.movie_id = r.movie_id
WHERE date_renting >= '2019-01-01'
GROUP BY country
ORDER BY average_rating;

-- WHich actors are the Spanish customers watching most often?

SELECT 
    a.name,
    count(*)
FROM renting AS r 
JOIN customers AS c 
    USING (customer_id)
JOIN actsin AS ai
    USING (movie_id)
JOIN actors AS a 
    USING(actor_id)
WHERE c.country='Spain'
GROUP BY a.name 
ORDER BY count(*) DESC;

-- Which is the favorite movie on MovieNow? Answer this question for a specific group of customers: for all customers born in the 70s.

SELECT 
    m.title,
    round(avg(rating), 2) AS avg_rating,
    count(rating) AS count_ratings,
    count(*) AS count_rentals
FROM renting AS r 
LEFT JOIN movies AS m 
    USING(movie_id)
LEFT JOIN customers AS c 
    USING (customer_id)
WHERE EXTRACT(YEAR FROM c.date_of_birth) BETWEEN 1970 AND 1979
GROUP BY m.title
HAVING avg(rating) IS NOT NULL
ORDER BY avg_rating DESC


-- Find the oldest and youngest actors and actresses in the database, assuming they're all still alive.

SELECT 
	gender, 
	min(year_of_birth), 
	max(year_of_birth)
FROM actors
WHERE nationality='USA'
GROUP BY gender


-- What is the approximate age of each actor in the database, assuming they're all still alive?

SELECT
   name,
   EXTRACT(YEAR FROM now())-year_of_birth AS age 
FROM actors 
WHERE nationality='USA'
ORDER BY age DESC

-- How much income did each movie generate? 

SELECT 
       m.title,
       sum(renting_price) AS revenue
FROM renting AS r 
LEFT JOIN movies AS m
       USING(movie_id)
GROUP BY m.title
ORDER BY revenue DESC;

-- Create a list of actors in the database and the movies they acted in

SELECT 
    a.name,
    m.title
FROM actsin AS ai
LEFT JOIN movies AS m
ON m.movie_id = ai.movie_id
LEFT JOIN actors AS a
ON a.actor_id = ai.actor_id;

-- Find the KPIs (total revenue, total rentals, total customers) from 2018

SELECT 
	SUM(m.renting_price), 
	COUNT(*), 
	COUNT(DISTINCT r.customer_id)
FROM renting AS r
LEFT JOIN movies AS m
ON r.movie_id = m.movie_id
-- Only look at movie rentals in 2018
WHERE EXTRACT(YEAR FROM date_renting) = 2018;

--What is the average rating of customers from Belgium?

SELECT avg(rating)
FROM renting AS r
LEFT JOIN customers AS c
ON r.customer_id = c.customer_id
WHERE c.country='Belgium';

-- Which customers gave hte lowest average rating, and how many rental/ratings have they had?

SELECT customer_id, 
      avg(rating), 
      count(rating), 
      count(*) 
FROM renting
GROUP BY customer_id
HAVING count(*)>7 
ORDER BY avg(rating); 

-- What is the average rating of each movie rental, and how many views/ratings does it have?

SELECT movie_id, 
       AVG(rating) AS avg_rating,
       COUNT(rating) AS number_ratings,
       COUNT(*) AS number_renting
FROM renting
GROUP BY movie_id
ORDER BY avg_rating DESC;

-- When did MovieNow break into each company?

SELECT 
	country,
	min(date_account_start) AS first_account
FROM customers
GROUP BY country
ORDER BY first_account;

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
