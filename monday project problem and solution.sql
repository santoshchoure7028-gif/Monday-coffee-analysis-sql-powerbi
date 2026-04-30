-- Monday Coffee -- Data Analysis 
SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports & Data Analysis


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
	ROUND(
	(population * 0.25)/1000000, 
	2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC;

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?


SELECT 
	SUM(total) as total_revenue
FROM sales
WHERE 
	EXTRACT(YEAR FROM sale_date)  = 2023
	AND
	EXTRACT(quarter FROM sale_date) = 4;



SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date)  = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city abd total sale
-- no cx in each these city


SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(
			SUM(s.total)/
				COUNT(DISTINCT s.customer_id)
			,2) as avg_sale_pr_cx
	
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;

-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name;

-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

WITH ranked_products AS (
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        DENSE_RANK() OVER (
            PARTITION BY ci.city_name
            ORDER BY COUNT(s.sale_id) DESC
        ) AS product_rank
    FROM sales AS s
    JOIN products AS p
        ON s.product_id = p.product_id
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name, p.product_name
)

SELECT 
    city_name,
    product_name,
    total_orders,
    product_rank
FROM ranked_products
WHERE product_rank <= 3;


-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT * FROM products;



SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1;

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT * FROM products;



SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1;


-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions

SELECT 
    cs.city_name,
    cs.total_customers,
    ROUND(cs.total_sales * 1.0 / cs.total_customers, 2) AS avg_sale_per_customer,
    ROUND(ci.estimated_rent * 1.0 / NULLIF(cs.total_customers, 0), 2) AS avg_rent_per_customer
FROM (
    SELECT 
        ci.city_id,
        ci.city_name,
        COUNT(DISTINCT s.customer_id) AS total_customers,
        SUM(s.total) AS total_sales
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_id, ci.city_name
) cs
JOIN city ci ON cs.city_id = ci.city_id
ORDER BY avg_sale_per_customer DESC;

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH monthly_sales AS (
    SELECT 
        ci.city_id,
        ci.city_name,
        DATE_FORMAT(s.sale_date, '%Y-%m') AS month,
        SUM(s.total) AS total_sales
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_id, ci.city_name, month
),

sales_with_lag AS (
    SELECT 
        city_id,
        city_name,
        month,
        total_sales,
        LAG(total_sales) OVER (
            PARTITION BY city_id 
            ORDER BY month
        ) AS prev_month_sales
    FROM monthly_sales
)

SELECT 
    city_name,
    month,
    total_sales,
    prev_month_sales,
    ROUND(
        (total_sales - prev_month_sales) * 100.0 / 
        NULLIF(prev_month_sales, 0),
        2
    ) AS growth_percentage
FROM sales_with_lag
ORDER BY city_name, month;

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer


WITH city_table AS (
    SELECT 
        ci.city_id,
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_customers,
        ROUND(SUM(s.total) * 1.0 / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_per_customer
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_id, ci.city_name
),

city_info AS (
    SELECT 
        city_id,
        city_name,
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_consumers_millions
    FROM city
)

SELECT 
    ci.city_name,
    ct.total_revenue,
    ci.estimated_rent AS total_rent,
    ct.total_customers,
    ci.estimated_coffee_consumers_millions,
    ct.avg_sale_per_customer,
    ROUND(ci.estimated_rent * 1.0 / NULLIF(ct.total_customers, 0), 2) AS avg_rent_per_customer
FROM city_table ct
JOIN city_info ci ON ct.city_id = ci.city_id
ORDER BY ct.total_revenue DESC
LIMIT 3;

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.




