-- Programming SQL
USE AdventureWorks2019;
-- Variables
/*
- A variable is a named placeholder for a value or set of values
- A varaible only needs to be defined once, but can be reused many times.
- This allows us to consolidate complex logic into a variable, then refer to
	the variable as many times as we need without repeating the logic.
*/

-- Declaring a variable
DECLARE @MyVar INT
SET @MyVar = 11
SELECT @MyVar

-- Declaring a variable
DECLARE @MyVar1 INT = 11
SELECT @MyVar1

DECLARE @MinPrice MONEY
SET @MinPrice = 1000
select 
*
from AdventureWorks2019.Production.Product
where ListPrice >= @MinPrice

-- Using variable query Scenario
DECLARE @AvgPrice MONEY
SELECT @AvgPrice = (SELECT AVG(ListPrice) FROM AdventureWorks2019.Production.Product)

select 
ProductID,
[Name],
StandardCost,
ListPrice,
AvgListPrice = @AvgPrice ,
AvgListPriceDiff = ListPrice - @AvgPrice
from AdventureWorks2019.Production.Product
where ListPrice > @AvgPrice
order by ListPrice 

/*
Variables - Exercise 1
Exercise
*/
--Starter code:

SELECT
	   BusinessEntityID
      ,JobTitle
      ,VacationHours
	  ,MaxVacationHours = (SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee)
	  ,PercentOfMaxVacationHours = (VacationHours * 1.0) / (SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee)

FROM AdventureWorks2019.HumanResources.Employee

WHERE (VacationHours * 1.0) / (SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee) >= 0.8

-- Refactor above code
DECLARE @VacaHours FLOAT = (SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee)
SELECT
	   BusinessEntityID
      ,JobTitle
      ,VacationHours
	  ,MaxVacationHours = @VacaHours
	  ,PercentOfMaxVacationHours = VacationHours / @VacaHours

FROM AdventureWorks2019.HumanResources.Employee

WHERE VacationHours / @VacaHours > 0.8


-- Using variable query Scenario
DECLARE @Today DATE = CAST(GETDATE() AS DATE)
-- SET @Today = CAST(GETDATE() AS DATE)
-- SELECT @Today

-- Get value of 1st day of the month based on @Today variable - BOM - Beginning of Month
DECLARE @BOM DATE = DATEFROMPARTS(YEAR(@Today),MONTH(@Today),1)
-- SELECT @BOM

-- get first day of the previous month
DECLARE @PrevBOM DATE = DATEADD(MONTH,-1,@BOM)
-- SELECT @PrevBOM

-- get previous EOM - End of Month
DECLARE @PrevEOM DATE = DATEADD(DAY,-1,@BOM)
-- SELECT @PrevEOM

-- SELECT DATEADD(MONTH,-1,DATEFROMPARTS(YEAR(CAST(GETDATE() AS DATE)),MONTH(CAST(GETDATE() AS DATE)),1))

SELECT 
*
FROM AdventureWorks2019.dbo.Calender
where DateValue BETWEEN @PrevBOM AND  @PrevEOM

/*
Variables - Exercise 2
Exercise:
Let's say your company pays once per month, on the 15th.
If it's already the 15th of the current month (or later), 
the previous pay period will run from the 15th of the previous month, 
to the 14th of the current month.

If on the other hand it's not yet the 15th of the current month, 
the previous pay period will run from the
15th two months ago to the 14th on the previous month.
*/


DECLARE @Today2 DATE = CAST(GETDATE() AS DATE)
SELECT @Today2 AS Today

DECLARE @Current14 DATE = DATEFROMPARTS(YEAR(@Today2),MONTH(@Today2),14)
SELECT @Current14 AS Current14

DECLARE @PayPeriodEnd DATE =
	CASE
		WHEN DAY(@Today2) < 15 THEN DATEADD(MONTH,-1,@Current14)
		ELSE @Current14
	END

DECLARE @PayPeriodStart DATE = DATEADD(DAY,1,DATEADD(MONTH,-1,@PayPeriodEnd))

SELECT @PayPeriodStart AS PayPeriodStart
SELECT @PayPeriodEnd AS PayPeriodEnd


-- User Defined Functions
/*
When built-in functions just aren't enough
*/

