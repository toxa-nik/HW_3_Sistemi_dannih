-- Домашнее задание №3.

-- Я не стал перегружать таблицы, поэтому осталось везде HW2.

-- Задание № 1 --
-- Таблица почищена от неуникальных product_id 
-- Вывести распределение (количество) клиентов по сферам деятельности, отсортировав результат по убыванию количества.

select customer.job_industry_category , count(customer_id) 
from HW2.customer 
group by HW2.customer.job_industry_category 
order by count(customer_id) desc;


-- Задание № 2 --
-- Найти общую сумму дохода (list_price * quantity) по всем подтвержденным заказам за каждый месяц по сферам деятельности клиентов.
-- Отсортировать результат по году, месяцу и сфере деятельности.

select to_char(date_trunc('Year', ord.order_date::date),'YYYY') as year, 
	   to_char(date_trunc('Month', ord.order_date::date),'Month') as month, 
	   cust.job_industry_category, 
	   sum(oi.item_list_price_at_sale * oi.quantity) as month_orders_sum 
from HW2.order_items oi
join HW2.orders ord on ord.order_id=oi.order_id
join HW2.customer cust on cust.customer_id = ord.customer_id
where order_status = 'Approved'
group by date_trunc('Year', ord.order_date::date), date_trunc('Month', ord.order_date::date), cust.job_industry_category 
order by date_trunc('Year', ord.order_date::date), date_trunc('Month', ord.order_date::date), cust.job_industry_category;

-- Задание № 3 --	
-- Вывести количество уникальных онлайн-заказов для всех брендов в рамках подтвержденных заказов клиентов из сферы IT. 
-- Включить бренды, у которых нет онлайн-заказов от IT-клиентов, — для них должно быть указано количество 0.
	

select pc.brand,  
		count(distinct case         
				when cust.job_industry_category = 'IT' then ord.order_id
			  end)
from HW2.product_cor pc
left join HW2.order_items oi on pc.product_id = oi.product_id 
left join HW2.orders ord on ord.order_id = oi.order_id
		and ord.online_order  = true and order_status = 'Approved'
left join HW2.customer cust on cust.customer_id = ord.customer_id 
group by pc.brand;

-- Задание № 4 --
-- Найти по всем клиентам: сумму всех заказов (общего дохода), максимум, минимум и количество заказов, 
-- а также среднюю сумму заказа по каждому клиенту. Отсортировать результат по убыванию суммы всех заказов и количества заказов. 
-- Выполнить двумя способами: используя только GROUP BY и используя только оконные функции. Сравнить результат.


-- #1 С помощью GROUP BY --

select cust.customer_id, 
		sum(oi.quantity * oi.item_list_price_at_sale) as sum_cust, 
		max(oi.quantity * oi.item_list_price_at_sale), 
		min(oi.quantity * oi.item_list_price_at_sale),
		count(ord.order_id) as count_cust,
		avg(oi.quantity * oi.item_list_price_at_sale)
from HW2.customer cust
join HW2.orders ord on cust.customer_id = ord.customer_id 
join HW2.order_items oi on ord.order_id = oi.order_id
group by cust.customer_id
order by sum(oi.quantity * oi.item_list_price_at_sale) desc, count(ord.order_id) desc;

-- #2 С помощью оконных функций --


select distinct cust.customer_id, 
		sum(oi.quantity * oi.item_list_price_at_sale) over ww as sum_cust, 
		max(oi.quantity * oi.item_list_price_at_sale) over ww, 
		min(oi.quantity * oi.item_list_price_at_sale) over ww,
		count(ord.order_id) over ww as count_cust,
		avg(oi.quantity * oi.item_list_price_at_sale) over ww
from HW2.customer cust
join HW2.orders ord on cust.customer_id = ord.customer_id 
join HW2.order_items oi on ord.order_id = oi.order_id
window ww as (partition by cust.customer_id)
order by sum_cust desc, count_cust desc;

-- В результате сравнения результата у меня получился небольшой разброс в sum_cust между вариантами (в районе 0 - 0,02). 
-- Сложно сказать, с чем это связано, возможно с разной спецификой округления при использовании оконных функций и группировок.

-- Задание № 5 --
-- Найти имена и фамилии клиентов с топ-3 минимальной и топ-3 максимальной суммой транзакций за весь период 
-- (учесть клиентов, у которых нет заказов, приняв их сумму транзакций за 0).

