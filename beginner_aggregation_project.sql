SELECT 
	stay,
	COUNT(Inter_dom) AS count_int,
	ROUND(avg(todep), 2) AS average_phq,
	ROUND(avg(tosc), 2) AS average_scs,
	ROUND(avg(toas), 2) AS average_as
FROM students
WHERE Inter_dom='Inter'
GROUP BY
	stay
ORDER BY stay DESC