-- SELECT GETDATE() -- 2023-03-07 17:30:05.550
USE AdventureWorks2019;

GO
CREATE FUNCTION dbo.ufnCurrentDate()

RETURNS DATE

AS

-- Logic lies within BEGIN and END
BEGIN
	RETURN CAST(GETDATE() AS DATE)
END
GO

SELECT 
	SalesOrderID,
	OrderDate,
	DueDate,
	ShipDate,
	[Today] = dbo.ufnCurrentDate()
FROM AdventureWorks2019.Sales.SalesOrderHeader A
WHERE YEAR(A.OrderDate) = 2011

/*
We actually need to subtract 1 from the output of the current calculation, 
since our elapsed business days should be 0 if our start and end dates are the same, 
and not 1 as the current logic would return.
*/

-- 63. Making Functions Flexible With Parameters
SELECT 
	SalesOrderID,
	OrderDate,
	DueDate,
	ShipDate,
	ElapserBusinessDays = (
		SELECT
		COUNT(*)
		FROM AdventureWorks2019.dbo.Calender B
		WHERE B.DateValue BETWEEN A.OrderDate AND A.ShipDate
			AND B.WeekendFlag = 0
			AND B.HolidayFlag = 0)-1
FROM AdventureWorks2019.Sales.SalesOrderHeader A
WHERE YEAR(A.OrderDate) = 2011

/* TRICK: create function must be the only statement in the batch ERROR pops up

The function needs to be either the only function in the query window OR 
the only statement in the batch.
If there are more statements in the query window, 
you can make it the only one "in the batch" by surrounding it with GO's.
*/

GO
CREATE FUNCTION dbo.ufnElapsedBusinessDays(@StartDate DATE, @EndDate DATE)

RETURNS INT

AS

BEGIN

RETURN(
	(SELECT 
		COUNT(*)
	FROM AdventureWorks2019.dbo.Calender
	WHERE DateValue BETWEEN @StartDate AND @EndDate
		AND WeekendFlag = 0
		AND HolidayFlag = 0
	)-1)
END
GO

-- DROP FUNCTION dbo.ufnElapsedBusinessDays;

SELECT 
	SalesOrderID,
	DueDate,
	OrderDate,
	ShipDate,
	ElapserBusinessDays = dbo.ufnElapsedBusinessDays(A.OrderDate,A.ShipDate)
FROM AdventureWorks2019.Sales.SalesOrderHeader A
WHERE YEAR(A.OrderDate) = 2011

/*
User Defined Functions - Exercises
Exercise 1

Hints: 
	- Remember that you can implicitly convert an integer to a decimal by multiplying it by 1.0.
	- You can format a decimal (say, 0.1) as a percent (10%) with the following code: FORMAT(0.1, 'P').
*/

-- DECLARE @num1 INT = 8
-- DECLARE @num2 INT = 10
-- SELECT format(ROUND(@num1*1.0/@num2,2),'P')

USE AdventureWorks2019
GO
CREATE FUNCTION dbo.ufnIntegerPercent(@numerator INT, @denominator INT)

RETURNS VARCHAR(50)

AS

BEGIN
	DECLARE @Decimal FLOAT= (@numerator *1.0)/@denominator
	RETURN format(@Decimal, 'P')
END
GO

-- drop function dbo.ufnIntegerPercent;
-- Test the function
SELECT test = dbo.ufnIntegerPercent(8,10)


/*
User Defined Functions - Exercises
Exercise 2: Use above defined function to create new column PercentOfMaxVacation
*/

DECLARE @MaxVacation INT = (SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee)
-- SELECT @MaxVacation

Select
	BusinessEntityID,
	JobTitle,
	VacationHours,
	[PercentOfMaxVacation] = dbo.ufnIntegerPercent(VacationHours,@MaxVacation)
from AdventureWorks2019.HumanResources.Employee


-- Stored Procedures
/*
Reusable SQL scripts, available on demand

Stored procedures are database objects that provide almost unlimited flexibility in allowing us to execute
single or multiple blocks of code, that do anything from manipulating tables in our database to returning
the output of whole select queries or both at their most basic stored procedures, essentially allow
us to save queries to our database server and then execute them on demand by invoking the stored procedure.
*/

