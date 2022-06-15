-- Statement Caller Requests

SELECT
    Q.[statename] AS 'Queue'
    ,SR.[ReferenceNumber] AS 'Reference #'
    ,LTRIM(RTRIM(J.[ManagerPodName])) AS 'Pod'
    ,SR.[JobNo] AS 'Job #'
    ,LTRIM(RTRIM(SR.[CustomerName])) AS 'Customer Name'
    ,LTRIM(RTRIM((
        SELECT E.[FullName] 
        FROM [OnBase].[hsi].[rm_DVEmployees] E WITH (NOLOCK)
        WHERE E.[ID] = J.[ManagerID])
        )) AS 'Manager'
    ,LTRIM(RTRIM((
        SELECT E.[FullName] 
        FROM [OnBase].[hsi].[rm_DVEmployees] E WITH (NOLOCK)
        WHERE E.[ID] = J.[SupervisorID])
        )) AS 'Supervisor'
    ,SR.[VendorNo] AS 'Vendor #'
    ,LTRIM(RTRIM(SR.[VendorGroupName])) AS 'Vendor Group Name'
    ,SR.[VolumeTier] AS 'Scope'
    ,SR.[Volume] AS 'Vendor Volume'
    ,SR.[VolumeLast12] AS 'Volume Last 12'
    ,SR.[CallsheetNo] AS 'Callsheet #'
    ,LTRIM(RTRIM((
        SELECT E.[FullName] 
        FROM [OnBase].[hsi].[rm_DVEmployees] E WITH (NOLOCK)
        WHERE E.[ID] = SR.[CurrentAssigneeID])
        )) AS 'Current Assignee'
    ,SR.[Status] AS 'Recon Status'
    ,SR.[CallerStatus] AS 'Caller Status'
    ,SR.[RequestMethod] AS 'Request Method'
    ,SR.[RequestType] AS 'Request Type'
    ,CASE 
        WHEN SR.[StatementWNC] = 1 THEN 'Y'
        ELSE ''
        END 
        AS 'WNC Vendor'
     ,CASE
        WHEN SR.[WNCSpecialHandling] = 1 THEN 'Y'
        ELSE ''
        END AS 'WNC Special Handling'
     ,CASE
        WHEN SR.[NeedLeadVendor] = 1 THEN 'Y'
        ELSE ''
        END AS 'Needs Lead Vendor'
     ,CASE
        WHEN SR.[WebsiteVendor] = 1 THEN 'Y'
        ELSE ''
        END AS 'Website Vendor'
    ,CAST(SR.[RequestDate] AS date) AS 'Request Date'
    ,CAST(SR.[LastActivityDate] AS date) AS 'Last Activity Date'
    ,CAST(S.[Statement Date] AS date) AS 'Last Statement Received Date'
    ,CAST(SN_RE.[STNAdded] AS date) AS 'Last Re-Release Date'
    ,(SELECT COUNT(C.[ClaimID]) 
        FROM [BSIHC-GVL-SQL01].[BSI].[dbo].[Claims] C WITH (NOLOCK)
        WHERE C.[CLStatus] = 2 -- Approved
        AND C.[CLVendorCode] = LTRIM(RTRIM(SR.[VendorNo]))
        AND C.[JID] = SR.[JobNo]
        ) AS 'Approved Vendor Claim Count'
    ,COALESCE((SELECT SUM(C.[CLAmount]) 
        FROM [BSIHC-GVL-SQL01].[BSI].[dbo].[Claims] C WITH (NOLOCK)
        WHERE C.[CLStatus] = 2 -- Approved
        AND C.[CLVendorCode] = LTRIM(RTRIM(SR.[VendorNo]))
        AND C.[JID] = SR.[JobNo]
        ),0) AS 'Approved Vendor Claim Volume'
    ,(
        SELECT COUNT(SRAR.[ObjectID]) 
        FROM [OnBase].[hsi].[rm_DVStatementRequestActivityRecords] SRAR WITH (NOLOCK)
        WHERE SRAR.[ReferenceNumber] = SR.[ReferenceNumber]
        ) 'Activity Count'
    ,CAST((GETDATE() - (SRAR.[ActivityDate])) AS int) AS 'Days Since Last Activity'
    ,LTRIM(RTRIM(SRAR.[ActivityUser])) AS 'Last Note By'
    ,CAST((SRAR.[ActivityDate]) AS date) AS 'Last Note Date'
    ,SRAR.[Notes]  AS 'Last Note'
