/*/

						Danny Ma 8 Weeks SQL Challenge - Week 2 - Pizza Runners Solutions

This code block includes Part I and Part II solutions. 

/*/

/*/
									PART I questions 
 /*/
 
-- Q1 : How many pizzas were ordered?
-- Approach: Easy beginning questions; simple approach with count all 
SELECT COUNT(*) as number_of_pizzas_ordered FROM customer_orders;

-- Q2 : How many unique customer orders were made?
-- Approach: Again, count question with Distinct usage
SELECT  DISTINCT COUNT(customer_id) AS total_pizzas_ordered, customer_id  FROM customer_orders 
	GROUP BY customer_id;

-- Q3: How many successful orders were delivered by each runner?
-- Approach: Get the count of all rows where cancellation is null (delivered orders)
SELECT COUNT(*) AS sucecessful_orders, runner_id FROM runner_orders
	WHERE cancellation IS NULL
    GROUP BY runner_id;

-- Q4 : How many of each type of pizza was delivered?
-- Approach: Count question again, this time group by pizza type
SELECT COUNT(c.pizza_id) AS numbers_sold, p.pizza_name  FROM customer_orders c
	JOIN pizza_names p ON c.pizza_id = p.pizza_id
	GROUP BY p.pizza_name;

-- Q5: How many Vegetarian and Meatlovers were ordered by each customer?
-- Approach: Get count of pizza id, join two tables and group by customer_id and pizza_name or id
SELECT COUNT(c.pizza_id) AS numbers_sold,c.customer_id, p.pizza_name  FROM customer_orders c
	JOIN pizza_names p ON c.pizza_id = p.pizza_id
	GROUP BY c.customer_id,p.pizza_name;

-- Q6: What was the maximum number of pizzas delivered in a single order?
-- Approach: Select within Select statement
SELECT COUNT(pizza_id), order_id FROM customer_orders
GROUP BY order_id 
HAVING COUNT(pizza_id) >= ALL(SELECT COUNT(pizza_id) AS order_count 
								FROM customer_orders
								GROUP BY order_id);
    
-- Q7: For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- Approach: Case when statement on exclusions. 
SELECT customer_id, changes, COUNT(changes) 
FROM (
	SELECT *,
    CASE 
		WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 'Y'
        WHEN exclusions IS NULL AND extras IS NULL THEN 'N'
        END AS changes
	FROM customer_orders) as t
GROUP BY changes, customer_id;

-- Q8: How many pizzas were delivered that had both exclusions and extras?
-- Approach: Select count of pizza id where exclusions and extras is not null.
SELECT COUNT(pizza_id) AS all_changed_pizzas FROM customer_orders
	WHERE exclusions IS NOT NULL AND extras IS NOT NULL;

-- Q9: What was the total volume of pizzas ordered for each hour of the day?
-- Approach: Select hour from order time and group by the same value 
SELECT HOUR(order_time), COUNT(order_id) FROM customer_orders
GROUP BY  HOUR(order_time);

-- Q10: What was the volume of orders for each day of the week?
-- Approach: Used Dayname function 
SELECT DAYNAME(order_time) AS Days, COUNT(order_id) as number_of_pizzas FROM customer_orders
GROUP BY DAYNAME(order_time);

/*/
							PART II:
/*/
-- Q1: How many runners signed up for each 1 week period?
-- Approach: Simple select statement, additionally used Week function 
SELECT COUNT(runner_id) as new_runners, WEEK(registration_date) AS week_number
FROM runners
GROUP BY week_number;


-- Q2: What was the average time in minutes it took for each runner to arrive at the 
-- Pizza Runner HQ to pickup the order?
-- To answer that, we need to know : 
-- the pickup_time is the timestamp at which the runner arrives at the Pizza Runner headquarters 
-- to pick up the freshly cooked pizzas

-- Approach: calculate the time difference between order time and pickup time, and get mean for each runner
SELECT AVG(TIMESTAMPDIFF(MINUTE,c.order_time,r.pickup_time)) AS avg_pick_latency,
		runner_id
FROM runner_orders r 
JOIN customer_orders c ON c.order_id = r.order_id
GROUP BY r.runner_id;

-- Q3: Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- Approach: 
-- Step 1: Turn off only_full_group_by in SQL 
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
-- Step 2: Generate a table that presents order preparation time and pizza count:
-- Interpretation: WE can easily conclude that prep time increase by ordered pizza count
WITH cte AS (
SELECT AVG(TIMESTAMPDIFF(MINUTE,c.order_time,r.pickup_time)) AS order_prep_time, 
		COUNT(c.pizza_id) as pizza_count, 
        c.order_id
FROM runner_orders r 
JOIN customer_orders c ON c.order_id = r.order_id
GROUP BY c.order_id) 
SELECT order_prep_time, pizza_count FROM cte
GROUP BY pizza_count;


-- Pearson Correlation 
-- Creating temporary table 
DROP TABLE IF EXISTS pearson;
CREATE TEMPORARY TABLE pearson 
	SELECT AVG(TIMESTAMPDIFF(MINUTE,c.order_time,r.pickup_time)) AS order_prep_time, 
		COUNT(c.pizza_id) as pizza_count, 
        c.order_id
FROM runner_orders r 
JOIN customer_orders c ON c.order_id = r.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY c.order_id; 

-- Creating average and std tables
SELECT @ax := AVG(order_prep_time), 
       @ay := AVG(pizza_count), 
       @div := (stddev_samp(order_prep_time) * stddev_samp(pizza_count))
from pearson;
-- Calculating pearson r value
SELECT SUM(( order_prep_time - @ax ) * (pizza_count - @ay)) / ((count(order_prep_time) -1) * @div) AS pearson_r
FROM pearson;

-- 0.83, is highly correlated. We can say there is a relation between nubmer of orders and preperation time
	
-- Q4: What was the average distance travelled for each customer? 
-- Approach: Get AVG distance by each customer
SELECT AVG(r.distance + 0) AS avg_distance, c.customer_id FROM runner_orders r
JOIN customer_orders c on r.order_id = c.order_id
GROUP BY c.customer_id;

-- Q5: What was the difference between the longest and shortest delivery times for all orders?
-- Approach: Extract minimum duration from maximum
SELECT MAX(duration + 0)-  MIN(duration + 0) AS difference FROM runner_orders
WHERE duration + 0 <> "Null";

-- Q6: What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- Approach: calculated average speed of each runner by order
SELECT AVG((((r.distance + 0) * 60) / (r.duration + 0))) AS avg_speed, c.customer_id, r.runner_id, c.order_id
FROM runner_orders r
JOIN customer_orders c on r.order_id = c.order_id
WHERE distance + 0 != 0
GROUP BY r.runner_id, c.order_id
ORDER BY runner_id;
-- I think there is no trend for these values

-- Q7 : What is the successful delivery percentage for each runner?
-- Approach: Case when statement for to create successful deliveries, and calculated percentage
SELECT 
	(SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END)) * 100 / COUNT(runner_id) AS total_deliveries ,
    runner_id
FROM runner_orders
GROUP BY runner_id;


