-- 04. Customer retention
-- - What proportion of identifiable customers place multiple orders?
with unique_counts as (
	select customer_unique_id as count_un
	from customers
	group by customer_unique_id
	having count(customer_id)>1
)
select round((count(count_un)/(select count(distinct customer_unique_id) from customers)::numeric)*100,2) as repeat_customer_rate  from unique_counts;
-- - How do purchasing frequency and spending differ between one-time and repeat customers?
with labels as (
	select customer_unique_id,
	case 
		when count(customer_id)>1 then 'repeat_customer'
		else 'one_time_customer'
	end as customer_type
	from customers
	group by customer_unique_id
),
with_labels as (
	select o.order_id,c.customer_id,l.customer_unique_id,l.customer_type from labels l
	join customers c 
		on c.customer_unique_id=l.customer_unique_id
	join orders o
		on o.customer_id=c.customer_id
),
purchase_frequency as (
	select customer_type, count(distinct customer_unique_id) as no_of_customer, count(customer_id) as no_of_purchases,
	round(count(customer_id)/count(distinct customer_unique_id)::numeric,2) as avg_purchase_frequency
	from with_labels
	group by customer_type
)
,
spending as (
	select wl.customer_type,sum(p.payment_value) as total_spending
	from order_payments p
	join with_labels wl
		on p.order_id=wl.order_id
	group by wl.customer_type 
)
select pf.customer_type,pf.no_of_customer,pf.no_of_purchases,pf.avg_purchase_frequency,s.total_spending,
round(s.total_spending/pf.no_of_customer,2) as avg_spending
from spending s
join purchase_frequency pf
	on s.customer_type = pf.customer_type;
-- - Do repeat-purchase patterns vary across customer groups?
with labels as (
	select customer_unique_id,
	case 
		when count(customer_id)>1 then 'repeat_customer'
		else 'one_time_customer'
	end as customer_type
	from customers
	group by customer_unique_id
),
state_repeat_purchases as (
	select c.customer_state, count(l.customer_unique_id) as no_of_purchases from labels l
	join customers c
		on c.customer_unique_id=l.customer_unique_id
	where l.customer_type='repeat_customer'
	group by c.customer_state
	order by no_of_purchases desc
)
select customer_state, no_of_purchases, round(no_of_purchases*100.00/sum(no_of_purchases) over(),2) as purchase_percentage
from state_repeat_purchases;
