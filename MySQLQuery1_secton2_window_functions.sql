SELECT  TOP (10) * 
FROM [AdventureWorks2019_1].[Sales].[SalesOrderHeader]

-- WINDOWS FUNCTION - OVER
/*
Windows function allow you to include aggregate calculations in your query,
	WITHOUT changing the output in any way.

The aggregate calculation is simple tacked on to the query as an additional column.

It is also possible to group these calculations, just like we can with aggregate queries, 
	using PARTITION
*/
--YTD Sales Via Aggregate Query:

SELECT

      [Total YTD Sales] = SUM(SalesYTD)
      ,[Max YTD Sales] = MAX(SalesYTD)

FROM AdventureWorks2019.Sales.SalesPerson



--YTD Sales With OVER:

SELECT BusinessEntityID
      ,TerritoryID
      ,SalesQuota
      ,Bonus
      ,CommissionPct
      ,SalesYTD
	  ,SalesLastYear
      ,[Total YTD Sales] = SUM(SalesYTD) OVER()
      ,[Max YTD Sales] = MAX(SalesYTD) OVER()
      ,[% of Best Performer] = SalesYTD/MAX(SalesYTD) OVER()

FROM AdventureWorks2019.Sales.SalesPerson

/*
Introducing Window Functions With OVER - Exercises
Exercise 1
*/

select 
	p.FirstName,
	p.LastName,
	hr.JobTitle,
	hr_ep.Rate,
	[AverageRate] = AVG([Rate]) OVER()
from AdventureWorks2019.Person.Person as p
	left join AdventureWorks2019.HumanResources.Employee as hr
		on hr.BusinessEntityID = p.BusinessEntityID
	left join AdventureWorks2019.HumanResources.EmployeePayHistory as hr_ep
		on hr.BusinessEntityID = hr_ep.BusinessEntityID
/*
Introducing Window Functions With OVER - Exercises
Exercise 2
*/

select 
	p.FirstName,
	p.LastName,
	hr.JobTitle,
	hr_ep.Rate,
	[AverageRate] = AVG([Rate]) OVER(),
	[MaximumRate] = MAX([Rate]) OVER()
from AdventureWorks2019.Person.Person as p
	left join AdventureWorks2019.HumanResources.Employee as hr
		on hr.BusinessEntityID = p.BusinessEntityID
	left join AdventureWorks2019.HumanResources.EmployeePayHistory as hr_ep
		on hr.BusinessEntityID = hr_ep.BusinessEntityID

/*
Introducing Window Functions With OVER - Exercises
Exercise 3
*/
select 
	p.FirstName,
	p.LastName,
	hr.JobTitle,
	hr_ep.Rate,
	[AverageRate] = AVG([Rate]) OVER(),
	[MaximumRate] = MAX([Rate]) OVER(),
	[DiffFromAvgRate] = hr_ep.Rate - AVG([Rate]) OVER()
from AdventureWorks2019.Person.Person as p
	left join AdventureWorks2019.HumanResources.Employee as hr
		on hr.BusinessEntityID = p.BusinessEntityID
	left join AdventureWorks2019.HumanResources.EmployeePayHistory as hr_ep
		on hr.BusinessEntityID = hr_ep.BusinessEntityID

/*
Introducing Window Functions With OVER - Exercises
Exercise 4
*/

select 
	p.FirstName,
	p.LastName,
	hr.JobTitle,
	hr_ep.Rate,
	[AverageRate] = AVG([Rate]) OVER(),
	[MaximumRate] = MAX([Rate]) OVER(),
	[DiffFromAvgRate] = hr_ep.Rate - AVG([Rate]) OVER(),
	[PercentofMaxRate] = hr_ep.Rate / MAX([Rate]) OVER()
from AdventureWorks2019.Person.Person as p
	left join AdventureWorks2019.HumanResources.Employee as hr
		on hr.BusinessEntityID = p.BusinessEntityID
	left join AdventureWorks2019.HumanResources.EmployeePayHistory as hr_ep
		on hr.BusinessEntityID = hr_ep.BusinessEntityID

-- PARTITION BY
/*
PARTITION BY allows us to compute aggregate totals for groups within our data,
	while still retaining row-level detail
PARTITION BY assigns each row of your query output to a group,
	without collapsing your data into fewer rows as with GROUP BY 

We need to specify the columns these groups will be based on
*/

