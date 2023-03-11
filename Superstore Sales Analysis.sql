-------------------------------------HI-Counselor---------------------------------------------------
--------------------------SQL-Project---Superstore-Sales-Analysis-----------------------------------
-----------------------------------By-Rishabh-Mahajan-----------------------------------------------
----------------------------------------------------------------------------------------------------
-----Using---Window-Functions---Joins---Common-Table-Expressions---Subqueries---Clauses-etc---------

drop table if exists Superstore
--Table-Schema--
CREATE TABLE Superstore (
    Row_ID INT,
    Order_ID VARCHAR(255),
    Order_Date DATE,
    Ship_Date DATE,
    Ship_Mode VARCHAR(255),
    Customer_ID VARCHAR(255),
    Customer_Name VARCHAR(255),
    Segment VARCHAR(255),
    Country VARCHAR(255),
    City VARCHAR(255),
    State VARCHAR(255),
    Postal_Code INT,
    Region VARCHAR(255),
    Product_ID VARCHAR(255),
    Category VARCHAR(255),
    Sub_Category VARCHAR(255),
    Product_Name VARCHAR(255),
    Sales DECIMAL(10, 2));
	
--1. What percentage of total orders were shipped on the same date?
SELECT COUNT(CASE WHEN order_date = ship_date THEN 1 END) * 100.0 / COUNT(*) AS same_day_shipment_percentage
FROM Superstore;

--2.Name top 3 customers with highest total value of orders.
select customer_name, sales from superstore 
order by sales desc 
Limit 3;

--3. Find the top 5 items with the highest average sales per day.

with t1 as
(
SELECT Product_Name, SUM(Sales) / COUNT(DISTINCT Order_Date) AS Avg_Sales_Per_Day
FROM superstore
GROUP BY Product_Name
)
select * from t1
ORDER BY Avg_Sales_Per_Day DESC
LIMIT 5;


--4. Write a query to find the average order value for each customer, and rank the customers by their average order value.

select customer_name, customer_id,  avg(sales) as avg_order_value from superstore
group by customer_id, customer_name
order by avg(sales) desc;

--5.Give the name of customers who ordered highest and lowest orders from each city.
-- highest order means order with highest

-- lowest orders from each city
with t1 as
(select city, customer_name, row_number() over (partition by city order by sales) as sales_values 
from superstore)
select city, customer_name as customer_with_min_value, min(sales_values) as lowest_order_value
from t1
group by city, customer_name
order by city

-- highest orders from each city
with t1 as
(select city, customer_name, row_number() over (partition by city order by sales) as sales_values 
from superstore)
select city, customer_name as customer_with_max_value, max(sales_values) as highest_order_value
from t1
group by city, customer_name
order by city;


--6. What is the most demanded sub-category in the west region?
select sub_category, count(order_id) as no_of_orders
from superstore
where region = 'West'
group by sub_category
order by count(order_id) desc;

--7. Which order has the highest number of items? And which order has the highest cumulative value?
--order which has highest number of item

with t1 as 
(
select order_id, city, count(order_id) as no_of_items_ordered
from superstore
group by order_id, city
),
t2 as--order which has highest cumulative value
(
select distinct(order_id) as order_id, sum(sales) over (partition by order_id) as cum_value
from superstore
group by order_id, sales
)
select t1.order_id, t1.city, t1.no_of_items_ordered, t2.cum_value
from t1
inner join t2 on t1.order_id = t2.order_id
order by no_of_items_ordered desc, cum_value desc
Limit 1;



--8. Which order has the highest cumulative value?

select distinct(order_id) as order_id, sum(sales) over (partition by order_id) as cum_value
from superstore
group by order_id, sales
order by sum(sales) over (partition by order_id) desc
limit 1;


--9. Which segment’s order is more likely to be shipped via first class?

with t1 as
(
select ship_mode, segment
from superstore
where ship_mode = 'First Class'
), 
t0 as 
(
select count(segment) as total_segment from t1 
)
,
t2 as
(
select distinct segment as segments, count(segment) as no_of_orders_in_first_class_per_segment
from t1
group by segment
), 
t3 as 
(
select t2.*, t0.*
from t2 cross join t0
)
select *, 100.0*no_of_orders_in_first_class_per_segment/total_segment as percent_order_shipped_via_first_class
from t3
order by 100.0*no_of_orders_in_first_class_per_segment/total_segment desc;

