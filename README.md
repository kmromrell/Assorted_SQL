# Assorted_SQL

This is a compilation of the queries I wrote while in the DataCamp SQL Data Analytics career track. It serves as both a personal reference for past queries and a demonstration of my present SQL skills. My basic approach to this course was to write all my queries from scratch (deleting the fill-in-the-blank style prompts), which sometimes resulted in me using different methods than the course intended. In those cases, I included both my method query and the method intended by DataCamp so that I practiced both 1) coming up with my own methods to solve questions, and 2) practicing new functions that I wasn't yet comfortable with.

## Master List of Functions/Expressions:  
*(Note: This list is compiled by ChatGPT and checked/reorganized by me)*

### SQL Basics
* Essentials: `SELECT`, `FROM`, `WHERE`
* Grouping: `GROUP BY`, `HAVING`
* Viewing/Aliases: `ORDER BY`, `LIMIT`, `DISTINCT`, `AS`, `ASC`, `DESC`
* Combinations: `AND`, `OR`, `IN`, `NOT IN`, `LIKE`, `NOT LIKE`, `BETWEEN`
* Basic Operators: `=`, `<`, `>`, `<=`, `>=`, `<>`, `!=`
* Basic Arithmetics: `+`, `-`, `*`, `/`

### Aggregate Functions
* Basic Aggregates: `COUNT()`, `SUM()`, `AVG()`, `MIN()`, `MAX()`
* Advanced Aggregates: `ROUND()`, `STRING_AGG()`, `STDDEV()`, `CORR()`, `PERCENTILE_DISC()`, `PERCENTILE_CONT()`
* Advanced Grouping Sets: `ROLLUP()`, `CUBE()`, `GROUPING SETS()`

### Window Functions
* Ranking & Positioning: `RANK() OVER()`, `DENSE_RANK() OVER()`, `ROW_NUMBER() OVER()`, `NTILE(n) OVER()`
* Value Retrieval: `FIRST_VALUE() OVER()`, `LEAD() OVER()`, `LAG() OVER()`
* Aggregates Over Window: `SUM() OVER()`, `AVG() OVER()`, `ROUND() OVER()`
* Window Framing/Partitioning: `PARTITION BY`, `ORDER BY`, `CURRENT ROW`, `UNBOUNDED PRECEDING`, `FOLLOWING`, etc.

### Conditional Expressions
* Conditional Logic: `CASE WHEN ... THEN ... ELSE ... END`
* Null Handling: `COALESCE()`, `IS NULL`, `IS NOT NULL`
* Type Conversion: `CAST()`

### Text and String Functions
* Trimming & Substring: `LEFT()`, `RTRIM()`, `LTRIM()`, `TRIM()`, `SUBSTR()`, `SUBSTRING()`, `POSITION()`, `REVERSE()`
* Capitalization: `INITCAP()`, `UPPER()`, `LOWER()`
* Concatenation & Splitting: `CONCAT()`, `SPLIT_PART()`
* Replacement & Padding: `REPLACE()`, `RPAD()`, `LPAD()`
* Length & Matching: `LENGTH()`, `ILIKE`, `LIKE`

### Date and Time Functions
* Extraction & Truncation: `EXTRACT()`, `DATE_TRUNC()`
* Current Time: `NOW()`, `CURRENT_TIMESTAMP`, `CURRENT_DATE`, `CURRENT_TIME`
* Intervals & Arithmetic: `INTERVAL`
* Formatting: `TO_CHAR()`

### Joins & Other Combination Queries
* Joins: `LEFT JOIN`, `INNER JOIN`, `CROSS JOIN`, `FULL OUTER JOIN`, `RIGHT JOIN`, `ON`, `USING()`
* Set Operations: `UNION`, `INTERSECT`
* CTEs/Subqueries: `WITH`, `EXISTS`, `NOT EXISTS` (subqueries used in `SELECT`, `FROM`, and `WHERE`/`HAVING` clauses)

### PostgreSQL-Specific Functions
* Fuzzy Matching & Full-Text Search: `similarity()`, `levenshtein()`, `to_tsvector()`, `to_tsquery()`, `@@`
* Array Data Types & Operators: `@>`, `= ANY()`, `array[index]`
* Cast Operators: `::numeric`, `::integer`, etc.
* Date/Set Returning: `AGE()`, `DATE_PART()`, `GENERATE_SERIES()`, `FILTER()`
* Other: `CREATE EXTENSION`
