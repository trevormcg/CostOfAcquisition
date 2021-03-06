/****** Script for SelectTopNRows command from SSMS  ******/
SELECT  
      e.[Type] AS 'EventType'
	  --, e.EventId
	  --, e.Attendees
	  --, e.StartDate
	  , Convert(varchar(10),YEAR(e.StartDate)) + '-' +e.Type as yearEventType
	  , COUNT ( DISTINCT (e.Id)) as '# Events'
      , SUM(e.[Attendees]) AS '# Attendees'
	  , SUM(e.[Attendees])/ COUNT ( DISTINCT (e.Id)) As 'Avg. Attendees / Event'
	  , Format(SUM(e.ARSActualCost),'C', 'en-us') AS '2015 Event Cost, by Type'
	  , Format(SUM(e.ARSActualCost)/NULLIF(SUM(e.[Attendees]),0),'C', 'en-us') AS '2015 Event Cost Per Attendee'
  FROM [FSCentral].[dbo].[Events] e

  LEFT JOIN FSCentral.dbo.Enum_EventStatus es
  ON e.Status = es.Id

  Where
	e.[StartDate] > '1/1/2015'
	AND ((e.Type in ('Conference/Seminar','Conference/Seminar Entertainment') AND ((es.Name = 'Planning' and e.Attendees > 0) Or es.Name !='Planning'))
	OR ( e.Type ='Business Development'	And (es.Name = 'Completed' or 
		(es.Name in ('Confirmed','Approved','In Progress') And e.Attendees > 0))))
	--AND e.Status in (6,9) ---Completed or Confirmed
	
GROUP BY 
Year(e.StartDate), e.[Type]