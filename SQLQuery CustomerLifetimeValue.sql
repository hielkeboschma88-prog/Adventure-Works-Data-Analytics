/* 26 Bereken customer lifetime value per klant.*/ 

-- Formule: CLV = gemiddelde aankoopwaarde X aankoopfrequentie X klantduur x winstmarge


-- Stap 1. Een startselectie van velden maken en samenvoegen tot 1 tabel om mee te werken. Ik gebruik alleen internetsales, de resellersales is niet te herleiden naar een klant. Hierop kan later een losse analyse worden gemaakt ter vergelijking.
WITH cte_starttable AS (
		SELECT
			SalesOrderNumber,
			SalesOrderLineNumber,
			CustomerKey,
			OrderDate,
			TotalProductCost,
			SalesAmount,
			/* Input veld voor CLV */
			(SalesAmount - TotalProductCost * 1.00) / SalesAmount  AS ProfitMargin

		FROM dbo.FactInternetSales),

CTE_aggr_customer AS (
		SELECT
			SUM(SalesAmount) as TotalSalesPerCustomer,
			/* Input veld voor CLV. DISTINCT op SalesOrderNumber want we willen het aantal ORDERS, niet het aantal producten */
			COUNT(DISTINCT SalesOrderNumber) AS PurchaseFrequency,
			/* Input veld voor CLV. Pak de omzet en deel dit door het aantal Orders*/
			SUM(SalesAmount) / COUNT(DISTINCT SalesOrderNumber) AS AvgPurchase,
			MIN(OrderDate) As CustomerStart,
			MAX(OrderDate) AS CustomerEnd,
			/* Input veld voor CLV. Gekozen om in dagen te meten en dan te delen door 365.25. Dan heb je een nauwkeuriger beeld van in losse jaren*/
			(DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate))) / 365.25 AS CustomerDurationYear,
			/* Input veld voor CLV. Pak de winst en deel dit door het verkoopbedrag. */
			SUM((SalesAmount - TotalProductCost) * 1.00) / SUM(SalesAmount) AS AvgProfitMargin,
			CustomerKey

			FROM cte_starttable
			GROUP BY CustomerKey),

CTE_CLV_calc AS (

		SELECT 
			CustomerKey,
			TotalSalesPerCustomer,
			PurchaseFrequency,
			AvgPurchase,
			CustomerStart,
			CustomerEnd,
			CustomerDurationYear,
			AvgProfitMargin,
			/* Berekening Eindresultaat via CLV = gemiddelde aankoopwaarde X aankoopfrequentie X klantduur x winstmarge */
			AvgPurchase * PurchaseFrequency * CustomerDurationYear * AvgProfitMargin AS CLV
		FROM CTE_aggr_customer)

SELECT 
	CustomerKey,
	CAST(AvgPurchase AS DECIMAL(20,2)) AS AvgPurchase,
	PurchaseFrequency,
	CAST(CustomerDurationYear AS DECIMAL (20,2)) AS CustomerDurationYear,
	CAST(AvgProfitMargin AS DECIMAL (20,2)) AS ProfitMargin,
	CAST(CLV AS DECIMAL (20,2)) AS CLV
FROM CTE_CLV_calc
ORDER BY CLV DESC
	

	
