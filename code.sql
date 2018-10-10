-- SELECT THE FIRST 100 rows from the table
SELECT *
 FROM subscriptions
 LIMIT 100;
 -- Based on the code there appears to only be two segments (87 or 30)
 
 -- SELECT THE NUMBER OF DISTINCT SEGMENTS, count the number of users in each segment
 SELECT DISTINCT segment, COUNT(*) as 'Number of customers'
 FROM subscriptions
 GROUP BY segment;
 
 
 -- How we would find the available months for churn
 SELECT MIN(subscription_start),MAX(subscription_start)
 FROM subscriptions;



 -- CREATE A temporary table for MONTHS and Utilize a cross join along with case statement to convert active subs into flag column 1 or 0
WITH months AS
(SELECT
  '2017-01-01' as first_day,
  '2017-01-31' as last_day
UNION
SELECT
  '2017-02-01' as first_day,
  '2017-02-28' as last_day
UNION
SELECT
  '2017-03-01' as first_day,
  '2017-03-31' as last_day
),
cross_join AS
(SELECT *
FROM subscriptions
CROSS JOIN months),
status AS
(SELECT id, first_day as month,
 
  -- The is total active segment
 CASE
  WHEN (subscription_start < first_day)
    AND (
      subscription_end > first_day
      OR subscription_end IS NULL
    )
 THEN 1
  ELSE 0
END as is_active,
 
  -- Here we'll create out cancelled segments
CASE
WHEN (subscription_end BETWEEN first_day AND last_day)
THEN 1
ELSE 0
END as is_canceled

FROM cross_join),
-- Lets compute our Aggregate numbers for both segments
status_aggregate AS
(SELECT
  month,
 SUM(is_active) as sum_active,
 SUM(is_canceled) as sum_canceled
FROM status
GROUP BY month)

-- Compute the Churn Rates and round the rates
SELECT month, 
ROUND(1.0*sum_canceled/sum_active,2) as 'overall churn_rate'
FROM status_aggregate;





 -- CREATE A temporary table for MONTHS
WITH months AS
(SELECT
  '2017-01-01' as first_day,
  '2017-01-31' as last_day
UNION
SELECT
  '2017-02-01' as first_day,
  '2017-02-28' as last_day
UNION
SELECT
  '2017-03-01' as first_day,
  '2017-03-31' as last_day
),
-- Now we can cross Join the Months table with the subscriptions table
cross_join AS
(SELECT *
FROM subscriptions
CROSS JOIN months),
-- Now we'll Create the temporary status table for the two customer Segments
status AS
(SELECT id, first_day as month,
 
  -- These are the total active segments
 CASE
  WHEN (subscription_start < first_day)
    AND (
      subscription_end > first_day
      OR subscription_end IS NULL
    )
 THEN 1
  ELSE 0
END as is_active,
 
  -- These are the cancelled segments
CASE
WHEN (subscription_end BETWEEN first_day AND last_day)
THEN 1
ELSE 0
END as is_canceled,
 
 -- Derive the active 87 segment
 CASE
  WHEN (subscription_start < first_day)
    AND (
      subscription_end > first_day
      OR subscription_end IS NULL
    )
 AND segment = 87
 THEN 1
  ELSE 0
END as is_active_87,

 -- Derive the cancelled 87 segment
CASE
WHEN (subscription_end BETWEEN first_day AND last_day) AND ( segment= 87) 
THEN 1
ELSE 0
END as is_canceled_87,
 
-- Derive the active 30 segments
CASE
  WHEN (subscription_start < first_day)
    AND (
      subscription_end > first_day
      OR subscription_end IS NULL
    ) 
   AND segment = 30
 THEN 1
  ELSE 0
END as is_active_30,
 
 -- And the cancelled 30 segments
CASE
WHEN (subscription_end BETWEEN first_day AND last_day) AND ( segment= 30) 
THEN 1
ELSE 0
END as is_canceled_30

FROM cross_join),

-- Now we'll generate the Aggregate numbers for both segments
status_aggregate AS
(SELECT
  month,
 SUM(is_active) as sum_active,
  SUM(is_active_30) as sum_active_30,
  SUM(is_active_87) as sum_active_87, 
 SUM(is_canceled) as sum_canceled,
  SUM(is_canceled_30) as sum_canceled_30,
  SUM(is_canceled_87) as sum_canceled_87
FROM status
GROUP BY month)

-- Compute the Churn Rates & Round 
SELECT month, 
ROUND(1.0*sum_canceled/sum_active,2) as total_churn_rate,
ROUND(1.0*sum_canceled_30/sum_active_30,2) as churn_rate_30,
ROUND(1.0*sum_canceled_87/sum_active_87,2) as churn_rate_87
FROM status_aggregate;