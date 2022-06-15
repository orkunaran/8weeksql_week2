USE 8_weeks_sql_challange_week2;

/*

						PART IV - Pricing and Ratings

*/

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
-- how much money has Pizza Runner made so far if there are no delivery fees?
SELECT 
	SUM(CASE WHEN pizza_id=1 THEN 12
    WHEN pizza_id = 2 THEN 10
    END) AS Total_earnings
 FROM runner_orders r
JOIN customer_orders c ON c.order_id = r.order_id
WHERE r.cancellation IS  NULL;


-- 2. What if there was an additional $1 charge for any pizza extras?
WITH cte AS
(SELECT 
	(CASE WHEN pizza_id=1 THEN 12
    WHEN pizza_id = 2 THEN 10
    END) AS pizza_cost, 
    c.exclusions,
    c.extras
 FROM runner_orders r
JOIN customer_orders c ON c.order_id = r.order_id
WHERE r.cancellation IS  NULL)
SELECT 
	SUM(CASE WHEN extras IS NULL THEN pizza_cost
		WHEN LENGTH(extras) = 1 THEN pizza_cost + 1
        ELSE pizza_cost + 2
        END )
FROM cte;

-- The Pizza Runner team now wants to add an additional ratings system that allows customers 
-- to rate their runner, how would you design an additional table for this new dataset 
-- generate a schema for this new table and insert your own data for ratings for 
-- each successful customer order between 1 to 5.
DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings 
	(order_id INTEGER,
    rating INTEGER);

INSERT INTO ratings
	(order_id ,rating)
VALUES 
(1,3),
(2,4),
(3,5),
(4,2),
(5,1),
(6,3),
(7,4),
(8,1),
(9,3),
(10,5);

-- Using your newly generated table - can you join all of the information together to 
-- form a table which has the following information for successful deliveries?

SELECT c.customer_id, c.order_id, r.runner_id, rt.rating, c.order_time,
	r.pickup_time, TIMESTAMPDIFF(minute, order_time, pickup_time) as delivery_delay, 
    r.duration, ROUND(avg(r.distance*60/r.duration),1) as avg_speed, 
    count(c.pizza_id) as PizzaCount
FROM customer_orders c
JOIN runner_orders r
ON c.order_id = r.order_id
JOIN ratings rt
ON rt.order_id = c.order_id
GROUP BY c.customer_id, c.order_id, r.runner_id, rt.rating, c.order_time,
r.pickup_time, delivery_delay, r.duration
ORDER BY c.customer_id;

-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost 
-- for extras and each runner is paid $0.30 per kilometre traveled 
-- how much money does Pizza Runner have left over after these deliveries?


SELECT 
	SUM(CASE WHEN pizza_id=1 THEN 12
    WHEN pizza_id = 2 THEN 10
    END)  - SUM((r.distance+0) * 0.3) AS pizza_cost,
    SUM(CASE WHEN pizza_id=1 THEN 12
    WHEN pizza_id = 2 THEN 10
    END ) AS pizza_only,
    (SUM(r.distance+0) * 0.3) AS distance_cost
FROM runner_orders r
JOIN customer_orders c ON c.order_id = r.order_id
WHERE r.cancellation IS  NULL