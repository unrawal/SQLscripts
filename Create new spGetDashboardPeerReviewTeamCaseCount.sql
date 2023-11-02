--Create a new Stored procedure for PeerReviewTeamCaseCount tile dashboard grid - spGetDashboardPeerReviewTeamCaseCount.sql--

USE [CMSPRO_ZEUS]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [Entity].[spGetDashboardPeerReviewTeamCaseCount]
AS
BEGIN
                -- Get Dashboard items
                WITH NextActionDue
                AS (
                            SELECT EntityId
                                        ,MIN(DueDate) AS NextActionDue
                            FROM [Diary].[Diary]
                            WHERE CompletedDate IS NULL
                            GROUP BY EntityId
                            )

				
                SELECT DISTINCT e.EntityId,e.StatusId
                            ,e.AdvisorOfConcern               AS Advisor
                            ,e.Reference   AS Reference
                            ,cp.[Name]                   AS CasePriority
                            ,ISNULL(cp.CasePriorityId,99999) AS casePriorityId --set a rediciously number so its sorted last
                            ,ct.[Name]                    AS Complexity
                            ,ao.[Name]                  AS AssessmentOutcome
                            ,vwCA.NumOfDays     AS Age
                            ,e.SchemeName
                            ,i.NAME                                   AS IFAName
                            ,u1.UserId                   AS CHAllocatedTo
                            ,u1.DisplayName         AS CHAllocatedToFullName
                            ,u2.UserId                   AS QCAllocatedTo
                            ,u2.DisplayName         AS QCAllocatedToFullName
                            ,u3.UserId                   AS QAAllocatedTo
                            ,u3.DisplayName         AS QAAllocatedToFullName
                            ,e.StatusId
                            ,s.NAME                                  AS [Status]
                            ,RTRIM(LTRIM(ecn.FirstName)) + ' ' + RTRIM(LTRIM(ecn.LastName)) AS ClientName
                            ,s.IsComplete
                            ,nad.NextActionDue
                        
                            ,CASE 
                                        WHEN COALESCE(nad.NextActionDue, GETDATE()) < GETDATE()
                                                    THEN 1
                                        ELSE 0
                                        END 'Overdue'
                            ,e.LastUpdatedDate AS LastModified
                            ,ISNULL(vwSA.SLAage,0)   AS CaseRAG
                FROM [Entity].[Entity] e
                LEFT JOIN [Entity].[IFA] i ON e.IFAId = i.IFAId
                LEFT JOIN [Entity].[Allocation] a1 ON e.EntityId = a1.EntityId
                            AND a1.DeallocatedDate IS NULL
                LEFT JOIN [User].[User] u1 ON a1.AllocatedTo = u1.UserId
                LEFT JOIN [Entity].[Allocation] A2 ON e.EntityId = A2.EntityId
                            AND A2.DeallocatedDate IS NULL
                            AND a2.AllocationTypeId = 2-- @QCAllocationTypeId
                LEFT JOIN [User].[User] u2 ON A2.AllocatedTo = u2.UserId
                LEFT JOIN [Entity].[Allocation] A3 ON e.EntityId = A3.EntityId
                            AND A3.DeallocatedDate IS NULL
                            AND a3.AllocationTypeId = 3 -- @QAAllocationTypeId
                LEFT JOIN [User].[User] u3 ON A3.AllocatedTo = u3.UserId
                 JOIN [Status].[Status] S ON e.StatusId = S.StatusId
				LEFT JOIN ( SELECT EntityId
                             ,MIN(DueDate) AS NextActionDue
                            FROM [Diary].[Diary]
                            WHERE CompletedDate IS NULL
                            GROUP BY EntityId ) nad ON e.EntityId = nad.EntityId
                LEFT JOIN [Entity].CasePriority cp on cp.CasePriorityId = e.CasePriorityId
                LEFT JOIN [Entity].ComplexityType ct on ct.ComplexityTypeId = e.ComplexityTypeId
                LEFT JOIN  [Entity].[AssessmentOutcomeType] ao on ao.AssessmentOutcomeTypeId = e.AssessmentOutcomeTypeId
                 JOIN [Entity].vwCaseAge vwCA ON vwCA.entityid = e.EntityId
                LEFT JOIN [Entity].vwSLA vwSA ON vwSA.EntityId = e.EntityId
                LEFT JOIN [Entity].[EntityCustomerNumbered] ecn ON e.EntityId = ecn.EntityId AND ecn.CustomerNumber = 1
                WHERE e.IsVisible = 1
                            AND s.IsComplete = 0
                            AND (
                                        e.CaseTypeId = 1 --@caseTypeId
                                        AND 
                                        (
                                                                EXISTS(
                                                                            SELECT * 
                                                                                        FROM [Entity].Allocation saa
                                                                                        INNER JOIN [User].[UserTeam] sut 
                                                                                                    ON sut.UserId = saa.AllocatedTo
                                                                            WHERE 
                                                                                        saa.EntityId = e.EntityId
                                                                                        AND sut.TeamId = 1 --@PeerReviewTeam
                                                                                        AND DeallocatedDate IS NULL
                                                                )
                                        )
                                )
                ORDER BY Age desc
End