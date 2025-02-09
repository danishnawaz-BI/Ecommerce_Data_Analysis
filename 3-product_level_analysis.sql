-- PRODUCT LEVEL ANALYSIS

-- 1. Product Level Sales Analysis

SELECT
year(created_at) AS year ,
MONTH (created_at) AS month,
COUNT(order_id) AS number_of_sales ,
SUM(price_usd) AS total_revenue,
SUM(price_usd-cogs_usd) AS total_margin
FROM mavenfuzzyfactory.orders
WHERE year(created_at)=2012
GROUP BY 1,2;

-- 2. Analyzing Product Launches

SELECT 
year(website_sessions.created_at) AS year ,
MONTH (website_sessions.created_at) AS month,
count(website_sessions.website_session_id) AS sessions,
count(order_id) AS orders,
count(order_id)  / count(website_sessions.website_session_id)*100 AS conv_rate_perc,
SUM(price_usd) AS total_revenue,
SUM(orders.price_usd)/ COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session,
COUNT(DISTINCT CASE WHEN primary_product_id=1 THEN order_id ELSE NULL END) AS product_1_orders,
COUNT(DISTINCT CASE WHEN primary_product_id=2 THEN order_id ELSE NULL END) AS product_2_orders
FROM mavenfuzzyfactory.website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id=orders.website_session_id
where website_sessions.created_at<'2013-04-01'-- Date of request
AND website_sessions.created_at>'2012-04-01'-- Since
GROUP BY 1,2;

-- 3. Product Level Website Pathing

-- Step 1: Find the website session ids and pageview ids when a user visits products url
-- Step 2: Find the next pageview id that occurs after visiting the products url
-- Step 3: Find the next url associated with the next pageview id in the Step 2
-- Step 4: Summarize the data and analyze pre vs post launch period

-- Step 1

CREATE TEMPORARY TABLE products_page_views
SELECT 
website_session_id,
website_pageview_id,
pageview_url,
created_at,
CASE WHEN created_at < '2013-01-06' THEN 'A. pre_product_2_launch'
WHEN created_at >= '2013-01-06' THEN 'B. post_product_2_launch'
END AS time_period
FROM mavenfuzzyfactory.website_pageviews
WHERE created_at < '2013-04-06' -- date of request
AND created_at > '2012-10-06' -- 3 months prior to the 2nd product launch
AND pageview_url = '/products';

-- Step 2

CREATE TEMPORARY TABLE sessions_w_next_pageview_id
SELECT 
products_page_views.time_period,
products_page_views.website_session_id,
MIN(website_pageviews.website_pageview_id) AS min_next_pageview_id-- The very 1st url visited after landing on the products page
FROM products_page_views
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id=products_page_views.website_session_id
AND website_pageviews.website_pageview_id > products_page_views.website_pageview_id
GROUP BY 1,2;

-- Step 3

CREATE TEMPORARY TABLE sessions_with_next_pageview_url
SELECT 
sessions_w_next_pageview_id.time_period,
sessions_w_next_pageview_id.website_session_id,
website_pageviews.pageview_url AS next_pageview_url
FROM sessions_w_next_pageview_id
LEFT JOIN website_pageviews
ON website_pageviews.website_pageview_id=sessions_w_next_pageview_id.min_next_pageview_id;

-- Step 4