-- Basic example
GO
CREATE PROCEDURE dbo.OrdersReport
AS

BEGIN 
	SELECT
	*
	FROM (
		select 
			B.Name As ProductName,
			LineTotalSum = SUM(A.LineTotal),
			LineTotalSumRank = DENSE_RANK() OVER(ORDER BY SUM(A.LineTotal) DESC)
		from AdventureWorks2019.Sales.SalesOrderDetail A
			INNER JOIN AdventureWorks2019.Production.Product B
				ON A.ProductID = B.ProductID
		group by B.Name
	) X
	WHERE LineTotalSumRank <= 10
END
GO

-- Executing a Store Procedure
EXEC dbo.OrdersReport

-- Making the stored procedure a Paramerized store procedure
GO
ALTER PROCEDURE dbo.OrdersReport (@TopN INT)
AS

BEGIN 
	SELECT
	*
	FROM (
		select 
			B.Name As ProductName,
			LineTotalSum = SUM(A.LineTotal),
			LineTotalSumRank = DENSE_RANK() OVER(ORDER BY SUM(A.LineTotal) DESC)
		from AdventureWorks2019.Sales.SalesOrderDetail A
			INNER JOIN AdventureWorks2019.Production.Product B
				ON A.ProductID = B.ProductID
		group by B.Name
	) X
	WHERE LineTotalSumRank <= @TopN
END
GO

EXEC dbo.OrdersReport 20
EXEC dbo.OrdersReport 5


/*
Stored Procedures - Exercise
Exercise
*/
USE AdventureWorks2019;
GO
CREATE PROCEDURE dbo.OrdersAboveThreshold (@Threshold MONEY,@StartYear INT, @EndYear INT)
AS

BEGIN 
	SELECT 
		A.SalesOrderID,
		A.OrderDate,
		A.TotalDue
	FROM AdventureWorks2019.Sales.SalesOrderHeader A
		INNER JOIN AdventureWorks2019.dbo.Calender B
			ON A.OrderDate = B.DateValue
	WHERE A.TotalDue > @Threshold
		AND B.YearNumber BETWEEN @StartYear AND @EndYear
END
GO

-- DROP PROCEDURE dbo.OrdersAboveThreshold;

EXEC dbo.OrdersAboveThreshold 20000,2011,2012 -- 696 records


-- Query returns same output as above.......
SELECT 
	SalesOrderID,
	OrderDate,
	TotalDue
FROM AdventureWorks2019.Sales.SalesOrderHeader 
WHERE YEAR(OrderDate) BETWEEN 2011 AND 2012
	AND TotalDue > 20000


-- Control Flow with IF statements
/*
If statements allow us to introduce what's called control flow to our skill scripts, functions and
stored procedures.
*/

-- Sample example
DECLARE @MyInput INT
-- SET @MyInput = 1
SET @MyInput = 6

IF @MyInput >1
	BEGIN
		SELECT 'Hello World!'
	END

ELSE 
	BEGIN
		SELECT 'Farwell'
	END



-- Applying IF to stored procedures
GO
ALTER PROCEDURE dbo.OrdersReport (@TopN INT, @OrderType INT)
AS

BEGIN 
	IF @OrderType = 1
		BEGIN
			SELECT
			*
			FROM (
				select 
					B.Name As ProductName,
					LineTotalSum = SUM(A.LineTotal),
					LineTotalSumRank = DENSE_RANK() OVER(ORDER BY SUM(A.LineTotal) DESC)
				from AdventureWorks2019.Sales.SalesOrderDetail A
					INNER JOIN AdventureWorks2019.Production.Product B
						ON A.ProductID = B.ProductID
				group by B.Name
			) X
			WHERE LineTotalSumRank <= @TopN
		END
	ELSE
		BEGIN
			SELECT
			*
			FROM (
				select 
					B.Name As ProductName,
					LineTotalSum = SUM(A.LineTotal),
					LineTotalSumRank = DENSE_RANK() OVER(ORDER BY SUM(A.LineTotal) DESC)
				from AdventureWorks2019.Purchasing.PurchaseOrderDetail A
					INNER JOIN AdventureWorks2019.Production.Product B
						ON A.ProductID = B.ProductID
				group by B.Name
			) X
			WHERE LineTotalSumRank <= @TopN
		END	
