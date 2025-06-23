use logistic;

----------Assigning_primary_key----------
ALTER TABLE customers ADD PRIMARY KEY (customer_id);
ALTER TABLE products ADD PRIMARY KEY (product_id);
ALTER TABLE orders ADD PRIMARY KEY (order_id);
ALTER TABLE order_items ADD PRIMARY KEY (order_item_id);
ALTER TABLE trucks ADD PRIMARY KEY (truck_id);
ALTER TABLE shipments ADD PRIMARY KEY (shipment_id);

------------Assigning_foreign_key------------

ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_order
FOREIGN KEY (order_id) REFERENCES orders(order_id),
ADD CONSTRAINT fk_order_items_product
FOREIGN KEY (product_id) REFERENCES products(product_id);

ALTER TABLE shipments
ADD CONSTRAINT fk_shipments_order
FOREIGN KEY (order_id) REFERENCES orders(order_id),
ADD CONSTRAINT fk_shipments_truck
FOREIGN KEY (truck_id) REFERENCES trucks(truck_id);

------------sample tables for reference----------------------

SELECT * FROM customers LIMIT 5;
SELECT * FROM products LIMIT 5;
SELECT * FROM orders LIMIT 5;
SELECT * FROM order_items limit 5;
SELECT * FROM trucks LIMIT 5;
SELECT * FROM shipments LIMIT 5;


-----------Total numer of order-----------
---Description: calculate total number of orders---------------
---Tables used: orders
SELECT COUNT(*) AS total_orders
FROM orders;

----------1.Top 5 Customers by Spending---------------
---Description: finding out top 5 customers in temrs of there spending based on thier orders and the products they orders and its quantity.
--- Tables used: customers, orders, order_items, products

select C.customer_id, customer_name, sum(order_price) as total_revenue from customers as C join
(select O.order_id, customer_id, order_price from orders as O 
left join ( select order_item_id, order_id, OI.product_id, quantity, price, (quantity*price) as order_price from order_items as OI left join products as P on OI.product_id = P.product_id) 
as temp1 on O.order_id = temp1.order_id) as temp2 on C.customer_id = temp2.customer_id
group by C.customer_id 
order by total_revenue desc
limit 5;

---------2.Top selling products-------------
---Description: finding out top selling products bases on product price from product table and the quantity ordered from order_items table
---Tables used: order_items, products

select P.product_name, sum(OI.quantity) as total from order_items as OI join products as P on OI.product_id = P.product_id 
group by product_name
order by total desc;

-------------3.Revenue by product catogery------------
---Description: Revenue generated from diffenert catagories of products
---Tables used: order_items, products

select category, sum(quantity * price) as revenue from order_items as OI join products as P on OI.product_id = P.product_id
group by category;

-----------4.Monthly order trend------------------
---Description: number of orders in received every month
---tables used: orders

select date_format(order_date, '%Y-%m') as month, count(*) as total_orders from orders
group by month
order by month desc;

-------5.delivery delays and on-time delivery rate-------------
---Description: delevery status rate 
---table used: shipments

select delivery_status, count(*) as total, round(count(*) * 100/sum(count(*)) over (), 2) as rate from shipments group by delivery_status;

------------6.Truck utilization--------------
---Description: number of shipemenst each trucks had
---Table used: shipments

select truck_id, count(shipment_id) as num_shipments from shipments group by truck_id order by num_shipments desc;

------------7.regionwise sales analysis------------
---Description: total revenue across regions based on quantity, price from order_items and product and regions from where customers ordered
---Tables used: products, order_items, customers, orders

select region, count(order_id) as total_orders, sum(quantity*price) as total_revenue from products as P right join (select temp1.region, temp1.order_id, OI.product_id, OI.quantity from order_items as OI left join (select C.region, O.order_id from customers as C right join orders as O on C.customer_id = O.customer_id) as temp1
on OI.order_id = temp1.order_id) as temp2 on P.product_id = temp2.product_id
group by region;

-----------8.Average order value---------------
---Description: average order value based on quantities form order_items and price from products and number of order_items per order
---Tables used: order_items, products

select avg(order_total) as avg_ord_val from (select OI.order_id, sum((quantity * price)) as order_total from order_items as OI left join products as P on OI.product_id = P.product_id
group by order_id
order by order_id) as temp1;

------------------9.customers with repeat orders-----------------------------------
---Description: customers who has ordered more than once
---Tables used: customers, orders

select C.customer_id, customer_name, count(*) as total_orders from customers as C left join orders as O on C.customer_id = O.customer_id
group by C.customer_id, customer_name
having total_orders > 2
order by total_orders desc;

--------------10.shipment status------------------
---Description: number of shipments as per delevery status
---Table used: shipements

select delivery_status, count(*) as num_shipments from shipments
group by delivery_status;

----------11. Top 5 customers contributes--------------------------------------
---Description: top 5 customers contributed based on total revenue generated
--- Tables used: customers, orders, order_items, products

select  round((select sum(total_revenue) from
(select C.customer_id, customer_name, sum(order_price) as total_revenue from customers as C join
(select O.order_id, customer_id, order_price from orders as O 
left join ( select order_item_id, order_id, OI.product_id, quantity, price, (quantity*price) as order_price from order_items as OI left join products as P on OI.product_id = P.product_id) 
as temp1 on O.order_id = temp1.order_id) as temp2 on C.customer_id = temp2.customer_id
group by C.customer_id 
order by total_revenue desc
limit 5)
 as temp3) *100/ (select sum(total_revenue) from (select C.customer_id, customer_name, sum(order_price) as total_revenue from customers as C join
(select O.order_id, customer_id, order_price from orders as O 
left join ( select order_item_id, order_id, OI.product_id, quantity, price, (quantity*price) as order_price from order_items as OI left join products as P on OI.product_id = P.product_id) 
as temp1 on O.order_id = temp1.order_id) as temp2 on C.customer_id = temp2.customer_id
group by C.customer_id 
order by total_revenue desc) as temp4), 2) as top_5_contribution;