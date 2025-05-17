-- This practice is queried using filtered tables from the soccer database explaine din the "case_practice.sql" tab. 


-- Calculate the average number of goals per match in each country's league and its difference from the overall average, both in 2013-2014

SELECT
    l.name AS league,
    round(avg(m.home_goal+m.away_goal), 2) AS avg_goals,
    round(avg(m.home_goal+m.away_goal)-(    
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


-- Identify the number of matches played by each country in which there were a total of 10 or more goals.

SELECT
    name AS country_name,
    count(name) AS matches
FROM country AS c 
INNER JOIN (
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
	(SELECT c.name AS country, 
     	    m.date, 
     		m.home_goal, 
     		m.away_goal,
           (m.home_goal + m.away_goal) AS total_goals
    FROM match AS m
    LEFT JOIN country AS c
    ON m.country_id = c.id) AS subq
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

-- This practice is queried using filtered tables from the soccer database explaine din the "case_practice.sql" tab. This is practicing subqueries in the "WHERE" clause.

-- Identify the teams who have, in a single home game, scored 8 or more points

SELECT 
FROM country AS

WHERE


SELECT 
	t.team AS team,
	avg(m.home_goal) AS home_avg
FROM match AS m 
LEFT JOIN team AS t
	ON m.hometeam_id=t.team_api_id
WHERE season='2011-2012'
GROUP BY t.team
ORDER BY home_avg DESC
LIMIT 3;

SELECT 
	team_long_name,
	team_short_name
FROM team
WHERE team_api_id IN (
	SELECT hometeam_id
	FROM match 
	WHERE home_goal>=8
)
	

-- Identify the teams who have never played a game at home

SELECT
	team_long_name,
	team_short_name
FROM team
WHERE team_api_id<> NOT IN
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
	SELECT avg(home_goal+away_goal)*3
	FROM matches_2013_2014
);

