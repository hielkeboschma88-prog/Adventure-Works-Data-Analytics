/* 11 Bereken de rang van klanten op basis van totale omzet. */

WITH Renevue_per_customer_cte AS 

	(SELECT 
		CONCAT(dbc.FirstName, ' ', dbc.LastName) AS Name,
		ROUND(CAST(SUM(fis.SalesAmount) AS FLOAT), 2) AS TotalRevenue

	FROM dbo.FactInternetSales fis
		INNER JOIN dbo.DimCustomer dbc ON
		dbc.CustomerKey = fis.CustomerKey

	GROUP BY CONCAT(dbc.FirstName, ' ', dbc.LastName) 
)

SELECT 
	Name,
	TotalRevenue,
	ROW_NUMBER() OVER (ORDER BY TotalRevenue DESC) AS CustomerRank

FROM Renevue_per_customer_cte

/* 12 Vind de vorige orderdatum per klant. */

SELECT 
	CustomerKey,
	OrderDate,
	LAG(OrderDate) OVER (PARTITION BY CustomerKey ORDER BY OrderDate) as LastOrderDate
	
FROM dbo.FactInternetSales
	

/* 13 Bereken het verschil in dagen tussen opeenvolgende orders per klant. */

SELECT 
	CustomerKey,
	OrderDate,
	LAG(OrderDate) OVER (PARTITION BY CustomerKey ORDER BY OrderDate) as LastOrderDate,
	DATEDIFF(DAY, OrderDate, LAG(OrderDate) OVER (PARTITION BY CustomerKey ORDER BY OrderDate)) AS DaysBetweenOrders

FROM dbo.FactInternetSales

/* 14 Bereken running total van omzet per klant. */

SELECT
	CustomerKey,
	YEAR(OrderDate) AS Year,
	MONTH(OrderDate) AS Month,
	SalesAmount,
	SUM(SalesAmount) OVER (PARTITION BY CustomerKey ORDER BY YEAR(OrderDate), MONTH(OrderDate) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotalRevenue

FROM dbo.FactInternetSales

/* 15 Toon per product zijn aandeel in totale omzet (%). */

WITH Pct_Revenue_cte AS

(SELECT
	dp.EnglishProductName AS Product,
	fis.SalesAmount,
	SUM(fis.SalesAmount) OVER (PARTITION BY fis.ProductKey) AS TotalRevenuePerProduct,
	SUM(fis.SalesAmount) OVER () AS TotalRevenue,
	SUM(fis.SalesAmount) OVER (PARTITION BY fis.ProductKey) / SUM(fis.SalesAmount) OVER () * 100 AS PercentOfTotalRevenue

FROM dbo.FactInternetSales fis
	JOIN dbo.DimProduct dp ON
	dp.ProductKey = fis.ProductKey
)

SELECT
	Product,
	MAX(PercentOfTotalRevenue) AS PercentOfTotalRevenue

FROM Pct_Revenue_cte
GROUP BY Product
ORDER BY PercentOfTotalRevenue DESC;


/* 16 Vind de best verkopende product per categorie. */

WITH SalesPerProductCte AS

(SELECT
	dp.EnglishProductName AS Product,
	dpc.EnglishProductCategoryName AS ProductCategory,
	SUM(fis.SalesAmount) AS SalesPerProduct

FROM dbo.FactInternetSales fis
	LEFT JOIN dbo.DimProduct dp ON
	dp.ProductKey = fis.ProductKey
	LEFT JOIN dbo.DimProductSubCategory dpsc ON
	dpsc.productsubcategorykey = dp.productsubcategorykey
	LEFT JOIN dbo.DimProductCategory dpc ON
	dpc.ProductCategoryKey = dpsc.ProductCategoryKey

GROUP BY
	dpc.EnglishProductCategoryName,
	dp.EnglishProductName
)


SELECT 
	Product,
	ProductCategory,
	ROUND(CAST(SalesPerProduct AS FLOAT), 2) AS SalesPerProduct,
	ROW_NUMBER() OVER (PARTITION BY ProductCategory ORDER BY SalesPerProduct DESC) AS SalesRankPerProductCategory

FROM SalesPerProductCte

/* 17 Bereken het gemiddelde orderbedrag per maand met window functions. */

SELECT
	SalesOrderNumber,
	SalesAmount,
	FORMAT(OrderDate, 'MMM yyyy') as Month,
	ROUND(CAST(AVG(SalesAmount) OVER (PARTITION BY FORMAT(OrderDate, 'MMM yyyy')) AS FLOAT), 2) as AvgSalesPerMonth

FROM dbo.FactInternetSales
	

/* 18 Toon per klant hun eerste en laatste orderdatum. */

SELECT
	CustomerKey,
	OrderDate,
	FIRST_VALUE(OrderDate) OVER (PARTITION BY CustomerKey ORDER BY OrderDate) as FirstOrder,
	LAST_VALUE(OrderDate) OVER (PARTITION BY CustomerKey ORDER BY OrderDate ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS LastOrder

FROM dbo.FactInternetSales

/* 19 Bereken cumulatieve omzet per jaar. */

WITH Revenue_CTE AS

(SELECT
	YEAR(OrderDate) AS Year,
	MONTH(OrderDate) AS Month,
	SUM(SalesAmount) AS TotalRevenue

FROM dbo.FactInternetSales
GROUP BY
	YEAR(OrderDate),
	MONTH(OrderDate)
	)

SELECT 
	Year,
	Month,
	SUM(TotalRevenue) OVER (PARTITION BY Year ORDER BY MONTH) AS RunningTotalSales

FROM Revenue_CTE 
	


/* 20 Vind klanten die meer dan 3 orders hebben in 1 maand. */

WITH OrdersPerCustomerPerMonthCTE AS

(SELECT DISTINCT
	CustomerKey,
	SalesOrderNumber,
	FORMAT(OrderDate, 'MMM yyyy') AS Month,
	COUNT(*) OVER (PARTITION BY CustomerKey, FORMAT(OrderDate, 'MMM yyyy')) AS OrdersPerCustomerPerMonth

FROM dbo.FactInternetSales
)

SELECT *
FROM OrdersPerCustomerPerMonthCTE
WHERE OrdersPerCustomerPerMonth > 3