USE trips_db;

-- BUSINESS REQUEST 1: City-Level Fare and Trip Summary Report          
/*
step 1: select the city_name from the table dim_city
step 2: count the trip_id as total trips from the fact_trips table
step 3: divide the sum the fare_amount by the sum of distance_travelled_km to give the avg_fare_per_km
step 4: calculate the average of fare_amount as the avg_fare_per trip
step 5: divide the count of each city trip_id by the sum of the count of the each city trip_id as the %_contribution_to total_trips
step 6: group by the city_name
*/
SELECT
	dc.city_name,
    COUNT(ft.trip_id) AS total_trips,
	SUM(ft.fare_amount) / SUM(ft.distance_travelled_km) AS avg_fare_per_km,
    AVG(ft.fare_amount) AS avg_fare_per_trip,
    ROUND(
		COUNT(ft.trip_id) * 100 / SUM(COUNT(ft.trip_id)) OVER(), 1
        ) AS percentage_contribution_to_total_trip
FROM dim_city dc
LEFT JOIN fact_trips ft
	ON ft.city_id = dc.city_id
GROUP BY 1
ORDER BY 2 DESC;



-- BUSINESS REQUEST 2: Monthly City-Level  Trips Target Performance Report
/*
step 1: 
	from the trips_db
		a) retrive the city name from dim_city table, 
		b) retrieve city_id, month, monthname and count of trip_id as total_trip from fact_trips table
		c) group by city_name, city_id, month and month_name
		d) order by city_name and month in ascending order
		e) store the result as a temporary table "tb1"
step 2:
	from the targets_db
		a) retrive the city_id, month_name, month and total_target_trips from the monthly_targets_trip
		b) order by city_id and month
		c) store the result as a temporary table "tb2"
step 3: 
	a) join the two temporary table using inner join at city_id, month_name, month
    b) order by city_name and month in ascending order
    c) store the result as a temporary table "tb3"
step 4: 
	from temporary table "tb3"
		a) retrieve the city_name, month_name, actual_trips, target_trips
		b) using CASE statement, create performance status with values "Below Target" when actual_trips is 
           less than or equal to target_trips else "Above target"
		c) calculate the %_contribution as actual_trips - target_trips / actual_trips
*/

WITH tb1 AS (
SELECT
	dc.city_name,
    ft.city_id,
    month(ft.date) AS month,
    monthname(ft.date) AS month_name,
    COUNT(ft.trip_id) AS total_trips
FROM trips_db.dim_city dc
LEFT JOIN trips_db.fact_trips ft
	ON dc.city_id = ft.city_id
GROUP BY 1, 2, 3, 4
ORDER BY 1, 3 ASC),
tb2 AS (
SELECT 
	city_id,
    monthname(month) AS monthname,
    month(month) AS month,
    total_target_trips
FROM targets_db.monthly_target_trips
ORDER BY 1, 3 ASC),
tb3 AS (
    SELECT
		tb1.city_name,
        tb1.city_id,
        tb1.month_name,
        tb1.month,
        tb1.total_trips,
        tb2.total_target_trips
	FROM tb1
	INNER JOIN tb2
		ON tb1.city_id = tb2.city_id
			AND tb1.month_name = tb2.monthname
            AND tb1.month = tb2.month
	ORDER BY 1, 4 ASC)
	SELECT
		city_name,
		month_name,
        total_trips AS actual_trips,
        total_target_trips AS target_trips,
		CASE
 			WHEN total_trips > total_target_trips THEN "Above Target"
			WHEN total_trips <= total_target_trips THEN "Below Target"
		END AS performance_status,
 		(total_trips - total_target_trips) *100 / (total_trips) AS percentage_difference
 		FROM tb3;

            
            
-- BUSINESS REQUEST - 3: CITY-LEVEL REPEAT PASSENGER TRIP FREQUENCY REPORT
/*
step 1: select the city_name from the dim_city table
step 2: using SUM and CASE statement, sum the repeat_passenger_count for each trip_count category 
		(2-Trips, 3-Trips, 4-Trips ..., 10-Trips) from the dim_repeat_trip_distribution table
step 3: group by the city_name
*/

SELECT
	dc.city_name,
    SUM(CASE
		WHEN dr.trip_count = "2-Trips" THEN dr.repeat_passenger_count
	END) * 100 / SUM(dr.repeat_passenger_count) AS "2-Trips",
    SUM(CASE
        WHEN dr.trip_count = "3-Trips" THEN dr.repeat_passenger_count
	END) * 100 / SUM(dr.repeat_passenger_count) AS "3-Trips",
    SUM(CASE
        WHEN dr.trip_count = "4-Trips" THEN dr.repeat_passenger_count
	END) * 100 / SUM(dr.repeat_passenger_count) AS "4-Trips",
    SUM(CASE
        WHEN dr.trip_count = "5-Trips" THEN dr.repeat_passenger_count
	end) * 100 / SUM(dr.repeat_passenger_count) AS "5-Trips",
    SUM(CASE
        WHEN dr.trip_count = "6-Trips" THEN dr.repeat_passenger_count
	END) * 100 / SUM(dr.repeat_passenger_count) AS "6-Trips",
    SUM(CASE
        WHEN dr.trip_count = "7-Trips" THEN dr.repeat_passenger_count
	END) * 100 / SUM(dr.repeat_passenger_count) AS "7-Trips",
    SUM(CASE
        WHEN dr.trip_count = "8-Trips" THEN dr.repeat_passenger_count
	END) * 100 / SUM(dr.repeat_passenger_count) AS "8-Trips",
    SUM(CASE
        WHEN dr.trip_count = "9-Trips" THEN dr.repeat_passenger_count
	END) * 100 / SUM(dr.repeat_passenger_count) AS "9-Trips",
    SUM(CASE
        WHEN dr.trip_count = "10-Trips" THEN dr.repeat_passenger_count
	END) * 100 / SUM(dr.repeat_passenger_count) AS "10-Trips"
