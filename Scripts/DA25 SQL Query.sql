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

