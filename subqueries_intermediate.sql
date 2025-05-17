-- This practice is queried using filtered tables from the soccer database explaine din the "case_practice.sql" tab. 


-- Identify the teams who have, in a single home game, scored 8 or more points

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

