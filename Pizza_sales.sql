create database pizzahut;
use pizzahut;
-- Creating table orders
create table orders(
order_id int not null,
order_date date not null,
order_time time not null,
primary key (order_id)
);

-- creating table order_details
create table order_details(
order_details_id int,
order_id int,
pizza_id varchar(30),
quantity int
);

alter table order_details
add primary key (order_details_id);

-- Creating table pizza.
create table pizza(
pizza_id varchar(30),
pizza_type_id varchar(30),
size text,
price decimal
);

-- Creating table pizza type.
CREATE table pizza_type(
pizza_type_id varchar(30),
name varchar (30),
category varchar (30),
ingredient varchar (150)
);

##loading data into customer table
LOAD DATA INFILE 'C:/order_details.csv'
 INTO TABLE order_details
 FIELDS TERMINATED BY ','
 ENCLOSED BY '"'
 LINES TERMINATED BY '\n'
 IGNORE 1 ROWS;
 
##loading data into orders
LOAD DATA INFILE 'C:/orders.csv'
 INTO TABLE orders
 FIELDS TERMINATED BY ','
 ENCLOSED BY '"'
 LINES TERMINATED BY '\n'
 IGNORE 1 ROWS;
 
##loading data into pizza
LOAD DATA INFILE 'C:/pizzas.csv'
 INTO TABLE pizza
 FIELDS TERMINATED BY ','
 ENCLOSED BY '"'
 LINES TERMINATED BY '\n'
 IGNORE 1 ROWS;
 
 ##loading data into pizza_type
LOAD DATA INFILE 'C:/pizza_types.csv'
 INTO TABLE pizza_type
 FIELDS TERMINATED BY ','
 ENCLOSED BY '"'
 LINES TERMINATED BY '\r\n' 
 IGNORE 1 ROWS;

select count(*) from pizza_type;

-- Retrieve the total number of orders placed.
select count(order_id)as total_orders from orders;
-- Calculate the total revenue generated from pizza sales.
SELECT 
    SUM(order_details.quantity * pizza.price) AS total_sales
FROM
    order_details
        JOIN
    pizza ON pizza.pizza_id = order_details.pizza_id;

-- Identify the highest-priced pizza along with pizza name.
SELECT 
    pizza_type.name, pizza.price
FROM
    pizza_type
        JOIN
    pizza ON pizza_type.pizza_type_id = pizza.pizza_type_id
ORDER BY pizza.price DESC
LIMIT 1;


-- Identify the most common pizza size ordered.
SELECT 
    pizza.size,
    COUNT(order_details.order_details_id) AS order_count
FROM
    pizza
        JOIN
    order_details ON pizza.pizza_id = order_details.pizza_id
GROUP BY pizza.size
ORDER BY order_count DESC;

-- List the top 5 most ordered pizza types along with their quantities.
SELECT 
    pizza_type.name as pizza_type, SUM(order_details.quantity) AS tot_quantity
FROM
    pizza_type
        JOIN
    pizza ON pizza_type.pizza_type_id = pizza.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizza.pizza_id
GROUP BY pizza_type.name 
ORDER BY tot_quantity DESC
LIMIT 5;

-- Join the necessary tables to find the total quantity of each pizza category orderded.
select pizza_type.category, sum(order_details.quantity) as quantity 
from pizza_type join pizza
on pizza_type.pizza_type_id = pizza.pizza_type_id
join order_details
on order_details.pizza_id = pizza.pizza_id
group by pizza_type.category
order by quantity desc;

-- Determine the distribution of orders by hour of the day.
select hour(order_time) as hour, count(order_id) as count from orders
group by hour 
order by count desc;

-- Join relevant tables to find the category-wise distribution of pizzas.
select category, count(name) as name from pizza_type
group by category;
 -- Group the orders by date and calculate the average number of pizzas ordered per day.
select round(avg(tot_quantity)) from
(select orders.order_date, sum(order_details.quantity) as tot_quantity
from orders join order_details
on orders.order_id = order_details.order_id
group by orders.order_date) as order_quantity;
-- Determine the top 3 most ordered pizza types based on revenue.
select pizza_type.name, sum(order_details.quantity*pizza.price) as revenue
from pizza_type join pizza 
on  pizza_type.pizza_type_id = pizza.pizza_type_id 
join order_details
on order_details.pizza_id = pizza.pizza_id
group by pizza_type.name
order by revenue desc limit 3;

-- Calculate the percentage contribution of each pizza type to total revenue.
select pizza_type.category, round(sum(order_details.quantity*pizza.price) /
(select round(SUM(order_details.quantity * pizza.price),2) AS total_sales
FROM order_details
JOIN pizza ON pizza.pizza_id = order_details.pizza_id) * 100,2) as revenue
from pizza_type join pizza 
on pizza_type.pizza_type_id = pizza.pizza_type_id 
join order_details
on order_details.pizza_id = pizza.pizza_id
group by pizza_type.category
order by revenue desc;
-- Analyze the cumulative revenue generated over time.
select order_date, sum(tot_rev) over(order by order_date) as cum_rev
from
(select orders.order_date, sum(order_details.quantity*pizza.price) as tot_rev
from order_details join pizza
on order_details.pizza_id = pizza.pizza_id
join orders
on orders.order_id = order_details.order_id
group by orders.order_date
order by tot_rev desc) as sales;
-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
select name,tot_sales_rev from
(select category,name,tot_sales_rev,
dense_rank() over(partition by category order by tot_sales_rev) as revenue
from
(select pizza_type.category, pizza_type.name,
(sum(order_details.quantity* pizza.price)) as tot_sales_rev
from pizza_type join pizza
on pizza_type.pizza_type_id = pizza.pizza_type_id
join order_details
on order_details.pizza_id = pizza.pizza_id 
group by pizza_type.category, pizza_type.name) as sales_rev) as sales
where revenue <=3;
