USE [Honda]
GO

/****** Object:  View [dbo].[Vw_Service_Master]    Script Date: 30-10-2026 17:33:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO












CREATE view [dbo].[Vw_Service_Master]
as

WITH 
SERVICEBASE AS (
select 
Network_Code
,M.Service_Type	
,AMC_Service	
,M.Current_KMs	
,Customer_Name	
,Customer_Mobile	
,Job_Card_Status	
,Frame_Number	
,M.Model_Name	
,Registration_Number	
,Job_Card_Closed_Date	
,Job_Card_Number	
,Labour_Revenue
,Parts_Revenue	
,Lubes_Revenue	
,Accessories_Revenue
,Total_Job_Card_Revenue	
,Job_Card_Created_Date	

,ROW_NUMBER () OVER (PARTITION BY Job_Card_Number ORDER BY Job_Card_Closed_Date DESC ) AS RNK

from
[Stage].[Master Service] M
where M.Job_Card_Status = 'Closed' )

SELECT 
Network_Code
,M.Service_Type	
,AMC_Service	
,M.Current_KMs	
,Customer_Name	
,Customer_Mobile	
,Job_Card_Status	
,Frame_Number	
,M.Model_Name	
,Registration_Number	
,Job_Card_Closed_Date	
,Job_Card_Number	
,Labour_Revenue
,Parts_Revenue	
,Lubes_Revenue	
,Accessories_Revenue
,Total_Job_Card_Revenue	
,Job_Card_Created_Date	
,Claimed_Labour_Amount
,Claimed_FSC_Labour_Amount

FROM SERVICEBASE M
left join [Stage].[Claims_Data_Indore_Master] C
ON M.Job_Card_Number = C.JC AND C.[Status] NOT LIKE 'Cancelled'
LEFT JOIN [Stage].[FSC Claim Data Indore Master] F
ON M.Job_Card_Number = F.JC AND F.status = 'Invoiced'
WHERE M.RNK = 1

GO


