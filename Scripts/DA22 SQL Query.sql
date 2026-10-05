/* 22 Bereken churn: klanten zonder order in de laatste 12 maanden. 
Een actieve klant is iemand die binnen 1 jaar nog een bestelling heeft gedaan*/ 

-- Aantal klanten dat weggaat / aantal klanten begin periode * 100 = churn

-- stap 1: Bereken hoeveel klanten er waren in 2013

CREATE VIEW churn AS

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