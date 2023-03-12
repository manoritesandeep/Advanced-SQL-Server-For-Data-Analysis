-- Optimization

-- Optimizing with UPDATE
/*
What slows down queries the most?
JOINs against or between very large tables

What can we do about it?
	- Define a filtered dataset as early as possible in our process,
		so we can JOIN additional tables to a smaller core population
	- Avoid several JOINs in a single SELECT query, especially those involving
		large tables
	- Instead, use UPDATE statements to populate fields in a temp table, 
		one source table at a time.
	- Apply indexes to fields that will be used in JOINs
*/

--Starter Code:

SELECT 
	   A.SalesOrderID
	  ,A.OrderDate
      ,B.ProductID
      ,B.LineTotal
	  ,C.[Name] AS ProductName
	  ,D.[Name] AS ProductSubcategory
	  ,E.[Name] AS ProductCategory


FROM AdventureWorks2019.Sales.SalesOrderHeader A
	JOIN AdventureWorks2019.Sales.SalesOrderDetail B
		ON A.SalesOrderID = B.SalesOrderID
	JOIN AdventureWorks2019.Production.Product C
		ON B.ProductID = C.ProductID
	JOIN AdventureWorks2019.Production.ProductSubcategory D
		ON C.ProductSubcategoryID = D.ProductSubcategoryID
	JOIN AdventureWorks2019.Production.ProductCategory E
		ON D.ProductCategoryID = E.ProductCategoryID

WHERE YEAR(A.OrderDate) = 2012


--Optimized script


--1.) Create filtered temp table of sales order header table WHERE year = 2012

CREATE TABLE #Sales2012 
(
SalesOrderID INT,
OrderDate DATE
)

INSERT INTO #Sales2012
(
SalesOrderID,
OrderDate
)

SELECT
SalesOrderID,
OrderDate

FROM AdventureWorks2019.Sales.SalesOrderHeader

WHERE YEAR(OrderDate) = 2012


--2.) Create new temp table after joining in SalesOrderDetail  table

CREATE TABLE #ProductsSold2012
(
SalesOrderID INT,
OrderDate DATE,
LineTotal MONEY,
ProductID INT,
ProductName VARCHAR(64),
ProductSubcategoryID INT,
ProductSubcategory VARCHAR(64),
ProductCategoryID INT,
ProductCategory VARCHAR(64)
)

INSERT INTO #ProductsSold2012
(
SalesOrderID,
OrderDate,
LineTotal,
ProductID
)

SELECT 
	   A.SalesOrderID
	  ,A.OrderDate
      ,B.LineTotal
      ,B.ProductID

FROM #Sales2012 A
	JOIN AdventureWorks2019.Sales.SalesOrderDetail B
		ON A.SalesOrderID = B.SalesOrderID

--3.) Add product data with UPDATE
/*
Consideration to be made using TEMP tables
What fields do I have to have in my temp table so that I can join 
my temp table out to some other table. 
In the case below we add in ProductSubcategoryID
*/
UPDATE A
SET
ProductName = B.[Name],
ProductSubcategoryID = B.ProductSubcategoryID	-- We bring this in to tie in other tables such ProductSubcategory in this case.

FROM #ProductsSold2012 A
	JOIN AdventureWorks2019.Production.Product B
		ON A.ProductID = B.ProductID

--4.) Add product subcategory with UPDATE

UPDATE A
SET
ProductSubcategory= B.[Name],
ProductCategoryID = B.ProductCategoryID

FROM #ProductsSold2012 A
	JOIN AdventureWorks2019.Production.ProductSubcategory B
		ON A.ProductSubcategoryID = B.ProductSubcategoryID

--5.) Add product category data with UPDATE

UPDATE A
SET
ProductCategory= B.[Name]

FROM #ProductsSold2012 A
	JOIN AdventureWorks2019.Production.ProductCategory B
		ON A.ProductCategoryID = B.ProductCategoryID


SELECT * FROM #ProductsSold2012

/*
Optimizing With UPDATE - Exercise
Exercise
*/

-- Rewrite below query using UPDATE optimization
SELECT 
	   A.BusinessEntityID
      ,A.Title
      ,A.FirstName
      ,A.MiddleName
      ,A.LastName
	  ,B.PhoneNumber
	  ,PhoneNumberType = C.Name
	  ,D.EmailAddress

