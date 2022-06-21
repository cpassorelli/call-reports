SELECT
    -- [Document Handle],
    -- [Date Created],
    [MAIL Date Time] as MAILDateTime,
    [MAIL From Address] as MAILFromAddress,
    -- [MAIL To Address],
    -- [MAIL Cc Address],
    -- [MAIL Subject],
    [MAIL MessageID] as MAILMessageID,
    -- [MAIL Attachment Count],
    [S - Ref #] as ReferenceNumber,
    -- [S - Customer Name],
    -- [S - Job #],
    -- [S - Vendor Name],
    -- [S - Created By User],
    -- [S - Skip AutoReceive],
    [S - Recon] as Recon
    -- [S - Large Credits],
    -- [Ingestion Source],
    -- [S - Statement Exists In Batch]
FROM
    dbo.cc_STStatementEmailDocs