END
GO

EXEC dbo.OrdersReport 5,1
EXEC dbo.OrdersReport 5,2

/*
Control Flow With IF Statements - Exercise
Exercise
*/
GO
ALTER PROCEDURE dbo.OrdersAboveThreshold (@Threshold MONEY,@StartYear INT, @EndYear INT, @OrderType INT)
AS

BEGIN 
	IF @OrderType = 1
		BEGIN
			SELECT 
				A.SalesOrderID,
				A.OrderDate,
				A.TotalDue
			FROM AdventureWorks2019.Sales.SalesOrderHeader A
				INNER JOIN AdventureWorks2019.dbo.Calender B
					ON A.OrderDate = B.DateValue
			WHERE A.TotalDue > @Threshold
				AND B.YearNumber BETWEEN @StartYear AND @EndYear
		END
	ELSE 
		BEGIN
			SELECT 
				A.PurchaseOrderID,
				A.OrderDate,
				A.TotalDue
			FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader A
				INNER JOIN AdventureWorks2019.dbo.Calender B
					ON A.OrderDate = B.DateValue
			WHERE A.TotalDue > @Threshold
				AND B.YearNumber BETWEEN @StartYear AND @EndYear
		END
END
GO

--Call modified procedure
EXEC dbo.OrdersAboveThreshold 10000, 2011, 2013, 1

EXEC dbo.OrdersAboveThreshold 10000, 2011, 2013, 2


-- Using Multiple IF Statements

		SELECT 
			ProductID,
			LineTotal
		INTO #AllOrders
		FROM AdventureWorks2019.Sales.SalesOrderDetail

		INSERT INTO #AllOrders

		SELECT 
			ProductID,
			LineTotal
		FROM AdventureWorks2019.Purchasing.PurchaseOrderDetail

		SELECT
		*
		FROM (
			select 
				B.Name As ProductName,
				LineTotalSum = SUM(A.LineTotal),
				LineTotalSumRank = DENSE_RANK() OVER(ORDER BY SUM(A.LineTotal) DESC)
			from AdventureWorks2019.Sales.SalesOrderDetail A
				INNER JOIN AdventureWorks2019.Production.Product B
					ON A.ProductID = B.ProductID
			group by B.Name
		) X
		WHERE LineTotalSumRank <= 5 --@TopN

		DROP TABLE #AllOrders



-- Applying Multiple IF to stored procedures
GO
ALTER PROCEDURE dbo.OrdersReport (@TopN INT, @OrderType INT)
AS

BEGIN 
	IF @OrderType = 1
		BEGIN
			SELECT
			*
			FROM (
				select 
					B.Name As ProductName,
					LineTotalSum = SUM(A.LineTotal),
					LineTotalSumRank = DENSE_RANK() OVER(ORDER BY SUM(A.LineTotal) DESC)
				from AdventureWorks2019.Sales.SalesOrderDetail A
					INNER JOIN AdventureWorks2019.Production.Product B
						ON A.ProductID = B.ProductID
				group by B.Name
			) X
			WHERE LineTotalSumRank <= @TopN
		END
	IF @OrderType = 2
		BEGIN
			SELECT
			*
			FROM (
				select 
					B.Name As ProductName,
					LineTotalSum = SUM(A.LineTotal),
					LineTotalSumRank = DENSE_RANK() OVER(ORDER BY SUM(A.LineTotal) DESC)
				from AdventureWorks2019.Purchasing.PurchaseOrderDetail A
					INNER JOIN AdventureWorks2019.Production.Product B
						ON A.ProductID = B.ProductID
				group by B.Name
			) X
			WHERE LineTotalSumRank <= @TopN
		END	
	IF @OrderType = 3
		BEGIN
			SELECT 
				ProductID,
				LineTotal
			INTO #AllOrders
			FROM AdventureWorks2019.Sales.SalesOrderDetail

			INSERT INTO #AllOrders

			SELECT 
				ProductID,
				LineTotal
			FROM AdventureWorks2019.Purchasing.PurchaseOrderDetail

			SELECT
			*
			FROM (
				select 
					B.Name As ProductName,
					LineTotalSum = SUM(A.LineTotal),
					LineTotalSumRank = DENSE_RANK() OVER(ORDER BY SUM(A.LineTotal) DESC)
				from #AllOrders A
					INNER JOIN AdventureWorks2019.Production.Product B
						ON A.ProductID = B.ProductID
				group by B.Name
			) X
			WHERE LineTotalSumRank <= @TopN

			DROP TABLE #AllOrders
		END
