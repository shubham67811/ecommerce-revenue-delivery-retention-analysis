-- 03. Customer satisfaction
-- - What do review scores look like overall?
SELECT ROUND(avg(review_score),2) AS overall_review_score FROM order_reviews;

-- - Are late deliveries associated with lower review scores?
WITH labels AS(
	select order_id,customer_id,
	case 
		when order_delivered_customer_date<=order_estimated_delivery_date then 'on_time'
		else 'late'
	end as delivery_labels
	from orders
	where order_status='delivered' and order_delivered_customer_date is not null
)
SELECT l.delivery_labels, ROUND(AVG(r.review_score),2) AS avg_review_score
FROM labels l
JOIN order_reviews r
	ON r.order_id=l.order_id
GROUP BY l.delivery_labels;
-- - Which categories or geographic markets have relatively poor reviews?
with selection as (
	select *, row_number() over(partition by order_id) as sl
	from order_items
)
select coalesce(pt.product_category_name_english,p.product_category_name) as product_category,round(avg(r.review_score),2) as average_scores, count(r.order_id)
from selection oi
join products p
	on oi.product_id=p.product_id
join order_reviews r
	on r.order_id=oi.order_id 
left join product_category_name_translation pt
	on pt.product_category_name=p.product_category_name
where oi.sl=1
group by coalesce(pt.product_category_name_english,p.product_category_name)
order by round(avg(r.review_score),2);

