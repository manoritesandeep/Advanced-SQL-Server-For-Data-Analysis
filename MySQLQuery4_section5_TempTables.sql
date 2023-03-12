-- Temporary Tables
/*
A more flexible alternative to CTEs are temporary tables

When to use TEMP tables
	- When need to reference one of the virtual tables in multiple outputs
	- When need to join massive datasets in virtual tables
	- When need a 'script' instead of a query i.e. bundle of SQL queries
*/

SELECT 
	OrderDate,
	TotalDue,
	OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1),
	OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
INTO #sales
FROM AdventureWorks2019.Sales.SalesOrderHeader

select * from #sales

select 
		OrderMonth,
		Top10Total = SUM(TotalDue)
INTO #Top10
from #sales
where OrderRank <= 10
group by OrderMonth

select * from #Top10

select
	A.OrderMonth,
	A.Top10Total,
	PrevTop10Total = B.Top10Total
from #Top10 A
	LEFT JOIN #Top10 B
		ON A.OrderMonth = DATEADD(MONTH,1,B.OrderMonth)
Order by A.OrderMonth

-- DROP TABLE #sales

/*
Temp Tables - Exercises
Exercise
*/
select 
	OrderDate,
	TotalDue,
	OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1),
	OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
INTO #SalesOrder
from AdventureWorks2019.Sales.SalesOrderHeader

select 
	OrderMonth,
	TotalSales = SUM(TotalDue)
INTO #SalesMinusTop10
from #SalesOrder
where OrderRank > 10
group by OrderMonth

select 
	OrderDate,
	TotalDue,
	OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1),
	OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
INTO #Purchases
from AdventureWorks2019.Purchasing.PurchaseOrderHeader

select 
	OrderMonth,
	TotalPurchases = SUM(TotalDue)
INTO #PurchasesMinusTop10
from #Purchases
where OrderRank >10
group by OrderMonth

select 
	S.OrderMonth,
	S.TotalSales,
	P.TotalPurchases
from #SalesMinusTop10 S
	inner join #PurchasesMinusTop10 P
		on S.OrderMonth = P.OrderMonth
order by S.OrderMonth

DROP TABLE #sales

-- CREATE and INSERT
CREATE TABLE #sales
(
	OrderDate DATETIME,
	TotalDue MONEY,
	OrderMonth DATE,
	OrderRank INT
)

INSERT INTO #sales
(
	OrderDate,
	TotalDue,
	OrderMonth,
	OrderRank
)

SELECT 
	OrderDate,
	TotalDue,
	OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1),
	OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
FROM AdventureWorks2019.Sales.SalesOrderHeader

select * from #sales

DROP TABLE #Top10

CREATE TABLE #Top10
(
	OrderMonth DATE,
	Top10Total INT
)

INSERT INTO #Top10

select 
		OrderMonth,
		Top10Total = SUM(TotalDue)
from #sales
where OrderRank <= 10
group by OrderMonth

select * from #Top10

select
	A.OrderMonth,
	A.Top10Total,
	PrevTop10Total = B.Top10Total
from #Top10 A
	LEFT JOIN #Top10 B
		ON A.OrderMonth = DATEADD(MONTH,1,B.OrderMonth)
Order by A.OrderMonth


-- TRUNCATE command
/* 
For clearing and reusing tables
Allows us to clear the data in table while keep the structure intact
*/

--Top 10 sales + purchases script

CREATE TABLE #Orders
(
       OrderDate DATE
	  ,OrderMonth DATE
      ,TotalDue MONEY
	  ,OrderRank INT
)



INSERT INTO #Orders
(
       OrderDate
	  ,OrderMonth
      ,TotalDue
	  ,OrderRank
)
SELECT 
       OrderDate
	  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
      ,TotalDue
	  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)

FROM AdventureWorks2019.Sales.SalesOrderHeader



CREATE TABLE #Top10Orders
(
OrderMonth DATE,
OrderType VARCHAR(32),
Top10Total MONEY
)


INSERT INTO #Top10Orders
(
OrderMonth,
OrderType,
Top10Total
)
SELECT
OrderMonth,
OrderType = 'Sales',
Top10Total = SUM(TotalDue)

FROM #Orders
WHERE OrderRank <= 10
GROUP BY OrderMonth


/*Fun part begins here*/

TRUNCATE TABLE #Orders

INSERT INTO #Orders
(
       OrderDate
	  ,OrderMonth
      ,TotalDue
	  ,OrderRank
)
SELECT 
       OrderDate
	  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
      ,TotalDue
	  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)

FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader


INSERT INTO #Top10Orders
(
OrderMonth,
OrderType,
Top10Total
)
SELECT
OrderMonth,
OrderType = 'Purchase',
Top10Total = SUM(TotalDue)

FROM #Orders
WHERE OrderRank <= 10
GROUP BY OrderMonth


SELECT
A.OrderMonth,
A.OrderType,
A.Top10Total,
PrevTop10Total = B.Top10Total