--Sum of line totals, grouped by ProductID AND OrderQty, in an aggregate query

SELECT
	ProductID,
	OrderQty,
	LineTotal = SUM(LineTotal)

FROM AdventureWorks2019.Sales.SalesOrderDetail

GROUP BY
	ProductID,
	OrderQty

ORDER BY 1,2 DESC


--Sum of line totals via OVER with PARTITION BY

SELECT
	ProductID,
	SalesOrderID,
	SalesOrderDetailID,
	OrderQty,
	UnitPrice,
	UnitPriceDiscount,
	LineTotal,
	ProductIDLineTotal = SUM(LineTotal) OVER(PARTITION BY ProductID, OrderQty)

FROM AdventureWorks2019.Sales.SalesOrderDetail

ORDER BY ProductID, OrderQty DESC

/*
PARTITION BY - Exercises
Exercise 1
*/

select 
	A.Name as ProductName,
	A.ListPrice,
	B.Name as ProductSubcategory,
	C.Name as ProductCategory

from AdventureWorks2019.Production.Product as A
	inner join AdventureWorks2019.Production.ProductSubcategory B
		on A.ProductSubcategoryID = B.ProductSubcategoryID
	inner join AdventureWorks2019.Production.ProductCategory C
		on C.ProductCategoryID = B.ProductCategoryID

/*
PARTITION BY - Exercises
Exercise 2
*/

select 
	A.Name as ProductName,
	A.ListPrice,
	B.Name as ProductSubcategory,
	C.Name as ProductCategory,
	[AvgPriceByCategory] = AVG([ListPrice]) OVER(PARTITION BY C.Name)

from AdventureWorks2019.Production.Product as A
	inner join AdventureWorks2019.Production.ProductSubcategory B
		on A.ProductSubcategoryID = B.ProductSubcategoryID
	inner join AdventureWorks2019.Production.ProductCategory C
		on C.ProductCategoryID = B.ProductCategoryID

/*
PARTITION BY - Exercises
Exercise 3
*/

select 
	A.Name as ProductName,
	A.ListPrice,
	B.Name as ProductSubcategory,
	C.Name as ProductCategory,
	[AvgPriceByCategory] = AVG([ListPrice]) OVER(PARTITION BY C.Name),
	[AvgPriceByCategoryAndSubcategory] = AVG([ListPrice]) OVER(PARTITION BY C.Name, B.Name)

from AdventureWorks2019.Production.Product as A
	inner join AdventureWorks2019.Production.ProductSubcategory B
		on A.ProductSubcategoryID = B.ProductSubcategoryID
	inner join AdventureWorks2019.Production.ProductCategory C
		on C.ProductCategoryID = B.ProductCategoryID

/*
PARTITION BY - Exercises
Exercise 4
*/

select 
	A.Name as ProductName,
	A.ListPrice,
	B.Name as ProductSubcategory,
	C.Name as ProductCategory,
	[AvgPriceByCategory] = AVG([ListPrice]) OVER(PARTITION BY C.Name),
	[AvgPriceByCategoryAndSubcategory] = AVG([ListPrice]) OVER(PARTITION BY C.Name, B.Name),
	[ProductVsCategoryDelta] = A.ListPrice - AVG([ListPrice]) OVER(PARTITION BY C.Name)
from AdventureWorks2019.Production.Product as A
	inner join AdventureWorks2019.Production.ProductSubcategory B
		on A.ProductSubcategoryID = B.ProductSubcategoryID
	inner join AdventureWorks2019.Production.ProductCategory C
		on C.ProductCategoryID = B.ProductCategoryID


-- ROW_NUMBER
/*
Beyond aggregations, we also have the ability to RANK records within our data.
These rankings can either be applied across the entire query output, 
	or to partitioned groups within it. 
*/

--Ranking all records within each group of sales order IDs

SELECT
	SalesOrderID,
	SalesOrderDetailID,
	LineTotal,
	ProductIDLineTotal = SUM(LineTotal) OVER(PARTITION BY SalesOrderID),
	Ranking = ROW_NUMBER() OVER(PARTITION BY SalesOrderID ORDER BY LineTotal DESC)

