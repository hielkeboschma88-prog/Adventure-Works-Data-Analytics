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