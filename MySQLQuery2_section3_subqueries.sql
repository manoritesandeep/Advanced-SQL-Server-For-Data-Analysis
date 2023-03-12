-- Scalar Subqueries
/*
Subqueries that return a single value...

Note: Sub-queries IN the FROM clause would need an alias, other mostly won't
*/

--Example 1: Scalar values
SELECT
	MAX(ListPrice)
FROM AdventureWorks2019.Production.Product

SELECT
	AVG(ListPrice)
FROM AdventureWorks2019.Production.Product

--Example 2: Scalar subqueries in the SELECT and WHERE clauses

SELECT 
	   ProductID
      ,[Name]
      ,StandardCost
      ,ListPrice
	  ,AvgListPrice = (SELECT AVG(ListPrice) FROM AdventureWorks2019.Production.Product)
	  ,AvgListPriceDiff = ListPrice - (SELECT AVG(ListPrice) FROM AdventureWorks2019.Production.Product)

FROM AdventureWorks2019.Production.Product

WHERE ListPrice > (SELECT AVG(ListPrice) FROM AdventureWorks2019.Production.Product)

ORDER BY ListPrice ASC

/*
Scalar Subqueries - Exercises
Exercise 1
*/

select 
	BusinessEntityID,
	JobTitle,
	VacationHours,
	MaxVacationHours = (SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee)
from AdventureWorks2019.HumanResources.Employee

/*
Scalar Subqueries - Exercises
Exercise 2
*/

select 
	BusinessEntityID,
	JobTitle,
	VacationHours,
	MaxVacationHours = (SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee),
	-- multiply at least one side of your equation by 1.0, 
	-- to ensure the output will be a decimal.
	MaxVacationHour_employee = (VacationHours * 1.0)/(SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee) 
from AdventureWorks2019.HumanResources.Employee

/*
Scalar Subqueries - Exercises
Exercise 3
*/

select 
	BusinessEntityID,
	JobTitle,
	VacationHours,
	MaxVacationHours = (SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee),
	MaxVacationHour_employee = (VacationHours * 1.0)/(SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee) 
from AdventureWorks2019.HumanResources.Employee
-- employees whose vacation hours are less then 80% of the
-- maximum amount of vacation hours for any one employee
where (VacationHours * 1.0)/(SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee) >= 0.8


-- Correlated Subqueries
/*
Correlated subqueries are subqueries that run once for each record
	in the main/outer query

They then return a scalar output (i.e. a single value) for each of those records

Correlated subqueries can be used in either the SELECT or WHERE clauses.
*/
SELECT 
       SalesOrderID
      ,OrderDate
      ,SubTotal
      ,TaxAmt
      ,Freight
      ,TotalDue
	  ,MultiOrderCount = --correlated subquery
	  (
		  SELECT
		  COUNT(*)
		  FROM AdventureWorks2019.Sales.SalesOrderDetail B
		  WHERE A.SalesOrderID = B.SalesOrderID
		  AND B.OrderQty > 1
	  )

FROM AdventureWorks2019.Sales.SalesOrderHeader A


 SELECT
SalesOrderID,
OrderQty
FROM AdventureWorks2019.Sales.SalesOrderDetail 
 WHERE SalesOrderID IN (43659,43660)

 /*
Correlated Subqueries - Exercises
Exercise 1
*/

select 
	--COUNT(*)
	PurchaseOrderID

from AdventureWorks2019.Purchasing.PurchaseOrderDetail B
where RejectedQty = 0

select 
PurchaseOrderID,
VendorID,
OrderDate,
TotalDue,
NonRejectedItems = 
(
select 
	COUNT(*)
from AdventureWorks2019.Purchasing.PurchaseOrderDetail B
where A.PurchaseOrderID = B.PurchaseOrderID
	 and RejectedQty = 0
)
from AdventureWorks2019.Purchasing.PurchaseOrderHeader A

 /*
Correlated Subqueries - Exercises
Exercise 2
*/

select 
PurchaseOrderID,
VendorID,
OrderDate,
TotalDue,
NonRejectedItems = 
(
	select 
		COUNT(*)
	from AdventureWorks2019.Purchasing.PurchaseOrderDetail B
	where A.PurchaseOrderID = B.PurchaseOrderID
		 and RejectedQty = 0
),
MostExpensiveItem = 
(
	select 
		MAX(B.UnitPrice)
	from AdventureWorks2019.Purchasing.PurchaseOrderDetail B
	where A.PurchaseOrderID = B.PurchaseOrderID
)
from AdventureWorks2019.Purchasing.PurchaseOrderHeader A


