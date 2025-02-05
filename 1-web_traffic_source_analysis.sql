
-- Web Traffic Source Analysis

-- 1. Finding Top Traffic Sources

SELECT utm_source,
	utm_campaign,
	http_referer,
	count(website_session_id) AS sessions
 FROM mavenfuzzyfactory.website_sessions
where created_at<'2012-04-12'-- Assignment Date
group by 1,2,3
order by sessions DESC;

-- 2.Traffic Source Conversion Rate

SELECT 
	count(website_sessions.website_session_id) AS sessions,
    count(order_id) AS orders,
    count(order_id)  / count(website_sessions.website_session_id)*100 AS conv_rate
FROM mavenfuzzyfactory.website_sessions
 LEFT JOIN orders
 ON website_sessions.website_session_id=orders.website_session_id
where website_sessions.created_at<'2012-04-14'-- Assignment Date
AND utm_source='gsearch'
AND utm_campaign='nonbrand';

-- 3. Traffic Source Trending

SELECT 
year(created_at) AS year,
week(created_at) AS week,
min(date(created_at)) AS start_of_week_date,
count(website_sessions.website_session_id) AS sessions
FROM mavenfuzzyfactory.website_sessions
where website_sessions.created_at<'2012-05-10'
AND utm_source='gsearch'
AND utm_campaign='nonbrand'
group by 1,2;

-- 4. Bid Optimization for Paid Traffic

SELECT 
	device_type,
	count(website_sessions.website_session_id) AS sessions,
    count(order_id) AS orders,
    count(order_id)  / count(website_sessions.website_session_id)*100 AS conv_rate
FROM mavenfuzzyfactory.website_sessions
 LEFT JOIN orders
 ON website_sessions.website_session_id=orders.website_session_id
where website_sessions.created_at<'2012-05-11'-- Assignment Date
AND utm_source='gsearch'
AND utm_campaign='nonbrand'
group by device_type;

-- 5. Traffic Source Segment Trending

SELECT 
-- year(created_at),
-- week(created_at),
min(date(created_at)) AS week_start_date,
count(CASE WHEN device_type ='mobile' THEN device_type ELSE NULL END) AS mob_sessions,
count(CASE WHEN device_type ='desktop' THEN device_type ELSE NULL END) AS desk_sessions,
count(website_sessions.website_session_id) AS total_sessions
FROM mavenfuzzyfactory.website_sessions
where website_sessions.created_at>'2012-04-15'
 AND website_sessions.created_at<'2012-06-09'
AND utm_source='gsearch'
AND utm_campaign='nonbrand'
group by year(created_at),
week(created_at);

