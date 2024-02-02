USE test    
SELECT *
from EachOrderBreakdown$

---Data Cleaning
---1. Establish the relationship between the tables as per the ER diagram.
ALTER Table OrdersList$
ADD CONSTRAINT pk_orderid PRIMARY key (ORDERID)

ALTER Table OrdersList$
ALTER COLUMN ORDERID nvarchar(255) not NULL

ALTER Table EachOrderBreakdown$
ALTER COLUMN ORDERID nvarchar(255) not NULL

ALTER Table EachOrderBreakdown$
ADD CONSTRAINT fk_orderid FOREIGN key (OrderID) REFERENCES OrdersList$(ORDERID)

--2. Split City State Country into 3 individual columns namely ‘City’, ‘State’, ‘Country’
ALTER table OrdersList$
ADD city NVARCHAR(255),
    State NVARCHAR(255),
    Country NVARCHAR(255)

UPDATE OrdersList$
set city = parsename (REPLACE([City State Country],',','.'),3),
    State = parsename (REPLACE([City State Country],',','.'),2),
    Country = parsename (REPLACE([City State Country],',','.'),1) ;
--drop column
ALTER TABLE OrdersList$
DROP column [City State Country];

--3. Add a new Category Column using the following mapping as per the first 3 characters in the 
--Product Name Column: 
--a. TECH- Technology
--b. OFS – Office Supplies
--c. FUR - Furniture
SELECT *
from EachOrderBreakdown$

ALTER TABLE EachOrderBreakdown$
ADD Category NVARCHAR(255)

UPDATE EachOrderBreakdown$
set Category= Case when LEFT(ProductName,3)= 'TECH' then 'Technology'
                   when LEFT(ProductName,3)= 'OFS' then  'Offece_Supplies'
                   when LEFT(ProductName,3)= 'FUR' then 'Furniture'
              end
--Q4. Delete the first 4 characters from the ProductName Column.
UPDATE EachOrderBreakdown$
set ProductName= SUBSTRING(ProductName,5,Len(ProductName)-4) 

--Q5. Remove duplicate rows from EachOrderBreakdown table, if all column values are matching
with cte as
(SELECT *,
      ROW_NUMBER()over(PARTITION by OrderID,ProductName,
      Discount,Sales,profit,Quantity,SubCategory,Category order by OrderID   ) r
From EachOrderBreakdown$)
DELETE from cte 
WHERE r>1

--6. Replace blank with NA in OrderPriority Column in OrdersList table

SELECT * FROM OrdersList$

UPDATE OrdersList$
set OrderPriority = case when OrderPriority = '' then 'N/A'
                    end;

                    --or
UPDATE OrdersList$
set OrderPriority = 'N/A'
where OrderPriority =' '


                               --Data Exploration
--Beginner

--1. List the top 10 orders with the highest sales from the EachOrderBreakdown table.
SELECT top 10 ProductName, MAX(Sales) [highest sales]
FROM EachOrderBreakdown$
GROUP BY ProductName 
order by MAX(Sales) DESC

SELECT TOP 10 *
FROM EachOrderBreakdown$
Order BY Sales DESC

--2. Show the number of orders for each product category in the EachOrderBreakdown table.
SELECT Category ,
       count(*) [number of orders]
from EachOrderBreakdown$
group by Category

--3. Find the total profit for each sub-category in the EachOrderBreakdown table.
select SubCategory, sum(Profit) [total profit]
from EachOrderBreakdown$
GROUP by SubCategory

--Intermediate

--1. Identify the customer with the highest total sales across all orders.
SELECT top 1 o.OrderID, o.CustomerName, sum(e.Sales) [total sales]
from OrdersList$ as o
JOIN EachOrderBreakdown$ as  e
     on o.OrderID=e.OrderID
GROUP by o.OrderID,o.CustomerName
ORDER by 3 DESC


--2. Find the month with the highest average sales in the OrdersList table.
select top 1 DATEPART(MM,o.ShipDate) month, 
       AVG(e.Sales) [average sales]
from OrdersList$ o
join EachOrderBreakdown$ e
    on o.OrderID=e.OrderID
GROUP by DATEPART(MM,o.ShipDate)
order by 2
--3. Find out the average quantity ordered by customers whose first name
 --starts with an alphabet 's'?
SELECT o.CustomerName ,
      AVG(e.Quantity) [Average Quantity]
from OrdersList$ o
join EachOrderBreakdown$ e
     on o.OrderID=e.OrderID
where o.CustomerName like 's%'
GROUP by o.CustomerName


--Advanced
--1. Find out how many new customers were acquired in the year 2014?

SELECT COUNT(*) AS NumOfCustomers
FROM (
    SELECT CustomerName, min(OrderDate) AS LatestOrderDate
    FROM OrdersList$
    GROUP BY CustomerName
    HAVING YEAR(MIN(OrderDate)) = '2014') sub



--2. Calculate the percentage of total profit contributed by each sub-category to the overall profit.

SELECT SubCategory, 
       SUM(Profit) / (SELECT SUM(Profit) FROM EachOrderBreakdown$) * 100 AS PercentageOfTotalProfit
FROM EachOrderBreakdown$
GROUP BY SubCategory;


--3. Find the average sales per customer, 
--   considering only customers who have made more than one order.
with cte as(
SELECT CustomerName,
       count(distinct o.OrderID)[no of orders],
       AVG(Sales) [average sales]
from OrdersList$ o
join EachOrderBreakdown$ e
    on o.OrderID=e.OrderID
GROUP BY CustomerName

)
select CustomerName,
       [average sales]
from cte
WHERE [no of orders] > 1

--4. Identify the top-performing subcategory in each category based on total sales. 
--   Include the subcategory name, total sales, and a ranking of sub-category within each category
WITH cte AS (
    SELECT Category,
           SubCategory,
           SUM(sales) AS TotalSales,
           RANK() OVER(PARTITION BY Category ORDER BY SUM(sales) DESC) AS rk
    FROM EachOrderBreakdown$
    GROUP BY Category, SubCategory
) 
SELECT Category, SubCategory, TotalSales
FROM cte
WHERE rk = 1 and Category is not null;