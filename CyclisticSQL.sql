--This project was done using a real data set from a real bike-share company, stripped of personal details and made freely available to the public by Divvy.
--I first downloaded all of the 2022 bike-share data (202201-divvy-tripdata.zip, 202202-divvy-tripdata.zip... 202212-divvy-tripdata.zip) from https://divvy-tripdata.s3.amazonaws.com/index.html.
--Then I extracted the respective .csv files, wrote a macro to add the 'day_number' column to each of the sheets, saved the sheets as workbooks (.xlsx), and then imported those workbooks into my local server database 'Cyclistic' via SQL Server Management Studio.
--I renamed the tables to match the format 'TripData2022xx' (where xx is the two digit numeral for the month).

--The primary questions I'm tasked with answering for the fictional bike-share company Cyclistic are:
--How do annual members and casual riders use Cyclistic bikes differently?
--Why would casual riders buy Cyclistic annual memberships?
--How can Cyclistic use digital media to influence casual riders to become members?

--In addition to answering these questions I also want to thorougly inspect and clean all of the data, to validate its integrity and explore what other insights I might be able to glean.
--I'll walk through every step of my process in the comments.

--First and foremost I want to back up my imported tables, just in case.

USE Cyclistic

SELECT * INTO TripData202201_backup FROM TripData202201;
SELECT * INTO TripData202202_backup FROM TripData202202;
SELECT * INTO TripData202203_backup FROM TripData202203;
SELECT * INTO TripData202204_backup FROM TripData202204;
SELECT * INTO TripData202205_backup FROM TripData202205;
SELECT * INTO TripData202206_backup FROM TripData202206;
SELECT * INTO TripData202207_backup FROM TripData202207;
SELECT * INTO TripData202208_backup FROM TripData202208;
SELECT * INTO TripData202209_backup FROM TripData202209;
SELECT * INTO TripData202210_backup FROM TripData202210;
SELECT * INTO TripData202211_backup FROM TripData202211;
SELECT * INTO TripData202212_backup FROM TripData202212;

--I want to create a new table combining all 12 tables to more easily work with data for the whole year, so I will write a query that checks for column name or data type conflicts between the tables.

SELECT 
    a.TABLE_NAME AS Table1,
    b.TABLE_NAME AS Table2,
    a.COLUMN_NAME,
    a.DATA_TYPE AS DataType1,
    b.DATA_TYPE AS DataType2
FROM 
    INFORMATION_SCHEMA.COLUMNS a
JOIN 
    INFORMATION_SCHEMA.COLUMNS b
ON 
    a.COLUMN_NAME = b.COLUMN_NAME
WHERE 
    a.TABLE_NAME IN ('TripData202201', 'TripData202202', 'TripData202203', 'TripData202204', 'TripData202205', 'TripData202206', 'TripData202207', 'TripData202208', 'TripData202209', 'TripData202210', 'TripData202211', 'TripData202212')
AND 
    b.TABLE_NAME IN ('TripData202201', 'TripData202202', 'TripData202203', 'TripData202204', 'TripData202205', 'TripData202206', 'TripData202207', 'TripData202208', 'TripData202209', 'TripData202210', 'TripData202211', 'TripData202212')
AND
    a.TABLE_NAME <> b.TABLE_NAME
AND
    a.DATA_TYPE <> b.DATA_TYPE

--There are data type conflicts between the start_station_id columns and the end_station_id columns, so I will inspect a sample.

SELECT TOP 10 start_station_id
FROM TripData202205
WHERE start_station_id IS NOT NULL;

SELECT TOP 10 start_station_id
FROM TripData202204
WHERE start_station_id IS NOT NULL;

--Some of the months contain station id's which don't follow the same naming convention as the rest.
--Given that these values are simply used to identify a corresponding station, I will convert the conflicting floats to nvarchar so that I can execute a union.

--For start_station_id column.

ALTER TABLE TripData202201
ALTER COLUMN start_station_id NVARCHAR(255);

