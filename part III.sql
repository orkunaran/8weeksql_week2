-- Q1. What are the standard ingredients for each pizza?
SELECT ones.id, ones.topping, twos.id
FROM 
(SELECT id, topping FROM pizza_tops
WHERE id = 1) AS ones,
(SELECT id, topping FROM pizza_tops
WHERE id = 2) AS twos
WHERE ones.topping = twos.topping;


-- Q2. What was the most commonly added extra?
WITH cte AS
(SELECT substring_index(extras,',', 1) AS extras1,substring_index(extras,',', -1) AS extras2
  FROM customer_orders) 
SELECT COUNT(topping_name), topping_name FROM cte JOIN pizza_toppings p ON p.topping_id = cte.extras1
GROUP BY topping_name;

-- Q3. What was the most common exclusion?
WITH cte AS
(SELECT substring_index(exclusions,',', 1) AS exclusions1 ,substring_index(exclusions,',', -1) AS exclusions2
  FROM customer_orders) 
SELECT COUNT(topping_name), topping_name FROM cte JOIN pizza_toppings p ON p.topping_id = cte.exclusions1
GROUP BY topping_name LIMIT 1;

-- Q4. Generate an order item for each record in the customers_orders table in the format of one of the following:
/*/
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
/*/

-- First create a temporary table than includes extras and exclusions in different columns
DROP TABLE IF EXISTS extras_exclusions;
CREATE TEMPORARY TABLE extras_exclusions
SELECT *, 
		substring_index(exclusions, ',', 1) AS exclusions_part_1,
		CASE 
			WHEN exclusions REGEXP ',' THEN substring_index(exclusions, ',', -1) 
			END AS exclusions_part_2,
		substring_index(extras, ',', 1) AS extras_1,
		CASE 
			WHEN extras REGEXP ',' THEN substring_index(extras, ',', -1) 
			END AS extras_2
FROM customer_orders;

-- Now create a temp table that includes the extras and exclusions information as Text data
DROP TABLE IF EXISTS item_record;
CREATE TEMPORARY TABLE item_record
WITH t3 AS
	(WITH t2 AS
		(WITH t1 AS
			(SELECT e.order_id
					,p.pizza_name
					,e.exclusions_part_1
					,e.exclusions_part_2
					,extras_1
					,extras_2
					,pt.topping_name AS exclusion_1
					from extras_exclusions e
			JOIN pizza_names p ON p.pizza_id = e.pizza_id
			LEFT JOIN pizza_toppings pt ON pt.topping_id = e.exclusions_part_1)
		SELECT order_id
				,pizza_name
				,exclusion_1
				,extras_1
				,extras_2
				,topping_name AS exclusion_2
		FROM t1
		LEFT JOIN pizza_toppings p ON p.topping_id = t1.exclusions_part_2)
	SELECT order_id
			,pizza_name
			,exclusion_1
			,exclusion_2
			,extras_2
			,topping_name AS extra_1
	FROM t2
	LEFT JOIN pizza_toppings p ON p.topping_id = t2.extras_1)
SELECT order_id
		,pizza_name
        ,exclusion_1
        ,exclusion_2
        ,extra_1
        ,topping_name AS extra_2
FROM t3
LEFT JOIN pizza_toppings p ON p.topping_id = t3.extras_2;

-- Finally the item record table.
SELECT 
	DISTINCT(CASE 
		WHEN COALESCE(exclusion_1, exclusion_2, extra_1, extra_2) IS NULL THEN pizza_name
		WHEN exclusion_2 IS NULL AND extra_1 IS NULL and  extra_2 IS NULL
			THEN CONCAT(pizza_name, ' - Exclude ', exclusion_1)
		WHEN exclusion_1 IS NULL AND exclusion_2 IS NULL and  extra_2 IS NULL
			THEN CONCAT(pizza_name, ' - Extra ', extra_1)
		WHEN COALESCE(exclusion_1, exclusion_2, extra_1, extra_2) IS NOT NULL 
			THEN CONCAT_WS("", pizza_name, ' - Extra ', extra_1, ', ', extra_2,
					   ' - Exclude ', exclusion_1,', ', exclusion_2)
		END)
FROM item_record;


/*/
Q5. Generate an alphabetically ordered comma separated ingredient list for each pizza order
from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
/*/
DROP TABLE IF EXISTS toppings;
CREATE TEMPORARY TABLE toppings
SELECT id, GROUP_CONCAT(topping_name, ' ') AS ingredients
FROM pizza_tops p 
JOIN pizza_toppings t on p.topping = t.topping_id
GROUP BY id;


-- Create a temp table for easier manipulation
DROP TABLE IF EXISTS ingredients;
CREATE TEMPORARY TABLE ingredients
SELECT i.pizza_name, extra_1, extra_2, ingredients FROM item_record i
JOIN (select * from toppings t
JOIN pizza_names n ON n.pizza_id = t.id) p ON p.pizza_name = i.pizza_name;
 
-- Answer
SELECT CONCAT(pizza_name, ' : ' ,
	CASE 
		WHEN LOCATE(extra_1, ingredients) > 0 AND LOCATE(extra_2, ingredients) > 0 
			THEN REPLACE(REPLACE(ingredients, extra_2, CONCAT('2x',extra_2)), extra_1, CONCAT('2x',extra_1))
        ELSE ingredients
        END)
FROM ingredients;

-- Q6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
DROP TABLE IF EXISTS extras_exc;
CREATE TEMPORARY TABLE extras_exc 
	SELECT id, topping FROM pizza_tops;
INSERT INTO extras_exc SELECT pizza_id, extras_1 AS topping FROM extras_exclusions
	WHERE extras_1 IS NOT NULL;
INSERT INTO extras_exc SELECT pizza_id, extras_2 AS topping FROM extras_exclusions
	WHERE extras_2 IS NOT NULL;


SELECT t.topping_name, COUNT((p.topping))
FROM extras_exc e
JOIN pizza_tops p ON p.id = e.id
JOIN pizza_toppings t ON p.topping = t.topping_id
GROUP BY t.topping_name
ORDER BY COUNT((p.topping)) DESC


-- 						PART IV 								--
/*/
If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were 
no charges for changes - how much money has Pizza Runner made so far 
if there are no delivery fees?
/*/







