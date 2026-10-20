-- 05. Payment & order issues
-- - What are the order-status and cancellation patterns?
select order_status, count(order_id) as count
from orders
group by order_status
order by count(order_id) desc;

select extract(year from order_purchase_timestamp) as years,extract(month from order_purchase_timestamp) as months, count(order_id) filter(where o.order_status='canceled'
) as canceled_orders,
count(order_id) as total_orders,
round(100.0*count(*) filter(where o.order_status='canceled')/nullif(count(order_id),0),2) as cancellation_rate
from orders o
group by  years,months
order by years,months;

-- - How do payment methods and installment choices vary?
select * from order_payments;
select payment_type from order_payments group by payment_type;
select payment_installments,
	   count(*) filter(where payment_type='credit_card') as credit_card_count,
	   count(*) filter(where payment_type='debit_card') as debit_card_count,
	   count(*) filter(where payment_type='voucher') as voucher_count,
	   count(*) filter(where payment_type='boleto') as boleto_count,
	   count(*) filter(where payment_type='not_defined') as not_defined_count
from order_payments
group by payment_installments;

-- - What order value is associated with cancelled orders, and how should that figure be interpreted?
select o.order_status, sum(p.payment_value) as total from orders o
join order_payments p
	on p.order_id=o.order_id
where o.order_status='canceled'
group by o.order_status;