-- Я оставил customer_id, чтобы избежать проблем с одинаковыми first/last names
-- Ну и клиентом с суммой 0 довольно много, я просто взял 3 попавших.

(select cust.customer_id, cust.first_name, cust.last_name, 
		sum(case when ord.order_id is not null then oi.quantity * oi.item_list_price_at_sale else 0 end) as sum_cust
from HW2.customer cust
left join HW2.orders ord on cust.customer_id = ord.customer_id 
left join HW2.order_items oi on ord.order_id = oi.order_id
group by cust.customer_id, cust.first_name, cust.last_name
order by sum(case when ord.order_id is not null then oi.quantity * oi.item_list_price_at_sale else 0 end) desc
limit 3)
union all
(select cust.customer_id, cust.first_name, cust.last_name, 
		sum(case when ord.order_id is not null then oi.quantity * oi.item_list_price_at_sale else 0 end) as sum_cust
from HW2.customer cust
left join HW2.orders ord on cust.customer_id = ord.customer_id 
left join HW2.order_items oi on ord.order_id = oi.order_id
group by cust.customer_id, cust.first_name, cust.last_name
order by sum(case when ord.order_id is not null then oi.quantity * oi.item_list_price_at_sale else 0 end)
limit 3)
order by sum_cust desc;


-- Задание № 6 --
-- Вывести только вторые транзакции клиентов (если они есть) с помощью оконных функций.
-- Если у клиента меньше двух транзакций, он не должен попасть в результат.

select customer_id, order_date, order_id
from (
select ord.customer_id, ord.order_date, ord.order_id, row_number() over (partition by ord.customer_id order by ord.order_date, ord.order_id ) as numb_of_order
from HW2.orders ord
where ord.order_status = 'Approved'
)
where numb_of_order = 2;

-- Задание № 7 --
-- Вывести имена, фамилии и профессии клиентов, а также длительность максимального интервала (в днях) 
-- между двумя последовательными заказами. Исключить клиентов, у которых только один или меньше заказов.

-- Выглядит громозко и не очень эффективно, конечно.


create or replace view hw2.good_customers as 
(
select distinct customer_id
from (
		select 
			customer_id, 
			count(*) OVER (PARTITION BY customer_id) as order_count
		from HW2.orders
		where order_status = 'Approved'
	 )
where order_count >= 2
);

select customer_id, 
	   first_name, 
	   last_name, 
	   job_title, 
	   max(order_dates_dif) as max_diff_in_days
from (
		select ord.customer_id, 
			   cust.first_name, 
			   cust.last_name, 
			   cust.job_title, 
			   ((lead(ord.order_date) over (partition by ord.customer_id order by ord.order_date))::date - ord.order_date::date) as order_dates_dif
		from HW2.customer cust
		left join HW2.orders ord on cust.customer_id = ord.customer_id 
		where ord.order_status = 'Approved'
	 )
where customer_id in (select customer_id from hw2.good_customers)
group by customer_id, first_name, last_name, job_title
order by customer_id;

-- Задание № 8 --
-- Найти топ-5 клиентов (по общему доходу) в каждом сегменте благосостояния (wealth_segment). 
-- Вывести имя, фамилию, сегмент и общий доход. Если в сегменте менее 5 клиентов, вывести всех.

-- Я вначале использовал rank(), он может вывести больше 5 клиентов, в случае если доход у них будет одинаковый.
-- Всё же остановился на топ 5 клиентов, а не топ 5 доходов, оставил с dense_rank().

select wealth_segment, 
	   customer_id, 
	   first_name, 
	   last_name, 
	   cust_sum,
	   wealth_rank
from 
	(
	select cust.wealth_segment, 
		   cust.first_name,  
		   cust.last_name, 
		   cust.customer_id, 
		   sum(oi.quantity * oi.item_list_price_at_sale) as cust_sum, 
		   dense_rank() over (partition by cust.wealth_segment order by sum(oi.quantity * oi.item_list_price_at_sale) desc) as wealth_rank
	from HW2.customer cust
	join HW2.orders ord on cust.customer_id = ord.customer_id and ord.order_status = 'Approved' 
	join HW2.order_items oi on ord.order_id = oi.order_id
	group by cust.wealth_segment, cust.first_name,  cust.last_name, cust.customer_id 
	)
where wealth_rank <=5
ORDER BY wealth_segment, wealth_rank;