FROM AdventureWorks2019.Person.Person A
	LEFT JOIN AdventureWorks2019.Person.PersonPhone B
		ON A.BusinessEntityID = B.BusinessEntityID
	LEFT JOIN AdventureWorks2019.Person.PhoneNumberType C
		ON B.PhoneNumberTypeID = C.PhoneNumberTypeID
	LEFT JOIN AdventureWorks2019.Person.EmailAddress D
		ON A.BusinessEntityID = D.BusinessEntityID


--Optimized script

-- 1. Create a temp table
CREATE TABLE #Person
(
	 BusinessEntityID INT
    ,Title VARCHAR(64)
    ,FirstName VARCHAR(50)
    ,MiddleName VARCHAR(50)
    ,LastName VARCHAR(50)
	,PhoneNumber VARCHAR(25)
	,PhoneNumberTypeID INT
	,PhoneNumberType VARCHAR(25)
	,EmailAddress VARCHAR(256)
)

INSERT INTO #Person
(
	 BusinessEntityID
    ,Title
    ,FirstName
    ,MiddleName
    ,LastName
)

SELECT 
	BusinessEntityID,
    Title,
    FirstName,
    MiddleName,
    LastName
FROM AdventureWorks2019.Person.Person

-- Add PhoneNumber
UPDATE #Person
SET 
	PhoneNumber = B.PhoneNumber,
	PhoneNumberTypeID = B.PhoneNumberTypeID
FROM #Person A
	LEFT JOIN AdventureWorks2019.Person.PersonPhone B
		ON A.BusinessEntityID = B.BusinessEntityID

-- Add PhoneNumberType
UPDATE A
SET 
	PhoneNumberType = B.Name
FROM #Person A
	LEFT JOIN AdventureWorks2019.Person.PhoneNumberType B
		ON A.PhoneNumberTypeID = B.PhoneNumberTypeID

UPDATE A
SET 
	EmailAddress = B.EmailAddress
FROM #Person A
	LEFT JOIN AdventureWorks2019.Person.EmailAddress B
		ON A.BusinessEntityID = B.BusinessEntityID

-- drop table #Person
select * from #Person ORDER BY BusinessEntityID
select distinct PhoneNumberTypeID, PhoneNumberType from #Person -- [1,2,3][Work, Cell, Home]


-- An improved EXISTS with UPDATE
/*
EXISTS strengths and weaknesses
 - EXISTS lets you check for matching records from the 'many' side of a 
	relationship, without resulting in duplicated data from the 'one' side
 - EXISTS works fine in this scenario as long as you don't need any additional
	information about the match, other than that it exists
 -However, if you need to see any data points pertaining to the match from 
	'many' side, UPDATE can be a superior alternative to EXISTS & NOT EXISTS
*/

--Select all orders with at least one item over 10K, using EXISTS

SELECT
       A.SalesOrderID
      ,A.OrderDate
      ,A.TotalDue

FROM AdventureWorks2019.Sales.SalesOrderHeader A

WHERE EXISTS (
	SELECT
	1
	FROM AdventureWorks2019.Sales.SalesOrderDetail B
	WHERE A.SalesOrderID = B.SalesOrderID
		AND B.LineTotal > 10000
)

ORDER BY 1



--5.) Select all orders with at least one item over 10K, including a line item value, using UPDATE

--Create a table with Sales data, including a field for line total:
CREATE TABLE #Sales
(
SalesOrderID INT,
OrderDate DATE,
TotalDue MONEY,
LineTotal MONEY
)


--Insert sales data to temp table
INSERT INTO #Sales
(
SalesOrderID,
OrderDate,
TotalDue
)

SELECT
SalesOrderID,
OrderDate,
TotalDue

FROM AdventureWorks2019.Sales.SalesOrderHeader


--Update temp table with > 10K line totals

UPDATE A
SET LineTotal = B.LineTotal

FROM #Sales A
	JOIN AdventureWorks2019.Sales.SalesOrderDetail B
		ON A.SalesOrderID = B.SalesOrderID
WHERE B.LineTotal > 10000

SELECT * FROM #Sales

--Recreate EXISTS:

SELECT * FROM #Sales WHERE LineTotal IS NOT NULL


--Recreate NOT EXISTS:

SELECT * FROM #Sales WHERE LineTotal IS NULL

/*
When should you use what technique?
	- If you need to see all matches from the many side of the
		relationship, use a JOIN
	- If you don't want to see all matches from the many side, AND
		don't care to see any information about those matches 
		(other than their existence), EXISTS is fine.
	- If you don't want to see all matches from the many side, but
		would like some information about a (any) match that was returned,
			use UPDATE.
*/

