/* Businessvraag: Breng in kaart in welk land de winstmarge het hoogste is */


WITH analyze_table_cte AS

(SELECT
	dp.EnglishProductName,
	dst.SalesTerritoryCountry,
	fis.TotalProductCost,
	fis.SalesAmount,
	fis.SalesAmount - fis.TotalProductCost AS Margin,
	fis.TaxAmt,
	SUM(fis.SalesAmount) OVER (PARTITION BY dst.SalesTerritoryCountry ORDER BY fis.OrderDate) As RunningSalesTotalPerCountry,
	fis.OrderDate
	

FROM FactInternetSales fis
	INNER JOIN DimProduct dp ON
	fis.ProductKey = dp.ProductKey
	INNER JOIN DimSalesTerritory dst ON
	dst.SalesTerritoryKey = fis.SalesTerritoryKey
)

SELECT
	AVG(TotalProductCost / SalesAmount * 100)  as AvgMarginPct,
	SalesTerritoryCountry

FROM analyze_table_cte 

GROUP BY SalesTerritoryCountry
