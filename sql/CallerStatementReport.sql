IF OBJECT_ID('tempdb..#TSCD') IS NOT NULL DROP TABLE #TSCD
IF OBJECT_ID('tempdb..#TSCD_A') IS NOT NULL DROP TABLE #TSCD_A
CREATE TABLE #TSCD
(
    PrimaryName nvarchar(50) null,
    InboundCalls int null,
    OutboundCalls int null,
    AverageInboundDuration nvarchar(10) null,
    AverageOutboundDuration nvarchar(10) null,
    NumberOfStatementsReceived int null,
    NumberOfStatementEmailsReceived int null,
    PrimaryDateMin datetime null,
    PrimaryDate datetime null
)
INSERT INTO
    #TSCD
SELECT 
    PrimaryName
    ,SUM(q.inboundCalls) AS InboundCalls
    ,SUM(q.outboundCalls) AS OutboundCalls
    ,MAX(q.averageInboundDuration) AS AverageInboundDuration
    ,MAX(q.averageOutboundDuration) AS AverageOutboundDuration
    ,MAX(q.NumberOfStatementsReceived) AS NumberOfStatementsReceived
    ,MAX(q.NumberOfStatementEmailsReceived) AS NumberOfStatementEmailsReceived
    ,MIN(q.primaryDate) AS PrimaryDateMin
    ,MAX(q.primaryDate) AS PrimaryDate
FROM 
    (
        -- outbound calls
        SELECT
            CD.caller_name AS primaryName,
            COUNT(call_id) AS outboundCalls,
            RIGHT(CONVERT(CHAR(8),DATEADD(second,AVG(duration),0),108),5) AS averageOutboundDuration,
            0 AS inboundCalls,
            RIGHT(CONVERT(CHAR(8),DATEADD(second,0,0),108),5) AS averageInboundDuration,
            MAX(CD.date_time_est) primaryDate,
            0 AS NumberOfStatementsReceived,
            0 AS NumberOfStatementEmailsReceived
        FROM
            [dbo].[StatementCallerZoomData] CD
        WHERE
            UPPER(RTRIM(LTRIM(CD.caller_name))) IN 
            (
                SELECT 
                    DISTINCT UPPER(RTRIM(LTRIM(ActivityUser))) 
                FROM 
                    dbo.StatementsActivities 
                WHERE 
                    (ActivityType <> 'Note Only' AND ActivityType IS NOT NULL)
                    AND ActivityDate >= CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)
                    AND ActivityDate < CAST(CAST(GETDATE() AS DATE) AS DATETIME)
            )
            AND direction = 'outbound'
            AND date_time_est >= CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)
            AND date_time_est <  CAST(CAST(GETDATE() AS DATE) AS DATETIME)
        GROUP BY 
            caller_name
        UNION 
        -- inbound calls
        SELECT
            CD.callee_name AS primaryName,
            0 AS outboundCalls,
            RIGHT(CONVERT(CHAR(8),DATEADD(second,0,0),108),5) AS averageOutboundDuration,
            COUNT(*) AS inboundCalls,
            RIGHT(CONVERT(CHAR(8),DATEADD(second,AVG(duration),0),108),5) AS averageInboundDuration,
            MAX(CD.date_time_est) primaryDate,
            0 AS NumberOfStatementsReceived,
            0 AS NumberOfStatementEmailsReceived
        FROM
            [dbo].[StatementCallerZoomData] CD
        WHERE
            UPPER(RTRIM(LTRIM(CD.callee_name))) IN 
            (
                SELECT 
                    DISTINCT UPPER(RTRIM(LTRIM(ActivityUser))) 
                FROM 
                    dbo.StatementsActivities 
                WHERE 
                    (ActivityType <> 'Note Only' AND ActivityType IS NOT NULL)
                    AND ActivityDate >= CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)
                    AND ActivityDate < CAST(CAST(GETDATE() AS DATE) AS DATETIME)
            )
            AND direction = 'inbound'
            AND date_time_est >= CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)
            AND date_time_est < CAST(CAST(GETDATE() AS DATE) AS DATETIME)
        GROUP BY 
            callee_name
        UNION
        -- statement receipts
        SELECT
            ActivityUser AS primaryName,
            0 AS outboundCalls,
            RIGHT(CONVERT(CHAR(8),DATEADD(second,0,0),108),5) AS averageOutboundDuration,
            0 AS inboundCalls,
            RIGHT(CONVERT(CHAR(8),DATEADD(second,0,0),108),5) AS averageInboundDuration,
            MAX(ActivityDate) AS primaryDate,
            COALESCE(SUM(S.NumberOfStatementsReceived),0) AS NumberOfStatementsReceived,
            COUNT(S.EmailMessageID) AS NumberOfStatementEmailsReceived
        FROM
            [dbo].[StatementsActivities] S
        WHERE
            (ActivityType <> 'Note Only' AND ActivityType IS NOT NULL)
            AND ActivityDate >= CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)
            AND ActivityDate < CAST(CAST(GETDATE() AS DATE) AS DATETIME)
        GROUP BY 
            ActivityUser
    ) as q
