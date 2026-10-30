USE [Honda]
GO

/****** Object:  View [dbo].[Service Summary]    Script Date: 30-10-2026 17:30:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




--select top 10 * from  Vw_Service_Master

ALTER VIEW [dbo].[Service Summary]
AS

WITH ServiceSummary AS
(
    SELECT
        Frame_Number,

        MIN(Job_Card_Closed_Date) AS [First Service Date],

        MAX(Job_Card_Closed_Date) AS [Last Service Date],

        SUM(
            CASE 
                WHEN Service_Type = 'PAID' THEN 1 
                ELSE 0 
            END
        ) AS [Total Paid Cnt],

        COUNT(*) AS [Total Service Cnt]

    FROM [Stage].[Master Service]

    GROUP BY
        Frame_Number
),

LastService AS
(
    SELECT
        Frame_Number,
        Service_Type,
       -- Customer_Name,
       -- Customer_Mobile,
       -- Model_Name,
       -- Registration_Number,
        Job_Card_Closed_Date,

        ROW_NUMBER() OVER
        (
            PARTITION BY Frame_Number
            ORDER BY Job_Card_Closed_Date DESC
        ) AS RN

    FROM [Stage].[Master Service]
)

SELECT
    S.Frame_Number,
	S.[First Service Date],
	S.[Last Service Date],
	S.[Total Paid Cnt],
	S.[Total Service Cnt],
	L.Service_Type
	--L.Customer_Name,
	--L.Customer_Mobile,
    --L.Model_Name,
	--L.Registration_Number

FROM ServiceSummary S

LEFT JOIN LastService L
    ON S.Frame_Number = L.Frame_Number
    AND L.RN = 1;
GO


