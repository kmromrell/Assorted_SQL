/*Explore and analyze the students data to see how the length of stay (stay) impacts the average mental health diagnostic scores of the international students present in the study.

	1. Return a table with nine rows and five columns.
	2. The five columns should be aliased as: stay, count_int, average_phq, average_scs, and average_as, in that order.
	3. The average columns should contain the average of the todep (PHQ-9 test), tosc (SCS test), and toas (ASISS test) columns for each length of stay, rounded to two decimal places.
	4. The count_int column should be the number of international students for each length of stay.
	5. Sort the results by the length of stay in descending order.*/

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