GROUP BY 
    primaryName
-- add hourly columns
ALTER TABLE #TSCD ADD TotalActivities int null, TwelveAM int null, OneAM int null, TwoAM int null, ThreeAM int null, FourAM int null, FiveAM int null, SixAM int null, SevenAM int null, EightAM int null, NineAM int null, TenAM int null, ElevenAM int null, TwelvePM int null, OnePM int null, TwoPM int null, ThreePM int null, FourPM int null, FivePM int null, SixPM int null, SevenPM int null, EightPM int null, NinePM int null, TenPM int null, ElevenPM int null
-- create temp table for activities
CREATE TABLE #TSCD_A
(
    ObjectID int null,
    CreatedDate datetime null,
    ActivityUser nvarchar(50) null,
    SRARMessageID nvarchar(max) null,
    NumberOfStatementsReceived int null,
    SRARReferenceNumber int null
)
-- populate temp table for activities
INSERT INTO 
    #TSCD_A
SELECT 
     SA.[ObjectID]
    ,SA.[CreatedDate]
    ,SA.[ActivityUser]
    ,SA.[SRARMessageID]
    ,SA.[NumberOfStatementsReceived]
    ,SA.[SRARReferenceNumber]
FROM 
    [dbo].[StatementsActivities] SA
WHERE 
    SA.[CreatedDate] >= CAST(GETDATE()-1 AS DATE)
    AND SA.[CreatedDate] < CAST(GETDATE() AS DATE)
-- populate hourly counts
UPDATE
    #TSCD
SET
    #TSCD.[TotalActivities] = T.[TotalActivities]
    ,#TSCD.[TwelveAM] = T.[TwelveAM]
    ,#TSCD.[OneAM] = T.[OneAM]
    ,#TSCD.[TwoAM] = T.[TwoAM]
    ,#TSCD.[ThreeAM] = T.[ThreeAM]
    ,#TSCD.[FourAM] = T.[FourAM]
    ,#TSCD.[FiveAM] = T.[FiveAM]
    ,#TSCD.[SixAM] = T.[SixAM]
    ,#TSCD.[SevenAM] = T.[SevenAM]
    ,#TSCD.[EightAM] = T.[EightAM]
    ,#TSCD.[NineAM] = T.[NineAM]
    ,#TSCD.[TenAM] = T.[TenAM]
    ,#TSCD.[ElevenAM] = T.[ElevenAM]
    ,#TSCD.[TwelvePM] = T.[TwelvePM]
    ,#TSCD.[OnePM] = T.[OnePM]
    ,#TSCD.[TwoPM] = T.[TwoPM]
    ,#TSCD.[ThreePM] = T.[ThreePM]
    ,#TSCD.[FourPM] = T.[FourPM]
    ,#TSCD.[FivePM] = T.[FivePM]
    ,#TSCD.[SixPM] = T.[SixPM]
    ,#TSCD.[SevenPM] = T.[SevenPM]
    ,#TSCD.[EightPM] = T.[EightPM]
    ,#TSCD.[NinePM] = T.[NinePM]
    ,#TSCD.[TenPM] = T.[TenPM]
    ,#TSCD.[ElevenPM] = T.[ElevenPM]