FROM AdventureWorks2019.Sales.SalesOrderDetail

ORDER BY
SalesOrderID


--Ranking ALL records by line total - no groups!

SELECT
	SalesOrderID,
	SalesOrderDetailID,
	LineTotal,
	ProductIDLineTotal = SUM(LineTotal) OVER(PARTITION BY SalesOrderID),
	Ranking = ROW_NUMBER() OVER(ORDER BY LineTotal DESC)

FROM AdventureWorks2019.Sales.SalesOrderDetail

ORDER BY 5

/*
ROW_NUMBER - Exercises
Exercise 1 and 2... 1 mainly loading table and cols.
*/

select 
	A.Name as ProductName,
	A.ListPrice,
	B.Name as ProductSubcategory,
	C.Name as ProductCategory,
	[Price Rank] = ROW_NUMBER() OVER(ORDER BY A.ListPrice DESC)
from AdventureWorks2019.Production.Product as A
	inner join AdventureWorks2019.Production.ProductSubcategory B
		on A.ProductSubcategoryID = B.ProductSubcategoryID
	inner join AdventureWorks2019.Production.ProductCategory C
		on C.ProductCategoryID = B.ProductCategoryID

/*
ROW_NUMBER - Exercises
Exercise 3
*/

select 
	A.Name as ProductName,
	A.ListPrice,
	B.Name as ProductSubcategory,
	C.Name as ProductCategory,
	[Price Rank] = ROW_NUMBER() OVER(ORDER BY A.ListPrice DESC),
	[Category Price Rank] = ROW_NUMBER() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC)
from AdventureWorks2019.Production.Product as A
	inner join AdventureWorks2019.Production.ProductSubcategory B
		on A.ProductSubcategoryID = B.ProductSubcategoryID
	inner join AdventureWorks2019.Production.ProductCategory C
		on C.ProductCategoryID = B.ProductCategoryID

		
/*
ROW_NUMBER - Exercises
Exercise 4
*/

select 
	A.Name as ProductName,
	A.ListPrice,
	B.Name as ProductSubcategory,
	C.Name as ProductCategory,
	[Price Rank] = ROW_NUMBER() OVER(ORDER BY A.ListPrice DESC),
	[Category Price Rank] = ROW_NUMBER() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC),
	[Top 5 Price In Category] = 
		case
			when ROW_NUMBER() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC) <= 5 then 'Yes' 
			else 'No'
		end

from AdventureWorks2019.Production.Product as A
	inner join AdventureWorks2019.Production.ProductSubcategory B
		on A.ProductSubcategoryID = B.ProductSubcategoryID
	inner join AdventureWorks2019.Production.ProductCategory C
		on C.ProductCategoryID = B.ProductCategoryID


-- RANK and DENSE_RANK
/*
If you are trying to pick exactly one record from each partition group
	-either the first or last - use ROW_NUMBER.. Probably the most common scenario
RANK and DENSE_RANK are helpful in rarer, more specialized cases. It mostly depends
	on what you're trying to get out of your data.
*/

select 
	SalesOrderID,
	SalesOrderDetailID,
	LineTotal,
	ranking = ROW_NUMBER() OVER(PARTITION BY SalesOrderID ORDER BY LineTotal DESC),
	RankingwithRank = RANK() OVER(PARTITION BY SalesOrderID ORDER BY LineTotal DESC),
	RankingwithDense_Rank = DENSE_RANK() OVER(PARTITION BY SalesOrderID ORDER BY LineTotal DESC)
from AdventureWorks2019.Sales.SalesOrderDetail
ORDER BY SalesOrderID, LineTotal DESC


/*
RANK and DENSE_RANK - Exercises
Exercise 1
*/

select 
	A.Name as ProductName,
	A.ListPrice,
	B.Name as ProductSubcategory,
	C.Name as ProductCategory,
	[Price Rank] = ROW_NUMBER() OVER(ORDER BY A.ListPrice DESC),
	[Category Price Rank] = ROW_NUMBER() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC),
	[Category Price Rank With Rank] = RANK() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC)
