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

/* 21 Vind klanten waarvan hun laatste order hoger is dan hun gemiddelde orderwaarde. */ 

WITH Orders_CTE AS

	(SELECT 
		CustomerKey,
		SalesOrderNumber,
		OrderDate,
		SUM(SalesAmount) AS SalesPerOrder

	FROM dbo.FactInternetSales
	GROUP BY 
		CustomerKey,
		SalesOrderNumber,
		OrderDate
)
,
AvgAndLastOrderCTE AS

	(SELECT
		CustomerKey,
		SalesOrderNumber,
		OrderDate,
		SalesPerOrder,
		AVG(SalesPerOrder) OVER (PARTITION BY CustomerKey) AS AvgOrder,
		ROW_NUMBER() OVER (PARTITION BY CustomerKey ORDER BY OrderDate DESC) LastOrder

	FROM Orders_CTE
	)

SELECT
	CustomerKey,
	SalesOrderNumber,
	OrderDate,
	SalesPerOrder,
	AvgOrder,
	LastOrder

FROM AvgAndLastOrderCTE
WHERE 
	LastOrder = 1 AND
	SalesPerOrder > AvgOrder

	
/* 22 Bereken churn: klanten zonder order in de laatste 12 maanden. 
Een actieve klant is iemand die binnen 1 jaar nog een bestelling heeft gedaan*/ 

-- Aantal klanten dat weggaat / aantal klanten begin periode * 100 = churn

-- stap 1: Bereken hoeveel klanten er waren in 2013



WITH cte_customers1 AS (
							SELECT DISTINCT
								customerkey as Customers1
							FROM dbo.factinternetsales
							WHERE OrderDateKey BETWEEN 20120101 AND 20130101),

-- stap 2: Bereken hoeveel klanten er waren in 2014

	cte_customers2 AS (		SELECT DISTINCT
								customerkey as Customers2
							FROM dbo.factinternetsales
							WHERE OrderDateKey BETWEEN 20130101 AND 20140101),

-- stap 3: Bereken de churn hieruit. Dus de klanten die niet meer in de 2e lijst met klanten voorkwamen. 
		 /*   Ik zoek hier de oude klanten en kijk of ze niet meer klant zijn, die zijn dus weggegaan */

	cte_churn AS (
							SELECT 
							customers1 AS CustomersLeft
							FROM cte_customers1
							WHERE customers1 NOT IN (SELECT Customers2 FROM cte_customers2)),

-- Stap 4: Combineren van alle waarden tot 1 tabel.

cte_combined AS (

				SELECT
					(SELECT COUNT(DISTINCT customers1) FROM cte_customers1) AS Begincustomers,
					(SELECT COUNT(DISTINCT customers2) from cte_customers2) AS Endcustomers,
					(SELECT COUNT (DISTINCT customersleft) from cte_churn) AS Churn)

-- stap 5: Churn berekenen
SELECT
	ROUND((churn * 1.00 / begincustomers) * 100, 2) as churn

FROM cte_combined
		
	
/* 23 Rank producten binnen elke categorie op omzet. */ 

WITH RevenuePerProduct_CTE AS

(SELECT
	dp.EnglishProductName AS Product,
	dpc.EnglishProductCategoryName AS Category,
	SUM(fis.SalesAmount) AS TotalRevenue

FROM dbo.FactInternetSales fis
	INNER JOIN dbo.DimProduct dp ON
	dp.ProductKey = fis.ProductKey
	INNER JOIN dbo.DimProductSubcategory dps ON
	dps.ProductSubcategoryKey = dp.ProductSubcategoryKey
	INNER JOIN dbo.DimProductCategory dpc ON
	dpc.ProductCategoryKey = dps.ProductCategoryKey

GROUP BY
	dpc.EnglishProductCategoryName,
	dp.EnglishProductName
)

SELECT
	Product,
	Category,
	ROUND(CAST(TotalRevenue AS FLOAT), 2) AS TotalRevenue,
	RANK() OVER (PARTITION BY Category ORDER BY TotalRevenue DESC) AS ProductRankPerCategory

FROM RevenuePerProduct_CTE

/* 24 Bereken maandelijkse groei in omzet per productcategorie. */ 

