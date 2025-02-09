
-- ANALYZING SEASONALITY AND BUSINESS PATTERN

-- 1. Analyzing Seasonality
-- 1.1 Yearly and Monthly Breakdown

SELECT 
YEAR(website_sessions.created_at) AS year,
MONTH(website_sessions.created_at) AS month,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at < '2013-01-01'-- Assignment Date
group by 1,2;

-- 1.2 Weekly Breakdown

SELECT 
YEAR(website_sessions.created_at) AS year,
WEEK(website_sessions.created_at) AS week,
MIN(DATE(website_sessions.created_at)) AS week_start,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.created_at < '2013-01-01'-- Assignment Date
group by 1,2;


-- 2. Analyzing Business Patterns ( using subquery)


SELECT 
hr,
ROUND(AVG(CASE WHEN wkday=0 THEN sessions ELSE NULL END),1) AS avg_mon_sessions,
ROUND(AVG(CASE WHEN wkday=1 THEN sessions ELSE NULL END),1) AS avg_tue_sessions,
ROUND(AVG(CASE WHEN wkday=2 THEN sessions ELSE NULL END),1) AS avg_wed_sessions,
ROUND(AVG(CASE WHEN wkday=3 THEN sessions ELSE NULL END),1) AS avg_thu_sessions,
ROUND(AVG(CASE WHEN wkday=4 THEN sessions ELSE NULL END),1) AS avg_fri_sessions,
ROUND(AVG(CASE WHEN wkday=5 THEN sessions ELSE NULL END),1) AS avg_sat_sessions,
ROUND(AVG(CASE WHEN wkday=6 THEN sessions ELSE NULL END),1) AS avg_sun_sessions
FROM

-- Subquery starts here

(SELECT 
DATE(created_at) AS date,
WEEKDAY(created_at) AS wkday,
HOUR(created_at) AS hr,
COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
GROUP BY 1,2,3) AS daily_hourly_sessions -- Named the subquery, Subquery ends here

GROUP BY 1
ORDER BY 1















