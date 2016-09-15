Select 
	t.Activity_Type_Copy__c as 'Activity Type'
	   , CASE WHEN t.Assigned_Profile__c LIKE '%ISC%' THEN 'INTERNAL' ELSE 'SALES ASSOCIATE' END as [Desk Role]
	   , count( Distinct (t.id)) as '# of Calls / Activities'
	   , count (Distinct (t.OwnerId)) as '# of Employees'
	   
     
       

FROM [SalesForce Backups].dbo.Task t

Left Join [SalesForce Backups].dbo.Contact c 
       ON t.WhoId = c.Id

Where t.ActivityDate Between '1/1/2015' AND '12/31/2015' AND
       t.Activity_Type_Copy__c IS NOT NULL AND 
       t.Assigned_Profile__c  in ('IBD ISC','RIA ISC','IBD SA','RIA SA') AND 
	   t.Task_Completed_At__c is not null

GROUP BY 
	t.Assigned_Profile__c
	, t.Activity_Type_Copy__c
 
ORDER BY
	t.Assigned_Profile__c
	