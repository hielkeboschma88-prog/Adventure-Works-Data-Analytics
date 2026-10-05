/* 1. Geef alle klanten (CustomerID) en hun totale aantal orders. */

SELECT 
	CustomerKey,
	COUNT(*) as TotalOrders
FROM dbo.FactInternetSales
GROUP BY CustomerKey
ORDER BY TotalOrders DESC

/* 2. Bereken de totale omzet per klant.  */

SELECT 
	fis.CustomerKey,
	dc.FirstName,
	dc.LastName,
	SUM(fis.SalesAmount) as TotalSales
FROM dbo.FactInternetSales fis 
	LEFT JOIN dbo.DimCustomer dc ON
	fis.CustomerKey = dc.CustomerKey
GROUP BY fis.CustomerKey, dc.FirstName,
	dc.LastName
ORDER BY SUM(fis.SalesAmount) DESC;

/* 3. Vind alle producten met hun categorie en subcategorie.  */

SELECT DISTINCT
	fpi.ProductKey,
	dp.EnglishProductName,
	dps.EnglishProductSubcategoryName

FROM FactProductInventory fpi
	LEFT JOIN dbo.DimProduct dp ON
	fpi.ProductKey = dp.ProductKey
	LEFT JOIN dbo.DimProductSubcategory dps ON
	dp.ProductSubcategoryKey = dps.ProductSubcategoryKey

/* 4. Geef het aantal orders per jaar.   */

SELECT 
	YEAR(orderdate) as OrderYear,
	COUNT(*) as TotalOrders
FROM dbo.FactInternetSales
GROUP BY YEAR(orderdate)
ORDER BY YEAR(orderdate) DESC

/* 5. Bereken de gemiddelde orderwaarde per klant. */

SELECT 
	CustomerKey,
	ROUND(CAST(SUM(SalesAmount) AS FLOAT), 2) AS TotalSalesAmount

FROM dbo.FactInternetSales
GROUP BY CustomerKey
ORDER BY TotalSalesAmount DESC

/* 6.Toon alle orders met klantnaam en orderdatum. */

SELECT
	fis.SalesOrderNumber,
	CONCAT(dbc.FirstName, ' ', dbc.LastName) AS Name,
	fis.OrderDate
FROM dbo.FactInternetSales fis
	INNER JOIN dbo.DimCustomer dbc ON
	dbc.CustomerKey = fis.CustomerKey

/* 7. Vind het totaal aantal verkochte producten per product. */

SELECT
	dp.EnglishProductName,
	COUNT(SalesOrderNumber) AS TotalSales

FROM dbo.FactInternetSales fis
	INNER JOIN dbo.DimProduct dp ON
	dp.ProductKey = fis.ProductKey

GROUP BY dp.EnglishProductName
ORDER BY TotalSales DESC;

/* 8 Geef de top 10 klanten op basis van totale omzet. */

SELECT TOP 10
	CONCAT(dbc.FirstName, ' ', dbc.LastName) AS Name,
	ROUND(CAST(SUM(fis.SalesAmount) AS FLOAT), 2) AS TotalRevenue

FROM dbo.FactInternetSales fis
	INNER JOIN dbo.DimCustomer dbc ON
	dbc.CustomerKey = fis.CustomerKey

GROUP BY CONCAT(dbc.FirstName, ' ', dbc.LastName) 
ORDER BY SUM(fis.SalesAmount) DESC;
	


/* 9 Bereken omzet per maand. */

SELECT
	ROUND(CAST(SUM(SalesAmount) AS FLOAT), 2) TotalRevenue,
	YEAR(OrderDate) AS Year,
	MONTH(OrderDate) AS Month

FROM dbo.FactInternetSales
GROUP BY 
	YEAR(OrderDate),
	MONTH(OrderDate)

ORDER BY
	Year DESC,
	Month DESC;
	

/* 10 Toon per productcategorie de totale omzet. */

SELECT
	dpc.EnglishProductCategoryName AS Category,
	ROUND(CAST(SUM(fis.SalesAmount) AS FLOAT) ,2) AS TotalRevenue

FROM dbo.FactInternetSales fis
	INNER JOIN dbo.DimProduct dp ON
	dp.ProductKey = fis.ProductKey

	INNER JOIN dbo.DimProductSubcategory dps ON
	dps.ProductSubcategoryKey = dp.ProductSubcategoryKey

	INNER JOIN dbo.DimProductCategory dpc ON
	dpc.ProductCategoryKey = dps.ProductCategoryKey

GROUP BY dpc.EnglishProductCategoryName
ORDER BY TotalRevenue DESC;