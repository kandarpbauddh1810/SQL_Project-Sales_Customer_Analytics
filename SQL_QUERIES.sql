CREATE DATABASE olist_analytics_db;
USE olist_analytics_db;

# Create Customer Table
CREATE TABLE customers(
customer_id VARCHAR(50) PRIMARY KEY,
customer_unique_id VARCHAR(50),
customer_zip_code_prefix INT,
customer_city VARCHAR(100),
customer_state CHAR(2));

#CREATE products table
CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);


CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

CREATE TABLE product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    PRIMARY KEY (review_id, order_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);




#Module 1: Sales & Revenue
#TOTAL REVENUE
SELECT COUNT(i.product_id)as total_sold_quantity,SUM(i.price) as total_revenue
from order_items as i 
JOIN orders as o
ON i.order_id = o.order_id
AND o.order_status = "delivered";

#Total quantity sold
SELECT COUNT(i.product_id)as total_sold_quantity,o.order_status
from order_items as i
JOIN orders as o
ON i.order_id = o.order_id
AND o.order_status = "delivered";

# Total revenue per category.
select p.product_category_name,t.product_category_name_english,
COUNT(o.product_id) as total_unit_sold,SUM(o.price) as total_revenue
from order_items as o
JOIN orders as c
ON c.order_id = o.order_id
AND c.order_status = "delivered"
JOIN products as p
ON o.product_id = p.product_id
JOIN product_category_translation as t
ON t.product_category_name = p.product_category_name
GROUP BY p.product_category_name,t.product_category_name_english;


#Module 2: Product & Seller Performance
#1.Most sold products
SELECT i.product_id,p.product_category_name,t.product_category_name_english,
COUNT(i.product_id) as total_quantity_sold
from order_items as i
JOIN orders as o
ON i.order_id = o.order_id
AND o.order_status = "delivered"
JOIN products as p
ON p.product_id = i.product_id
LEFT JOIN product_category_translation as t
ON t.product_category_name = p.product_category_name
GROUP BY 
i.product_id,
p.product_category_name,
t.product_category_name_english
ORDER BY total_quantity_sold DESC LIMIT 1;

#Best performing sellers
SELECT s.seller_id,COUNT(i.product_id) as total_quantity
FROM order_items as i
JOIN orders as o
ON o.order_id = i.order_id
AND o.order_status = "delivered"
JOIN sellers as s
ON s.seller_id = i.seller_id
GROUP BY s.seller_id
ORDER BY total_quantity DESC LIMIT 3;

#Seller vs product quality (reviews)
SELECT i.seller_id,i.product_id,
AVG(r.review_score) as Average_review_score,COUNT(r.review_score) as Total_review
FROM order_items as i
JOIN orders as o
ON i.order_id = o.order_id
AND o.order_status = "delivered"
JOIN order_reviews as r
ON r.order_id = i.order_id
GROUP BY i.seller_id,i.product_id;


#Module 3: Customer & Payment Behavior
#Installment vs full payment
SELECT COUNT(order_id),payment_installments,
CASE
	WHEN payment_installments > 1 THEN "Installment" 
    WHEN payment_installments = 1 THEN "Full Payment"
    ELSE "UNKNOWN"
    END payment_type
from order_payments
GROUP BY payment_installments;

#Credit card usage
SELECT COUNT(DISTINCT order_id) as total_credit_usage_count
FROM order_payments
WHERE payment_type = "credit_card";

#Payment strategy suggestions
#1. Payment Method Usage Analysis
SELECT p.payment_type,COUNT(i.order_id) as total_order
FROM order_items as i
JOIN orders as o
ON i.order_id = o.order_id
AND o.order_status = "delivered"
JOIN order_payments as p
ON p.order_id = i.order_id
GROUP BY p.payment_type;

#2.Revenue by Payment Method
SELECT p.payment_type,SUM(i.price) as total_revenue_of_payment_type
FROM order_items as i
JOIN orders as o
ON i.order_id = o.order_id
AND o.order_status = "delivered"
JOIN order_payments as p
ON p.order_id = i.order_id
GROUP BY p.payment_type;

#3.Installment vs full payment
SELECT 
    CASE 
        WHEN p.payment_installments = 1 THEN 'Single Payment'
        ELSE 'Installments (EMI)'
    END AS Payment_Mode,
    COUNT(DISTINCT o.order_id) AS Total_Orders,
    ROUND(AVG(p.payment_value), 2) AS Average_Order_Value,
    ROUND(SUM(i.price), 2) AS Total_Revenue
FROM order_payments p
JOIN orders o 
ON p.order_id = o.order_id
JOIN order_items as i
ON i.order_id= p.order_id
WHERE o.order_status = 'delivered'
GROUP BY Payment_Mode;


#4. High-Value Orders Analysis
select p.payment_type,COUNT(DISTINCT i.order_id),SUM(i.price) as high_value_ORDER from order_items as i
JOIN orders as o
ON i.order_id = o.order_id
AND o.order_status = "delivered"
JOIN order_payments as p
ON p.order_id = i.order_id
GROUP BY p.payment_type
ORDER BY high_value_ORDER DESC;

#Module 4: Location & Reviews
# city wise revenue
SELECT c.customer_city,SUM(i.price) as total_revenue_by_city
FROM order_items as i
JOIN orders as o 
ON i.order_id = o.order_id
AND o.order_status = "delivered"
JOIN customers as c
ON c.customer_id = o.customer_id
GROUP BY c.customer_city
ORDER BY total_revenue_by_city DESC;

#state wise sales
SELECT c.customer_state,SUM(i.price) as total_revenue_by_city
FROM order_items as i
JOIN orders as o 
ON i.order_id = o.order_id
AND o.order_status = "delivered"
JOIN customers as c
ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER BY total_revenue_by_city DESC;

#2.Review-based improvement insights
#1.Overall customers are satisfied or not?
SELECT review_score,COUNT(review_id) as total_review
FROM order_reviews
GROUP BY review_score
ORDER BY review_score DESC;

#2. How many customers are Unhappy.
SELECT review_score,COUNT(review_id) as total_review
FROM order_reviews
GROUP BY review_score
HAVING review_score IN(1,2);

#Delivered orders ke baad bhi low rating aa rahi hai ya nahi?
SELECT r.review_score,COUNT(o.order_id)
FROM order_reviews as r
JOIN orders as o
ON r.order_id = o.order_id
AND o.order_status = "delivered"
GROUP BY r.review_score
HAVING r.review_score IN(1,2);

#4.How many customers only give ratings and don't write comments?
SELECT r.review_score,COUNT(o.order_id)
FROM order_reviews as r
JOIN orders as o
ON o.order_id = r.order_id
AND o.order_status = "delivered"
WHERE r.review_comment_message IS NULL
GROUP BY r.review_score;
