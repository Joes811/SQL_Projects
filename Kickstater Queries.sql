------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Looking over the data and cleaning if needed --

SELECT *
FROM kickstarter_projects

/* Immediately I see the "Launched" and "Deadline" columns are datetime, I will change this to Date as time is irrelevant here. 
I will also changed pledged to integer */

ALTER TABLE kickstarter_projects
ALTER COLUMN Launched date NOT NULL

ALTER TABLE kickstarter_projects
ALTER COLUMN Deadline date NOT NULL

ALTER TABLE kickstarter_projects
ALTER COLUMN Pledged INT NOT NULL

/* Checked each column for null values, non present. Also checked columns distinct to identify any typos/incorrect entries */
SELECT COUNT(*)
FROM kickstarter_projects
WHERE State IS NULL

SELECT DISTINCT State
FROM kickstarter_projects

/* Since I'm only interested in the success or failure of projects I will remove the other state options as Successful and Failed make up 88% of the dataset*/

SELECT 
(SELECT CAST(COUNT(State) AS FLOAT) AS relevant_states
FROM kickstarter_projects
WHERE State = 'Successful' OR State = 'Failed')
/
(SELECT CAST(COUNT(State) AS FLOAT) AS Total_states
FROM kickstarter_projects)*100

DELETE FROM kickstarter_projects
WHERE State IN ('Live', 'Canceled', 'Suspended')


/* Data is clean and ready to be explored and analysed for the questions I have proposed */

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Analysing the data --

-- Which Category has the highest success percentage? How many projects have been successful? --

SELECT t1.Category, (t1.Success + t2.Failed) AS Total, ROUND((t1.Success / (t1.Success + t2.Failed)),2)*100 AS Success_rate
FROM
	(SELECT Category, CAST(COUNT(State) AS FLOAT) AS Success
	FROM kickstarter_projects
	WHERE State = 'Successful'
	GROUP BY Category) AS t1,
	(SELECT Category, CAST(Count(State) AS FLOAT) AS Failed
	FROM kickstarter_projects
	WHERE State = 'Failed'
	GROUP BY Category) AS t2
WHERE t1.Category = t2.Category
ORDER BY Success_rate DESC

/* Dance projects have the highest success rate with 65% but they also have a low amount of projects as a whole when compared to others. */

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- What project with a goal over $1000 has the biggest goal completion % (pledged / Goal)? How much money was pledged? --

/* I had to build a query where when the goal is 0 then to return 0 because I was having issues with "cannot divide by 0" error. */

SELECT TOP 5 Name, Goal, Pledged,
CASE
	WHEN Goal = 0 THEN 0 
	ELSE ROUND(CAST(Pledged AS FLOAT)/(CAST(Goal AS FLOAT)),2)*100
	END AS goal_completion
FROM kickstarter_projects
WHERE Goal > 1000
ORDER BY goal_completion DESC

/* Exploding Kittens has by far the biggest goal completion with a whopping 87826% of the goal pledged, the pledged amount was $8,782,572 */

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Identify any trends in project success rates over the years? --

SELECT ys.Year, (ys.Success + yf.Failed) AS Total, ROUND((ys.Success / (ys.Success + yf.Failed)),2)*100 AS Success_rate
FROM
	(SELECT YEAR(Launched) AS Year, CAST(COUNT(State) AS FLOAT) AS Success
	FROM kickstarter_projects
	WHERE State = 'Successful'
	GROUP BY YEAR(Launched), State) AS ys,
	(SELECT YEAR(Launched) AS Year, CAST(COUNT(State) AS FLOAT) AS Failed
	FROM kickstarter_projects
	WHERE State = 'Failed'
	GROUP BY YEAR(Launched), State) AS yf
WHERE ys.Year = yf.Year
GROUP BY ys.Year, ys.Success, yf.Failed
ORDER BY ys.Year


/* I will identify trends from this in visualisation, from a quick glance it seems as the success rates are trending downwards */

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- What country has the highest success rate from projects and where are the majority based? --

/* For this I can use the above query with and just change the year to country so I can get the number of projects and their success rates */

SELECT ys.Country, (ys.Success + yf.Failed) AS Total, ROUND((ys.Success / (ys.Success + yf.Failed)),2)*100 AS Success_rate
FROM
	(SELECT Country, CAST(COUNT(State) AS FLOAT) AS Success
	FROM kickstarter_projects
	WHERE State = 'Successful'
	GROUP BY Country, State) AS ys,
	(SELECT Country, CAST(COUNT(State) AS FLOAT) AS Failed
	FROM kickstarter_projects
	WHERE State = 'Failed'
	GROUP BY Country, State) AS yf