-- EXISTS and NOT EXISTS
/*
When we only need to bring a field to use it in our WHERE 
	and don't need to see it in our query output we use EXISTS.

why do we need EXISTS?
For one-to-one relationships, there really isn't much of an advantage to using EXISTS.
However, EXISTS offers some powerful advantages when dealing with 
	one-to-many relationships.

Use EXISTS if...
	You want to apply criteria to fields from a secondary table, but don't need
	to include those fields in your output.
	You want to apply criteria to fields from a secondary table, while ensuring
	that multiple matches in the secondary table won't duplicate data from the 
	primary table in your output.
	You need to check a secondary table to make sure a match of some types
	does NOT exist.
*/

--Example 1

SELECT * FROM AdventureWorks2019.Sales.SalesOrderHeader WHERE SalesOrderID = 43683

SELECT * FROM AdventureWorks2019.Sales.SalesOrderDetail WHERE SalesOrderID = 43683

--Example 2: One to many join with criteria

SELECT
       A.SalesOrderID
      ,A.OrderDate
      ,A.TotalDue

FROM AdventureWorks2019.Sales.SalesOrderHeader A
	INNER JOIN AdventureWorks2019.Sales.SalesOrderDetail B
		ON A.SalesOrderID = B.SalesOrderID

WHERE EXISTS(
	SELECT
		1

	FROM AdventureWorks2019.Sales.SalesOrderDetail B
	
	WHERE B.LineTotal > 10000
		AND A.SalesOrderID = B.SalesOrderID
	)

ORDER BY 1


--Example 3: Using EXISTS to pick only the records we need

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

--Example 4: exclusionary one to many join

SELECT
       A.SalesOrderID
      ,A.OrderDate
      ,A.TotalDue
	  ,B.SalesOrderDetailID
	  ,B.LineTotal

FROM AdventureWorks2019.Sales.SalesOrderHeader A
	INNER JOIN AdventureWorks2019.Sales.SalesOrderDetail B
		ON A.SalesOrderID = B.SalesOrderID

WHERE B.LineTotal < 10000
	AND A.SalesOrderID = 43683

ORDER BY 1

--Example 5: but this doesn't even do what we want!

SELECT
*
FROM AdventureWorks2019.Sales.SalesOrderDetail

WHERE SalesOrderID = 43683

ORDER BY LineTotal DESC


--Example 6: NOT EXISTS

SELECT
       A.SalesOrderID
      ,A.OrderDate
      ,A.TotalDue

FROM AdventureWorks2019.Sales.SalesOrderHeader A

WHERE NOT EXISTS (
	SELECT
	1
	FROM AdventureWorks2019.Sales.SalesOrderDetail B
	WHERE A.SalesOrderID = B.SalesOrderID
		AND B.LineTotal > 10000
)
	--AND A.SalesOrderID = 43683

ORDER BY 1


/*
EXISTS - Exercises
Exercise 1
*/
SELECT * FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader --WHERE PurchaseOrderID = 43683

SELECT * FROM AdventureWorks2019.Purchasing.PurchaseOrderDetail --WHERE PurchaseOrderID = 43683

select
	PurchaseOrderID,
	OrderDate,
	SubTotal,
	TaxAmt
from AdventureWorks2019.Purchasing.PurchaseOrderHeader A
WHERE EXISTS
	(
	SELECT 
	1
	FROM AdventureWorks2019.Purchasing.PurchaseOrderDetail B
	WHERE B.OrderQty > 500
		AND A.PurchaseOrderID = B.PurchaseOrderID
	)
ORDER BY 1

/*
EXISTS - Exercises
Exercise 2
*/
select
	A.*
from AdventureWorks2019.Purchasing.PurchaseOrderHeader A
WHERE EXISTS
(
	Select 
		1
	from AdventureWorks2019.Purchasing.PurchaseOrderDetail B
	where b.OrderQty > 500 AND b.UnitPrice > 50.00
		AND A.PurchaseOrderID = B.PurchaseOrderID
)

ORDER BY 1

/*
EXISTS - Exercises
Exercise 3
*/
select
	A.*
from AdventureWorks2019.Purchasing.PurchaseOrderHeader A
WHERE NOT EXISTS
(
	Select 
		1
	from AdventureWorks2019.Purchasing.PurchaseOrderDetail B
	where A.PurchaseOrderID = B.PurchaseOrderID
		AND B.RejectedQty > 0
)

ORDER BY 1

-- FOR XML PATH with STUFF
/*
Flattening multiple rows into one

*/
select 
STUFF(
	(
	select 
	',' + CAST(CAST(LineTotal AS MONEY) AS varchar)
	from AdventureWorks2019.Sales.SalesOrderDetail
	where SalesOrderID = 43659
	FOR XML PATH('')
	),
	1,1,'')

select
	SalesOrderID,
	OrderDate,
	SubTotal,
	TaxAmt,
	Freight,
	TotalDue,
	LineTotalS = 
		STUFF(
			(
			select 
				',' + CAST(CAST(B.LineTotal AS MONEY) AS varchar)
			from  AdventureWorks2019.Sales.SalesOrderDetail B
			where A.SalesOrderID = B.SalesOrderID
			FOR XML PATH('')
			),
		1,1,'')