from AdventureWorks2019.Production.Product A
	inner join AdventureWorks2019.Production.ProductSubcategory B
		on A.ProductSubcategoryID = B.ProductSubcategoryID
	inner join AdventureWorks2019.Production.ProductCategory C
		on C.ProductCategoryID = B.ProductCategoryID

/*
RANK and DENSE_RANK - Exercises
Exercise 2
*/

select 
	A.Name as ProductName,
	A.ListPrice,
	B.Name as ProductSubcategory,
	C.Name as ProductCategory,
	[Price Rank] = ROW_NUMBER() OVER(ORDER BY A.ListPrice DESC),
	[Category Price Rank] = ROW_NUMBER() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC),
	[Category Price Rank With Rank] = RANK() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC),
	[Category Price Rank With Dense Rank] = DENSE_RANK() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC)
from AdventureWorks2019.Production.Product A
	inner join AdventureWorks2019.Production.ProductSubcategory B
		on A.ProductSubcategoryID = B.ProductSubcategoryID
	inner join AdventureWorks2019.Production.ProductCategory C
		on C.ProductCategoryID = B.ProductCategoryID

/*
RANK and DENSE_RANK - Exercises
Exercise 3
*/

select 
	A.Name as ProductName,
	A.ListPrice,
	B.Name as ProductSubcategory,
	C.Name as ProductCategory,
	[Price Rank] = ROW_NUMBER() OVER(ORDER BY A.ListPrice DESC),
	[Category Price Rank] = ROW_NUMBER() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC),
	[Category Price Rank With Rank] = RANK() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC),
	[Category Price Rank With Dense Rank] = DENSE_RANK() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC),
	[Top 5 Price In Category_DenseRank] =
		case
			when DENSE_Rank() OVER(PARTITION BY C.Name ORDER BY A.ListPrice DESC) <=5 then 'Yes'
			else 'no'
		end		
from AdventureWorks2019.Production.Product A
	inner join AdventureWorks2019.Production.ProductSubcategory B
		on A.ProductSubcategoryID = B.ProductSubcategoryID
	inner join AdventureWorks2019.Production.ProductCategory C
		on C.ProductCategoryID = B.ProductCategoryID

-- LEAD and LAG: Time Travelling through time
/*
LEAD and LAG let us grab values from subsequent or previous records 
	relative to the position of the 'current' record in our data.
They can be useful any time we want to compare a value in a given column to the next 
	or previous value in the same column - but side by side, in the same row.
This is a very common problem in real-world analytics scenarios.
*/

select 
	SalesOrderID,
	OrderDate,
	CustomerID,
	TotalDue
	--,[NextTotalDue]  = LEAD(TotalDue,1) OVER(ORDER BY SalesOrderID) 
	--,[PreviousTotalDue] = LAG(TotalDue,1) OVER(ORDER BY SalesOrderID)
	--,[NextTotalDue]  = LEAD(TotalDue,2) OVER(ORDER BY SalesOrderID) 
	--,[PreviousTotalDue] = LAG(TotalDue,2) OVER(ORDER BY SalesOrderID)
	,[NextTotalDue_Partition]= LEAD(TotalDue,1) OVER(PARTITION BY CustomerID ORDER BY SalesOrderID)
	,[PreviousTotalDue_Partition] = LAG(TotalDue,1) OVER(PARTITION BY CustomerID ORDER BY SalesOrderID)
from AdventureWorks2019.Sales.SalesOrderHeader
ORDER BY CustomerID,SalesOrderID


/*
LEAD and LAG - Exercises
Exercise 1
*/

select 
	A.PurchaseOrderID,
	A.OrderDate,
	A.TotalDue,
	B.Name
from AdventureWorks2019.Purchasing.PurchaseOrderHeader A
	inner join AdventureWorks2019.Purchasing.Vendor B
		on B.BusinessEntityID = A.VendorID
where A.TotalDue > 500 AND YEAR(A.OrderDate) >=2013

/*
LEAD and LAG - Exercises
Exercise 2
*/

select 
	A.PurchaseOrderID,
	A.OrderDate,
	A.TotalDue,
	B.Name,
	[PrevOrderFromVendorAmt] = LAG(TotalDue,1) OVER(PARTITION BY A.VendorID ORDER BY OrderDate)
