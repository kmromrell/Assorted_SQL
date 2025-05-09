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

/*Build a query that identifies a match's winner, identifies the identity of the opponent, and finally filters for Barcelona as the home team. Complete the query in multiple steps to allow you to watch your results take shape with each new piece of information.

The matches_spain table currently contains Barcelona's matches from the 2011/2012 season, and has two key columns, hometeam_id and awayteam_id, that can be joined with the teams_spain table. However, you can only join teams_spain to one column at a time.*/

-- To generate code of the victor (with date of the game); 0 signifies a tie

SELECT
	DATE,
	CASE
		WHEN away_goal>home_goal THEN awayteam_Id
		WHEN away_goal<home_goal THEN hometeam_Id
		ELSE 0
	END AS outcome
FROM matches_spain;

-- To generate text identifying home victory/loss

SELECT
	DATE,
	CASE
		WHEN away_goal>home_goal THEN 'Home loss :('
		WHEN away_goal<home_goal THEN 'Home win!'
		ELSE 'Tie'
	END AS outcome
FROM matches_spain;

-- Generate victory/loss text with listed opponent on joint table

SELECT
	m.date,
	t.team_long_name AS opponent,
	CASE
		WHEN m.home_goal>m.away_goal THEN 'Home win!'
		WHEN m.home_goal>m.away_goal THEN 'Home loss :('
		ELSE 'Tie'
	END AS outcome
FROM matches_spain AS m
LEFT JOIN teams_spain AS t
	ON m.awayteam_Id=t.team_api_Id;

-- Filtering to only when Barcelona was the home team

SELECT
	m.date,
	t.team_long_name AS opponent,
	CASE
		WHEN m.home_goal>m.away_goal THEN 'Barcelona win!'
		WHEN m.home_goal<m.away_goal THEN 'Barcelona loss :('
		ELSE 'Tie'
	END AS outcome
FROM matches_spain AS m
LEFT JOIN teams_spain AS t
	ON m.awayteam_Id=t.team_api_Id
WHERE m.hometeam_Id=8634;

-- Filtering to only when Barcelona is the away team

SELECT
	m.date,
	t.team_long_name AS opponent,
	CASE
		WHEN m.home_goal<m.away_goal THEN 'Barcelona win!'
		WHEN m.home_goal>m.away_goal THEN 'Barcelona loss :('			ELSE 'Tie'
	END AS outcome
FROM matches_spain AS m
LEFT JOIN teams_spain AS t
	ON m.hometeam_Id=t.team_api_Id
WHERE m.awayteam_Id=8634;


-- Union to result in Barcelona's win/loss status regardless of if at home/away

SELECT
	m.date,
	t.team_long_name AS opponent,
	CASE
		WHEN m.home_goal<m.away_goal THEN 'Barcelona win!'
		WHEN m.home_goal>m.away_goal THEN 'Barcelona loss :('
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
		WHEN m.home_goal<m.away_goal THEN 'Barcelona win!'
		WHEN m.home_goal>m.away_goal THEN 'Barcelona loss :('			ELSE 'Tie'
	END AS outcome
FROM matches_spain AS m
LEFT JOIN teams_spain AS t
	ON m.hometeam_Id=t.team_api_Id
WHERE m.awayteam_Id=8634;