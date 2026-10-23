Create database Supply_Chain_Dataset;
Use	Supply_Chain_Dataset;
SELECT COUNT(*) AS total_rows
FROM fact_orders;
show tables;
SELECT COUNT(*) AS total_records
FROM dim_product;
SELECT COUNT(*) AS total_records
FROM dim_supplier;
SELECT COUNT(*) AS total_records
FROM dim_warehouse;
SELECT COUNT(*) AS total_records
FROM dim_customer;
SELECT COUNT(*) AS total_records
FROM fact_orders;
SELECT COUNT(*) AS total_records
FROM fact_inventory;
DESCRIBE fact_orders;
SHOW COLUMNS FROM fact_orders;
SELECT *
FROM fact_orders
LIMIT 5;
SHOW COLUMNS FROM fact_orders LIKE '%Order%';
ALTER TABLE fact_orders rename column `ï»¿Order_ID` TO Order_ID;
show columns from fact_orders;

-- KPI 1: Total Orders
SELECT COUNT(DISTINCT Order_ID)
AS Total_Orders
FROM fact_orders;

-- KPI 2: Total Sales Revenue
select round(SUM(Revenue),2) as total_sales_revenue
From fact_orders;

-- KPI 3: Stock on hand
Select sum(Stock_On_Hand) as stock_on_hand
from fact_inventory
where Snapshot_Date=
(select max(Snapshot_Date)
from fact_inventory);

-- KPI 4: On Time Delivery
select round(100*AVG(
case
when Delivery_Status= "On-Time" 
THEN 1
else 0
END),
2) as on_time_delivery_pct
FROM fact_orders;

-- KPI 5: Fill rate
select round(100*sum(Shipped_Quantity)/
NULLIF(Sum(Order_Quantity),0),2)
as fill_rate_pct
FROM fact_orders;

-- Charts
-- Order by Region
select c.Customer_Region as region,
COUNT(DISTINCT o.Order_ID) as total_orders
FROM fact_orders as o
INNER JOIN dim_customer AS c ON o.customer_id = c.customer_id
GROUP BY c.Customer_Region
ORDER BY total_orders DESC;

ALTER TABLE dim_customer rename column 
`ï»¿Customer_ID` TO Customer_ID;

-- order by Ship Mode
select Ship_Mode,
Count(Distinct Order_ID) as total_orders
from fact_orders
group by Ship_Mode
order by total_orders desc;

-- Top 5 cities by sales
select c.customer_city as city,
Round(Sum(o.revenue),2) as Total_Sales
from fact_orders as o
join dim_customer as c on c.Customer_ID =o.Customer_ID
group by c.customer_city
order by Total_Sales desc
limit 5;

-- Average Lead Time by Ship Mode 
select Ship_mode,
round(AVG(
datediff(Actual_Delivery_Date,Order_Date)),2) as AVG_Lead_Time_Days
from fact_orders 
group by Ship_Mode
order by AVG_Lead_Time_Days desc;

-- Forecast vs Actual Demand
WITH monthly_demand AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(order_quantity) AS actual_demand
    FROM fact_orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)

SELECT *
FROM monthly_demand
ORDER BY month;
WITH monthly_demand AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(order_quantity) AS actual_demand
    FROM fact_orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)

SELECT
    month,
    actual_demand,

    ROUND(
        AVG(actual_demand) OVER (
            ORDER BY month
            ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
        ),
        2
    ) AS forecast_demand

FROM monthly_demand
ORDER BY month;

-- Reorder Ratio
select count(*) as total_inventory_records,
sum(
case
when Stock_On_Hand < Reorder_Level then 1
else 0
end
)as reorder_ratio_pct
from fact_inventory;