WHERE ys.Country = yf.Country
GROUP BY ys.Country, ys.Success, yf.Failed
ORDER BY Success_rate DESC

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- With the United States been the biggest player in kickstarter projects, which products would I recommend investors back better their chances of success? --

/* I will filter only for projects in the United States as they have the vast majority of the start ups. I will also find the average total of each product type
and only include the average of above to ensure a good sample size */

/* First I will find the average amount of projects launched in all subcategories. Which equals 1643.*/

SELECT AVG(Total) AS avg_projects
FROM
	(SELECT Subcategory, COUNT(*) AS Total
	FROM kickstarter_projects
	WHERE Country = 'United States'
	GROUP BY Subcategory) AS counted_projects

-----
/* I will create a CTE to find the project success rates for each category & subcategory where the projects are based in the United states and have more or equal to the
average amount of projects on kickstarter to ensure a good sample size. */

/* This is the primary category CTE */

WITH average_success_rate_cat AS
	(SELECT t1.Category, t1.Success, t2.Failed, (t1.Success + t2.Failed) AS Total
FROM
	(SELECT Category, CAST(COUNT(State) AS FLOAT) AS Success
	FROM kickstarter_projects
	WHERE State = 'Successful' AND Country = 'United States'
	GROUP BY Category) AS t1,
	(SELECT Category, CAST(Count(State) AS FLOAT) AS Failed
	FROM kickstarter_projects
	WHERE State = 'Failed' AND Country = 'United States'
	GROUP BY Category) AS t2
WHERE t1.Category = t2.Category)
SELECT asr.Category, AVG(asr.Total) AS num_projects, ROUND((asr.Success) / (asr.Total),2)*100 AS success_rate
FROM kickstarter_projects ks
JOIN average_success_rate_cat asr
	ON ks.Category = asr.Category
WHERE asr.Total >= (SELECT AVG(Total) FROM (
  SELECT Category, COUNT(*) AS Total
  FROM kickstarter_projects
  WHERE Country = 'United States'
  GROUP BY Category
) AS counted_projects)
GROUP BY asr.Category, asr.Success, asr.Total 
ORDER BY success_rate DESC

/* This is the subcategory CTE and I have filtered to only show results that have over 50% success rate */

WITH average_success_rate_subcat AS
	(SELECT t1.Subcategory, t1.Success, t2.Failed, (t1.Success + t2.Failed) AS Total
FROM
	(SELECT Subcategory, CAST(COUNT(State) AS FLOAT) AS Success
	FROM kickstarter_projects
	WHERE State = 'Successful' AND Country = 'United States'
	GROUP BY Subcategory) AS t1,
	(SELECT Subcategory, CAST(Count(State) AS FLOAT) AS Failed
	FROM kickstarter_projects
	WHERE State = 'Failed' AND Country = 'United States'
	GROUP BY Subcategory) AS t2
WHERE t1.Subcategory = t2.Subcategory)
SELECT asr.Subcategory, AVG(asr.Total) AS num_projects, ROUND((asr.Success) / (asr.Total),2)*100 AS success_rate
FROM kickstarter_projects ks
JOIN average_success_rate_subcat asr
	ON ks.Subcategory = asr.Subcategory
WHERE asr.Total >= (SELECT AVG(Total) FROM (
  SELECT Subcategory, COUNT(*) AS Total
  FROM kickstarter_projects
  WHERE Country = 'United States'
  GROUP BY Subcategory
) AS counted_projects) AND ROUND((asr.Success) / (asr.Total),2)*100 > 50
GROUP BY asr.Subcategory, asr.Success, asr.Total 
ORDER BY success_rate DESC

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Creating views for visualisation --

-- 1. Which Category has the highest success percentage? How many projects have been successful? --

CREATE VIEW category_success_rates AS
SELECT t1.Category, (t1.Success + t2.Failed) AS Total, ROUND((t1.Success / (t1.Success + t2.Failed)),2)*100 AS Success_rate
FROM
	(SELECT Category, CAST(COUNT(State) AS FLOAT) AS Success
	FROM kickstarter_projects
	WHERE State = 'Successful'
	GROUP BY Category) AS t1,
	(SELECT Category, CAST(Count(State) AS FLOAT) AS Failed
	FROM kickstarter_projects
	WHERE State = 'Failed'
	GROUP BY Category) AS t2
WHERE t1.Category = t2.Category

-- 2. What project with a goal over $1000 has the biggest goal completion % (pledged / Goal)? How much money was pledged? --

CREATE VIEW goal_completion AS
SELECT TOP 5 Name, Goal, Pledged,
CASE
	WHEN Goal = 0 THEN 0 
	ELSE ROUND(CAST(Pledged AS FLOAT)/(CAST(Goal AS FLOAT)),2)*100
	END AS goal_completion
