/****** Script for SelectTopNRows command from SSMS  ******/
SELECT  
      e.[Type] AS '2015 Conference Events'
	  , COUNT ( DISTINCT (e.Id)) as '# Events'
      , SUM(e.[Attendees]) AS '# Attendees'
  FROM [FSCentral].[dbo].[Events] e

  LEFT JOIN FSCentral.dbo.EventStatus es
  ON e.Status = es.Id

  Where
	year(e.[StartDate]) >= 2015 AND year(e.[StartDate]) < 2016
	AND e.Type LIKE '%Conference%'
	AND e.Type NOT LIKE '%Webinar%'
	AND e.Name NOT LIKE '%test%'
	AND ((es.Name = 'Planning' and e.Attendees > 0)
	OR es.Name != 'Planning')
	--AND e.Status in (6,9) ---Completed or Confirmed

GROUP BY 
	e.Type