END
GO

EXEC dbo.OrdersReport 10,1
EXEC dbo.OrdersReport 10,2
EXEC dbo.OrdersReport 10,3

/*
Using Multiple IF Statements - Exercise
Exercise
*/

			SELECT 
				A.SalesOrderID,
				OrderType = 'Sales',
				A.OrderDate,
				A.TotalDue
			FROM AdventureWorks2019.Sales.SalesOrderHeader A
				INNER JOIN AdventureWorks2019.dbo.Calender B
					ON A.OrderDate = B.DateValue
			WHERE A.TotalDue > 10000
				AND B.YearNumber BETWEEN 2011 AND  2013

			UNION ALL

			SELECT 
				A.PurchaseOrderID,
				OrderType = 'Purchase',
				A.OrderDate,
				A.TotalDue
			FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader A
				INNER JOIN AdventureWorks2019.dbo.Calender B
					ON A.OrderDate = B.DateValue
			WHERE A.TotalDue > 10000
				AND B.YearNumber BETWEEN 2011 AND 2013


GO
ALTER PROCEDURE dbo.OrdersAboveThreshold (@Threshold MONEY,@StartYear INT, @EndYear INT, @OrderType INT)
AS

BEGIN 
	IF @OrderType = 1
		BEGIN
			SELECT 
				A.SalesOrderID,
				A.OrderDate,
				A.TotalDue
			FROM AdventureWorks2019.Sales.SalesOrderHeader A
				INNER JOIN AdventureWorks2019.dbo.Calender B
					ON A.OrderDate = B.DateValue
			WHERE A.TotalDue > @Threshold
				AND B.YearNumber BETWEEN @StartYear AND @EndYear
		END
	IF @OrderType = 2
		BEGIN
			SELECT 
				A.PurchaseOrderID,
				A.OrderDate,
				A.TotalDue
			FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader A
				INNER JOIN AdventureWorks2019.dbo.Calender B
					ON A.OrderDate = B.DateValue
			WHERE A.TotalDue > @Threshold
				AND B.YearNumber BETWEEN @StartYear AND @EndYear
		END
	IF @OrderType = 3
		BEGIN
			SELECT 
				OrderID = A.SalesOrderID,
				OrderType = 'Sales',
				A.OrderDate,
				A.TotalDue
			FROM AdventureWorks2019.Sales.SalesOrderHeader A
				INNER JOIN AdventureWorks2019.dbo.Calender B
					ON A.OrderDate = B.DateValue
			WHERE A.TotalDue > @Threshold
				AND B.YearNumber BETWEEN @StartYear AND @EndYear

			UNION ALL

			SELECT 
				OrderID = A.PurchaseOrderID,
				OrderType = 'Purchase',
				A.OrderDate,
				A.TotalDue
			FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader A
				INNER JOIN AdventureWorks2019.dbo.Calender B
					ON A.OrderDate = B.DateValue
			WHERE A.TotalDue > @Threshold
				AND B.YearNumber BETWEEN @StartYear AND @EndYear
		END
END
GO


EXEC dbo.OrdersAboveThreshold 10000, 2011, 2013, 1
EXEC dbo.OrdersAboveThreshold 10000, 2011, 2013, 2
EXEC dbo.OrdersAboveThreshold 10000, 2011, 2013, 3


--  Dynamic SQL
/*
Writing code... that writes code
Downside is debugging can be difficult
*/

-- Simple Example
select top 100 * from AdventureWorks2019.Production.Product

DECLARE @DynamicSQL VARCHAR(MAX) = 'select top 100 * from AdventureWorks2019.Production.Product'
-- SET @DynamicSQL = 'select top 100 * from AdventureWorks2019.Production.Product'
-- To execure Dynamic SQL code 
EXEC( @DynamicSQL)


