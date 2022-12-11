-- First I will union the 12 monthly bike trip data tables into a single table consisting of all bike trips from - Jan 1, 2021 to Dec 31, 2021. --

SELECT *
INTO [bike_tripdata_2021.combined]
FROM (
	SELECT * FROM [bike_tripdata_jan.2021]
	UNION ALL
	SELECT * FROM [bike_tripdata_feb.2021]
	UNION ALL
	SELECT * FROM [bike_tripdata_mar.2021]
	UNION ALL
	SELECT * FROM [bike_tripdata_apr.2021]
	UNION ALL
	SELECT * FROM [bike_tripdata_may.2021]
	UNION ALL
	SELECT * FROM [bike_tripdata_jun.2021]
	UNION ALL
	SELECT * FROM [bike_tripdata_jul.2021]
	UNION ALL
	SELECT * FROM [bike_tripdata_aug.2021]
	UNION ALL
	SELECT * FROM [bike_tripdata_sep.2021]
	UNION ALL
	SELECT * FROM [bike_tripdata_oct.2021]
	UNION ALL
	SELECT * FROM [bike_tripdata_nov.2021]
	UNION ALL
	SELECT * FROM [bike_tripdata_dec.2021]
	) AS combined_data

	SELECT *
	FROM [bike_tripdata_2021.combined]

/* After compiling all the data into a single table the SELECT * function of the new table brings back 5,595,063 rows.
I doubled checked to see if all the data has been combined by selecting all the 12 tables together and this returned the same number of rows. */
------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Before I start looking to clean the data, I will add new columns "ride_length" and "day_of_week" as required in briefing --

ALTER TABLE [bike_tripdata_2021.combined]
ADD ride_length INT

UPDATE [bike_tripdata_2021.combined]
SET ride_length = DATEDIFF(MINUTE, started_at, ended_at)

ALTER TABLE [bike_tripdata_2021.combined]
ADD day_of_week nvarchar(50)

UPDATE [bike_tripdata_2021.combined]
SET day_of_week = DATENAME(WEEKDAY, started_at)

/* I will also add a month column for sake of further analysis */

ALTER TABLE [bike_tripdata_2021.combined]
ADD month_name nvarchar(50)

UPDATE [bike_tripdata_2021.combined]
SET month_name = DATENAME(MONTH, started_at)

-- Now I will being cleaning the data by checking for mispellings and irregularities of columns containing strings using DISTINCT as well as checking ride_id as the Primary key --

-- Col #1 - ride_id --

SELECT LEN(ride_id), COUNT(*)
FROM [bike_tripdata_2021.combined]
GROUP BY LEN(ride_id)

SELECT COUNT(DISTINCT ride_id)
FROM [bike_tripdata_2021.combined]

/* All ride_id strings are 16 characters long and they are all distinct.
Cleaning is not required on this column. */

-- Col #2 & Col #13 rideable_type & member_casual --

SELECT DISTINCT rideable_type
FROM [bike_tripdata_2021.combined]

SELECT DISTINCT member_casual
FROM [bike_tripdata_2021.combined]

/* There are 3 types of rideable bikes electric, classic and docked & two customer types member and casual. No cleaning required here */

-- Col #5 & #7 start_station_name & end_station_name --

SELECT DISTINCT start_station_name, end_station_name
FROM [bike_tripdata_2021.combined]

/* These columns look fine apart from some NULL values in each of them. For this project I will remove these rows due to time constraints on the project
and the fact the vast majority of data remains to make informed analysis. */

DELETE FROM [bike_tripdata_2021.combined]
WHERE start_station_name IS NULL

DELETE FROM [bike_tripdata_2021.combined]
WHERE end_station_name IS NULL

-- Some ride lengths are negative and over 24 hours. This is clearly an error. I will remove these rows --

SELECT MIN(ride_length), MAX(ride_length)
FROM [bike_tripdata_2021.combined]

SELECT COUNT(ride_length) AS negative_ride_length
FROM [bike_tripdata_2021.combined]
WHERE ride_length < 1

SELECT COUNT(ride_length) AS rides_longer_than_24h
FROM [bike_tripdata_2021.combined]
WHERE ride_length > 1440

DELETE FROM [bike_tripdata_2021.combined]
WHERE ride_length < 1

DELETE FROM [bike_tripdata_2021.combined]
WHERE ride_length > 1440

/* Checked all other columns for NULLs in case more needed to be removed. No more NULLs present */

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Analysing the cleaned data --

-- Count of members and casual riders --

SELECT DISTINCT member_casual, COUNT(*) AS number_of_rides
FROM [bike_tripdata_2021.combined]
GROUP BY member_casual

--------------------------------------------------------------------------------

-- Which bike is most and least used by members and casual riders? --