ALTER TABLE TripData202202
ALTER COLUMN start_station_id NVARCHAR(255);

ALTER TABLE TripData202203
ALTER COLUMN start_station_id NVARCHAR(255);

ALTER TABLE TripData202204
ALTER COLUMN start_station_id NVARCHAR(255);

ALTER TABLE TripData202205
ALTER COLUMN start_station_id NVARCHAR(255);

ALTER TABLE TripData202206
ALTER COLUMN start_station_id NVARCHAR(255);

ALTER TABLE TripData202207
ALTER COLUMN start_station_id NVARCHAR(255);

ALTER TABLE TripData202208
ALTER COLUMN start_station_id NVARCHAR(255);

ALTER TABLE TripData202209
ALTER COLUMN start_station_id NVARCHAR(255);

ALTER TABLE TripData202210
ALTER COLUMN start_station_id NVARCHAR(255);

ALTER TABLE TripData202211
ALTER COLUMN start_station_id NVARCHAR(255);

ALTER TABLE TripData202212
ALTER COLUMN start_station_id NVARCHAR(255);

--And for the end_station_id column.

ALTER TABLE TripData202201
ALTER COLUMN end_station_id NVARCHAR(255);

ALTER TABLE TripData202202
ALTER COLUMN end_station_id NVARCHAR(255);

ALTER TABLE TripData202203
ALTER COLUMN end_station_id NVARCHAR(255);

ALTER TABLE TripData202204
ALTER COLUMN end_station_id NVARCHAR(255);

ALTER TABLE TripData202205
ALTER COLUMN end_station_id NVARCHAR(255);

ALTER TABLE TripData202206
ALTER COLUMN end_station_id NVARCHAR(255);

ALTER TABLE TripData202207
ALTER COLUMN end_station_id NVARCHAR(255);

ALTER TABLE TripData202208
ALTER COLUMN end_station_id NVARCHAR(255);

ALTER TABLE TripData202209
ALTER COLUMN end_station_id NVARCHAR(255);

ALTER TABLE TripData202210
ALTER COLUMN end_station_id NVARCHAR(255);

ALTER TABLE TripData202211
ALTER COLUMN end_station_id NVARCHAR(255);

ALTER TABLE TripData202212
ALTER COLUMN end_station_id NVARCHAR(255);

--Executing the initial conflict check again now yields no results, so I should be clear to create a new table that combines them with a union.
--I'll call the new table All_2022_Trips.

SELECT *
INTO dbo.All_2022_Trips
FROM TripData202201
UNION
SELECT *
FROM TripData202202
UNION
SELECT *
FROM TripData202203
UNION
SELECT *
FROM TripData202204
UNION
SELECT *
FROM TripData202205
UNION
SELECT *
FROM TripData202206
UNION
SELECT *
FROM TripData202207
UNION
SELECT *
FROM TripData202208
UNION
SELECT *
FROM TripData202209
UNION
SELECT *
FROM TripData202210
UNION
SELECT *
FROM TripData202211
UNION
SELECT *
FROM TripData202212;

--Now I'll take a sample of the new table.

SELECT TOP 1000 * FROM All_2022_Trips

--I can see that there are some NULL values peppered throughout the data, particularly in the station name and station id columns. I should be able to fill these in by inferring their values from matching sets of names, id numbers, and/or coordinate pairs.
--I'll make a backup of the current table before I start applying updates.

SELECT *
INTO All_2022_Trips_backup1
FROM All_2022_Trips;

--I'll use four common table expressions to fill in null values in the station name / id columns that have matching pairs to infer from.

WITH CTE AS
(
  SELECT 
    start_station_id, 
    start_station_name, 
    MAX(start_station_name) OVER (PARTITION BY start_station_id) as new_start_station_name
  FROM 
    All_2022_Trips
)
UPDATE CTE 
SET start_station_name = new_start_station_name
WHERE start_station_name IS NULL;