FROM dim_city dc
LEFT JOIN dim_repeat_trip_distribution dr
	ON dr.city_id = dc.city_id
GROUP BY 1
ORDER BY 1 ASC;



-- BUSINESS REQUEST - 4: CITY WITH HIGHEST AND LOWEST TOTAL NEW PASSENGERS
/*
step 1:
	a) retrieve the city_name from dim_city table
    b) retrieve the total_new_passengers from the fact_passenger_summary table
    c) store the result in a temporary table "table1"
step 2:
	using the temporary table "table1"
		a) retrieve all columns from the temporary table
        b) rank the total_new_passengers in descending order
        c) store the result in a temporary table "table2"
step 3:
	using the temporary table "table2"
		a) retrieve all the columns in the temporary table "table2"
        b) create a cit_category column with values as "Top 3" if the ranked is less than 4 
		   and "Bottom 3" if the ranked is greater than 7
		c) store the result in a temporary table "table3"
step 4:
	from temporary table "table3"
		a) retrieve city_name, total_new_passengers and city_category columns
*/

WITH table1 AS (
SELECT
    dc.city_name,
    SUM(fps.new_passengers) AS total_new_passengers
FROM dim_city dc
LEFT JOIN fact_passenger_summary fps
	ON fps.city_id = dc.city_id
GROUP BY 1),
table2 AS (
SELECT
	*,
    RANK () OVER(ORDER BY total_new_passengers DESC) AS ranked
FROM table1),
table3 AS (
    SELECT
		*,
        CASE
			WHEN ranked < 4 THEN "Top 3"
            WHEN ranked > 7 THEN "Bottom 3"
		ELSE " " END AS city_category
	FROM table2)
		SELECT 
			city_name,
            total_new_passengers,
            city_category
		FROM table3;
        
        
    

-- BUSINESS REQUEST - 5: MONTH WITH HIGHEST REVENUE FOR EACH CITY
/*
step 1: 
	a) retrieve the city_name from the dim_city table
    b) retrieve the month, month_name and sum of fare_amount from fact_trips table
    c) store the result as a temporary table "tb1"
step 2: 
	from temporary table "tb1"
		a) retrieve all columns
        b) create a column ranked, by ranking the revenue by city_name in descending order
        c) create a column %_contribution, by dividing the revenue by the sum of revenue partition by city_name
        d) store the result in a temporary table "tb2"
step 3:
	from temporary table "tb2'
		a) retrieve the city_name
        b) month_name, where the ranked < 2 as the highest_revenue_month,
        c) retrieve the revenue and %_contribution columns
*/

WITH tb1 AS (
SELECT
	dc.city_name,
    month(ft.date) AS month,
    monthname(ft.date) AS month_name,
    SUM(ft.fare_amount) AS revenue
FROM dim_city dc
LEFT JOIN fact_trips ft
	ON dc.city_id = ft.city_id
GROUP BY 1,2,3),
tb2 AS (
SELECT 
	*,
    RANK() OVER(PARTITION BY city_name ORDER BY revenue DESC) AS ranked,
    revenue * 100 / SUM(revenue) OVER(PARTITION BY city_name) AS percentage_contribution
FROM tb1)
	SELECT
		city_name,
        month_name AS highest_revenue_month,
        revenue,
        percentage_contribution
	FROM tb2
    WHERE ranked < 2
    ORDER BY 3 DESC;



-- BUSINESS REQUEST 6: REPEAT PASSENGER RATE ANALYSIS
/*
step 1: 
	a) select the city_name from the table dim_city
    b) select month, month_name, total_passengers, repeat_passengers from the fact_passenger_summary table
    c) calculate the monthly_repeat by dividing repeat_passengers by total_passengers per city, per month
    d) calculate the overall repeat passenger for each city aggregated across all months
*/

SELECT
	dc.city_name,
    month(fps.month) AS month,
    monthname(fps.month) AS month_name,
    fps.total_passengers,
    fps.repeat_passengers,
    fps.repeat_passengers * 100 /fps.total_passengers AS monthly_repeat_passenger_rate,
    sum(fps.repeat_passengers) OVER(PARTITION BY dc.city_name)  * 100 / 
		sum(fps.total_passengers) OVER(PARTITION BY dc.city_name) AS city_repeat_passenger_rate
FROM dim_city dc 
LEFT JOIN fact_passenger_summary fps
	ON dc.city_id = fps.city_id
ORDER BY 1, 2 ASC;
    