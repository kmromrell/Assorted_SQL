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