-- 02. Delivery performance
-- - What proportion of delivered orders arrived after the estimated delivery date?
select ROUND(((select count(*) from orders where order_delivered_customer_date>order_estimated_delivery_date AND order_status='delivered' AND order_delivered_customer_date is not null)/(select count(*)::numeric from orders where order_status='delivered' AND order_delivered_customer_date is not null))*100,2) AS late_delivery_pct;
-- - How does delivery performance vary by state or product category?
WITH states_otp AS(
	select order_id,customer_id,
	case 
		when order_delivered_customer_date<=order_estimated_delivery_date then 'on_time'
		else 'late'
	end as labels
	from orders
	where order_status='delivered' and order_delivered_customer_date is not null
),
states AS(
	select c.customer_state,so.labels
	from states_otp so
	join customers c
		on c.customer_id=so.customer_id
),
on_time_count AS(
	select c.customer_state, count(so.labels) as ontime_count
	from states_otp so
	join customers c
		on c.customer_id=so.customer_id
	where so.labels='on_time'
	group by c.customer_state
),
total_count AS(
		select c.customer_state, count(so.labels) as total_count
		from states_otp so
		join customers c
			on c.customer_id=so.customer_id
		group by c.customer_state
)
select tc.customer_state,otc.ontime_count,tc.total_count,
round(((otc.ontime_count)/(tc.total_count)::numeric)*100,2) as on_time_performance
from total_count tc
join on_time_count otc
	on tc.customer_state=otc.customer_state
order by on_time_performance desc;

	-- - How does actual delivery time compare with estimated delivery time?
SELECT avg((order_delivered_customer_date-order_estimated_delivery_date)) as avg_days_delay 
, min((order_delivered_customer_date-order_estimated_delivery_date)) as min_days_delay 
, max((order_delivered_customer_date-order_estimated_delivery_date)) as max_days_delay from orders where order_status='delivered' and order_delivered_customer_date is not null;

--analyzing earliest delivery 
with earliest_delivery as (
SELECT * FROM orders where order_delivered_customer_date-order_estimated_delivery_date=(select min((order_delivered_customer_date-order_estimated_delivery_date)) from orders)
)
select ed.order_id, r.review_id, r.review_score,r.review_comment_title, r.review_comment_message
from earliest_delivery ed
join order_reviews r
	on r.order_id=ed.order_id;
--analyzing latest delivery
with latest_delivery as (
SELECT * FROM orders where order_delivered_customer_date-order_estimated_delivery_date=(select max((order_delivered_customer_date-order_estimated_delivery_date)) from orders)
)
select ld.order_id, r.review_id, r.review_score,r.review_comment_title, r.review_comment_message
from latest_delivery ld
join order_reviews r
	on r.order_id=ld.order_id;