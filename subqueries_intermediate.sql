-- This practice is queried using filtered tables from the soccer database explaine din the "case_practice.sql" tab. 

-- CORRELATED SUBQUERIES

-- Use a correlated subquery to identify matches with total scores equaling the max number of goals in a match

SELECT
    main.country_id,
    main.date,
    main.home_goal,
    main.away_goal
FROM match AS main
WHERE (main.home_goal+main.away_goal)=(
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