/*
An Improved EXISTS With UPDATE - Exercise
Exercise
*/
-- Rewrite below query with UPDATE
SELECT
       A.PurchaseOrderID,
	   A.OrderDate,
	   A.TotalDue

FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader A

WHERE EXISTS (
	SELECT
	1
	FROM AdventureWorks2019.Purchasing.PurchaseOrderDetail B
	WHERE A.PurchaseOrderID = B.PurchaseOrderID
		AND B.RejectedQty > 5
)

ORDER BY 1

-- Create table with purchase data
CREATE TABLE #Purchases
(
	PurchaseOrderID INT,
	OrderDate DATE,
	TotalDue MONEY,
	RejectedQty INT
)

INSERT INTO #Purchases
(
	PurchaseOrderID,
	OrderDate,
	TotalDue 
)
SELECT
	PurchaseOrderID,
	OrderDate,
	TotalDue 
FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader

UPDATE A
SET 
	RejectedQty = B.RejectedQty
FROM #Purchases A
	LEFT JOIN AdventureWorks2019.Purchasing.PurchaseOrderDetail B
		ON A.PurchaseOrderID = B.PurchaseOrderID


select * from #Purchases

--Recreate EXISTS:

SELECT * FROM #Purchases WHERE RejectedQty > 0 

--Recreate NOT EXISTS:

SELECT * FROM #Purchases WHERE RejectedQty < 0

-- Optimizing with INDEXES 
/*
(pdf in notes folder)
What are indexes?
o Indexes are database objects that can make queries against your
	tables faster.
o They do this by sorting the data in the fields they apply to –
	either in the table itself, or in a separate data structure.
o This sorting allows the database engine to locate records within
	a table without having to search through the table row-by-row.
o There are two types of indexes – clustered and non-clustered
*/

/*
-- Clustered Index
o The rows of a table with a clustered index are physically sorted
	based on the field or fields the index is applied to.
o A table with a primary key is given a clustered index (based on
	the primary key field) by default
o Most tables should have at least a clustered index, as queries
	against tables with a clustered index generally tend to be faster.
o A table may only have one clustered index.

-- Clustered Indexes selection 'strategies'
o Apply a clustered index to whatever field – or fields - are most
	likely to be used in a join against the table.
o Ideally this field (or combination of fields) should also be the
	one that most uniquely defines a record in the table.
o Whatever field would be a good candidate for a primary key of
	a table, is usually also a good candidate for a clustered index.
*/

/*
-- Non-Clustered Index
o A table may have many non-clustered indexes.
o Non-clustered indexes do not physically sort the data in a table
	like clustered indexes do.
o The sorted order of the field or fields non-clustered indexes
	apply to is stored in an external data structure, which works like
	a kind of phone book.

-- Non-Clustered Indexes selection 'strategies'
o If you will be joining your table on fields besides the one
	“covered” by the clustered index, consider non-clustered
	indexes on those fields.
o You can add as many non-clustered indexes as we like, but
	should be judicious in doing so.
o Fields covered by a non-clustered index should still have a high
	level of uniqueness.
*/

/*
INDEXES - General Approach
o It’s how our table utilized in joins that should drive our use and
	design of indexes.
o You should generally add a clustered index first, and then layer
	in non-clustered indexes as needed to “cover” additional fields
	used in joins against our table.
o Indexes take up memory in the database, so only add them
	when they are really needed.
o They also make inserts to tables take longer, so you should
	generally add indexes after data has been inserted to the table.
*/

CREATE TABLE #Sales2012 
(
SalesOrderID INT,
OrderDate DATE
)

INSERT INTO #Sales2012
(
SalesOrderID,
OrderDate
)

SELECT
SalesOrderID,
OrderDate

FROM AdventureWorks2019.Sales.SalesOrderHeader

WHERE YEAR(OrderDate) = 2012


--1.) Add clustered index to #Sales2012


CREATE CLUSTERED INDEX Sales2012_idx ON #Sales2012(SalesOrderID)


--2.) Add sales order detail ID

CREATE TABLE #ProductsSold2012
(
SalesOrderID INT,
SalesOrderDetailID INT, --Add for clustered index
OrderDate DATE,
LineTotal MONEY,
ProductID INT,
ProductName VARCHAR(64),
ProductSubcategoryID INT,
ProductSubcategory VARCHAR(64),
ProductCategoryID INT,
ProductCategory VARCHAR(64)
)

INSERT INTO #ProductsSold2012
(
SalesOrderID,
SalesOrderDetailID,
OrderDate,
LineTotal,
ProductID
)

