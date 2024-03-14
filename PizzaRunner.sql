--------------------------------
-- # Cleaning Data
--------------------------------
-- 1. Dropping/Trimming irrelavant data from columns

Select 
    order_id, 
    runner_id, 
    pickup_time,
    CASE 
        when distance like '%km' THEN Replace(distance, 'km', NULL)
        when distance like '%miles' THEN Replace(distance, 'miles', NULL)
        ELSE distance 
    END AS distance,
    CASE 
        when duration like '%minutes' THEN Replace(duration, 'minutes', NULL)
        when duration like '%mins' THEN Replace(duration, 'mins', NULL)
        when duration like '%minute' THEN Replace(duration, 'minute', NULL)
        ELSE duration 
    END AS duration,
    cancellation 
FROM 
    runner_orders;

-----------------------------------------------
-- 2. Handling missing/incorrect data

update runner_orders 
set cancellation = NULLIF(cancellation,'');

update runner_orders 
set cancellation = NULLIF(cancellation,'null');

update customer_orders 
set exclusions = NULLIF(exclusions,'');

update customer_orders 
set exclusions = NULLIF(exclusions,'null');

update customer_orders 
set extras = NULLIF(extras,'');

update customer_orders 
set extras = NULLIF(extras,'null');
 
--------------------------------------------
-- 3. Correcting the Data Types of columns

Alter table runner_orders
	Alter column pickup_time DATETIME NULL
	Alter column duration DECIMAL(5,3) NULL
	Alter column distance int NULL

----------------------------------------

-------------------------------------------------
Case Study A: Pizza Metrics
-------------------------------------------------
-- # How many pizzas were ordered?

select count(order_id) as num_of_pizzas from customer_orders;

------------------------------------------------------------------------------------------- 
-- # How many unique customer orders were made?

select count(distinct order_id)as unique_pizzas from customer_orders;

-------------------------------------------------------------------------------------------
-- # How many successful orders were delivered by each runner?
                 
SELECT
	runner_id,
	COUNT(order_id) AS successful_orders
FROM runner_orders
WHERE cancellation ISNULL
GROUP BY runner_id;

-------------------------------------------------------------------------------------------
-- # How many of each type of pizza was delivered?

select 
	piz.pizza_name, 
    count(cus.pizza_id) 
from customer_orders cus
	join pizza_names piz 
    on cus.pizza_id = piz.pizza_id
    join runner_orders run
    on cus.order_id = run.order_id
	where run.cancellation ISNULL
	group by piz.pizza_name;

-------------------------------------------------------------------------------------------	
-- # How many Vegetarian and Meatlovers were ordered by each customer?

select 
	cus.customer_id,piz.pizza_name, count(cus.pizza_id) as Number_of_Pizzas
from customer_orders cus
join pizza_names piz
on cus.pizza_id = piz.pizza_id
group by cus.customer_id,piz.pizza_name;
	
alternative:
	
SELECT
	customer_id,
    	SUM(CASE WHEN pizza_id = 1 THEN 1 ELSE 0 END) as Meat_Lovers,
		SUM(CASE WHEN pizza_id = 2 THEN 1 ELSE 0 END) as Vegetarian
FROM customer_orders
GROUP BY customer_id;

-------------------------------------------------------------------------------------------
-- # What was the maximum number of pizzas delivered in a single order?

select order_id, max_pizzas from(
  select 
	cus.order_id, count(cus.pizza_id) as max_pizzas from customer_orders cus
    join runner_orders run 
    on cus.order_id = run.order_id
    where run.cancellation ISNULL
	group by cus.order_id) as e
order by max_pizzas DESC
limit 1;

-------------------------------------------------------------------------------------------
-- # For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

select cus.customer_id,
	SUM(CASE when cus.exclusions Is NOT NULL OR cus.extras IS NOT NULL THEN 1 ELSE 0 END) AS changed,
    SUM(CASE when cus.exclusions ISNULL AND cus.extras ISNULL THEN 1 ELSE 0 END) AS no_changes
  FROM customer_orders cus
  JOIN runner_orders run
  on cus.order_id = run.order_id
  where run.distance is not NULL
  GROUP BY customer_id;

-------------------------------------------------------------------------------------------  
-- # How many pizzas were delivered that had both exclusions and extras?

select count(cus.pizza_id) as both_ext_and_exc from customer_orders cus
join runner_orders run
on cus.order_id = run.order_id
where extras IS not NULL and exclusions IS not NULL and run.cancellation IS not NULL;

-------------------------------------------------------------------------------------------
-- # What was the total volume of pizzas ordered for each hour of the day?

SELECT 
	HOUR(order_date) AS hour_of_the_day,
	COUNT(order_id) AS no_of_pizzas
FROM customer_orders
WHERE order_date != ' '
GROUP BY hour_of_day
ORDER BY hour_of_day;

-------------------------------------------------------------------------------------------
-- # What was the volume of orders for each day of the week?

SELECT 
	DAYNAME(order_date) AS hour_of_the_day,
	COUNT(order_id) AS no_of_pizzas
FROM customer_orders
WHERE order_date != ' '
GROUP BY hour_of_day
ORDER BY hour_of_day;
-------------------------------------------------------------------------------------------


WITH signed_up_runners AS (
	SELECT
		runner_id,
		registration_date,
		registration_date - ((registration_date - DATE('2021-01-01')) % 7) AS week
	FROM runners)
SELECT 
	week,
    COUNT(runner_id) AS no_of_runners
FROM signed_up_runners
GROUP BY week
ORDER BY week;

-------------------------------------------------------------------------------------------


	

