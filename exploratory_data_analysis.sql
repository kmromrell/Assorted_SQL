-- Exploratory Data Analysis


-- -- First, using the tag_type table, count the number of tags with each type. Order the results to find the most common tag type. Then enerate a list of companies using the most common tag type, joining together the necessary tables

SELECT  
  type,
  count(*) AS total
FROM tag_type
GROUP BY type
ORDER BY total DESC;

SELECT 
  c.name,
  tt.tag,
  tt.type
FROM company AS c
  INNER JOIN tag_company AS tc 
    ON c.id=tc.company_id
  INNER JOIN tag_type AS tt 
    ON tc.tag=tt.tag
WHERE type='cloud'; 

-- Using the entity relationship diagram, find the foreign key(s) aligning fortune500 to company and join them to show records that show up in both tables

SELECT *
FROM fortune500 
INNER JOIN company USING(ticker)


-- Does column ticker or industry have more missing values?

SELECT 
	count(*)-count(ticker) AS missing_ticker,
	count(*)-count(industry) AS missing_industry
FROM fortune500