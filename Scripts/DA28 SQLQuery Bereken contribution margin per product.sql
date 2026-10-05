/* 28 Bereken contribution margin per product (als cost data beschikbaar is). */ 

-- definitie contribution margin: In deze opdracht is dit het verschil tussen de verkoopprijs en de inkoopprijs

/* Stap 1: Informatie verzamelen. Er zijn twee fact tables. 
Productkey, inkoopprijs en verkoopprijs is beschikbaar in beide tabellen. 
Grain alleen anders. 
Ik kies er voor om per tabel in een aparte CTE een samenvatting te maken en als de grain gelijk is voeg ik ze samen. */

WITH CTE_startset AS (
						SELECT 
							ProductKey,
							SUM(TotalProductCost) AS TotalCostPerProduct,
							SUM(SalesAmount) AS TotalRevenuePerProduct
							FROM dbo.FactInternetSales
							GROUP BY ProductKey

							 UNION ALL 

						SELECT 
							ProductKey,
							SUM(TotalProductCost) AS TotalCostPerProduct,
							SUM(SalesAmount) AS TotalRevenuePerProduct
							FROM dbo.FactResellerSales
							GROUP BY ProductKey)

/* Stap 2: De resultaten samenvoegen. Totale inkoopprijs en omzet per product is nu in 1 tabel. 
Getest met ProductKey 214 of het op tellen van de tabellen goed gaat via testquery (

WITH cte_test AS (SELECT 
							ProductKey,
							SUM(TotalProductCost) AS TotalCostPerProduct,
							SUM(SalesAmount) AS TotalRevenuePerProduct
							FROM dbo.FactInternetSales
							GROUP BY ProductKey

							 UNION ALL 

						SELECT 
							ProductKey,
							SUM(TotalProductCost) AS TotalCostPerProduct,
							SUM(SalesAmount) AS TotalRevenuePerProduct
							FROM dbo.FactResellerSales
							GROUP BY ProductKey)

							SELECT *
							FROM cte_test
							WHERE productkey = 214) Test klopt. Er moet 55k uitkomen en dit is ook zo */

SELECT 
	ProductKey,
	SUM(TotalCostPerProduct) TotalCostPerProductCombined,
	SUM(TotalRevenuePerProduct) AS TotalRevenuePerProduct
	
FROM CTE_startset
GROUP BY ProductKey
ORDER BY productkey ASC


