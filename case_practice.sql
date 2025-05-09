/* The following questions are queried using data collected about soccer matches in Europe. There are three tables in the data set: country (with just the country code to country), teams (giving the team code and long/short names), and matches (with all the match data, including who's playing (by code), home/away score, etc.). This data was then partitioned off by country, resulting in tables for each country (e.g., matches_spain, teams_germany, etc.). The following queries were used to answer the given questions. I've listed the queries in reverse order of difficulty (focusing on the full-data queries first and then looking at the country based ones). */

-- Calculate the percentage of ties tht occur in each country, separated by the 2013-14 and 2014-15 seasons.

SELECT 
	c.name AS country,
	ROUND(AVG(CASE WHEN m.season='2013/2014' AND m.home_goal = m.away_goal THEN 1
			WHEN m.season='2013/2014' AND m.home_goal != m.away_goal THEN 0
			END), 2) AS pct_ties_2013_2014,
	ROUND(AVG(CASE WHEN m.season='2014/2015' AND m.home_goal = m.away_goal THEN 1
			WHEN m.season='2014/2015' AND m.home_goal != m.away_goal THEN 0
			END), 2) AS pct_ties_2014_2015
FROM country AS c
LEFT JOIN matches AS m
	ON c.id = m.country_id
GROUP BY country;

-- Count of home wins, away wins, and ties in each country

SELECT 
    c.name AS country,
    -- Count the home wins, away wins, and ties in each country
	AVG(CASE WHEN m.home_goal > m.away_goal THEN m.id 
        END) AS home_wins,
	AVG(CASE WHEN m.home_goal < m.away_goal THEN m.id 
        END) AS away_wins,
	AVG (CASE WHEN m.home_goal = m.away_goal THEN m.id 
        END) AS ties
FROM country AS c
LEFT JOIN matches AS m
	ON c.id = m.country_id
GROUP BY country;

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
			WHEN m.season='2013/2014' THEN m.ID
			ELSE NULL
		END 
	) AS matches_2014_2015
FROM country AS c 
LEFT JOIN match AS m 
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

/* Query a list of matches played between the two rivals, Barcelona and Real Madrid, in El Clásico matches. Retrieve information about matches played between Barcelona (id = 8634) and Real Madrid (id = 8633). In games that they played, indicate who was the home team, who was the away team, and who won. */

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
      AND (awayteam_id = 8633 OR hometeam_id = 8633)

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

/*Build a query that identifies the win/loss status of Barcelona's 2011/2012 matches.The matches_spain table currently contains Barcelona's matches from the 2011/2012 season, and has two key columns, hometeam_id and awayteam_id, that can be joined with the teams_spain table. However, you can only join teams_spain to one column at a time.*/

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
	ON m.hometeam_Id=t.team_api_Id
WHERE m.awayteam_Id=8634;

-- Count the number of matches that FC Schalke 04 and FC Bayern Munich heve each played at home using the data split across the filtered teams_germany and matches_germany datasets.

-- Identifying the corresponding API id

SELECT
	team_api_Id,
	team_long_name
FROM teams_germany
WHERE team_long_name IN ('FC Schalke 04', 'FC Bayern Munich');

-- Counting the numbers of each team's home games

SELECT
    CASE 
        WHEN hometeam_Id=10189 THEN 'FC Schalke 04'
        WHEN hometeam_Id=9823 THEN 'FC Bayern Munich'
        ELSE 'Other'
    END AS home_team,
    COUNT(Id) AS total_matches
FROM matches_germany
GROUP BY home_team;