SELECT 
	   A.SalesOrderID
	  ,B.SalesOrderDetailID
	  ,A.OrderDate
      ,B.LineTotal
      ,B.ProductID

FROM #Sales2012 A
	JOIN AdventureWorks2019.Sales.SalesOrderDetail B
		ON A.SalesOrderID = B.SalesOrderID


--3.) Add clustered index on SalesOrderDetailID

CREATE CLUSTERED INDEX ProductsSold2012_idx ON #ProductsSold2012(SalesOrderDetailID)


--4.) Add nonclustered index on product Id

CREATE NONCLUSTERED INDEX ProductsSold2012_idx2 ON #ProductsSold2012(ProductID)

--3.) Add product data with UPDATE

UPDATE A
SET
ProductName = B.[Name],
ProductSubcategoryID = B.ProductSubcategoryID

FROM #ProductsSold2012 A
	JOIN AdventureWorks2019.Production.Product B
		ON A.ProductID = B.ProductID


--4.) Add nonclustered index on product subcategory ID

CREATE NONCLUSTERED INDEX ProductsSold2012_idx3 ON #ProductsSold2012(ProductSubcategoryID)

UPDATE A
SET
ProductSubcategory= B.[Name],
ProductCategoryID = B.ProductCategoryID

FROM #ProductsSold2012 A
	JOIN AdventureWorks2019.Production.ProductSubcategory B
		ON A.ProductSubcategoryID = B.ProductSubcategoryID


--5) Add nonclustered index on category Id

CREATE NONCLUSTERED INDEX ProductsSold2012_idx4 ON #ProductsSold2012(ProductCategoryID)


UPDATE A
SET
ProductCategory= B.[Name]

FROM #ProductsSold2012 A
	JOIN AdventureWorks2019.Production.ProductCategory B
		ON A.ProductCategoryID = B.ProductCategoryID


SELECT * FROM #ProductsSold2012


/*
Optimizing With Indexes - Exercise
Exercise
*/

CREATE TABLE #PersonContactInfo
(
	   BusinessEntityID INT
      ,Title VARCHAR(8)
      ,FirstName VARCHAR(50)
      ,MiddleName VARCHAR(50)
      ,LastName VARCHAR(50)
	  ,PhoneNumber VARCHAR(25)
	  ,PhoneNumberTypeID VARCHAR(25)
	  ,PhoneNumberType VARCHAR(25)
	  ,EmailAddress VARCHAR(50)
)

INSERT INTO #PersonContactInfo
(
	   BusinessEntityID
      ,Title
      ,FirstName
      ,MiddleName
      ,LastName
)


SELECT
	   BusinessEntityID
      ,Title
      ,FirstName
      ,MiddleName
      ,LastName

FROM AdventureWorks2019.Person.Person


CREATE CLUSTERED INDEX person_idx ON #PersonContactInfo(BusinessEntityID)

UPDATE A
SET
	PhoneNumber = B.PhoneNumber,
	PhoneNumberTypeID = B.PhoneNumberTypeID

FROM #PersonContactInfo A
	JOIN AdventureWorks2019.Person.PersonPhone B
		ON A.BusinessEntityID = B.BusinessEntityID

CREATE NONCLUSTERED INDEX person_idx1 ON #PersonContactInfo(PhoneNumberTypeID)

UPDATE A
SET	PhoneNumberType = B.Name

FROM #PersonContactInfo A
	JOIN AdventureWorks2019.Person.PhoneNumberType B
		ON A.PhoneNumberTypeID = B.PhoneNumberTypeID

UPDATE A
SET	EmailAddress = B.EmailAddress

FROM #PersonContactInfo A
	JOIN AdventureWorks2019.Person.EmailAddress B
		ON A.BusinessEntityID = B.BusinessEntityID


SELECT * FROM #PersonContactInfo


-- LookUp Tables
/*
Make something permanent with the knowledge of temp tables... eg. calendar table

The commands used to define and manipulate temporary tables are broadly classified
into two groups 
	Data Definition Language commands(DDL) and
	Data Manipulation Commands(DML)

	DDL commands pertain to the definition and structure of our database objects, 
	so these include create, drop and truncate.

	DML commands, involve manipulating data in existing objects,
	so these include insert, update and delete.

Benefits of lookup tables
	- Eliminate duplicated effort by locating frequently used attributes
		in one place
	- Promote data integrity by consolidating a 'single version of the truth'
		in a central location
*/
-- CREATE TABLE DATABASE_NAME.SCHEMA.NAME_OF_TABLE
CREATE TABLE AdventureWorks2019.dbo.Calender
(
	DateValue DATE,
	DayOfWeekNumber INT,
	DayOfWeekName VARCHAR(32),
	DayOfMonthNumber INT,
	MonthNumber INT,
	YearNumber INT,
	WeekendFlag TINYINT,
	HolidayFlag TINYINT
)