from AdventureWorks2019.Purchasing.PurchaseOrderHeader A
	inner join AdventureWorks2019.Purchasing.Vendor B
		on B.BusinessEntityID = A.VendorID
where A.TotalDue > 500 AND YEAR(A.OrderDate) >=2013

 ORDER BY 
  A.VendorID,
  A.OrderDate

/*
LEAD and LAG - Exercises
Exercise 3
*/

select 
	A.PurchaseOrderID,
	A.OrderDate,
	A.TotalDue,
	B.Name,
	[PrevOrderFromVendorAmt] = LAG(TotalDue,1) OVER(PARTITION BY A.VendorID ORDER BY OrderDate),
	[NextOrderByEmployeeVendor] = LEAD(B.name,1) OVER(PARTITION BY A.EmployeeID ORDER BY A.OrderDate)
from AdventureWorks2019.Purchasing.PurchaseOrderHeader A
	inner join AdventureWorks2019.Purchasing.Vendor B
		on B.BusinessEntityID = A.VendorID
where A.TotalDue > 500 AND YEAR(A.OrderDate) >=2013

 ORDER BY 
  A.VendorID,
  A.OrderDate

/*
LEAD and LAG - Exercises
Exercise 4
*/

select 
	A.PurchaseOrderID,
	A.OrderDate,
	A.TotalDue,
	B.Name,
	[PrevOrderFromVendorAmt] = LAG(TotalDue,1) OVER(PARTITION BY A.VendorID ORDER BY OrderDate),
	[NextOrderByEmployeeVendor] = LEAD(B.name,1) OVER(PARTITION BY A.EmployeeID ORDER BY A.OrderDate),
	[Next2OrderByEmployeeVendor] = LEAD(B.name,2) OVER(PARTITION BY A.EmployeeID ORDER BY A.OrderDate)
from AdventureWorks2019.Purchasing.PurchaseOrderHeader A
	inner join AdventureWorks2019.Purchasing.Vendor B
		on B.BusinessEntityID = A.VendorID
where A.TotalDue > 500 AND YEAR(A.OrderDate) >=2013

 ORDER BY 
  A.VendorID,
  A.OrderDate


-- 16. Introducing Subqueries
/*
Multi-step SQL queries are EXTREMELY common in the real world of data analysis.

Subqueries are best for straightforward, two-step queries
*/
select 
	*
FROM(
select 
	SalesOrderID,
	SalesOrderDetailID,
	LineTotal,
	LineTotalRanking = ROW_NUMBER() OVER(PARTITION BY SalesOrderID ORDER BY LineTotal DESC)
from AdventureWorks2019.Sales.SalesOrderDetail
) A
WHERE LineTotalRanking = 1

/*
Introducing Subqueries - Exercises
Exercise 1
*/

select 
	PurchaseOrderID,
	VendorID,
	OrderDate,
	TaxAmt,
	Freight,
	TotalDue
from(
select 
	PurchaseOrderID,
	VendorID,
	OrderDate,
	TaxAmt,
	Freight,
	TotalDue,
	--three_top = DENSE_RANK() OVER(PARTITION BY VendorID ORDER BY TotalDue DESC)
	PurchaseOrderRank = ROW_NUMBER() OVER(PARTITION BY VendorID ORDER BY TotalDue DESC)
from AdventureWorks2019.Purchasing.PurchaseOrderHeader
) A
where PurchaseOrderRank <=3

/*
Introducing Subqueries - Exercises
Exercise 2
*/

select 
	PurchaseOrderID,
	VendorID,
	OrderDate,
	TaxAmt,
	Freight,
	TotalDue
from(
select 
	PurchaseOrderID,
	VendorID,
	OrderDate,
	TaxAmt,
	Freight,
	TotalDue,
	--three_top = DENSE_RANK() OVER(PARTITION BY VendorID ORDER BY TotalDue DESC)
	PurchaseOrderRank = DENSE_RANK() OVER(PARTITION BY VendorID ORDER BY TotalDue DESC)
from AdventureWorks2019.Purchasing.PurchaseOrderHeader
) A
where PurchaseOrderRank <=3

-- END OF SECTION 
-- Next Section: Section 3: Subqueries in MySQLQuery2_section3_subqueries.sql file. 