from AdventureWorks2019.Sales.SalesOrderHeader A

/*
FOR XML PATH With STUFF - Exercises
Exercise 1
*/

select
STUFF(
(
	select 
		',' + B.Name
	from AdventureWorks2019.Production.Product B
	FOR XML PATH('')
	--WHERE B.ProductSubcategoryID = A.ProductSubcategoryID
),
1,1,'')


select
	A.Name as SubcategoryName,
	Products = 
	STUFF(
	(
		select 
			',' + B.Name
		from AdventureWorks2019.Production.Product B
		WHERE B.ProductSubcategoryID = A.ProductSubcategoryID
		FOR XML PATH('')
	),
	1,1,'')
from AdventureWorks2019.Production.ProductSubcategory A

/*
FOR XML PATH With STUFF - Exercises
Exercise 2
*/
select 
	B.Name,
	B.ListPrice
from AdventureWorks2019.Production.Product B
WHERE B.ListPrice >50
-- FOR XML PATH('')

select
STUFF(
(
	select 
		',' + B.Name
	from AdventureWorks2019.Production.Product B
	WHERE B.ListPrice >50
	FOR XML PATH('')
	--WHERE B.ProductSubcategoryID = A.ProductSubcategoryID
),
1,1,'')


select
	A.Name as SubcategoryName,
	Products = 
	STUFF(
	(
		select 
			',' + B.Name
		from AdventureWorks2019.Production.Product B
		WHERE B.ProductSubcategoryID = A.ProductSubcategoryID
			AND  B.ListPrice >50
		FOR XML PATH('')
	),
	1,1,'')
from AdventureWorks2019.Production.ProductSubcategory A

-- Verifying
select 
	A.Name,
	B.ListPrice
from AdventureWorks2019.Production.ProductSubcategory A
	inner join AdventureWorks2019.Production.Product B
		on B.ProductSubcategoryID = A.ProductSubcategoryID
where B.ListPrice < 50 AND A.Name = 'Bottles and Cages'


-- PIVOT
/*
Another way to flatten your data is using PIVOT.
*/
SELECT 
	[Accessories],
	[Bikes],
	[Clothing],
	[Components]
FROM 
(
select 
	D.Name as ProductCategoryName,
	-- ProductCategoryName = D.Name
	A.LineTotal
from AdventureWorks2019.Sales.SalesOrderDetail A
	inner join AdventureWorks2019.Production.Product B
		on A.ProductID = B.ProductID
	inner join AdventureWorks2019.Production.ProductSubcategory c
		on B.ProductSubcategoryID = C.ProductSubcategoryID
	inner join AdventureWorks2019.Production.ProductCategory D
		on C.ProductCategoryID = D.ProductCategoryID
) A
PIVOT(
SUM(LineTotal)
FOR ProductCategoryName IN ([Accessories],[Bikes],[Clothing],[Components])
) B


-- Example 2
select 
--OrderQty as [Order Quantity],
* 
from
(
select 
	ProductCategoryName = D.Name,
	A.LineTotal,
	A.OrderQty
from AdventureWorks2019.Sales.SalesOrderDetail A
	inner join AdventureWorks2019.Production.Product B
		on A.ProductID = B.ProductID
	inner join AdventureWorks2019.Production.ProductSubcategory c
		on B.ProductSubcategoryID = C.ProductSubcategoryID
	inner join AdventureWorks2019.Production.ProductCategory D
		on C.ProductCategoryID = D.ProductCategoryID
) A
PIVOT (
SUM(LineTotal)
FOR ProductCategoryName IN ([Accessories],[Bikes],[Clothing],[Components])
) B
ORDER BY OrderQty


/*
PIVOT - Exercises
Exercise 1
*/
select
	*
from (
	select 
		JobTitle,
		VacationHours
	from AdventureWorks2019.HumanResources.Employee
) A
PIVOT(
AVG(VacationHours)
FOR JobTitle IN ([Sales Representative],[Buyer],[Janitor])
)B
-- [Buyer], [Sales Representative],[Janitor]

/*
PIVOT - Exercises
Exercise 2
*/
select
	Gender as [Employee Gender],
	[Sales Representative],
	[Buyer],
	[Janitor]
from (
	select 
		JobTitle,
		VacationHours,
		Gender
	from AdventureWorks2019.HumanResources.Employee
) A
PIVOT(
AVG(VacationHours)
FOR JobTitle IN ([Sales Representative],[Buyer],[Janitor])
)B
-- [Buyer], [Sales Representative],[Janitor]

-- End of section... Notes contd. in MySQLQuery3_section4_CTEs