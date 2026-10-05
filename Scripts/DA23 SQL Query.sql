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