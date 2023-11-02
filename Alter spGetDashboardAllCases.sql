USE [CMSPRO_ZEUS]
GO
/****** Object:  StoredProcedure [Entity].[spGetDashboardAllCases]    Script Date: 6/15/2023 12:28:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [Entity].[spGetDashboardAllCases] (
	@UserId INT
)
AS
BEGIN
	DECLARE @Action INT = 1;
	-- Roles	
	DECLARE @AdminRoleId INT = 5;
	DECLARE @ManagerRoleId INT = 2;
	
	-- Allocation Type
	DECLARE @CHAllocationTypeId INT = 1;
	DECLARE @QCAllocationTypeId INT = 2;
	DECLARE @QAAllocationTypeId INT = 3;

	DECLARE @AllCases			INT = 1;
    DECLARE @AwaitingReview		INT = 2;
    DECLARE @AwaitingQC			INT = 3;
    DECLARE @AwaitingQA			INT = 4;
    DECLARE @ActionsDueToday			INT = 5;
    DECLARE @ActionsOverdue				INT = 6;
    DECLARE @ActionsOnHold				INT = 7;
	DECLARE @ActionsOutOfScope			INT = 8;
	DECLARE @ActionsAssessment			INT = 9;
	DECLARE @ActionsAssessmentCompleted	INT = 10;
	DECLARE @ActionsFindingsCall		INT = 11;
	DECLARE @ActionsPeerReview			INT = 12;
	DECLARE @ActionsPeerReviewCompleted	INT = 13;
	DECLARE @ActionsQualityAssurance	INT = 14;
	DECLARE @ActionsQualityAssuranceCompleted	  INT = 15;
	DECLARE @ActionsCalcs				INT = 16;
	DECLARE @ActionsCalcsCompleted		INT = 17;
	DECLARE @ActionsCalcsPR				INT = 18;
	DECLARE @ActionsCalcsPRCompleted	INT = 19;
	DECLARE @ActionsCalcsQA				INT = 20;
	DECLARE @ActionsCalcsQACompleted	INT = 21;
	--DECLARE @ActionsBuild				INT	= 22;
	DECLARE @ActionsApproval			INT	= 23;
	DECLARE @ActionsAssessmentRework	INT = 24;
	DECLARE @ActionsQARework			INT = 25;
	DECLARE @ActionsPRRework			INT = 26;
	DECLARE @ActionsCalcsRework			INT = 27;
	DECLARE @ActionsCalcsQARework		INT = 28;
	DECLARE @ActionsCalcsPRRework		INT = 29;
	DECLARE @PeerReviewTeamCaseCount	INT = 30;
	DECLARE @AssessmentTeamCaseCount	INT = 31;
	DECLARE @AdministratorTeamCaseCount	INT = 32;
	DECLARE @QualityTeamCaseCount		INT = 33;
	DECLARE @ClientTeamCaseCount		INT = 34;
	DECLARE @CalculationTeamCaseCount	INT = 35;
	DECLARE @ManagementTeamCaseCount	INT = 36;
	DECLARE @AdministrationTeamCaseCount INT = 37;
	DECLARE @PaymentCaseCount			INT = 38;
	DECLARE @PaymentRequiredCount		INT = 39;
	DECLARE @ActionsAllTeamCases		INT = 99;

	DECLARE @tbAssessmentStatusId		INT
	DECLARE @tbOnHoldStatusId			INT
	DECLARE @tbFindingsCallStatusId		INT
	DECLARE @tbPeerReviewStatusId		INT
	DECLARE @tbQualityAssuranceStatusId	INT
	DECLARE @tbCalcsStatusId			INT
	DECLARE @tbCalcsPRStatusId			INT
	DECLARE @tbCalcsQAStatusId			INT
	DECLARE @tbBuildStatusId			INT
	DECLARE @tbApprovalStatusId			INT
	DECLARE @tbAssessmentReworkStatusId	INT
	DECLARE @tbQAReworkStatusId			INT
	DECLARE @tbPRReworkStatusId			INT
	DECLARE @tbCalcsReworkStatusId		INT
	DECLARE @tbCalcsReworkQAStatusId	INT
	DECLARE @tbCalcsQAReworkStatusId	INT
	DECLARE @tbCalcsPRReworkStatusId	INT
	DECLARE @caseTypeId				    INT
	DECLARE @tbClientRoleId				INT
	DECLARE @tbInappCalcsReqId			INT
	DECLARE @tbInappCalcsNotReqId		INT
	DECLARE @tbCaseCloseId				INT
	
	SELECT @tbAssessmentStatusId = StatusId 
	FROM [Status].Status
	WHERE Name = 'Assessment';

	SELECT @tbOnHoldStatusId = StatusId 
	FROM [Status].Status
	WHERE Name LIKE '%on hold%';

	SELECT @tbFindingsCallStatusId = StatusId 
	FROM [Status].Status
	WHERE Name LIKE '%Findings Call%';

	SELECT @tbPeerReviewStatusId = StatusId 
	FROM [Status].Status
	WHERE Name LIKE 'Peer Review';

	SELECT @tbQualityAssuranceStatusId = StatusId 
	FROM [Status].Status
	WHERE Name LIKE 'Quality';

	SELECT @tbCalcsStatusId = StatusId 
	FROM [Status].Status
	WHERE Name LIKE 'calculation%';

	SELECT @tbCalcsPRStatusId = StatusId 
	FROM [Status].Status
	WHERE Name LIKE 'Calcs Peer Review%';

	SELECT @tbCalcsQAStatusId = StatusId 
	FROM [Status].Status
	WHERE Name LIKE 'Calcs quality%';

	SELECT @tbBuildStatusId = StatusId 
	FROM [Status].Status
	WHERE Name LIKE 'build%';
		   
	SELECT @tbApprovalStatusId = StatusId 
	FROM [Status].Status
	WHERE Name LIKE 'Approval';

	SELECT @tbAssessmentReworkStatusId= StatusId 
	FROM [Status].Status
	WHERE Name LIKE 'Assessment QA rework%';

	SELECT @tbQAReworkStatusId= StatusId 
	FROM [Status].Status
	WHERE Name LIKE 'QA rework';

	SELECT @tbPRReworkStatusId= StatusId 
	FROM [Status].Status
	WHERE Name LIKE 'Peer Review rework';

	SELECT @tbCalcsReworkStatusId= StatusId 
	FROM [Status].Status
	WHERE Name LIKE 'calcs rework';

	SELECT @tbCalcsReworkQAStatusId= StatusId 
	FROM [Status].Status
	WHERE Name LIKE 'calcs rework (from calcs qa)';

	SELECT @tbCalcsPRReworkStatusId= StatusId 
	FROM [Status].Status
	WHERE Name LIKE 'calcs PR rework';

	SELECT @tbCalcsQAReworkStatusId= StatusId 
	FROM [Status].Status
	WHERE Name LIKE 'calcs QA rework';
	
	SELECT @tbClientRoleId = RoleId
	FROM [User].[Role]
	WHERE Name LIKE 'Client'

	SELECT @tbInappCalcsReqId = AssessmentOutcomeTypeId
	FROM [Entity].[AssessmentOutcomeType]
	WHERE NAME LIKE 'Inappropriate - calcs required%'
	
	SELECT @tbInappCalcsNotReqId = AssessmentOutcomeTypeId
	FROM [Entity].[AssessmentOutcomeType]
	WHERE NAME LIKE 'Inappropriate - calcs not required%'

	SELECT @tbCaseCloseId= StatusId 
	FROM [Status].Status
	WHERE Name LIKE 'Case Closed%';

	DECLARE @PeerReviewTeam		INT = 1
	DECLARE @AssessmentTeam		INT = 2
	DECLARE @AdministrationTeam INT = 3
	DECLARE @QualityTeam		INT = 5
	DECLARE @ClientTeam			INT = 6
	DECLARE @CalculationTeam	INT = 7
	DECLARE @ManagementTeam		INT = 8
	DECLARE @AdministratorTeam	INT = 9

	SET @caseTypeId = [Shared].GetCaseTypeId(@UserId)

	DECLARE @isClientRole BIT = 
		CASE WHEN EXISTS(SELECT * FROM [User].[UserRole]  WHERE RoleId = @tbClientRoleId and UserId = @UserId) THEN 1
		ELSE 0
	END ;

	DECLARE @Now DATE = GETDATE();
	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	DECLARE @NextDay DATE = DATEADD(DAY,1,CAST(GETDATE() AS DATE));

	-- If Manager or Admin then will bring back all cases rather than allocated
	DECLARE @ReturnAll BIT = 
		CASE WHEN EXISTS(SELECT * FROM [User].[UserRole] WHERE UserId = @UserId AND RoleId IN (@ManagerRoleId,@AdminRoleId)) THEN 1
		ELSE 0
	END ;

	if (@Action = @ActionsOnHold)
		SET @ReturnAll = 0;

	-- Get Dashboard items
	WITH NextActionDue
	AS (
		SELECT EntityId
			,MIN(DueDate) AS NextActionDue
		FROM [Diary].[Diary]
		WHERE CompletedDate IS NULL
		GROUP BY EntityId
		)
	SELECT DISTINCT e.EntityId
		,e.Reference	AS Reference
		,cp.[Name]		AS CasePriority
		,ISNULL(cp.CasePriorityId,99999) AS casePriorityId --set a rediciously number so its sorted last
		,ct.[Name]		AS Complexity
		,ao.[Name]		AS AssessmentOutcome
		,vwCA.NumOfDays	AS Age
		,e.SchemeName
		,i.NAME			AS IFAName
		,u1.UserId		AS CHAllocatedTo
		,u1.DisplayName	AS CHAllocatedToFullName
		,u2.UserId		AS QCAllocatedTo
		,u2.DisplayName	AS QCAllocatedToFullName
		,u3.UserId		AS QAAllocatedTo
		,u3.DisplayName	AS QAAllocatedToFullName
		,e.StatusId
		,s.NAME			AS [Status]
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
		AND a2.AllocationTypeId = @QCAllocationTypeId
	LEFT JOIN [User].[User] u2 ON A2.AllocatedTo = u2.UserId
	LEFT JOIN [Entity].[Allocation] A3 ON e.EntityId = A3.EntityId
		AND A3.DeallocatedDate IS NULL
		AND a3.AllocationTypeId = @QAAllocationTypeId
	LEFT JOIN [User].[User] u3 ON A3.AllocatedTo = u3.UserId
	 JOIN [Status].[Status] S ON e.StatusId = S.StatusId
	LEFT JOIN NextActionDue nad ON e.EntityId = nad.EntityId
	LEFT JOIN [Entity].CasePriority cp on cp.CasePriorityId = e.CasePriorityId
	LEFT JOIN [Entity].ComplexityType ct on ct.ComplexityTypeId = e.ComplexityTypeId
	LEFT JOIN [Entity].[AssessmentOutcomeType] ao on ao.AssessmentOutcomeTypeId = e.AssessmentOutcomeTypeId
	 JOIN [Entity].vwCaseAge vwCA ON vwCA.entityid = e.EntityId
	LEFT JOIN [Entity].vwSLA vwSA ON vwSA.EntityId = e.EntityId
	LEFT JOIN [Entity].[EntityCustomerNumbered] ecn ON e.EntityId = ecn.EntityId AND ecn.CustomerNumber = 1
	WHERE e.IsVisible = 1
		AND s.IsComplete = 0
		AND (
			e.CaseTypeId = @caseTypeId
			OR 
			(
				@isClientRole = 1
				AND EXISTS(
					--Here you will bring back the entityid that are NAB cases as it's in approval status 
					SELECT sube.entityid
					FROM [Entity].[Entity] sube
					INNER JOIN [Status].[Status] s ON s.StatusId = sube.StatusId
					WHERE s.IsComplete = 0
						AND sube.IsVisible = 1
						AND sube.CaseTypeId = @caseTypeId
						AND sube.EntityId = e.EntityId
					UNION
					SELECT sube2.entityid
					FROM [Entity].[Entity] sube2 
					INNER JOIN [Status].[Status] s ON s.StatusId = sube2.StatusId
					WHERE s.IsComplete = 0
						AND sube2.IsVisible = 1
						AND sube2.StatusId = @tbApprovalStatusId
						AND sube2.EntityId = e.EntityId
				)
			)
		)
	ORDER BY Age desc
END