SELECT rideable_type, member_casual, COUNT(*) AS bike_usage_count
FROM [bike_tripdata_2021.combined]
GROUP BY rideable_type, member_casual
ORDER BY bike_usage_count DESC

--------------------------------------------------------------------------------

-- Finding the average, min and max ride length for all riders --

SELECT MIN(ride_length) AS min_ride_length, MAX(ride_length) AS max_ride_length, AVG(ride_length) AS average_ride_length 
FROM [bike_tripdata_2021.combined] 

/* Max ride length 1440 minutes, Min ride length less than a minute, average ride length 19 minutes.*/


--------------------------------------------------------------------------------

-- Finding the average ride length for members and casual riders --

SELECT member_casual, AVG(ride_length) AS average_ride_length
FROM [bike_tripdata_2021.combined]
GROUP BY member_casual


/* average ride length for members: 13 minutes. For casual riders: 28 minutes */

--------------------------------------------------------------------------------

-- How many trips per month for members and casual riders --

SELECT member_casual, month_name, COUNT(*) AS num_of_monthly_rides
FROM [bike_tripdata_2021.combined]
GROUP BY member_casual, month_name


-- Average ride length for both members and casual riders for each month.--

/* SELECT month_name, AVG(ride_length) AS avg_monthly_ride_length_member
FROM [bike_tripdata_2021.combined]
WHERE member_casual = 'member'
GROUP BY month_name
ORDER BY avg_monthly_ride_length_member DESC

SELECT month_name, AVG(ride_length) AS avg_monthly_ride_length_casual
FROM [bike_tripdata_2021.combined]
WHERE member_casual = 'casual'
GROUP BY month_name
ORDER BY avg_monthly_ride_length_casual DESC  Not necessary need to seperate these two queries so I commented them out*/

SELECT member_casual, month_name, AVG(ride_length) AS avg_ride_length
FROM [bike_tripdata_2021.combined]
GROUP BY month_name, member_casual


--------------------------------------------------------------------------------


-- Amount of trips each day for members and casual riders --

SELECT member_casual, day_of_week, COUNT(*) AS num_of_daily_rides
FROM [bike_tripdata_2021.combined]
GROUP BY member_casual, day_of_week
ORDER BY num_of_daily_rides DESC 


-- Average ride length for both members and casual riders for each day of the week. --

SELECT day_of_week, AVG(ride_length) AS avg_daily_ride_length_member
FROM [bike_tripdata_2021.combined]
WHERE member_casual = 'member'
GROUP BY day_of_week
ORDER BY avg_daily_ride_length_member DESC

SELECT day_of_week, AVG(ride_length) AS avg_daily_ride_length_casual
FROM [bike_tripdata_2021.combined]
WHERE member_casual = 'casual'
GROUP BY day_of_week
ORDER BY avg_daily_ride_length_casual DESC


----------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------

--Creating Visualisations --


/* Count of riders */
CREATE VIEW count_of_riders AS
SELECT DISTINCT member_casual, COUNT(*) AS number_of_rides
FROM [bike_tripdata_2021.combined]
GROUP BY member_casual

/* Bike type usage */
CREATE VIEW bike_type_usage AS
SELECT rideable_type, member_casual, COUNT(*) AS bike_usage_count
FROM [bike_tripdata_2021.combined]
GROUP BY rideable_type, member_casual

/* Average ride length for for each user type */
CREATE VIEW avg_user_ride_length AS
SELECT member_casual, AVG(ride_length) AS average_ride_length
FROM [bike_tripdata_2021.combined]
GROUP BY member_casual

/* Monthly riders */
CREATE VIEW monthly_riders AS
SELECT member_casual, month_name, COUNT(*) AS num_of_monthly_rides
FROM [bike_tripdata_2021.combined]
GROUP BY member_casual, month_name

/* Average monthly ride length for users */
CREATE VIEW avg_monthly_ride_length AS
SELECT member_casual, month_name, AVG(ride_length) AS avg_ride_length
FROM [bike_tripdata_2021.combined]
GROUP BY month_name, member_casual

/* Daily riders */
CREATE VIEW daily_riders AS
SELECT member_casual, day_of_week, COUNT(*) AS num_of_daily_rides
FROM [bike_tripdata_2021.combined]
GROUP BY member_casual, day_of_week

/* Average daily ride lengths for members and casual riders */

CREATE VIEW daily_ride_length_members AS
SELECT day_of_week, AVG(ride_length) AS avg_daily_ride_length_member
FROM [bike_tripdata_2021.combined]
WHERE member_casual = 'member'
GROUP BY day_of_week

CREATE VIEW daily_ride_length_casual AS
SELECT day_of_week, AVG(ride_length) AS avg_daily_ride_length_casual
FROM [bike_tripdata_2021.combined]
WHERE member_casual = 'casual'
GROUP BY day_of_week


