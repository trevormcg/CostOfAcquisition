--DECLARING AND SETTING Variables for Sales Desk Assumptions

DECLARE @SalaryAssumption as float, @TimeOpportunityMinutes as float, @AdminCallTime as float , 
				 @VMCallTime as float, @CallTime as float, @EmailTime as float, @InboundTime as float,
				 @OutboundTime as float, @SPTime as float, @WPTime as float, @NumDeskMembers as float

SET @SalaryAssumption = 80000; SET @InboundTime = 5; SET @OutboundTime = 10; SET @SPTime = 25; SET @WPTime = 30
SET @TimeOpportunityMinutes = 120000; SET @AdminCallTime = 3; SET @CallTime = 5; SET @EmailTime = 5; SET @VMCallTime = 3
SET @NumDeskMembers = 35

--DECLARING AND SETTING Variables for RSD Assumptions
DECLARE @RSD_SalaryAssumption as FLOAT, @RSD_RatePerMinute as FLOAT, @RSD_TimePerActivity as FLOAT, @RSD_TimeCost as Float, @RSD_TerrEvent_TimeAllocation as Float, @RSD_TerrEvent_TimeCost as Float

SET @RSD_SalaryAssumption = 350000; SET @RSD_RatePerMinute = @RSD_SalaryAssumption/@TimeOpportunityMinutes; SET @RSD_TimePerActivity = 60; SET @RSD_TerrEvent_TimeAllocation = 90
SET @RSD_TimeCost = @RSD_TimePerActivity*@RSD_RatePerMinute; SET @RSD_TerrEvent_TimeCost=@RSD_TerrEvent_TimeAllocation*@RSD_RatePerMinute

--DECLARING AND SETTING Variables for Portfolio Specialist Assumptions
DECLARE @PS_Salary_Assumptions as FLOAT, @PS_RatePerMinute as FLOAT, @PS_TimeCost as Float, @PS_TerrEvent_TimeAllocation as Float, @PS_TerrEvent_TimeCost as Float

SET @PS_Salary_Assumptions = 300000; SET @PS_RatePerMinute = @PS_Salary_Assumptions/@TimeOpportunityMinutes; SET @PS_TerrEvent_TimeAllocation = 90
SET @PS_TimeCost = @PS_TerrEvent_TimeAllocation*@PS_RatePerMinute


IF OBJECT_ID('tempdb..#TimeByActivity') IS NOT NULL
	DROP TABLE #TimeByActivity

SELECT Distinct
	t.Activity_Type_Copy__c
	, Case When t.Activity_Type_Copy__c = 'Admin Call' Then @AdminCallTime
				When t.Activity_Type_Copy__c = 'Call' Then @CallTime
				When t.Activity_Type_Copy__c = 'Email' Then @EmailTime
				When t.Activity_Type_Copy__c = 'Left Voicemail/Message with Assistant' then @VMCallTime
				When t.Activity_Type_Copy__c = 'Inbound' Then @InboundTime
				When t.Activity_Type_Copy__c = 'Outbound' Then @OutboundTime
				When t. Activity_Type_Copy__c = 'Sales Presentation' Then @SPTime
				When t.Activity_Type_Copy__c = 'Web Presentation' Then @WPTime
				Else 0 END AS [Call_TimeCost]
	, Count( t.Id) as [NumberOfActivities]
	, Case When t.Activity_Type_Copy__c = 'Admin Call' Then @AdminCallTime *Count(t.Id)
				When t.Activity_Type_Copy__c = 'Call' Then @CallTime *Count(t.Id)
				When t.Activity_Type_Copy__c = 'Email' Then @EmailTime *Count(t.Id)
				When t.Activity_Type_Copy__c = 'Left Voicemail/Message with Assistant' then @VMCallTime *Count(t.Id)
				When t.Activity_Type_Copy__c = 'Inbound' Then @InboundTime *Count(t.Id)
				When t.Activity_Type_Copy__c = 'Outbound' Then @OutboundTime *Count(t.Id)
				When t. Activity_Type_Copy__c = 'Sales Presentation' Then @SPTime *Count(t.Id)
				When t.Activity_Type_Copy__c = 'Web Presentation' Then @WPTime *Count(t.Id)
				Else 0 END AS [TotalTimeSpentOnActivities]
	, Case When t.Activity_Type_Copy__c = 'Admin Call' Then (@AdminCallTime *Count(t.Id))/@NumDeskMembers
				When t.Activity_Type_Copy__c = 'Call' Then (@CallTime *Count(t.Id))/@NumDeskMembers
				When t.Activity_Type_Copy__c = 'Email' Then (@EmailTime *Count(t.Id))/@NumDeskMembers
				When t.Activity_Type_Copy__c = 'Left Voicemail/Message with Assistant' then (@VMCallTime *Count(t.Id))/@NumDeskMembers
				When t.Activity_Type_Copy__c = 'Inbound' Then (@InboundTime *Count(t.Id))/@NumDeskMembers
				When t.Activity_Type_Copy__c = 'Outbound' Then (@OutboundTime *Count(t.Id))/@NumDeskMembers
				When t. Activity_Type_Copy__c = 'Sales Presentation' Then (@SPTime *Count(t.Id))/@NumDeskMembers
				When t.Activity_Type_Copy__c = 'Web Presentation' Then (@WPTime *Count(t.Id))/@NumDeskMembers
				Else 0 END AS [AvgIndividualTimeSpentOnActivities]