WITH CTE AS
(
  SELECT 
    end_station_id, 
    end_station_name, 
    MAX(end_station_name) OVER (PARTITION BY end_station_id) as new_end_station_name
  FROM 
    All_2022_Trips
)
UPDATE CTE 
SET end_station_name = new_end_station_name
WHERE end_station_name IS NULL;

WITH CTE AS
(
  SELECT 
    start_station_id, 
    start_station_name, 
    MAX(start_station_id) OVER (PARTITION BY start_station_name) as new_start_station_id
  FROM 
    All_2022_Trips
)
UPDATE CTE 
SET start_station_id = new_start_station_id
WHERE start_station_id IS NULL;

WITH CTE AS
(
  SELECT
    end_station_id,
    end_station_name,
    MAX(end_station_id) OVER (PARTITION BY end_station_name) as new_end_station_id
  FROM
    All_2022_Trips
)
UPDATE CTE 
SET end_station_id = new_end_station_id
WHERE end_station_id IS NULL;

--Now I'll double check to see if there are any null values left in these columns.

SELECT ride_id
FROM All_2022_Trips
WHERE start_station_id IS NULL
OR start_station_name IS NULL
OR end_station_id IS NULL
OR end_station_name IS NULL;

--There are 1065 rows with station name values that didn't have a matching pair to refer to in the columns I specified. They are all associated with three stations in particular.

SELECT * 
FROM All_2022_Trips 
WHERE (start_station_name = 'Green St & Madison Ave*' OR start_station_name = 'Loomis St & Lexington St*') 
AND end_station_id IS NOT NULL;

SELECT * 
FROM All_2022_Trips 
WHERE end_station_name = 'Divvy Valet - Oakwood Beach' 
AND start_station_id IS NOT NULL;

--I found station id matches for these station names in the other columns, so I'll just do a quick update on these three specific instances.

UPDATE All_2022_Trips
SET end_station_id = 'chargingstx07'
WHERE end_station_name = 'Green St & Madison Ave*';

UPDATE All_2022_Trips
SET end_station_id = 'chargingstx06'
WHERE end_station_name = 'Loomis St & Lexington St*';

UPDATE All_2022_Trips
SET start_station_id = 'Divvy Valet - Oakwood Beach'
WHERE start_station_name = 'Divvy Valet - Oakwood Beach';

--Now I'll check to see if there are any NULL values left in the whole table.

SELECT *
FROM All_2022_Trips
	WHERE ride_id IS NULL
	OR rideable_type IS NULL
	OR started_at IS NULL
	OR ended_at IS NULL
	OR start_lat IS NULL
	OR start_lng IS NULL
	OR end_lat IS NULL
	OR end_lng IS NULL
	OR member_casual IS NULL
	OR start_station_id IS NULL
	OR start_station_name IS NULL
	OR end_station_id IS NULL
	OR end_station_name IS NULL;

--The end_lat and end_lng columns for end_station_name = 'Yates Blvd & 75th St' are all NULL, but I do have coordinates associated with the same station in start_station_name.
--Since the coordinates for a given station are all fairly close together and they're all describing the same general location, I will simply apply the average of start_lat and start_lng for this station to the all NULL values in end_lat and end_lng.
	
UPDATE All_2022_Trips
SET end_lat =
(
    SELECT ROUND(AVG(start_lat), 6)
    FROM All_2022_Trips
    WHERE start_station_id = 'KA1503000024'
    AND start_lat IS NOT NULL
)
WHERE end_station_id = 'KA1503000024'
AND end_lat IS NULL;

UPDATE All_2022_Trips
SET end_lng =
(
    SELECT ROUND(AVG(start_lng), 6)
    FROM All_2022_Trips
    WHERE start_station_id = 'KA1503000024'
    AND start_lng IS NOT NULL
)
WHERE end_station_id = 'KA1503000024'
AND end_lng IS NULL;

Executing my NULL check again returns 0 rows.
Now that all of the NULL values in the table have been addressed, I'll investigate any further cleaning that might be necessary.

