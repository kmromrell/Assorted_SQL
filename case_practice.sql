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