FROM kickstarter_projects
WHERE Goal > 1000
ORDER BY goal_completion DESC

-- 3. Identify any trends in project success rates over the years? --

CREATE VIEW yearly_success_trends AS
SELECT ys.Year, (ys.Success + yf.Failed) AS Total, ROUND((ys.Success / (ys.Success + yf.Failed)),2)*100 AS Success_rate
FROM
	(SELECT YEAR(Launched) AS Year, CAST(COUNT(State) AS FLOAT) AS Success
	FROM kickstarter_projects
	WHERE State = 'Successful'
	GROUP BY YEAR(Launched), State) AS ys,
	(SELECT YEAR(Launched) AS Year, CAST(COUNT(State) AS FLOAT) AS Failed
	FROM kickstarter_projects
	WHERE State = 'Failed'
	GROUP BY YEAR(Launched), State) AS yf
WHERE ys.Year = yf.Year
GROUP BY ys.Year, ys.Success, yf.Failed

-- 4. What country has the highest success rate from projects and where are the majority based? --

CREATE VIEW country_success_rates AS
SELECT ys.Country, (ys.Success + yf.Failed) AS Total, ROUND((ys.Success / (ys.Success + yf.Failed)),2)*100 AS Success_rate
FROM
	(SELECT Country, CAST(COUNT(State) AS FLOAT) AS Success
	FROM kickstarter_projects
	WHERE State = 'Successful'
	GROUP BY Country, State) AS ys,
	(SELECT Country, CAST(COUNT(State) AS FLOAT) AS Failed
	FROM kickstarter_projects
	WHERE State = 'Failed'
	GROUP BY Country, State) AS yf
WHERE ys.Country = yf.Country
GROUP BY ys.Country, ys.Success, yf.Failed

-- 5. With the United States been the biggest player in kickstarter projects, which products would I recommend investors back better their chances of success? --

/* Categories */

CREATE VIEW category_avg_success_US AS
WITH average_success_rate_cat AS
	(SELECT t1.Category, t1.Success, t2.Failed, (t1.Success + t2.Failed) AS Total
FROM
	(SELECT Category, CAST(COUNT(State) AS FLOAT) AS Success
	FROM kickstarter_projects
	WHERE State = 'Successful' AND Country = 'United States'
	GROUP BY Category) AS t1,
	(SELECT Category, CAST(Count(State) AS FLOAT) AS Failed
	FROM kickstarter_projects
	WHERE State = 'Failed' AND Country = 'United States'
	GROUP BY Category) AS t2
WHERE t1.Category = t2.Category)
SELECT asr.Category, AVG(asr.Total) AS num_projects, ROUND((asr.Success) / (asr.Total),2)*100 AS success_rate
FROM kickstarter_projects ks
JOIN average_success_rate_cat asr
	ON ks.Category = asr.Category
WHERE asr.Total >= (SELECT AVG(Total) FROM (
  SELECT Category, COUNT(*) AS Total
  FROM kickstarter_projects
  WHERE Country = 'United States'
  GROUP BY Category
) AS counted_projects)
GROUP BY asr.Category, asr.Success, asr.Total 

/* Subcategories */

CREATE VIEW subcategory_avg_success_US AS
WITH average_success_rate_subcat AS
	(SELECT t1.Subcategory, t1.Success, t2.Failed, (t1.Success + t2.Failed) AS Total
FROM
	(SELECT Subcategory, CAST(COUNT(State) AS FLOAT) AS Success
	FROM kickstarter_projects
	WHERE State = 'Successful' AND Country = 'United States'
	GROUP BY Subcategory) AS t1,
	(SELECT Subcategory, CAST(Count(State) AS FLOAT) AS Failed
	FROM kickstarter_projects
	WHERE State = 'Failed' AND Country = 'United States'
	GROUP BY Subcategory) AS t2
WHERE t1.Subcategory = t2.Subcategory)
SELECT asr.Subcategory, AVG(asr.Total) AS num_projects, ROUND((asr.Success) / (asr.Total),2)*100 AS success_rate
FROM kickstarter_projects ks
JOIN average_success_rate_subcat asr
	ON ks.Subcategory = asr.Subcategory
WHERE asr.Total >= (SELECT AVG(Total) FROM (
  SELECT Subcategory, COUNT(*) AS Total
  FROM kickstarter_projects
  WHERE Country = 'United States'
  GROUP BY Subcategory
) AS counted_projects) AND ROUND((asr.Success) / (asr.Total),2)*100 > 50
GROUP BY asr.Subcategory, asr.Success, asr.Total 