-- Example 2
/*
Note:  the next step is to take our query and break it into string fragments sandwiched around the variable
input that users pass in.
The general idea is that we take the parts of the query that won't change based on user input, say
the fields in the select list or the tables in the from clause, and use those as a kind of template
that we will then concatenate our variable values to ultimately resulting in a sequel string that changes
based on the provided user input.
*/

SELECT 
	*
FROM (

	SELECT 
		ProductName = B.[Name],
		LineTotalSum = SUM(A.LineTotal),
		LineTotalSumRank = DENSE_RANK() OVER(ORDER BY SUM(A.LineTotal) DESC)
	FROM AdventureWorks2019.Sales.SalesOrderDetail A
		INNER JOIN AdventureWorks2019.Production.Product B
			ON A.ProductID = B.ProductID
	GROUP BY B.[Name]
	)X
	WHERE LineTotalSumRank <= 10

-- Creating DynamicSQL query for above query, Aggregate Function - AVG
DECLARE @TopN INT = 10
DECLARE @AggFunc VARCHAR(50) = 'AVG'
DECLARE @DynamicSQLquery VARCHAR(MAX)

SET @DynamicSQLquery = 'SELECT 
	*
FROM (

	SELECT 
		ProductName = B.[Name],
		LineTotalSum = '
SET @DynamicSQLquery = @DynamicSQLquery + @AggFunc

SET @DynamicSQLquery = @DynamicSQLquery + '(A.LineTotal),
		LineTotalSumRank = DENSE_RANK() OVER(ORDER BY '

SET @DynamicSQLquery = @DynamicSQLquery + @AggFunc

SET @DynamicSQLquery = @DynamicSQLquery + '(A.LineTotal) DESC)
	FROM AdventureWorks2019.Sales.SalesOrderDetail A
		INNER JOIN AdventureWorks2019.Production.Product B
			ON A.ProductID = B.ProductID
	GROUP BY B.[Name]
	)X
	WHERE LineTotalSumRank <= '
SET @DynamicSQLquery = @DynamicSQLquery + CAST(@TopN AS VARCHAR)

-- SELECT @DynamicSQLquery

EXEC(@DynamicSQLquery)

-- Creating DynamicSQL query for above query, Aggregate Function - MAX
DECLARE @TopN1 INT = 10
DECLARE @AggFunc1 VARCHAR(50) = 'MAX'
DECLARE @DynamicSQLquery1 VARCHAR(MAX)

SET @DynamicSQLquery1 = 'SELECT 
	*
FROM (

	SELECT 
		ProductName = B.[Name],
		LineTotalSum = '
SET @DynamicSQLquery1 = @DynamicSQLquery1 + @AggFunc1

SET @DynamicSQLquery1 = @DynamicSQLquery1 + '(A.LineTotal),
		LineTotalSumRank = DENSE_RANK() OVER(ORDER BY '

SET @DynamicSQLquery1 = @DynamicSQLquery1 + @AggFunc1

SET @DynamicSQLquery1 = @DynamicSQLquery1 + '(A.LineTotal) DESC)
	FROM AdventureWorks2019.Sales.SalesOrderDetail A
		INNER JOIN AdventureWorks2019.Production.Product B
			ON A.ProductID = B.ProductID
	GROUP BY B.[Name]
	)X
	WHERE LineTotalSumRank <= '
SET @DynamicSQLquery1 = @DynamicSQLquery1 + CAST(@TopN1 AS VARCHAR)

-- SELECT @DynamicSQLquery1
EXEC(@DynamicSQLquery1)

-- Wrap above code to make stored procedures
GO
CREATE PROCEDURE dbo.DynamicTopN(@TopN INT, @AggFunc VARCHAR(50))
AS

BEGIN
	DECLARE @DynamicSQLquery VARCHAR(MAX)

	SET @DynamicSQLquery = 'SELECT 
		*
	FROM (

		SELECT 
			ProductName = B.[Name],
			LineTotalSum = '
	SET @DynamicSQLquery = @DynamicSQLquery + @AggFunc

	SET @DynamicSQLquery = @DynamicSQLquery + '(A.LineTotal),
			LineTotalSumRank = DENSE_RANK() OVER(ORDER BY '

	SET @DynamicSQLquery = @DynamicSQLquery + @AggFunc

	SET @DynamicSQLquery = @DynamicSQLquery + '(A.LineTotal) DESC)
		FROM AdventureWorks2019.Sales.SalesOrderDetail A
			INNER JOIN AdventureWorks2019.Production.Product B
				ON A.ProductID = B.ProductID
		GROUP BY B.[Name]
		)X
		WHERE LineTotalSumRank <= '
	SET @DynamicSQLquery = @DynamicSQLquery + CAST(@TopN AS VARCHAR)

	EXEC(@DynamicSQLquery)
END
GO

EXEC  dbo.DynamicTopN 15,AVG
EXEC  dbo.DynamicTopN 15,MIN
EXEC  dbo.DynamicTopN 15,MAX

/*
Dynamic SQL - Exercises
Exercise 1
*/

SELECT
	*
FROM AdventureWorks2019.Person.Person
WHERE FirstName LIKE '%K%'



GO
CREATE PROCEDURE dbo.NameSearch(@NameToSearch VARCHAR(100), @SearchPattern VARCHAR(100))
AS

BEGIN
	DECLARE @DynamicSQL_NameSearch VARCHAR(MAX)
	DECLARE @NameColumn VARCHAR(100)

	IF LOWER(@NameToSearch) = 'First'
		SET @NameColumn = 'FirstName'
	IF LOWER(@NameToSearch) = 'Middle'
		SET @NameColumn = 'MiddleName'
	IF LOWER(@NameToSearch) = 'Last'
		SET @NameColumn = 'LastName'

	SET @DynamicSQL_NameSearch = 'SELECT
			*
		FROM AdventureWorks2019.Person.Person
		WHERE '

	SET @DynamicSQL_NameSearch = @DynamicSQL_NameSearch + @NameColumn
	SET @DynamicSQL_NameSearch = @DynamicSQL_NameSearch  + ' LIKE ' + '''' + '%' + @SearchPattern + '%' + ''''


	EXEC(@DynamicSQL_NameSearch)

END
GO

EXEC dbo.NameSearch First,Ken
EXEC dbo.NameSearch first,rav
EXEC dbo.NameSearch Last,B


/*
Dynamic SQL - Exercises
Exercise 2
*/

GO
ALTER PROCEDURE dbo.NameSearch(@NameToSearch VARCHAR(100), @SearchPattern VARCHAR(100), @MatchType INT)
AS

BEGIN
	DECLARE @DynamicSQL_NameSearch VARCHAR(MAX)
	DECLARE @DynamicWhere VARCHAR(MAX)
	DECLARE @NameColumn VARCHAR(100)

	IF LOWER(@NameToSearch) = 'First'
		SET @NameColumn = 'FirstName'
	IF LOWER(@NameToSearch) = 'Middle'
		SET @NameColumn = 'MiddleName'
	IF LOWER(@NameToSearch) = 'Last'
		SET @NameColumn = 'LastName'
	
	If @MatchType = 1
		SET @DynamicWhere = ' = ' + '''' + @SearchPattern + ''''
	IF @MatchType = 2
		SET @DynamicWhere = ' LIKE ' + '''' + @SearchPattern + '%' + ''''

	IF @MatchType = 3
		SET @DynamicWhere = ' LIKE ' + '''' + '%' + @SearchPattern + ''''

	IF @MatchType = 4
		SET @DynamicWhere = ' LIKE ' + '''' + '%' + @SearchPattern + '%' + ''''
		
	SET @DynamicSQL_NameSearch = 'SELECT
			*
		FROM AdventureWorks2019.Person.Person
		WHERE '

	SET @DynamicSQL_NameSearch = @DynamicSQL_NameSearch + @NameColumn + @DynamicWhere
	--SET @DynamicSQL_NameSearch = @DynamicSQL_NameSearch  + ' LIKE ' + '''' + '%' + @SearchPattern + '%' + ''''
	
	-- SELECT  @DynamicSQL_NameSearch

	EXEC(@DynamicSQL_NameSearch)

END
GO

EXEC dbo.NameSearch First,Ken,1
EXEC dbo.NameSearch first,rav,4
EXEC dbo.NameSearch Last,B,2