-- Stap 1: Alle data selecteren: maanden, jaren, productcategorie, omzet

WITH cte_starttable AS (

							SELECT 
								fis.SalesOrderNumber AS SalesOrderNumber,
								DATEPART(YEAR, fis.OrderDate) AS OrderYear,
								DATEPART(MONTH, fis.OrderDate) AS OrderMonth,
								dp.EnglishProductName AS Product,
								dpc.EnglishProductCategoryName AS Category,
								fis.SalesAmount AS SalesAmount
							FROM dbo.factinternetsales fis
								INNER JOIN dbo.DimProduct dp ON
								dp.ProductKey = fis.ProductKey
								INNER JOIN dbo.DimProductSubcategory dps ON
								dps.ProductSubcategoryKey = dp.ProductSubcategoryKey
								INNER JOIN dbo.DimProductCategory dpc ON
								dpc.ProductCategoryKey = dps.ProductCategoryKey),

-- Stap 2: Totale omzet per product, per jaar, per maand vaststellen
cte_omzet_pm_pc AS (
					SELECT 
						Category,
						OrderYear,
						OrderMonth,
						SUM(SalesAmount) AS Revenue
					FROM cte_starttable
					GROUP BY
						Category,
						OrderYear,
						OrderMonth)

-- Stap 3: Vergelijken met maand er voor + vergelijking in berekend veld
SELECT
	Category,
	OrderYear,
	OrderMonth,
	Revenue,
	LEAD(revenue, 1) OVER (PARTITION BY Category ORDER BY OrderYear DESC, OrderMonth DESC) as RevenueMonthBefore,
	  (
        Revenue / LEAD(Revenue, 1) OVER (
            PARTITION BY Category
            ORDER BY OrderYear DESC, OrderMonth DESC
        ) - 1
    ) * 100 AS RevenueChange 

FROM cte_omzet_pm_pc
	
/* 25 Vind de 3 best presterende sales employees per regio.*/ 


-- Stap 1. Starttabel maken en relatie leggen zodat elke order gekoppeld is aan een werknemer en regio
WITH cte_selecttabel AS (SELECT 
						de.EmployeeKey,
						de.FirstName,
						de.LastName,
						dst.SalesTerritoryRegion, 
						frs.SalesOrderNumber,
						frs.SalesAmount

						FROM dbo.DimEmployee de 
							LEFT JOIN dbo.FactResellerSales frs ON
							de.EmployeeKey = frs.EmployeeKey
							LEFT JOIN dbo.DimSalesTerritory dst ON
							dst.SalesTerritoryKey = frs.SalesTerritoryKey),

-- Stap2: Aggregation op region en werknemer

cte_aggregate AS (
					SELECT	
						EmployeeKey,
						FirstName,
						LastName,
						SalesTerritoryRegion,
						SUM(SalesAmount) AS TotalSales
					FROM cte_selecttabel
					GROUP BY
						SalesTerritoryRegion,
						FirstName,
						LastName,
						EmployeeKey),

-- Stap 3: Rank de top verkopers per regio 
		cte_rank AS (SELECT
							EmployeeKey,
							FirstName,
							LastName,
							SalesTerritoryRegion,
							TotalSales,
							DENSE_RANK() OVER (PARTITION BY SalesTerritoryRegion ORDER BY TotalSales DESC) AS SalesRank

					FROM cte_aggregate)

--  Stap 4:Totaaloverzicht maken + filteren op top 3 verkopers
SELECT
	EmployeeKey,
	FirstName,
	LastName,
	SalesTerritoryRegion,
	TotalSales,
	SalesRank

FROM cte_rank 
WHERE 
	TotalSales IS NOT NULL AND
	SalesRank BETWEEN 1 AND 3
ORDER BY 
	SalesTerritoryRegion ASC,
	SalesRank ASC


		

/* 26 Bereken customer lifetime value per klant.*/ 

/* 27 Vind klanten die hun bestedingen maand-op-maand verhogen. */ 

/* 28 Bereken contribution margin per product (als cost data beschikbaar is). */ 

/* 29 Detecteer producten met dalende verkooptrend over 3 maanden. */ 

/* 30 Maak een cohortanalyse van klanten op basis van hun eerste aankoopmaand. */ 











	
			