FROM 
    [OnBase].[hsi].[rm_DVStatementRequests] SR WITH (NOLOCK)
    INNER JOIN [OnBase].[hsi].[workitemlc] O WITH (NOLOCK) ON O.[contentnum] = SR.[ObjectID] -- state
    INNER JOIN [OnBase].[hsi].[rmobject] R WITH (NOLOCK) ON R.[objectid] = O.[contentnum]
    INNER JOIN [OnBase].[hsi].[rm_DVJobs] J WITH (NOLOCK) ON J.[JobNo] = SR.[JobNo]
    INNER JOIN [OnBase].[hsi].[lcstate] Q WITH (NOLOCK) ON Q.[statenum] = O.[statenum] -- queue name
    OUTER APPLY 
        (
        SELECT TOP 1 SRAR_S.[ActivityDate], SRAR_S.[ActivityUser], SRAR_S.[Notes]
        FROM [OnBase].[hsi].[rm_DVStatementRequestActivityRecords] SRAR_S WITH (NOLOCK)
        WHERE SRAR_S.[ReferenceNumber] = SR.[ReferenceNumber] 
        AND SRAR_S.[Notes] IS NOT NULL
        AND SRAR_S.[Notes] <> 'Note added to create Statement Request in Project Tracker.'
        AND SRAR_S.[Notes] NOT LIKE '%The Statement Preferred Vendor Contact in OnBase for this Vendor had its contact information updated%'
        ORDER BY SRAR_S.[ActivityDate] DESC, SRAR_S.[CreatedDate] DESC
        ) SRAR 
    OUTER APPLY 
        (
        SELECT TOP 1 S2.[Statement Date]
        FROM [OnBase].[hsi].[rm_DVStatements] S2 WITH (NOLOCK)
        WHERE S2.[Reference Number] = SR.[ReferenceNumber] 
        ORDER BY S2.[ObjectID] + RAND(4) DESC
        ) S 

    -- superfluous: StatementRequestActivityRecord, ActivityDate? parse out date in note; NoteID in BSAP
    OUTER APPLY 
        (
        SELECT TOP 1 SN.[STNAdded] 
        FROM [BSIHC-GVL-SQL01].[BSI].[dbo].[SNotes] SN WITH (NOLOCK)
        WHERE SN.[STID] = SR.[ReferenceNumber] 
        AND SN.[STNDescription] LIKE '%re-released%'
        ORDER BY SN.[STNAdded] DESC, SN.[STNID] + RAND(4) DESC
        ) SN_RE
    OUTER APPLY
        (
        SELECT TOP 1 RTRIM(P.[Status]) AS 'Status'
        FROM [OnBase].[hsi].[rm_DVProjects] P WITH (NOLOCK)
        WHERE P.[JobNo] = J.[JobNo]
        AND P.[ProjectType] = 'Statements'
        ) P
WHERE 
    O.[lcnum] = 160 -- Statement Request Processing LC
    AND P.[Status] <> 'Closed' -- open projects only
    AND R.[activestatus] = 0 -- Active object status
    -- POD variable: rm_DVPods
    AND LTRIM(RTRIM(J.[ManagerPodName])) = 
        (
        CASE 
        WHEN @POD = '*WNC' THEN LTRIM(RTRIM(J.[ManagerPodName]))
        WHEN @POD = '*Needs Lead' THEN LTRIM(RTRIM(J.[ManagerPodName]))
        ELSE @POD 
        END
        )
    AND LTRIM(RTRIM(SR.[CallerStatus])) = 
        (
        CASE 
        WHEN @POD = '*WNC' THEN 'Will Not Comply' 
        WHEN @POD = '*Needs Lead' THEN 'Needs Lead' 
        ELSE LTRIM(RTRIM(SR.[CallerStatus])) 
        END
        )
    AND SR.[Status] <> 'Fully Received'
    AND SR.[Status] <> 'Partial Receipt'
    AND O.statenum <> 441 -- Initial Q
    AND O.statenum <> 447 -- Done Q
ORDER BY 
    O.[statenum] ASC
    ,SR.[JobNo] ASC