INTO
	#TimeByActivity

FROM [SalesForce Backups].dbo.Task t

Where t.ActivityDate Between '1/1/2015' AND '1/1/2016'
	AND t.Activity_Type_Copy__c IN ('Admin Call','Left Voicemail/Message with Assistant','Call','Email','Inbound','Outbound','Sales Presentation','Web Presentation') AND 
	t.Assigned_Profile__c  in ('IBD ISC','RIA ISC','IBD SA','RIA SA') AND 
	t.Task_Completed_At__c is not null


GROUP BY t.Activity_Type_Copy__c

DECLARE @TotalTimeSpent as INT
SET @TotalTimeSpent = (SELECT SUM(x.AvgIndividualTimeSpentOnActivities) FROM #TimeByActivity x)


IF OBJECT_ID('tempdb..#CallCost') IS NOT NULL
	DROP TABLE #CallCost


Select 
	t.Activity_Type_Copy__c as 'Activity Type'
	   --, CASE WHEN t.Assigned_Profile__c LIKE '%ISC%' THEN 'INTERNAL' ELSE 'SALES ASSOCIATE' END as [Desk Role]
	   , count( Distinct (t.id)) as '# of Calls / Activity'
	   , count (Distinct (t.OwnerId)) as '# of Employees'
	   , min(tba.Call_TimeCost) as [TimeSpentPerActivity]
	  , count( Distinct (t.id)) * MIN(tba.Call_TimeCost) as [TotalTimeSpentPerActivity]
	  , (count( Distinct (t.id)) * MIN(tba.Call_TimeCost)) / Max(@NumDeskMembers) AS [TimeSpentPerIndividual]
	  ,  count( Distinct (t.id)) / @NumDeskMembers as [NumActivitiesPerIndividual]
	  , (MIN(tba.AvgIndividualTimeSpentOnActivities) / MAX(@TotalTimeSpent))*Max(@SalaryAssumption)  as [TotalCostSpentPerIndividualByActivity]
	  ,((MIN(tba.AvgIndividualTimeSpentOnActivities) / MAX(@TotalTimeSpent))*Max(@SalaryAssumption) )/(count( Distinct (t.id)) / @NumDeskMembers)  as [CostPerActivity_BasedOn_TimeSpent]

INTO
		#CallCost

FROM [SalesForce Backups].dbo.Task t

Left Join [SalesForce Backups].dbo.Contact c 
       ON t.WhoId = c.Id

LEFT JOIN #TimeByActivity tba
		ON t.Activity_Type_Copy__c = tba.Activity_Type_Copy__c

Where t.ActivityDate Between '1/1/2015' AND '12/31/2015' AND
       t.Activity_Type_Copy__c IN ('Admin Call','Left Voicemail/Message with Assistant','Call','Email','Inbound','Outbound','Sales Presentation','Web Presentation') AND
       t.Assigned_Profile__c  in ('IBD ISC','RIA ISC','IBD SA','RIA SA') AND 
	   t.Task_Completed_At__c is not null

GROUP BY 
	t.Activity_Type_Copy__c


--Currently this section (BizDev and Conferences) is pulling data SFDC cost data to inform the Unit Cost for those activity types, but we know that data is not the most accurate.
--We need to identify a better, more accurate data source that is complete. As of 05/26/2016 FS360's Invoice allocation system does not allow for simple relationship creation between an invoice
--and an event [also, no one is currently creating the relationships]. Need to figure out a solution for the data and process to ensure that we develop a solution appropriately.
	IF OBJECT_ID('tempdb..#BDG_Conf_EventCosts') IS NOT NULL
	DROP TABLE #BDG_Conf_EventCosts

SELECT  
    --  Case WHEN e.[Type] in ('Conference/Seminar','Conference/Seminar Entertainment') Then 'Conference/Seminar'
				--ELSE 'Business Development' END  AS [BDG_Conf_EventType]
		e.[Type] AS [BDG_Conf_EventType]
	  --, Convert(varchar(10),YEAR(e.StartDate)) + '-' +e.Type AS [BDG_Conf_YearEventType]
	  , COUNT ( DISTINCT (e.Id)) as [BDG_Conf_NumEvents]
      , SUM(e.[Attendees]) AS [BDG_Conf_NumAttendees]
	  , SUM(e.[Attendees])/ COUNT ( DISTINCT (e.Id)) As [BDG_Conf_Avg_Attendees_Per_Event]
	  , SUM(e.ARSActualCost) AS [BDG_Conf_Event_Cost_By_Type]
	  , SUM(e.ARSActualCost)/NULLIF(SUM(e.[Attendees]),0) AS [BDG_Conf_Avg_Cost_Per_Attendee]
	  , Cast(SUM(e.ARSActualCost)/NULLIF(Count(e.[Id]),0) as float) AS [BDG_Conf_Avg_Cost_Per_Event_Type]
	  --, Format(SUM(e.ARSActualCost),'C', 'en-us') AS [BDG_Conf_Event_Cost_By_Type]
	  --, Format(SUM(e.ARSActualCost)/NULLIF(SUM(e.[Attendees]),0),'C', 'en-us') AS [BDG_Conf_Avg_Cost_Per_Attendee]
	  --, Format(SUM(e.ARSActualCost)/NULLIF(Count(e.[Id]),0),'C', 'en-us') AS [BDG_Conf_Avg_Cost_Per_Event_Type]

  INTO 
	#BDG_Conf_EventCosts

  FROM [FSCentral].[dbo].[Events] e

  LEFT JOIN FSCentral.dbo.Enum_EventStatus es
  ON e.Status = es.Id

  Where
	e.[StartDate] Between '1/1/2015' and '1/1/2016'
	AND ((e.Type in ('Conference/Seminar','Conference/Seminar Entertainment') AND ((es.Name = 'Planning' and e.Attendees > 0) Or es.Name !='Planning'))
	OR ( e.Type ='Business Development'	And (es.Name = 'Completed' or 
		(es.Name in ('Confirmed','Approved','In Progress') And e.Attendees > 0))))
	--AND e.Status in (6,9) ---Completed or Confirmed

	GROUP BY
		--Case WHEN e.[Type] in ('Conference/Seminar','Conference/Seminar Entertainment') Then 'Conference/Seminar'
		--		ELSE 'Business Development' END
		e.[Type]






IF OBJECT_ID('tempdb..#TerritoryLeveragedEventCosts') IS NOT NULL
	DROP TABLE #TerritoryLeveragedEventCosts

SELECT  
      e.[Type] AS '2015 Territory Events'
	  , COUNT ( DISTINCT (e.Id)) as '# Events'
      , SUM(e.[Attendees]) AS '# Attendees'
	  , SUM(e.[Attendees])/ COUNT ( DISTINCT (e.Id)) As 'Avg. Attendees / Event'
	  , SUM(e.ARSActualCost) AS '2015 Event Cost, by Type'
	  , CAST(SUM(e.ARSActualCost)/SUM(e.[Attendees]) as float) AS '2015 Event Cost Per Attendee'
	  , @RSD_TerrEvent_TimeCost AS [RSDTimeCost]
	  , CASE WHEN e.[Type] = 'Assisted Roadshow' THEN @PS_TimeCost ELSE 0 END AS [PortfolioSpecialistTimeCost]
	  , CAST(SUM(e.ARSActualCost)/SUM(e.[Attendees]) as float) +@RSD_TerrEvent_TimeCost  + CASE WHEN e.[Type] = 'Assisted Roadshow' THEN @PS_TimeCost ELSE 0 END AS [TotalCost] 

	  --, Format(SUM(e.ARSActualCost),'C', 'en-us') AS '2015 Event Cost, by Type'
	  --, Format(SUM(e.ARSActualCost)/SUM(e.[Attendees]),'C', 'en-us') AS '2015 Event Cost Per Attendee'

  INTO 
		#TerritoryLeveragedEventCosts

  FROM [FSCentral].[dbo].[Events] e

  LEFT JOIN FSCentral.dbo.enum_EventStatus es
  ON e.Status = es.Id

  Where
	year(e.[StartDate]) >= 2015 AND year(e.[StartDate]) < 2016
	AND e.Type in ('Assisted Roadshow','Investor University', 'Unassisted Roadshow')
	AND es.Name = 'Completed'
	--And (es.Name = 'Completed' or 
	--	(es.Name in ('Confirmed','Approved','In Progress') And e.Attendees > 0))
	--AND e.Status in (6,9) ---Completed or Confirmed
	
GROUP BY 
	e.Type






IF OBJECT_ID('tempdb..#RSDMeetingCosts') IS NOT NULL
	DROP TABLE #RSDMeetingCosts

Select
	CASE WHEN e.Activity_Type_Copy__c !='NULL' THEN 'Meeting' END as 'ActivityType'
	, COunt(e.Id) as 'NumEvents'
	, sum(e.WhoCount) as 'NumAttendees'
	, sum(e.WhoCount) / Cast(COunt(e.Id) As float) AS 'Avg_AttendeesPerEvent'
	, MAX(@RSD_TimeCost) / (sum(e.WhoCount) / Cast(COunt(e.Id) AS float)) AS 'AvgCostPerAttendee'

INTO
		#RSDMeetingCosts

FROM [SalesForce Backups].[dbo].[Event] e

LEFT JOIN [SalesForce Backups].[dbo].[User] u
	on e.OwnerId = u.Id

LEFT JOIN [SalesForce Backups].[dbo].[Contact] c
	ON e.WhoId = c.Id


Where e.ActivityDate Between '1/1/2015' AND '1/1/2016' AND
       e.Activity_Type_Copy__c NOT IN ('FS Internal Call/Event','Office Day','Personal','Travel') AND
       e.AccountId NOT LIKE '001E000000Duekn%' AND
	   e.Assigned_Profile__c = 'IBD Wholesaler'AND
	   e.Cancelled__c = 'False'

Group By 
		CASE WHEN e.Activity_Type_Copy__c !='NULL' THEN 'Meeting' END





DECLARE @LitOrderCost as DECIMAL(20,2), @LitOrderActvity as varchar(30)
SET @LitOrderCost = 34.01; SET @LitOrderActvity = 'LitOrder'


IF OBJECT_ID('tempdb..#AllCostTable') IS NOT NULL
	DROP TABLE #AllCostTable

SELECT cc.[Activity Type] as [ActivityType], cc.CostPerActivity_BasedOn_TimeSpent as [UnitCost_In_$$] INTO #AllCostTable FROM #CallCost cc

UNION ALL

SELECT bce.BDG_Conf_EventType, bce.BDG_Conf_Avg_Cost_Per_Attendee FROM  #BDG_Conf_EventCosts bce

UNION ALL

SELECT tlec.[2015 Territory Events], tlec.TotalCost FROM #TerritoryLeveragedEventCosts tlec

UNION ALL

SELECT rmc.ActivityType, rmc.AvgCostPerAttendee FROM #RSDMeetingCosts rmc

UNION ALL

SELECT @LitOrderActvity, @LitOrderCost

SELECT ROW_NUMBER() OVER(ORDER BY act.UnitCost_In_$$ DESC) AS [ID],act.ActivityType, act.UnitCost_In_$$ FROM #AllCostTable act
ORDER BY act.[UnitCost_In_$$] desc