INSERT INTO AdventureWorks2019.dbo.Calender
(
	DateValue,
	DayOfWeekNumber,
	DayOfWeekName,
	DayOfMonthNumber,
	MonthNumber,
	YearNumber,
	WeekendFlag,
	HolidayFlag
)

-- Manually inserting... not really practical
 -- VALUES 
	-- (CAST('01-01-2011' AS DATE),7,'Saturday',1,1,2011,1,1),
	-- (CAST('01-2-2011' AS DATE),1,'Sunday',1,1,2011,1,1)

-- select * from AdventureWorks2019.dbo.Calender
-- TRUNCATE TABLE AdventureWorks2019.dbo.Calender;-- clear table

-- Using recursion
WITH Dates AS
(
select 
	CAST('01-01-2011' AS DATE) AS FirstDate

UNION ALL

SELECT
	DATEADD(DAY,1,FirstDate)
FROM Dates
WHERE FirstDate < CAST('12-31-2030' AS DATE)
)
-- SELECT * FROM Dates OPTION(maxrecursion 0)
INSERT INTO AdventureWorks2019.dbo.Calender
(
DateValue
)
SELECT * 
FROM Dates 
OPTION(maxrecursion 0)

-- Populate other feilds
UPDATE AdventureWorks2019.dbo.Calender
SET
	DayOfWeekNumber = DATEPART(WEEKDAY, DateValue),
	DayOfWeekName = FORMAT(DateValue, 'dddd'),
	DayOfMonthNumber = DAY(DateValue),
	MonthNumber = MONTH(DateValue),
	YearNumber = YEAR(DateValue)


-- Populate WeekendFlag feild
UPDATE AdventureWorks2019.dbo.Calender
SET
	WeekendFlag = 
		CASE
			WHEN DayOfWeekName IN ('Saturday','Sunday') THEN 1
			ELSE 0
		END

-- Populate HolidayFlag feilds... 
-- Since this varies for this example we just set Jan 1 of all years as a holiday
UPDATE AdventureWorks2019.dbo.Calender
SET
	HolidayFlag = 
		CASE
			WHEN DayOfMonthNumber = 1 AND MonthNumber = 1 THEN 1
			ELSE 0
		END
select * from AdventureWorks2019.dbo.Calender

-- Example for using the above created table...
-- Q: List of all sales order on weekend

SELECT 
	A.*
FROM AdventureWorks2019.Sales.SalesOrderHeader A
	INNER JOIN AdventureWorks2019.dbo.Calender B
		ON A.OrderDate = B.DateValue
WHERE B.WeekendFlag = 1


/*
Lookup Tables - Exercises
Exercise 1
*/

UPDATE AdventureWorks2019.dbo.Calender
SET
	HolidayFlag = 
		CASE
			WHEN DayOfMonthNumber = 1 AND MonthNumber = 1 THEN 1
			WHEN DayOfMonthNumber = 4 AND MonthNumber = 7 THEN 1
			WHEN DayOfMonthNumber = 11 AND MonthNumber = 11 THEN 1
			WHEN DayOfMonthNumber = 25 AND MonthNumber = 12 THEN 1
			ELSE 0
		END

select * from AdventureWorks2019.dbo.Calender

/*
Lookup Tables - Exercises
Exercise 2
*/
select
	A.*,
	B.DateValue,
	B.HolidayFlag
FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader A
	INNER JOIN AdventureWorks2019.dbo.Calender B
		ON A.OrderDate = B.DateValue
WHERE B.HolidayFlag = 1

/*
Lookup Tables - Exercises
Exercise 3
*/
select
	A.*,
	B.DateValue,
	B.HolidayFlag
FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader A
	INNER JOIN AdventureWorks2019.dbo.Calender B
		ON A.OrderDate = B.DateValue
WHERE B.HolidayFlag = 1 AND B.WeekendFlag = 1

-- Testing since the above query returned 0
select 
	distinct
	HolidayFlag
from AdventureWorks2019.dbo.Calender

-- END of Section... Noted Contd in ... MySQLQuery6_section7_ProgrammingSQL.sql