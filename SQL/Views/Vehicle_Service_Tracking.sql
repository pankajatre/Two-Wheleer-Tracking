USE [Honda]
GO

/****** Object:  View [dbo].[Vehicle_Service_Tracking]    Script Date: 30-10-2026 17:31:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE VIEW [dbo].[Vehicle_Service_Tracking]
AS

WITH Chassis AS
(
    SELECT Frame_Number
    FROM [Stage].[Master Service]
    WHERE Frame_Number IS NOT NULL
      AND Frame_Number <> 'Unspecified'

    UNION

    SELECT Frame AS Frame_Number
    FROM [Stage].[Org_Master_Sales_Indore]
    WHERE Frame IS NOT NULL
      AND Frame <> 'Unspecified'
),

ServiceRanked AS
(
    SELECT
        Frame_Number,
        Job_Card_Closed_Date,
        Service_Type,
        Customer_Name,
        Customer_Mobile,
        Model_Name,
        Registration_Number,

        MIN(Job_Card_Closed_Date) OVER(PARTITION BY Frame_Number) AS [First Service Date],
        MAX(Job_Card_Closed_Date) OVER(PARTITION BY Frame_Number) AS [Last Service Date],

        SUM
        (
            CASE
                WHEN Service_Type = 'PAID' THEN 1
                ELSE 0
            END
        ) OVER
        (
            PARTITION BY Frame_Number
        ) AS [Total Paid Cnt],

        COUNT(*) OVER
        (
            PARTITION BY Frame_Number
        ) AS [Total Service Cnt],

        ROW_NUMBER() OVER
        (
            PARTITION BY Frame_Number
            ORDER BY Job_Card_Closed_Date DESC
        ) AS RN

    FROM [Stage].[Master Service]
    WHERE Frame_Number IS NOT NULL
      AND Frame_Number <> 'Unspecified'
),

LatestService AS
(
    SELECT
        Frame_Number,
        [First Service Date],
        [Last Service Date],
        [Total Paid Cnt],
        [Total Service Cnt],
        Service_Type AS [Last Service Type],
        Customer_Name,
        Customer_Mobile,
        Model_Name AS [Model_Name_Service],
        Registration_Number
    FROM ServiceRanked
    WHERE RN = 1
),

Sales AS
(
    SELECT
        Frame,
        Permanent_Reg_No,
        Invoice_Date,
        Mobile_Phone,
        Address_Line_1,
        Model_Name,
		Network_Code,
        Customer_First_Name,
        --First_Name,
		Assigned_To_DSE_Name,
        ROW_NUMBER() OVER (PARTITION BY Frame ORDER BY Invoice_Date DESC) AS RN
    FROM [Stage].[Org_Master_Sales_Indore]
	)

SELECT
    C.Frame_Number,

    LS.[First Service Date],
    LS.[Last Service Date],
    LS.[Total Paid Cnt],
    LS.[Total Service Cnt],
    LS.[Last Service Type],

    LS.Customer_Name,
    LS.Customer_Mobile,
    LS.Model_Name_Service,
    LS.Registration_Number,

    S.Permanent_Reg_No,
    S.Invoice_Date,
    S.Mobile_Phone,

    LTRIM(RTRIM(S.Address_Line_1)) AS [Address],
	CM.locality_area AS Colony,
	CT.City_Names as City,
    S.Model_Name AS [Model_Name_Sales],
    S.Customer_First_Name,
    S.Assigned_To_DSE_Name,
	s.Network_Code

FROM Chassis C

LEFT JOIN LatestService LS
    ON C.Frame_Number = LS.Frame_Number

LEFT JOIN Sales S
    ON C.Frame_Number = S.Frame AND S.RN = 1

-- Colony Matching
OUTER APPLY
(
    SELECT TOP 1
        W.locality_area
    FROM dbo.Indore_Ward W
    WHERE W.locality_area IS NOT NULL
      AND LTRIM(RTRIM(W.locality_area)) <> ''
      AND CHARINDEX
      (
          UPPER(LTRIM(RTRIM(W.locality_area))),
          UPPER(ISNULL(S.Address_Line_1, ''))
      ) > 0
    ORDER BY
        LEN(LTRIM(RTRIM(W.locality_area))) DESC,
        W.locality_area
) AS CM

-- City Matching
OUTER APPLY
(
    SELECT TOP 1
       C.City_Names
    FROM [dbo].[City_List] C
    WHERE C.City_Names IS NOT NULL
      AND LTRIM(RTRIM(C.City_Names)) <> ''
      AND CHARINDEX
      (
          UPPER(LTRIM(RTRIM(C.City_Names))),
          UPPER(ISNULL(S.Address_Line_1, ''))
      ) > 0
    ORDER BY
        LEN(LTRIM(RTRIM(C.City_Names))) DESC,
        C.City_Names
) AS CT;

GO


