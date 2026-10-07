/* 29. Detecteer producten met een dalende verkooptrend over 3 maanden. */

-- Stap 1: Wat is de grain en welke velden heb ik nodig. Waar staan deze en hoe join ik de tabellen aan elkaar.

/* Ik wil de productnaam, de orderdate om in maanden te meten en de salesamounts hebben om te kunnen bepalen wat er wordt verkocht.
   Er zijn twee fact tabellen die de sales in kaart brengen. Deze data haal ik eerst apart op, dan voeg ik ze samen tot 1 tabel. 
   Dan aggregeer ik de verkoopcijfers per product per maand uit de samengestelde tabel */
WITH cte_select_and_union AS (
SELECT
	fis.SalesOrderNumber,
	fis.ProductKey,
	dp.EnglishProductName,
	fis.OrderDate,
	fis.SalesAmount
	
	FROM dbo.FactInternetSales fis
	LEFT JOIN dbo.DimProduct dp ON
	dp.ProductKey = fis.ProductKey

/* Er zouden geen dezelfde orders in beide fact tables moeten zijn. Voor de zekerheid UNION gebruikt om eventuele duplicates er uit te filteren. */
UNION 

SELECT
	frs.SalesOrderNumber,
	frs.ProductKey,
	dp.EnglishProductName,
	frs.OrderDate,
	frs.SalesAmount
	
	FROM dbo.FactResellerSales frs
	LEFT JOIN dbo.DimProduct dp ON
	dp.ProductKey = frs.ProductKey
),

/* Stap 2: Nieuwe CTE met daarin de aggregate zodat er op maand niveau per product de totale sales berekend worden */
CTE_Sales_pp_pm AS (
	SELECT 
		EnglishProductName,
		DATEPART(YEAR, OrderDate) AS OrderYear,
		DATEPART(MONTH, OrderDate) AS OrderMonth,
		SUM(SalesAmount) AS TotalSales
	FROM cte_select_and_union
	GROUP BY 
		DATEPART(YEAR, OrderDate),
		DATEPART(MONTH, OrderDate),
		EnglishProductName
),

/* Stap 3: Maak tijdsvensters (maand +3) om vergelijkingen op te kunnen maken */

CTE_Sales_Lag AS (
SELECT
	EnglishProductName,
	OrderYear,
	OrderMonth,
	TotalSales,
	/* Ik wil als output de onderste regel van TotalSales. Opknippen per product en logisch sorteren. Sorteren is hier erg belangrijk. 
	Ik sorteer de data zo dat de LAG functie daadwerkelijk de waarde van een vorige maand in de nieuwe kolom toont */
	LAG(TotalSales, 1) OVER (PARTITION BY EnglishProductName ORDER BY OrderYear, OrderMonth) AS TotalSalesLastMonth,
	LAG(TotalSales, 2) OVER (PARTITION BY EnglishProductName ORDER BY OrderYear, OrderMonth) AS TotalSalesLastTwoMonths
	
FROM CTE_Sales_pp_pm
)

/* Stap 4: De benodigde velden uit de CTE ophalen. 
           Vervolgens filteren op de laatste 3 volle maanden (vanaf december 2013, 3 maanden terugkijken en vergelijken.) */
SELECT 
	EnglishProductName,
	OrderYear,
	OrderMonth,
	TotalSales,
	TotalSalesLastMonth,
	TotalSalesLastTwoMonths

FROM CTE_Sales_Lag

/* Ik wil de laatste 3 maanden weten. 2014 januari is niet compleet, dus filter ik van oktober 2013 t/m december 2013.
   Daarnaast vergelijk ik de maand -2 met maand -1 en maand -1 met de huidige maand. 
   De waarden moeten in het verleden hoger liggen, want we willen producten met een dalende omzet inzien */

WHERE
	OrderYear = 2013 AND
	OrderMonth = 12 AND
	TotalSalesLastTwoMonths > TotalSalesLastMonth AND
	TotalSalesLastMonth > TotalSales
ORDER BY EnglishProductName