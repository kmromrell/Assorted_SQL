/* The following questions are queried using data collected about soccer matches in Europe. 
There are four tables in the data set: country (with just the country code to country), teams (giving the team code and long/short names), leagues (giving the league inforamtion for the teams), and matches (with all the match data, including who's playing (by code), home/away score, etc.). 
The following queries were used to answer the given questions. 
I've listed the queries in reverse order of completion in order to show more advance queries first */



-- Create a dataset to compare Legia Warszawa's match scores against their home/away averages.

SELECT 
	CASE
		WHEN hometeam_id=8673 THEN 'home'
		WHEN awayteam_id=8673 THEN 'away'
		END AS location,
	CASE
		WHEN hometeam_id=8673 THEN home_goal
		WHEN awayteam_id=8673 THEN away_goal
		END AS lw_score,
	CASE
		WHEN hometeam_id=8673 
			THEN round(avg(home_goal) OVER(PARTITION BY hometeam_id), 2)
		WHEN awayteam_id=8673 
			THEN round(avg(away_goal) OVER(PARTITION BY awayteam_id), 2)
		END AS avg_score
FROM match
WHERE 
	hometeam_id=8673
	OR awayteam_id=8673
ORDER BY lw_score DESC;


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