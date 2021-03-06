/****** Script for SelectTopNRows command from SSMS  ******/
SELECT  
      e.[Type] AS '2015 Territory Events'
	  , COUNT ( DISTINCT (e.Id)) as '# Events'
      , SUM(e.[Attendees]) AS '# Attendees'
	  , SUM(e.[Attendees])/ COUNT ( DISTINCT (e.Id)) As 'Avg. Attendees / Event'
	  , Format(SUM(e.ARSActualCost),'C', 'en-us') AS '2015 Event Cost, by Type'
	  , Format(SUM(e.ARSActualCost)/SUM(e.[Attendees]),'C', 'en-us') AS '2015 Event Cost Per Attendee'
  FROM [FSCentral].[dbo].[Events] e

  LEFT JOIN FSCentral.dbo.EventStatus es
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