FROM #Top10Orders A
	LEFT JOIN #Top10Orders B
		ON A.OrderMonth = DATEADD(MONTH,1,B.OrderMonth)
			AND A.OrderType = B.OrderType

ORDER BY 3 DESC

DROP TABLE #Orders
DROP TABLE #Top10Orders

-- UPDATE
/*
For modifying tables - no SELECT required!
*/
CREATE TABLE #SalesOrders
(
 SalesOrderID INT,
 OrderDate DATE,
 TaxAmt MONEY,
 Freight MONEY,
 TotalDue MONEY,
 TaxFreightPercent FLOAT,
 TaxFreightBucket VARCHAR(32),
 OrderAmtBucket VARCHAR(32),
 OrderCategory VARCHAR(32),
 OrderSubcategory VARCHAR(32)
)

INSERT INTO #SalesOrders
(
 SalesOrderID,
 OrderDate,
 TaxAmt,
 Freight,
 TotalDue,
 OrderCategory
)

SELECT
 SalesOrderID,
 OrderDate,
 TaxAmt,
 Freight,
 TotalDue,
 OrderCategory = 'Non-holiday Order'

FROM [AdventureWorks2019].[Sales].[SalesOrderHeader]

WHERE YEAR(OrderDate) = 2013


UPDATE #SalesOrders
SET 
TaxFreightPercent = (TaxAmt + Freight)/TotalDue,
OrderAmtBucket = 
	CASE
		WHEN TotalDue < 100 THEN 'Small'
		WHEN TotalDue < 1000 THEN 'Medium'
		ELSE 'Large'
	END


UPDATE #SalesOrders
SET TaxFreightBucket = 
	CASE
		WHEN TaxFreightPercent < 0.1 THEN 'Small'
		WHEN TaxFreightPercent < 0.2 THEN 'Medium'
		ELSE 'Large'
	END


UPDATE #SalesOrders
SET  OrderCategory = 'Holiday'
FROM #SalesOrders
WHERE DATEPART(quarter,OrderDate) = 4


DROP TABLE #SalesOrders

/*
UPDATE - Exercise
Exercise
*/

CREATE TABLE #SalesOrders
(
 SalesOrderID INT,
 OrderDate DATE,
 TaxAmt MONEY,
 Freight MONEY,
 TotalDue MONEY,
 TaxFreightPercent FLOAT,
 TaxFreightBucket VARCHAR(32),
 OrderAmtBucket VARCHAR(32),
 OrderCategory VARCHAR(32),
 OrderSubcategory VARCHAR(32)
)

INSERT INTO #SalesOrders
(
 SalesOrderID,
 OrderDate,
 TaxAmt,
 Freight,
 TotalDue,
 OrderCategory
)

SELECT
 SalesOrderID,
 OrderDate,
 TaxAmt,
 Freight,
 TotalDue,
 OrderCategory = 'Non-holiday Order'

FROM [AdventureWorks2019].[Sales].[SalesOrderHeader]

WHERE YEAR(OrderDate) = 2013


UPDATE #SalesOrders
SET 
TaxFreightPercent = (TaxAmt + Freight)/TotalDue,
OrderAmtBucket = 
	CASE
		WHEN TotalDue < 100 THEN 'Small'
		WHEN TotalDue < 1000 THEN 'Medium'
		ELSE 'Large'
	END


UPDATE #SalesOrders
SET TaxFreightBucket = 
	CASE
		WHEN TaxFreightPercent < 0.1 THEN 'Small'
		WHEN TaxFreightPercent < 0.2 THEN 'Medium'
		ELSE 'Large'
	END


UPDATE #SalesOrders
SET  OrderCategory = 'Holiday'
FROM #SalesOrders
WHERE DATEPART(quarter,OrderDate) = 4

UPDATE #SalesOrders
SET OrderSubcategory = OrderCategory + ' ' + '-' + ' ' + OrderAmtBucket


select * from #SalesOrders

-- DELETE command
/*
Allows us to selectively remove rows from the dataset.
*/
--Selecting from temp table with WHERE clause

SELECT 
       OrderDate
	  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
      ,TotalDue
	  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)

INTO #Sales

FROM AdventureWorks2019.Sales.SalesOrderHeader


SELECT
*
FROM #Sales
WHERE OrderRank <= 10

DROP TABLE #Sales



--Deleting all records from temp table

SELECT 
       OrderDate
	  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
      ,TotalDue
	  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)

INTO #Sales

FROM AdventureWorks2019.Sales.SalesOrderHeader


DELETE FROM #Sales 




--Using DELETE with criteria

INSERT INTO #Sales

SELECT 
       OrderDate
	  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
      ,TotalDue
	  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)

FROM AdventureWorks2019.Sales.SalesOrderHeader


SELECT * FROM #Sales


DELETE FROM #Sales WHERE OrderRank > 10


SELECT
*
FROM #Sales


DROP TABLE #Sales

-- END of section... Notes contd in MySQLQuery5_section6_Optimization.sql