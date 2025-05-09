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