--I know that ride_id should be distinct for each row so I'll check for duplicates.

SELECT *
FROM All_2022_Trips
WHERE ride_id IN
(
    SELECT ride_id
    FROM All_2022_Trips
    GROUP BY ride_id
    HAVING COUNT(*) > 1
);

--There are 18 rows with very large numbers and duplicates in the ride_id column; two sets of 9 numbers. Since they're otherwise normal, unduplicated rows, and we don't need to have a unique ride_id for any other purpose, I will just leave them alone.

--Next I want to add columns that describe ride length by seconds and minutes.

ALTER TABLE All_2022_Trips
ADD ride_length_seconds AS DATEDIFF(SECOND, started_at, ended_at);

ALTER TABLE All_2022_Trips
ADD ride_length_minutes AS CAST(DATEDIFF(SECOND, started_at, ended_at) AS FLOAT) / 60;

--I also want to add a column that lists the names of the days instead of the numbers assigned to them, and a column for the month as well.

ALTER TABLE All_2022_Trips
ADD day_name VARCHAR(10);

UPDATE All_2022_Trips
SET day_name = DATENAME(WEEKDAY, started_at);

ALTER TABLE All_2022_Trips
ADD month_name VARCHAR(10);

UPDATE All_2022_Trips
SET month_name = DATENAME(MONTH, started_at);

--Now I'll see if I can find any outliers. 

SELECT TOP 1000
    ride_id,
    ride_length_minutes
FROM 
    All_2022_Trips
ORDER BY ride_length_minutes DESC;


--There are quite a few rides lasting longer than a day. Twenty-four hours sounds like a long bike ride, especially when you're paying by the minute, so I'll investigate.

SELECT
    (SELECT COUNT(*) 
     FROM All_2022_Trips
     WHERE ride_length_seconds < 10800) AS under_3_hours,
    
    (SELECT COUNT(*) 
     FROM All_2022_Trips
     WHERE ride_length_seconds >= 10800) AS over_3_hours,
    
    (SELECT COUNT(*) 
     FROM All_2022_Trips
     WHERE ride_length_seconds >= 21600) AS over_6_hours,
    
    (SELECT COUNT(*) 
     FROM All_2022_Trips
     WHERE ride_length_seconds >= 43200) AS over_12_hours,
    
    (SELECT COUNT(*) 
     FROM All_2022_Trips
     WHERE ride_length_seconds >= 86400) AS over_24_hours;

SELECT 
    SUM(CAST(ride_length_seconds AS BIGINT)) AS total_ride_duration_under_24h
FROM 
    All_2022_Trips
WHERE 
    ride_length_seconds < 86400;

SELECT 
    SUM(CAST(ride_length_seconds AS BIGINT)) AS total_ride_length_12_to_24
FROM 
    All_2022_Trips
WHERE 
    ride_length_seconds >= 43200
AND
    ride_length_seconds <= 86400;

SELECT 
    SUM(CAST(ride_length_seconds AS BIGINT)) AS total_ride_length_24h_plus
FROM 
    All_2022_Trips
WHERE 
    ride_length_seconds >= 86400;

--After a bit of investigating and some quick math, I have found that there are about 22,000 instances of trips longer than 6 hours, and of those there are 5360 values over 24 hours.
--This set of records represents less than 0.1% of the data, but it accounts for nearly 20% of the sum total of trip durations.
--Since users pay by the minute for bike rentals and are penalized for rides lasting longer than 3 hours, I have to imagine that many - if not most - of these records are in error, or by mistake such as improperly docking the bike at a station or losing a bike.
--I can't say for certain without some additional information, and of course not all outliers are errors, but what I do know is that this is a small and highly irregular subset of the data that massively skews my analysis, so I think it is best to omit these entries.
--The rides between 12 and 24 hours only account for just over 2% of the total trip duration, so even if there are also some irregularities there, they will be much less impactful.
--I'll make a backup first.

SELECT *
INTO All_2022_Trips_backup
FROM All_2022_Trips;

