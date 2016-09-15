/****** Script for SelectTopNRows command from SSMS  ******/
SELECT 
   ----   lo.[CreatedDate]
   ----   ,lo.[Id]
   ----   ,lo.[IsDeleted]      
	  ----,lo.[Order_Cost_Center__c]
      --,lo.[OrderDate__c]
      lo.[Ship_Method__c] AS '2015 Lit Orders by Shipping Method'

	  --,oc.SKU_Description__c
	  --,oc.Quantity__c

      --,lo.[Status__c]

	  --,oc.SKU__c
	  ,count(distinct(lo.Id)) AS '# Unique Lit Orders Placed'
	  ,sum(oc.Quantity__c) AS 'Quantity of Lit Ordered'
	  , sum(oc.Quantity__c) / count(distinct(lo.Id)) AS 'Avg. Items / Order'
	  , Format(SUM(oc.Item_Total_Price__c),'C','en-us') AS 'Order Price'
	  
  FROM [SalesForce Backups].[dbo].[literatureOrders__c] lo

  LEFT JOIN [SalesForce Backups].[dbo].Order_Content__c oc
  ON lo.Id = oc.Literature_Order__c

  WHERE lo.IsDeleted = 'False'
	AND lo.Status__c != 'Canceled'
	AND lo.OrderDate__c BETWEEN '01/01/2015' AND '12/31/2015'
	AND (oc.SKU__c LIKE '%KT%' OR oc.SKU__c LIKE '%KIT%"') AND oc.SKU__c NOT LIKE '%bookpen%'

GROUP BY
	lo.[Ship_Method__c]

ORDER BY
	[# Unique Lit Orders Placed] desc, [Quantity of Lit Ordered] 