FROM
    #TSCD TSCD
    INNER JOIN 
    (
        SELECT
            T.[ActivityUser]
            ,COUNT(T.[ObjectID]) AS TotalActivities
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,0,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,1,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS TwelveAM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,1,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,2,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS OneAM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,2,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,3,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS TwoAM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,3,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,4,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS ThreeAM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,4,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,5,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS FourAM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,5,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,6,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS FiveAM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,6,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,7,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS SixAM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,7,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,8,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS SevenAM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,8,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,9,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS EightAM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,9,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,10,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS NineAM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,10,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,11,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS TenAM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,11,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,12,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS ElevenAM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,12,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,13,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS TwelvePM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,13,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,14,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS OnePM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,14,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,15,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS TwoPM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,15,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,16,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS ThreePM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,16,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,17,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS FourPM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,17,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,18,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS FivePM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,18,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,19,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS SixPM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,19,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,20,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS SevenPM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,20,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,21,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS EightPM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,21,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,22,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS NinePM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,22,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,23,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS TenPM
            ,CAST(NULLIF(SUM(CASE WHEN T.[CreatedDate] >= DATEADD(HOUR,23,CAST( CAST(GETDATE()-1 AS Date) AS DateTime)) AND T.[CreatedDate] < DATEADD(HOUR,24,CAST( CAST(GETDATE()-1 AS Date) AS DateTime))THEN 1 ELSE 0 END) ,0) AS VARCHAR) AS ElevenPM
        FROM
            #TSCD_A AS T
        GROUP BY
            T.[ActivityUser]
    ) AS T ON T.[ActivityUser] = TSCD.[PrimaryName]
;


-- add total emails column
ALTER TABLE #TSCD ADD TotalEmailsSent int null
-- populate total emails
UPDATE
    #TSCD
SET
    #TSCD.[TotalEmailsSent] = T.[TotalEmailsSent]
FROM
    #TSCD TSCD
    INNER JOIN 
    (
        SELECT
            T.[ActivityUser]
            ,COUNT(T.[ObjectID]) AS [TotalEmailsSent]
        FROM
            #TSCD_A AS T
        WHERE
            T.[SRARMessageID] IS NOT NULL
        GROUP BY
            T.[ActivityUser]
    ) AS T ON T.[ActivityUser] = TSCD.[PrimaryName]
;


-- add unique refs column
ALTER TABLE #TSCD ADD UniqueRefs int null
-- add unique refs values
UPDATE
    #TSCD
SET
    #TSCD.[UniqueRefs] = T.[UniqueRefs]
FROM
    #TSCD TSCD
    INNER JOIN
    (
        SELECT 
            T.[ActivityUser]
            ,COUNT(DISTINCT T.[SRARReferenceNumber]) AS 'UniqueRefs'
        FROM 
            #TSCD_A AS T
        WHERE 
            T.[NumberOfStatementsReceived] IS NOT NULL
            AND T.[NumberOfStatementsReceived] <> 0
        GROUP BY
            T.[ActivityUser]
    ) AS T ON T.[ActivityUser] = TSCD.[PrimaryName]
-- zero out nulls
UPDATE
    #TSCD
SET
    #TSCD.[TotalEmailsSent] = CASE WHEN TSCD.[TotalEmailsSent] IS NULL THEN 0 ELSE TSCD.[TotalEmailsSent] END
    ,#TSCD.[TotalActivities] = CASE WHEN TSCD.[TotalActivities] IS NULL THEN 0 ELSE TSCD.[TotalActivities] END
    ,#TSCD.[UniqueRefs] = CASE WHEN TSCD.[UniqueRefs] IS NULL THEN 0 ELSE TSCD.[UniqueRefs] END
FROM
    #TSCD TSCD
-- final query
SELECT * FROM #TSCD
IF OBJECT_ID('tempdb..#TSCD') IS NOT NULL DROP TABLE #TSCD
IF OBJECT_ID('tempdb..#TSCD_A') IS NOT NULL DROP TABLE #TSCD_A