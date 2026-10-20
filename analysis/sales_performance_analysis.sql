-- 01. Revenue & sales performance
-- - How has monthly sales performance changed over time?
SELECT EXTRACT(MONTH FROM o.order_purchase_timestamp) AS months, EXTRACT(YEAR FROM o.order_purchase_timestamp) AS years,SUM(oi.price) AS total_sales
, count(distinct o.order_id) as no_of_orders
FROM orders o
JOIN order_items oi
	ON o.order_id=oi.order_id
GROUP BY years,months
ORDER BY years,months;
-- finding out reason behind low monthly sales for september 2018. 
SELECT count(distinct order_id) from orders where extract(month from order_purchase_timestamp)=9 and extract(year from order_purchase_timestamp) = 2018;


-- - Which product categories contribute the most to sales?
SELECT engpc.product_category_name_english AS product_category, SUM(o.price)
FROM products pr
JOIN order_items o
	ON o.product_id=pr.product_id
JOIN product_category_name_translation engpc
	ON engpc.product_category_name=pr.product_category_name
GROUP BY engpc.product_category_name_english
ORDER BY SUM(o.price) DESC LIMIT 5;
-- - Which geographic markets generate the most sales?
SELECT c.customer_state AS states, SUM(oi.price) AS total_sales
FROM customers c
JOIN orders o
	ON c.customer_id=o.customer_id
JOIN order_items oi
	ON o.order_id=oi.order_id
GROUP BY c.customer_state
ORDER BY SUM(oi.price) DESC LIMIT 5;
-- - Are there periods of unusually strong or weak performance?
WITH sales AS(
SELECT EXTRACT(MONTH FROM o.order_purchase_timestamp) AS months, EXTRACT(YEAR FROM o.order_purchase_timestamp) AS years,
SUM(oi.price) AS total_sales
FROM orders o
JOIN order_items oi
	ON o.order_id=oi.order_id
GROUP BY years,months
ORDER BY years,months
),
averagesales AS(
SELECT months,years,total_sales,
AVG(total_sales) over(partition by years) as avg_sales
FROM sales
),
stddev AS(
SELECT months,years,total_sales,avg_sales,
stddev_pop(total_sales) over(partition by years) as stddev_sales
from averagesales
),
zscore AS(
SELECT months,years, total_sales,avg_sales,stddev_sales,
(total_sales-avg_sales)/stddev_sales as zs
from stddev
)
select months, years, total_sales,round(zs,2) as z_score,
case 
	when zs < -2 then 'Unusually low'
	when zs > 2 then 'Unusually high'
	else 'Normal'
end as flagged
from zscore