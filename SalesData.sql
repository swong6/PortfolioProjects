/*
Sale Data Exploration

Skills used: Aggregate Functions, Window Functions, Sub Query, CTEs, XML Path Function, Tableau

*/

SELECT * from [dbo].[sales_data_sample]

-- Sales Volume -- How much has been sold?
SELECT 
	SUM(sales) as Revenue
FROM [dbo].[sales_data_sample]


-- Year-on-Year Sales -- Change of total sales over the years?
SELECT 
	YEAR(orderdate) as OrderYear,
	SUM(sales) as Revenue
FROM [dbo].[sales_data_sample]
GROUP BY YEAR(orderdate)
ORDER BY YEAR(orderdate)

-- Product Line Categories -- What are the sales per product line?
SELECT
	productline as ProductLine,
	SUM(sales) as Revenue
FROM [dbo].[sales_data_sample]
GROUP BY ProductLine
ORDER BY 2 DESC

-- Top Performing Month -- Which month had the best sales and how much was earned?
SELECT
	MONTH_ID as Month,
	SUM(sales) as Revenue,
	COUNT(ordernumber) as OrderCount 
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2003
GROUP BY MONTH_ID
ORDER BY 2 DESC

SELECT
	MONTH_ID as Month,
	SUM(sales) as Revenue,
	COUNT(ordernumber) as OrderCount 
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2004
GROUP BY MONTH_ID
ORDER BY 2 DESC


-- Top Selling Product -- What is the product during the top selling period (November)?
SELECT
	MONTH_ID as Month,
	SUM(sales) as Revenue,
	productline as ProductLine
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2003 and MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 2 DESC

SELECT
	MONTH_ID as Month,
	SUM(sales) as Revenue,
	productline as ProductLine
FROM [dbo].[sales_data_sample]
WHERE YEAR_ID = 2004 and MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 2 DESC

-- The Top Client Using RFM -- Who is our best client?
DROP TABLE IF EXISTS #rfm
;WITH RFM as
(
	SELECT
		CUSTOMERNAME as Client,
		SUM(sales) as TotalSales,
		AVG(sales) as AvgSales,
		COUNT(ordernumber) as OrderCount,
		MAX(orderdate) as LastOrderDate,
		(SELECT MAX(orderdate) from [dbo].[sales_data_sample]) as MaxOrderDate,
		DATEDIFF(DD, MAX(orderdate), (SELECT MAX(orderdate) from [dbo].[sales_data_sample])) as Recency
	FROM [dbo].[sales_data_sample]
	GROUP BY CUSTOMERNAME
),
rfm_calc as
(

	SELECT r.*,
		NTILE(4) OVER (ORDER BY Recency DESC) rfm_recency,
		NTILE(4) OVER (ORDER BY OrderCount) rfm_frequency,
		NTILE(4) OVER (ORDER BY TotalSales) rfm_monetary

	FROM rfm r
)

SELECT 
	c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	CAST(rfm_recency as varchar) + CAST(rfm_frequency as varchar) + CAST(rfm_monetary as varchar) as rfm_cell_string
INTO #rfm
FROM rfm_calc c

SELECT  Client, rfm_recency, rfm_frequency, rfm_monetary,
	CASE 
		WHEN rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'LostCustomers'  
		WHEN rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'Slipping' -- Great past customers who haven't bought in awhile
		WHEN rfm_cell_string in (311, 411, 331) then 'NewCustomers' -- First time buyers 
		WHEN rfm_cell_string in (222, 223, 233, 322) then 'Potential Churners'
		WHEN rfm_cell_string in (323, 333,321, 422, 332, 432) then 'Active' --(Customers who buy often & recently, but at low price points)
		WHEN rfm_cell_string in (433, 434, 443, 444) then 'Loyal'
	END rfm_segment

FROM #rfm

-- Which products are often bundled together?
SELECT DISTINCT ORDERNUMBER, STUFF(
	(SELECT ', ' + PRODUCTCODE
	FROM [dbo].[sales_data_sample] p
	WHERE ORDERNUMBER in 
	(
				SELECT ORDERNUMBER
				FROM (
					SELECT
					ORDERNUMBER, COUNT(*) rn
					FROM [dbo].[sales_data_sample]
					WHERE STATUS = 'Shipped'
					GROUP BY ORDERNUMBER
				)  m
				WHERE rn = 2
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '')  ProductCodes

FROM [dbo].[sales_data_sample] s
ORDER BY 2 DESC