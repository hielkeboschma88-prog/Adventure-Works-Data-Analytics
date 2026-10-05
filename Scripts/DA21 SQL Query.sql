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