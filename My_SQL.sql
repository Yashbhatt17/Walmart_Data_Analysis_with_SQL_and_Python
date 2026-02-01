select * from walmart w;

drop table walmart;
--
SELECT COUNT(*) AS row_count
FROM walmart;

select distinct payment_method from walmart;

SELECT
    payment_method,
    COUNT(*) AS payment_count
FROM walmart
GROUP BY payment_method;

select count(distinct Branch)
from walmart;

select MIN(quantity) from walmart;

-- Business problem
-- Q1 find different payment method and number of transaction, number of qty sold

SELECT
    payment_method,
    COUNT(*) AS no_payment,
    sum(quantity) as no_qty_sold
FROM walmart
GROUP BY payment_method;

-- Identify the highest-rated category in each branch, displaying the branch, category
-- AVG Rating

SELECT ranked.*
FROM (
    SELECT
        agg.branch,
        agg.category,
        agg.avg_rating,
        RANK() OVER (PARTITION BY agg.branch ORDER BY agg.avg_rating DESC) AS rating_rank
    FROM (
        SELECT
            branch,
            category,
            AVG(rating) AS avg_rating
        FROM walmart
        GROUP BY branch, category
    ) AS agg
) AS ranked
WHERE ranked.rating_rank = 1
ORDER BY ranked.branch, ranked.avg_rating DESC;

-- Q3 Identify the busiest day for each branch based on the number of transactons
SELECT ranked.*
FROM (
    SELECT
        branch,
        day_name,
        no_transactions,
        RANK() OVER (PARTITION BY branch ORDER BY no_transactions DESC) AS day_rank
    FROM (
        SELECT
            branch,
            DAYNAME(STR_TO_DATE(`date`, '%d/%m/%y')) AS day_name,
            COUNT(*) AS no_transactions
        FROM walmart
        GROUP BY branch, day_name
    ) AS agg
) AS ranked
WHERE ranked.day_rank = 1
ORDER BY ranked.branch, ranked.no_transactions DESC;

-- Q4: Calculate the total quantity of items sold per payment method
select payment_method,
sum(quantity) as no_qty_sold
from walmart 
group by payment_method;
     
-- Q5: Determine the average, minimum, and maximum rating of categories for each city
select city,
category,
min(rating) as min_rating,
max(rating) as max_rating,
avg(rating) as avg_rating
from walmart 
group by city, category;

-- Q6: Calculate the total profit for each category
select category,
sum(unit_price * quantity * profit_margin) as total_profit
from walmart 
group by category
order by total_profit desc;

-- Q7 Determine the most common payment method for each branch
WITH cte AS (
  SELECT
      branch,
      payment_method,
      COUNT(*) AS total_trans,
      RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS `rank`
  FROM walmart
  GROUP BY branch, payment_method
)
SELECT branch, payment_method AS preferred_payment_method
FROM cte
WHERE `rank` = 1;

-- Q8 Categories sales into morning, afternoon, and evening shifts
select branch,
case 
	when Hour(Time(time)) < 12 then 'Morning'
    when hour(Time(time)) between 12 and 17 then 'Afternoon'
    else 'everything'
end as shift,
count(*) as num_invoices
from walmart
group by branch, shift
order by branch, num_invoices desc;

-- Q9: Identify the 5 branches with the highest revenue decrease ratio from last year to current year (e.g., 2022 to 2023)
WITH revenue_2022 AS (
    SELECT 
        branch,
        SUM(`total`) AS revenue
    FROM walmart
    WHERE YEAR(STR_TO_DATE(`date`, '%d/%m/%Y')) = 2022
    GROUP BY branch
),
revenue_2023 AS (
    SELECT 
        branch,
        SUM(`total`) AS revenue
    FROM walmart
    WHERE YEAR(STR_TO_DATE(`date`, '%d/%m/%Y')) = 2023
    GROUP BY branch
)
SELECT 
    r2022.branch,
    r2022.revenue AS last_year_revenue,
    r2023.revenue AS current_year_revenue,
    ROUND(((r2022.revenue - r2023.revenue) / r2022.revenue) * 100, 2) AS revenue_decrease_ratio
FROM revenue_2022 r2022
JOIN revenue_2023 r2023 
  ON r2022.branch = r2023.branch
WHERE r2022.revenue > r2023.revenue
ORDER BY revenue_decrease_ratio DESC
LIMIT 5;
