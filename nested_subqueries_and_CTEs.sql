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