--While I'm at it I should check the other end of the time table as well.

SELECT *
FROM All_2022_Trips
WHERE ride_length_seconds <= 0;

--There are 531 rows with 0 or negative values for ride_length_seconds. Since those data points are either impossible or meaningless, I'll dispose of those records as well.

DELETE FROM All_2022_Trips
WHERE ride_length_seconds > 86400;

DELETE FROM All_2022_Trips
WHERE ride_length_seconds <= 0;

That is all of the cleaing I want to do for now, so next I want to create some views to visually explore the data in Tableau.



(I created a number of different views for exploration, but I'm just going to keep the ones I actually want to use for my visualization here.)

--The avg_ride_length_minutes view shows the average trip length for each type of rider.

CREATE VIEW avg_ride_length_minutes AS
SELECT 
    member_casual, 
    AVG(ride_length_minutes) AS avg_ride_length_minutes
FROM 
    All_2022_Trips
GROUP BY 
    member_casual;
	
--The preferred_rideable_type view shows which style of bike is preferable to each rider type.

CREATE VIEW preferred_rideable_type AS
SELECT 
    rideable_type,
    member_casual,
    COUNT(*) AS count
FROM 
    All_2022_Trips
GROUP BY 
    rideable_type,
    member_casual;

--The monthly_activity view shows how rider activity varies from month to month.

CREATE VIEW monthly_activity AS
SELECT
    member_casual,
    month_name,
    COUNT(*) AS trip_count
FROM All_2022_Trips
GROUP BY
    member_casual,
    month_name;

--The daily_activity view shows how rider activity varies depending on the day of the week.

CREATE VIEW daily_activity AS
SELECT
    member_casual,
    day_name,
    COUNT(*) AS trip_count
FROM All_2022_Trips
GROUP BY
    member_casual,
    day_name;

--The hourly_activity view shows how rider activity varies depending on the hour of the day.

CREATE VIEW hourly_activity AS
SELECT
	member_casual,
    DATEPART(HOUR, started_at) AS hour_of_day,
    COUNT(*) as total_rides
FROM
    All_2022_Trips
GROUP BY
	member_casual,
    DATEPART(HOUR, started_at)

--The start_station_use_types view shows the proportion of rideable types used at each starting station.

CREATE VIEW start_station_use_types AS
SELECT
	member_casual,
    start_station_name,
    SUM(CASE WHEN rideable_type = 'classic_bike' THEN 1 ELSE 0 END) AS classic_bike_count,
    SUM(CASE WHEN rideable_type IN ('electric_bike', 'docked_bike') THEN 1 ELSE 0 END) AS other_bike_count,
    (SUM(CASE WHEN rideable_type = 'classic_bike' THEN 1 ELSE 0 END) * 1.0 /
     NULLIF(SUM(CASE WHEN rideable_type IN ('electric_bike', 'docked_bike') THEN 1 ELSE 0 END), 0)) AS ratio
FROM 
    All_2022_Trips
GROUP BY
	member_casual,
    start_station_name
HAVING 
    SUM(CASE WHEN rideable_type = 'classic_bike' THEN 1 ELSE 0 END) +
    SUM(CASE WHEN rideable_type IN ('electric_bike', 'docked_bike') THEN 1 ELSE 0 END) >= 1000;

--The end_station_count_and_ride_length view shows the averaged coordinate pair associated with each each station name, along with the station's popularity and the time people spend getting to it.

CREATE VIEW end_station_count_and_length AS
SELECT 
	member_casual,
    end_station_name,
    AVG(ride_length_minutes) AS average_ride_length_minutes,
    SUM(ride_length_minutes) AS total_ride_length_minutes,
    AVG(end_lat) AS average_end_lat,
    AVG(end_lng) AS average_end_lng,
    COUNT(*) AS count_end_station
FROM
    All_2022_Trips
GROUP BY
	member_casual,
    end_station_name;

--Finally, I will create visualizations highlighting most insightful portions of the data using Tableau, and conclude my study.