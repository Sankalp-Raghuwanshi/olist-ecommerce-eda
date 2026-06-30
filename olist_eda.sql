create table customers (
      customer_id VARCHAR primary key,
      custome_unique_id VARCHAR,
      customer_zip_code_prefix INT,
      customer_city VARCHAR,
      customer_state VARCHAR
);

CREATE TABLE orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

create table order_items (
     order_id TEXT,
     order_item_id INT,
     product_id TEXT,
     seller_id TEXT,
     shipping_limit_date TIMESTAMP,
     price numeric,
     freight_value numeric
);

CREATE TABLE products (
    product_id TEXT,
    product_category_name TEXT,
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE sellers (
    seller_id TEXT,
    seller_zip_code_prefix INT,
    seller_city TEXT,
    seller_state TEXT
);

CREATE TABLE order_payments (
    order_id TEXT,
    payment_sequential INT,
    payment_type TEXT,
    payment_installments INT,
    payment_value NUMERIC
);

create table order_reviews (                        -- DATA INGESTION NOTE: All 9 raw Kaggle CSVs were imported into their respective PostgreSQL tables.
     review_id TEXT,                                 --order_reviews required special handling: review_comment_message contains
     order_id TEXT,                                  -- unescaped commas/quotes/line breaks (raw Portuguese customer text), which broke
     review_score int,                               -- DBeaver's CSV parser mid-row and caused column misalignment during import.
     review_comment_title TEXT,                      -- Resolved by loading this table via a Python (pandas) script instead, using
     review_comment_message TEXT,                    -- pandas' more robust CSV quote/escape handling, then inserting directly into
     review_creation_date TIMESTAMP,                 -- PostgreSQL via SQLAlchemy. This is a common real-world data quality issue
     review_answer_timestamp timestamp               -- with free-text fields in raw datasets.
);
TRUNCATE TABLE order_reviews;

CREATE TABLE product_category_translation (
    product_category_name TEXT,
    product_category_name_english TEXT
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat NUMERIC,
    geolocation_lng NUMERIC,
    geolocation_city TEXT,
    geolocation_state TEXT
);


select count(*) from customers;
select count(*) from orders o ;
select count (*) from order_items oi ;
select count(*) from order_payments op ;
select count(*) from order_reviews t ;
select count(*) from products p ;
select count(*) from sellers s ;
select count(*) from geolocation g ;
select count(*) from product_category_translation pct ;

select o.order_id,
       c.customer_state,
       oi.price,
       oi.freight_value
from orders o
join customers c on o.customer_id=c.customer_id 
join order_items oi on o.order_id=oi.order_id 
limit 20;

CREATE TABLE master_orders as  -- Creating a main table for further analysis 
SELECT 
    o.order_id,                                       
    DATE(o.order_purchase_timestamp) AS order_date,   -- joining orderid and orderdate from table orders 
    c.customer_state,                                 -- joining customer state from table customers
    s.seller_state,                                   --joining seller state from table sellers
    pct.product_category_name_english AS category,    -- joining product category from table product category translation
    oi.price,                                      
    oi.freight_value,                                 -- joining price and freight value from table order_items
    op.payment_value,                                 -- joining payment value from table order_payment
    r.review_score,                                   -- joining review score from table reviews 

    (o.order_delivered_customer_date - o.order_purchase_timestamp) 
        AS delivery_time,

    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
        THEN 1 ELSE 0 
    END AS delay_flag

FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_translation pct 
        ON p.product_category_name = pct.product_category_name
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN order_payments op ON o.order_id = op.order_id
JOIN order_reviews r ON o.order_id = r.order_id;

select count(*) from master_orders mo ;
select * from master_orders limit 20 ;       -- checking our main table 

select order_id ,count(*)                    -- Checking for duplicates
from master_orders mo 
group by order_id 
order by count(*) desc;

select * from master_orders mo                                                               -- Checking for nulls 
where review_score is null or payment_value is null or Category is null or order_date is null 
or customer_state is null or seller_state is null or price is null or   freight_value is null
or order_id is null;                                                                          -- no nulls in dataset 

alter table master_orders           -- Adding columns order month and order year 
add column order_month int,
add column order_year int;

update master_orders mo                            -- extracting data from order_date and adding in the new columns
set order_month = extract (month from order_date),
    order_year = extract (year from order_date);

alter table master_orders                          -- adding a column for total order value
add column total_value numeric;                    

update master_orders mo 
set total_value = price+freight_value;             -- updating the total order value column 

alter table master_orders                          -- ading column for the delivery days as number 
add column delivery_days int;

update master_orders mo                                 -- extracting data form delivery time and updating it in delivery days 
set delivery_days = extract (DAY from delivery_time);

SELECT MIN(order_date), MAX(order_date) FROM master_orders;  -- for understanding the range of time of orders
SELECT MIN(price), MAX(price) FROM master_orders;            -- for understanding the range of price of products 
SELECT MIN(delivery_days), MAX(delivery_days) FROM master_orders;   -- for understanding the range of delivery days 
SELECT DISTINCT category FROM master_orders ;                      -- for understanding the category of products 


CREATE INDEX idx_order_id ON master_orders(order_id);             -- Creating indexes on these columns to optimize analytical query performance for frequently queried columns  
CREATE INDEX idx_order_date ON master_orders(order_date);           
CREATE INDEX idx_category ON master_orders(category);

select *                                                          -- for viewing all the columns in the main table 
from master_orders mo ;

CREATE VIEW analytics_view as                                     -- Created a dedicated analytical view from the integrated dataset to enable efficient exploratory analysis without altering base tables.
SELECT
    order_id,
    order_date,
    order_year,
    order_month,
    customer_state,
    seller_state,
    category,
    price,
    freight_value,
    total_value,
    payment_value,
    review_score,
    delivery_days,
    delay_flag
FROM master_orders;

SELECT * FROM analytics_view LIMIT 20 ;                    -- checking the analytical view 



-- PHASE 2 : IMPORTANT QUESTIONS / Exploratory Insights
   --• Sales & Growth Findings
   --• Product & Category Findings
   --• Customer Behavior Findings
   --• Logistics & Delivery Findings
   --• Seller Performance Findings and insights 


-- BLOCK 1 : Sales and Growth Trends                           
--  Q1-Monthly order trend                                   -- KEY INSIGHTS AND PROBLEMS INDENTIFIED 

SELECT                                                       -- INSIGHT : Orders show strong growth with time exponentially increasing with time                 
    order_year,                                              -- PROBLEM : Total orders have been almost constant for around a year now , no exponential spike in them 
    order_month,
    COUNT(DISTINCT order_id) AS total_orders
FROM analytics_view
GROUP BY order_year, order_month
ORDER BY order_year, order_month ASC;

-- Q2-Monthly revenue Trend 

SELECT                                                      -- INSIGHT : Revenue trend closely follows order volume, confirming that business growth is primarily driven by increasing transactions rather than increase in order value
    order_year,
    order_month,
    SUM(total_value) AS revenue
FROM analytics_view
GROUP BY order_year, order_month
ORDER BY order_year, order_month asc ;

-- Q3-Average Order Value Trends 

SELECT                                                             -- Average order value remains relatively stable across months
    order_year,
    order_month,
    AVG(total_value) AS avg_order_value
FROM analytics_view
GROUP BY order_year, order_month;

--BLOCK 2 : Product & Category Insights
-- Q4-Top categories by revenue

select category ,                                                 -- INSIGHT : Health_beauty and watches_gifts category generate the most revenue 
       sum(total_value) as revenue                                             -- few categories generate the most revenue 
from analytics_view 
group by category 
order by revenue desc;

-- Q5-Categories with worst reviews                              -- INSIGHT : Security and services has the worst review score 

select category,
       avg(review_score) as avg_review 
from analytics_view 
group by category 
order by avg_review asc;

-- Q6-Categories with high freight cost problem                   -- INSIGHT : Home comfort has the highest frieght ratio 

select category,
       AVG(freight_value/price) as freight_ratio
from analytics_view
group by category 
order by freight_ratio desc;

-- BLOCK 3 : CUSTOMER BEHAVIOR 

-- Q7-Top states by order                                     INSIGHT : Sao Paulo is the state that holds the most orders

select customer_state ,
      count(distinct order_id) as orders
from analytics_view 
group by customer_state 
order by count(distinct order_id) desc ;

-- Q8-Repeat vs one time customer                               INSIGHT : 96% of the customers are repeat customers 


SELECT 
    COUNT(*) FILTER (WHERE order_count = 1) AS one_time,
    COUNT(*) FILTER (WHERE order_count > 1) AS repeat_customers
FROM (
    SELECT customer_state, order_id,
           COUNT(order_id) OVER (PARTITION BY order_id) AS order_count
    FROM analytics_view
) ;

-- BLOCK 4 : LOGISTICS AND DELIVERY 

-- Q9-Average delivery days by state                                     INSIGHT : Sao Paulo has the fast avg delivery duration 


select customer_state ,
    avg(delivery_days) as avg_delivery
from analytics_view
group by customer_state 
order by avg_delivery asc ;

-- Q10-State with highest delays                                           INSIGHT : Sao Paulo and Rio De Janeiro have the highest delay 

select customer_state ,
      sum(delay_flag) as total_delay 
from analytics_view 
group by customer_state 
order by total_delay desc ;

-- Q11-does delay affect reviews                                   INSIGHT - There is a 60% drop in reviews on an average when the delivery is delayed

select delay_flag,
       avg(review_score) as avg_review 
from analytics_view av 
group by delay_flag ;

-- BLOCK 5 : SELLER PERFORMANCE 

-- Q12-Sellers causing most delays                                  INSIGHT: Sellers of State of Amazon has the most delays 

select seller_state ,
       AVG(delay_flag) as delay_rate
from analytics_view av 
group by seller_state 
order by delay_rate desc ;

-- Q13-seller state with poor reviews                                 INSIGHT: State of Acre has the worst average review 

select seller_state ,
       avg(review_score) as avg_review
from analytics_view av 
group by seller_state 
order by avg_review asc ;


--- PHASE 3 : BUSINESS MODELING 
   -- Delay Impact Model
   -- Seller Performance Model 
   -- Freight Burden Model
   -- Customer Value Analysis

-- MODEL 1 : Delay Impact                             INSIGHT : More Delay Days = Lower Review Score 

select                                                -- Delivery delays beyond 20 days reduces the review score by almost 20%
     delivery_days,
     Avg(review_score) as avg_review 
from analytics_view av 
group by av.delivery_days 
order by delivery_days ;

-- Model 2 : Seller Performance Score                             INSIGHT : For identifying poor performing regions             

select seller_state,                                              -- Sellers from state of Amazonas have the highest delays 
       Count(order_id) as total_orders,
       AVG(review_score) as avg_review,
       AVG(delay_flag) as delay_rate 
from analytics_view av 
group by seller_state 
order by delay_rate desc;

-- Model 3 : Freight Burden Model                                 INSIGHT : High Freight % leads to bad reviews 
select category,                                                      -- Reduction in freight ratio by 18% increases the reviews by almost 10%
       AVG(freight_value/price) as freight_ratio,
       AVG(review_score) as avg_review 
from analytics_view av 
group by category 
order by freight_ratio desc;

-- MODEL 4 : Customer Value                                  INSIGHT: Where are the most valuable customers concentrated.
select customer_state,                                       -- More than 37% of the total Revenue comes from Sao Paulo state            
       Count(distinct order_id) as orders,
       sum(total_value) as revenue
from analytics_view av 
group by av.customer_state 
order by revenue desc;

select sum(total_value) as revenue 
from analytics_view av ;

-- INSIGHTS OF PHASE 3 :
-- 1. Sao Paulo alone contributes over 37% of total orders, highlighting strong regional demand concentration 
--    and indicating the need for region-focused logistics optimization and warehousing planning .
-- 2. An 18% reduction in Freight-to-price ration leads to an approximate 10% increase in average review score
--    proving that shipping cost is a critical driver of customer satisfaction .
-- 3. Sellers operating from Amazonas exhibit the highest delivery delay rates, indicating regional operational 
--    challenges that negatively affect delivery timelines and customer experience.
-- 4. Orders delivered beyond 20 days experience nearly a 20% drop in review score , identifying a clear delivery
--    threshold after which customer dessatisfaction rises sharply .

-- KEY PROBLEMS IDENTIFIED :

-- High dependency on a single state (São Paulo)
-- Poor seller performance from specific regions causing delays
-- Freight pricing negatively impacting reviews
-- Long delivery timelines reducing customer satisfaction

-- RECOMMENDATIONS :

-- Set Service Level Aggrement to keep delivery time under 20 days
-- Re-evaluate freight pricing model for high freight-ratio categories
-- Introduce seller performance tracking for high-delay regions
-- Strengthen warehouse/logistics in São Paulo

-- BUSINESS RULES DERIVED FROM DATA:

-- Deliveries must be completed within 20 days to maintain customer satisfaction
-- Freight cost should not exceed 75% of product price
-- Sellers from Amazonas require operational monitoring
-- Logistics focus should be highest in São Paulo due to order concentration

-- CONCLUSION :
-- This analysis revealed that customer satisfaction in the e-commerce business is primarily driven by logistics
-- efficiency rather than product factors alone. Delivery delays beyond 20 days, high freight costs relative to 
-- product price, and poor seller performance from specific regions significantly reduce review scores.
-- Additionally, with over 37% of orders concentrated in São Paulo, targeted logistics and seller optimization in 
-- key regions can create a substantial improvement in overall customer experience. Implementing data-driven service 
-- level agreements and freight optimization strategies can directly enhance customer satisfaction and operational 
-- performance.



