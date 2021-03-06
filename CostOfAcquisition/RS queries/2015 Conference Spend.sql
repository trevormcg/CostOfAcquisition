/****** Script for SelectTopNRows command from SSMS  ******/
SELECT 
	  i.Id
	  , i.Vendor
	  , CASE WHEN LEN(i.Vendor) - LEN(Replace(i.Vendor, ' ', '')) >=2 THEN LEFT(i.Vendor, P2.Pos-1)
	  ELSE i.Vendor END AS 'Short Vendor Name'
	  , i.Description
	  , i.AmountApplied
      --,FORMAT(SUM(i.[AmountApplied]), 'C', 'en-us') AS 'Total 2015 Sponsorship'

  FROM [FSCentral].[dbo].[Invoices] i 
	cross apply (select (charindex(' ', i.Vendor))) as P1(Pos)
	cross apply (select (charindex(' ', i.Vendor, P1.Pos+1))) as P2(Pos)


  WHERE
	YEAR(i.[CreatedOn]) >= 2015 AND YEAR(i.[CreatedOn]) < 2016
	AND i.IsDeleted = 0
	AND i.PaidDate IS NOT NULL

--GROUP BY
--	i.Vendor