SELECT 
time_period,
COUNT(DISTINCT website_session_id) AS sessions,
COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS sessions_to_next_pg,
COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)*100 AS pct_sessions_to_next_pg,
COUNT(DISTINCT CASE WHEN next_pageview_url='/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS sessions_to_mrfuzzy,
COUNT(DISTINCT CASE WHEN next_pageview_url='/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)*100 AS pct_sessions_to_mrfuzzy,
COUNT(DISTINCT CASE WHEN next_pageview_url='/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS sessions_to_lovebear,
COUNT(DISTINCT CASE WHEN next_pageview_url='/the-forever-love-bear' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)*100 AS pct_sessions_to_lovebear
FROM sessions_with_next_pageview_url
GROUP BY 1;
  
  
-- 4. Product Conversion Funnels

-- Step 1. Select relevant pageviews and sessions 

CREATE TEMPORARY TABLE sessions_seeing_product_pages
SELECT 
website_pageview_id,
website_session_id,
pageview_url AS product_page_seen
FROM mavenfuzzyfactory.website_pageviews
WHERE created_at <'2013-04-10' -- date of assignment
AND created_at > '2013-01-06' -- product 2 launch date 
AND pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear');

-- Step 2. Finding the right pageviews_urls to build the funnel 

CREATE TEMPORARY TABLE session_product_level_made_it_flags
SELECT 
website_session_id,
CASE 
WHEN product_page_seen= '/the-original-mr-fuzzy' THEN 'mrfuzzy'
WHEN product_page_seen= '/the-forever-love-bear' THEN 'lovebear'
END AS product_seen,
MAX(cart_page) AS cart_made_it,
MAX(shipping_page) AS shipping_made_it,
MAX(billing_page) AS billing_made_it,
MAX(thank_you_page) AS thankyou_made_it 
FROM (
SELECT 
sessions_seeing_product_pages.website_session_id,
sessions_seeing_product_pages.product_page_seen,
CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thank_you_page
FROM sessions_seeing_product_pages
LEFT JOIN website_pageviews
ON  website_pageviews.website_session_id=sessions_seeing_product_pages.website_session_id
AND
website_pageviews.website_pageview_id>sessions_seeing_product_pages.website_pageview_id
ORDER BY 
sessions_seeing_product_pages.website_session_id,
website_pageviews.created_at) AS pageview_level
GROUP BY website_session_id,
CASE 
WHEN product_page_seen= '/the-original-mr-fuzzy' THEN 'mrfuzzy'
WHEN product_page_seen= '/the-forever-love-bear' THEN 'lovebear'
END;


-- Step 3. final output part 1

SELECT 
product_seen,
COUNT(DISTINCT website_session_id ) AS sessions ,
COUNT(DISTINCT CASE WHEN cart_made_it= 1 THEN website_session_id ELSE NULL END) AS to_cart,
COUNT(DISTINCT CASE WHEN shipping_made_it= 1 THEN website_session_id ELSE NULL END) AS to_shipping,
COUNT(DISTINCT CASE WHEN billing_made_it= 1 THEN website_session_id ELSE NULL END) AS to_billing,
COUNT(DISTINCT CASE WHEN thankyou_made_it= 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_product_level_made_it_flags
GROUP BY product_seen;

-- Step 4.  final output part 2-click rates


SELECT 
product_seen,
COUNT(DISTINCT website_session_id ) AS sessions ,
COUNT(DISTINCT CASE WHEN cart_made_it= 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id )*100 AS product_page_click_rate,
COUNT(DISTINCT CASE WHEN shipping_made_it= 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN cart_made_it= 1 THEN website_session_id ELSE NULL END)*100 AS cart_click_rate,
COUNT(DISTINCT CASE WHEN billing_made_it= 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping_made_it= 1 THEN website_session_id ELSE NULL END)*100 AS shipping_click_rate,
COUNT(DISTINCT CASE WHEN thankyou_made_it= 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing_made_it= 1 THEN website_session_id ELSE NULL END)*100 AS billing_click_rate
FROM session_product_level_made_it_flags
GROUP BY product_seen;



-- 5. Cross Sell Analysis

-- Step 1 Identifying the relevant cart page views and their sessions

CREATE TEMPORARY TABLE sessions_seeing_cart
SELECT
CASE WHEN created_at < '2013-09-25' THEN 'A. Pre_Cross_Sell'
WHEN created_at >= '2013-09-25' THEN 'B. Post_Cross_Sell'
END AS time_period,
website_session_id AS cart_session_id,
website_pageview_id AS cart_pageview_id
FROM website_pageviews
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
AND pageview_url='/cart';

-- Step 2 Identifying the sessions who visited another page after the cart page 

CREATE TEMPORARY TABLE cart_sessions_seeing_another_page
SELECT
    sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    MIN(website_pageviews.website_pageview_id) AS pageview_id_after_cart -- the right next pageview after the cart page
FROM sessions_seeing_cart
LEFT JOIN website_pageviews
    ON website_pageviews.website_session_id = sessions_seeing_cart.cart_session_id
    AND website_pageviews.website_pageview_id > sessions_seeing_cart.cart_pageview_id -- only grabbing pageviews that happened after cart page
GROUP BY
    sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id
HAVING
    MIN(website_pageviews.website_pageview_id) IS NOT NULL; -- some people who abandoned on the cart page will show NULL values
    
-- Step 3

CREATE TEMPORARY TABLE pre_post_sessions_orders
SELECT
    time_period,
    cart_session_id,
    order_id,
    items_purchased,
    price_usd
FROM sessions_seeing_cart
INNER JOIN orders -- INNER join is used to keep the only sessions for which an order has been placed
    ON sessions_seeing_cart.cart_session_id = orders.website_session_id
;

-- Step 4

-- first, we'll look at this select statement
-- then we'll turn it into a subquery

SELECT
    sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    CASE WHEN cart_sessions_seeing_another_page.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
    CASE WHEN pre_post_sessions_orders.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
    pre_post_sessions_orders.items_purchased,
    pre_post_sessions_orders.price_usd
FROM sessions_seeing_cart
LEFT JOIN cart_sessions_seeing_another_page
    ON sessions_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
LEFT JOIN pre_post_sessions_orders
    ON sessions_seeing_cart.cart_session_id = pre_post_sessions_orders.cart_session_id
ORDER BY
    cart_session_id;


-- Step 5.  turning into a subquery with final results

SELECT
    time_period,
    COUNT(DISTINCT cart_session_id) AS cart_sessions,
    SUM(clicked_to_another_page) AS clickthroughs,
    SUM(clicked_to_another_page)/COUNT(DISTINCT cart_session_id)*100 AS '%cart_ctr',
    SUM(placed_order) AS orders_placed,
    SUM(items_purchased) AS products_purchased,
    SUM(items_purchased)/SUM(placed_order) AS products_per_order,
    SUM(price_usd) AS revenue,
    SUM(price_usd)/SUM(placed_order) AS aov,
    SUM(price_usd)/COUNT(DISTINCT cart_session_id) AS rev_per_cart_session
FROM (
    SELECT
        sessions_seeing_cart.time_period,
        sessions_seeing_cart.cart_session_id,
        CASE WHEN cart_sessions_seeing_another_page.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
        CASE WHEN pre_post_sessions_orders.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
        pre_post_sessions_orders.items_purchased,
        pre_post_sessions_orders.price_usd
    FROM
        sessions_seeing_cart
    LEFT JOIN cart_sessions_seeing_another_page
        ON sessions_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
    LEFT JOIN pre_post_sessions_orders
        ON sessions_seeing_cart.cart_session_id = pre_post_sessions_orders.cart_session_id
    ORDER BY
        cart_session_id
) AS full_data
GROUP BY time_period;



-- 6. Portfolio Expansion Analysis ( Launch of 3rd Product)


SELECT
CASE
    WHEN website_sessions.created_at < '2013-12-12' THEN 'A. Pre_Birthday_Bear'
    WHEN website_sessions.created_at >= '2013-12-12' THEN 'B. Post_Birthday_Bear'
    ELSE 'uh oh...check logic'
END AS time_period,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id)*100 AS '% conv_rate',
SUM(orders.price_usd) AS total_revenue,
SUM(orders.items_purchased) AS total_products_sold,
SUM(orders.price_usd)/COUNT(DISTINCT orders.order_id) AS average_order_value,
SUM(orders.items_purchased)/COUNT(DISTINCT orders.order_id) AS products_per_order,
SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session

FROM website_sessions
LEFT JOIN orders
    ON orders.website_session_id = website_sessions.website_session_id

WHERE website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1;


-- 7. Product Refund Rate Analysis

SELECT
    YEAR(order_items.created_at) AS yr,
    MONTH(order_items.created_at) AS mo,
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_item_id ELSE NULL END) AS p1_orders,
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_item_refunds.order_item_id ELSE NULL END)
    /COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_item_id ELSE NULL END)*100 AS p1_refund_rt,
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_item_id ELSE NULL END) AS p2_orders,
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_item_refunds.order_item_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_item_id ELSE NULL END)*100 AS p2_refund_rt,
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_item_id ELSE NULL END) AS p3_orders,
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_item_refunds.order_item_id ELSE NULL END)/
     COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_item_id ELSE NULL END)*100 AS p3_refund_rt,
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_item_id ELSE NULL END) AS p4_orders,
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_item_refunds.order_item_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_item_id ELSE NULL END)*100 AS p4_refund_rt
FROM order_items
LEFT JOIN order_item_refunds
    ON order_items.order_item_id = order_item_refunds.order_item_id
WHERE order_items.created_at < '2014-10-15'
GROUP BY 1,2;



