USE [Honda]
GO

/****** Object:  View [dbo].[vw_Honda_Enquiry_Indore]    Script Date: 30-10-2026 17:32:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE   VIEW [dbo].[vw_Honda_Enquiry_Indore]
AS

WITH EnquiryBase AS
(
SELECT 
Network_Code,
Network_Type,
Model_Category,
Model_Variant,
AA.[Model_Name],
Model_Code,
[Enquiry_Number],
[Dealer_Sales_Executive_Name],
AA.[Closure_Remarks],
AA.[Enquiry_Source],
AA.[Purchase_type],
AA.[Enquiry_Type],
[Enquiry_Sales_Stage],
[Customer_First_Name],
[Customer_Last_Name],
[Mobile_No],
[Follow_up_Remark],
[Enquiry_Created_Date] , 
[Description],
B.Financier FROM (
SELECT * FROM (
SELECT
[Model_Name],
[Enquiry_Number],
[Dealer_Sales_Executive_Name],
[Closure_Remarks],
[Enquiry_Source],
[Purchase_type],
[Enquiry_Type],
[Enquiry_Sales_Stage],
[Customer_First_Name],
[Customer_Last_Name],
[Mobile_No],
[Next_follow_up_date],
[Current_follow_up_date],
[Follow_up_Remark],
[Enquiry_Created_Date] ,
ROW_NUMBER() OVER (PARTITION BY ENQUIRY_NUMBER ORDER BY [Enquiry_Created_Date] DESC) AS RNK   
from [Sales].[Honda_Enquiry_Detailed_Master] )A WHERE RNK = 1 ) AS AA

LEFT JOIN [Stage].[Honda_Enquiry_Master_Indore] B
ON AA.Enquiry_Number = B.Enquiry  
WHERE [Mobile_No] IS NOT NULL),

PreviousEnquiry AS
(
    SELECT
        *,

        LAG([Mobile_No]) OVER
        (
            ORDER BY
                [Mobile_No],
                [Enquiry_Created_Date],
                [Enquiry_Number]
        ) AS [Previous_Mobile_Phone],

        LAG([Enquiry_Created_Date]) OVER
        (
            ORDER BY
                [Mobile_No],
                [Enquiry_Created_Date],
                [Enquiry_Number]
        ) AS [Previous_Created_Date]

    FROM EnquiryBase
)

SELECT
    [Mobile_No],
    [Enquiry_Created_Date],  
    [Enquiry_Number] AS [Enquiry],
	[Customer_First_Name] AS [First_Name],
	[Customer_Last_Name] AS [Last_Name],
    [Enquiry_Sales_Stage] as [Sales_Cycle],
	[Dealer_Sales_Executive_Name] as [Assigned_To_DSE_Name],
    [Purchase_Type],
    [Model_Name],
    [Description],
    [Financier],
    [Enquiry_Source],
    [Model_Code],
    [Network_Code],
    [Closure_Remarks],
    [Network_Type],
    [Model_Category],
    [Model_Variant],
    [Enquiry_Type],

    CASE
        WHEN [Previous_Mobile_Phone] IS NULL
            THEN 'New'

        WHEN [Mobile_No] <> [Previous_Mobile_Phone]
            THEN 'New'

        WHEN DATEDIFF
             (
                 DAY,
                 [Previous_Created_Date],
                 [Enquiry_Created_Date]
             ) > 30
            THEN 'New'

        ELSE 'Repeat'
    END AS [Enquiry_Status]

FROM PreviousEnquiry;
GO


