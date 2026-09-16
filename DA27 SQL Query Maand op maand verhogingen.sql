/* 27 Vind klanten die hun bestedingen maand-op-maand verhogen. */ 

-- Stap 1: Eerst een tabel maken met de nodige velden
WITH CTE_Select AS (
					SELECT
						CustomerKey,
						DATEPART(YEAR, OrderDate) AS OrderYear,
						DATEPART(Month, OrderDate) AS OrderMonth,
						SUM(SalesAmount) TotalSpent
	
					FROM dbo.FactInternetSales
					GROUP BY 
						CustomerKey,
						DATEPART(YEAR, OrderDate),
						DATEPART(Month, OrderDate)
						),
-- Stap 2: Sorteer de totalebestedingen per klant in de tijd
CTE_TotalSpentNext AS (
						SELECT 
							CustomerKey,
							OrderYear,
							OrderMonth,
							TotalSpent,
						/* Nieuwe kolom die eerst volgende besteding per klant toont. 
						    */
							LEAD(TotalSpent, 1) OVER (PARTITION BY CustomerKey ORDER BY OrderYear, OrderMonth) AS TotalSpentNext
						FROM CTE_Select
						),
-- Stap 3: Ik maak een kolom die een 1 geeft als de volgende order per klant hoger is, die tel ik later per klant
CTE_SpentIncreaseJN AS (

						SELECT 
							*,
							CASE	
								WHEN TotalSpentNext > TotalSpent THEN 1
								ELSE 0 
							END AS SpentIncreaseJN
						FROM CTE_TotalSpentNext),

/* Stap 4: De aggregate naar klant maken. 
De grain was nu per klant, alle orders. Dit moet terug naar 1 klant = 1 regel + per klant de gegevens nu samenvatten.
Hier bij tel ik de vlaggetjes op met SUM. Geen COUNT, die telt een 0 als regel. Ik wil het getal 0 helemaal niet tellen */
CTE_OrderCheck AS (
					SELECT 
						CustomerKEY,
						COUNT(TotalSpentNext) AS OrdersToCheck,
						SUM(SpentIncreaseJN) AS OrdersCheck
					FROM CTE_SpentIncreaseJN
					GROUP BY CustomerKey
					),
/* Stap 5: Aggregatie 1e CTE terugbrengen van 1 klant per order per regel naar 1 klant per regel grain. 
Dit om data te verrijken met de eindset. */
CTE_CustomerSpend AS (
						SELECT
							CustomerKey,
							SUM(TotalSpent) AS TotalSpentCustomer
						FROM CTE_Select
						GROUP BY CustomerKey
						)
/* Stap 6: Filteren door te vergelijken of de orders die zijn geplaatst inderdaad hoger waren dan de vorige. 
		   Alleen klanten met minimaal 2 maanden aan orders. OrderToCheck 0 = 1 maand, dus het moet hoger dan 0 zijn.
		   Dataverrijking door CTE stap 5 te joinen*/

SELECT 
	t1.CustomerKey,
	CAST(t2.TotalSpentCustomer AS DECIMAL(20,2)) AS TotalSpentCustomer
FROM CTE_OrderCheck  t1
	LEFT JOIN CTE_CustomerSpend t2 ON 
	T1.CustomerKey = t2.CustomerKey
WHERE 
	t1.OrdersCheck = t1.OrdersToCheck AND
	t1.OrdersToCheck > 0
ORDER BY TotalSpentCustomer DESC






	






