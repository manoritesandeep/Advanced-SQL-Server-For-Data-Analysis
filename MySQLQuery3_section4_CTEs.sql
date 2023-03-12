-- Common Table Expressions (CTEs)
/*
Analyzing data step by step

USE CTEs when..
	- Need a single query output
	- Quering small to medium-sized datasets

Limitations of CTEs 
	- CTEs can only be used in the current query score, meaning they cannot be
		referenced after the final SELECT.
	- This can be a problem if you need to reuse your virtual tables multiple times
		for different purposes
	- Virtual tables cannot be reference individually, making debugging more difficult
	- Certain optimization techniques are not available to CTEs
*/

/*
Sample problem
 - Identify the top 10 sales order per month,
 - Aggregate these into a sum total, by month
 - Compare each month's total to the previous months', on the same row.
*/


-- Using subqueries
Select 
A.OrderMonth,
A.Top10Total,
PrevTop10Total = B.Top10Total
from
(
select
	OrderMonth,
	Top10Total = SUM(TotalDue)
from (
	select 
		OrderDate,
		TotalDue,
		OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1),
		OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
	from AdventureWorks2019.Sales.SalesOrderHeader
) X
where OrderRank <= 10
group by OrderMonth
)A
Left JOIN 
(
select
	OrderMonth,
	Top10Total = SUM(TotalDue)
from (
	select 
		OrderDate,
		TotalDue,
		OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1),
		OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
	from AdventureWorks2019.Sales.SalesOrderHeader
) X
where OrderRank <= 10
group by OrderMonth
) B ON A.OrderMonth = DATEADD(MONTH,1,B.OrderMonth)
order by OrderMonth

-- June 01 total = 1083392.4929, May 1 - 1193730.414 in A

-- Using CTEs

WITH sales AS
(
SELECT 
	OrderDate,
	TotalDue,
	OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1),
	OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
FROM AdventureWorks2019.Sales.SalesOrderHeader
),
Top10 AS (
	select 
		OrderMonth,
		Top10Total = SUM(TotalDue)
	from sales
	where OrderRank <= 10
	group by OrderMonth
)

select
	A.OrderMonth,
	A.Top10Total,
	PrevTop10Total = B.Top10Total
from Top10 A
	LEFT JOIN Top10 B
		ON A.OrderMonth = DATEADD(MONTH,1,B.OrderMonth)
Order by A.OrderMonth

/*
CTEs - Exercise
*/
WITH SalesOrder AS
(
select 
	OrderDate,
	TotalDue,
	OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1),
	OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
from AdventureWorks2019.Sales.SalesOrderHeader
),
SalesMinusTop10 AS
(
select 
	OrderMonth,
	TotalSales = SUM(TotalDue)
from SalesOrder
where OrderRank > 10
group by OrderMonth
),

Purchases AS
(
select 
	OrderDate,
	TotalDue,
	OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1),
	OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
from AdventureWorks2019.Purchasing.PurchaseOrderHeader
),
PurchasesMinusTop10 AS
(
select 
	OrderMonth,
	TotalPurchases = SUM(TotalDue)
from Purchases
where OrderRank >10
group by OrderMonth
)

select 
	S.OrderMonth,
	S.TotalSales,
	P.TotalPurchases
from SalesMinusTop10 S
	inner join PurchasesMinusTop10 P
		on S.OrderMonth = P.OrderMonth
order by S.OrderMonth


-- Recursive CTEs
/*
Generating series of values with recursion

Recursion: is a technique in which a programming construct, 
like a function is able to refer to itself to a number of 
problems which would otherwise require substantial amounts 
of engineering and overhead.
*/

WITH NumSeries AS
(
-- Component 1: Anchor member, seed, starting point....
select 1 as mynumber

UNION ALL

-- Component 2: recursive member
select 
	mynumber + 1
from NumSeries
-- Component 3: Termination Condition This is a logical condition we include in our recursive member that 
--		ensures it will stop executing after a certain point.
where mynumber < 1000
)
select 
	mynumber
from NumSeries
option (maxrecursion 0); -- We get limited results if we do not specify this line, about 100. 

-- Generates dates for year using recursion
WITH DateSeries AS
(
-- Component 1: Anchor member, seed, starting point....
select CAST('01-01-2021' AS DATE) as myDate

UNION ALL

-- Component 2: recursive member
select 
	DATEADD(DAY,1,myDate)
from DateSeries
-- Component 3: Termination Condition This is a logical condition we include in our recursive member that 
--		ensures it will stop executing after a certain point.
where myDate < CAST('12-31-2021' AS DATE)
)
select myDate
from DateSeries
option(maxrecursion 0); -- OR option(maxrecursion 365)

/*
Recursive CTEs - Exercises
Exercise 1: 
Use a recursive CTE to generate a list of all odd numbers between 1 and 100.
*/

WITH oddNums AS
(
select 1 as mynum

UNION ALL

select 
	mynum + 2
from oddNums
where mynum < 99
)
select mynum from oddNums;

/*
Recursive CTEs - Exercises
Exercise 2: Use a recursive CTE to generate a date series of 
		all FIRST days of the month (1/1/2021, 2/1/2021, etc.)
from 1/1/2020 to 12/1/2029.
*/

WITH DateSeries AS
(
select CAST('1-1-2020' AS DATE) as firstdate

UNION ALL

select
	DATEADD(MONTH,1,firstdate)
	-- DATEFROMPARTS(YEAR(firstdate),MONTH(firstdate),1) -- Caused a infinte loop
from DateSeries
where firstdate < CAST('12-1-2029' AS DATE)
)
select firstdate from DateSeries option(maxrecursion 0);

-- END of section... notes contd in MySQLQuery4_section5_TempTables.sql