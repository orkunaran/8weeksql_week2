# 8weeksql_week2


```sql 
UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = 'null'
```

A. Pizza Metrics
How many pizzas were ordered?

````sql
SELECT COUNT(*) AS total_pizzas
FROM customer_orders

````

How many unique customer orders were made?
````sql
SELECT COUNT(DISTINCT(customer_id)) AS unique_customers
FROM customer_orders
````

How many successful orders were delivered by each runner?
```sql
SELECT COUNT(*) FROM runner_orders
WHERE cancellation IS NULL
```

How many of each type of pizza was delivered?
```sql
SELECT pizza_id, COUNT(pizza_id) FROM customer_orders
GROUP BY pizza_id
```

How many Vegetarian and Meatlovers were ordered by each customer?
```sql
SELECT customer_id,pizza_name, COUNT(p.pizza_name) FROM customer_orders c
JOIN pizza_names p ON p.pizza_id = c.pizza_id
GROUP BY c.customer_id, pizza_name
ORDER BY customer_id
```

What was the maximum number of pizzas delivered in a single order?
```sql
SELECT order_id, COUNT(order_id) AS single_orders
FROM customer_orders
GROUP BY order_id
ORDER BY single_orders DESC
LIMIT 1
```

For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
SELECT modified, COUNT(modified) 
FROM (
SELECT *, 
	CASE 
    WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN  'Y'
    WHEN exclusions IS NULL AND extras IS NULL THEN 'N'
    END AS modified
FROM customer_orders) as t
GROUP BY modified
```

How many pizzas were delivered that had both exclusions and extras?
```sql
SELECT *  FROM customer_orders
WHERE exclusions IS NOT NULL AND extras IS NOT  NULL
```
I didn't want to get counts here cause there are only two rows. 

What was the total volume of pizzas ordered for each hour of the day?
```sql
select HOUR(order_time), COUNT(order_id) from customer_orders
GROUP BY  HOUR(order_time)

```

What was the volume of orders for each day of the week?
```sql
select WEEKDAY(order_time), COUNT(order_id) from customer_orders
GROUP BY  WEEKDAY(order_time)
```


-- B. Runner and Customer Experience
-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
```sql
SELECT  COUNT(registration_date) AS weekly_runners, WEEK(registration_date,1) AS week_no 
FROM runners
GROUP BY WEEK(registration_date,1)

```


-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
SELECT AVG(REGEXP_SUBSTR(duration,"[0-9]+")) 
FROM runner_orders
```

OR 
```sql
SELECT AVG(duration + 0 )
FROM runner_orders
```
-- Is there any relationship between the number of pizzas and how long the order takes to prepare?


-- What was the average distance travelled for each customer?
-- What was the difference between the longest and shortest delivery times for all orders?
-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- What is the successful delivery percentage for each runner?