--
--SELECT segment, COUNT() FILTER (WHERE ship_mode = 'First Class') * 100.0 / COUNT() AS first_class_percentage
--FROM superstore
--GROUP BY segment
--ORDER BY first_class_percentage DESC;
------------------------------------------------------------------------------------------
--10. Which city is least contributing to total revenue?

select distinct city, sum(sales) over(partition by city) as revenue
from superstore
group by city, sales
order by revenue desc;

------------------------------------------------------------------------------------------
--11. What is the average time for orders to get shipped after order is placed?

select round(avg(no_of_days),2) as avg_time_for_shipment
from(
select order_date, ship_date, 
(ship_date-order_date) as no_of_days 
from superstore
) b;


------------------------------------------------------------------------------------------
--12. Which segment places the highest number of orders from each state 
--and which segment places the largest individual orders from each state?

--Which segment places the highest number of orders from each state
SELECT State, Segment, COUNT(*) AS OrderCount
FROM Superstore
GROUP BY State, Segment
HAVING COUNT(*) = (SELECT MAX(OrderCount)
                   FROM (SELECT State, Segment, COUNT(*) AS OrderCount
                         FROM Superstore
                         GROUP BY State, Segment) AS t
                   WHERE t.State = Superstore.State)
ORDER BY State;

--which segment places the largest individual orders from each state?
SELECT State, Segment, MAX(Sales) AS MaxSales
FROM Superstore
GROUP BY State, Segment
HAVING MAX(Sales) = (SELECT MAX(MaxSales)
                     FROM (SELECT State, Segment, MAX(Sales) AS MaxSales
                           FROM Superstore
                           GROUP BY State, Segment) AS t
                     WHERE t.State = Superstore.State)
ORDER BY State;


------------------------------------------------------------------------------------------
--13. Find all the customers who individually ordered on 3 consecutive days 
-- where each day’s total order was more than 50 in value. **


WITH daily_order_totals AS (
  SELECT
    Customer_id,Customer_name,
    Order_Date,
    SUM(Sales) AS total_sales
  FROM
    Superstore
  GROUP BY
    Customer_id,Customer_name,
    Order_Date
),
consecutive_days AS (
  SELECT
    Customer_Id,
    Order_Date, Customer_name,
    LAG(Order_Date, 1) OVER (PARTITION BY Customer_Id ORDER BY Order_Date) AS prev_order_date,
    LAG(Order_Date, 2) OVER (PARTITION BY Customer_Id ORDER BY Order_Date) AS prev_prev_order_date,
    total_sales,
    LAG(total_sales, 1) OVER (PARTITION BY Customer_ID ORDER BY Order_Date) AS prev_total_sales,
    LAG(total_sales, 2) OVER (PARTITION BY Customer_ID ORDER BY Order_Date) AS prev_prev_total_sales
  FROM
    daily_order_totals
),
qualified_customers AS (
  SELECT DISTINCT
    Customer_Id, Customer_name
  FROM
    consecutive_days
  WHERE
    prev_prev_order_date IS NOT NULL
    AND prev_prev_total_sales > 50
    AND prev_order_date = Order_Date - 1
    AND prev_total_sales > 50
    AND total_sales > 50
  group by Customer_name, Customer_Id		
)
SELECT
  *
FROM
  qualified_customers;


------------------------------------------------------------------------------------------
--14. Find the maximum number of days for which total sales on each day kept rising.
-- total number of days when the sales increased on days consecutively

WITH daily_sales AS (
  SELECT
    Order_Date,
    SUM(Sales) AS total_sales
  FROM superstore
  GROUP BY Order_Date
  ORDER BY Order_Date
),
sales_diff AS (
  SELECT
    Order_Date,
    total_sales,
    LAG(total_sales) OVER (ORDER BY Order_Date) AS prev_sales
  FROM daily_sales
),
max_consecutive_days AS (
  SELECT
    Order_Date,
    COUNT(*) OVER (ORDER BY Order_Date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS consecutive_days
  FROM sales_diff
  WHERE total_sales > prev_sales
)
SELECT MAX(consecutive_days) AS max_consecutive_days
FROM max_consecutive_days;

