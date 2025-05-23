/* The following questions are queried using data collected about soccer matches in Europe. 
There are four tables in the data set: country (with just the country code to country), teams (giving the team code and long/short names), leagues (giving the league inforamtion for the teams), and matches (with all the match data, including who's playing (by code), home/away score, etc.). 
The following queries were used to answer the given questions. 
I've listed the queries in reverse order of completion in order to show more advance queries first */

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