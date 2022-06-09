-- Employees
SELECT
    ID,
    -- OnBaseUserName,
    -- BSAPUserName,
    Email,
    -- FirstName,
    -- LastName,
    FullName,
    -- Title,
    Phone,
    PrimaryRoleName,
    -- PodId,
    -- [Named Client],
    -- [Named WF/WV],
    -- Active,
    PodName,
    ManagerName
    -- [Employee ID],
    -- [Hire Date],
    -- HRManagerFullName,
    -- [HR - Manager Object ID],
    -- [HR - Manager OnBase User Name],
    -- [HR - Manager Last Name],
    -- [HR - Manager First Name],
    -- BSAPSID,
    -- CreatedBy,
    -- CreatedDate
FROM
    hsi.rm_DVEmployees
;


-- Statements
SELECT
    [Reference Number] as ReferenceNumber,
    -- JobNo,
    -- JobTier,
    [Statement Date] as StatementDate,
    -- [Document Handle],
    ObjectID,
    -- CustVendorObjID,
    -- CustVendGroupObjID,
    -- CustVendGroupName,
    -- CustomerName,
    -- CID,
    -- CustVendName,
    -- CustVendNo,
    -- Volume,
    -- [Accounts Identified],
    -- Recon,
    EmailMessageID,
    CreatedDate,
    SRARObjectId
    -- ZeroBalance
FROM
    hsi.rm_DVStatements
;


-- Requests
SELECT
    -- JobNo,
    -- JobTier,
    -- CustomerName,
    -- CustVendorID,
    -- VendorNo,
    -- CustVendorGroupID,
    WNC,
    -- StatementWNC,
    -- VendorGroupName,
    -- Volume,
    -- VolumeTier,
    -- VolumeLast12,
    RequestDate,
    -- ReferenceNumber,
    Status,
    RequestMethod,
    RequestType,
    Contact,
    RequesterFullName,
    -- RequestText,
    LastActivityDate,
    LastStatementReceivedDate,
    -- CreatedDate,
    -- CallsheetNo,
    ObjectID
    -- CallerStatus,
    -- ReconStatus,
    -- CurrentAssigneeID,
    -- CurrentAssigneeName,
    -- EnteredReconDate,
    -- LastReconQueueName,
    -- LastReconQueueEntryDate,
    -- AccountsReceived,
    -- AccountsRequested,
    -- MessageID,
    -- VendorContactObjectID,
    -- WebsiteVendor,
    -- WNCSpecialHandling,
    -- NeedLeadVendor,
    -- VendorGroupPrimaryAccountType
FROM
    hsi.rm_DVStatementRequests
;


-- Contacts
SELECT
    -- CustVendorGroupNo,
    -- CustVendorNo,
    -- ContactType,
    -- TypePreferredContact,
    -- [Last Name],
    -- [First Name],
    [Full Name] as FullName,
    Email,
    Phone,
    -- Fax,
    -- Title,
    -- Note,
    -- ExternalID,
    -- BSAP VCID,
    -- CID,
    CustomerName,
    -- CVObjectID,
    -- CustObjectID,
    ObjectID
    -- CreatedDate,
    -- CreatedBy,
    -- BSAPVendorObjectID
FROM
    hsi.rm_DVVendorContacts
;


-- Activities
SELECT
    -- CustVendorGroupNo,
    -- CustVendorNo,
    -- ContactType,
    -- TypePreferredContact,
    -- [Last Name],
    -- [First Name],
    [Full Name] as FullName,
    Email,
    Phone,
    -- Fax,
    -- Title,
    -- Note,
    -- ExternalID,
    -- BSAP VCID,
    -- CID,
    CustomerName,
    -- CVObjectID,
    -- CustObjectID,
    ObjectID
    -- CreatedDate,
    -- CreatedBy,
    -- BSAPVendorObjectID
FROM
    hsi.rm_DVVendorContacts
;


-- Emails
SELECT
    -- [Document Handle],
    [Date Created] as DateCreated,
    [MAIL Date Time] as MAILDateTime,
    -- [MAIL From Address],
    -- [MAIL To Address],
    -- [MAIL Cc Address],
    -- [MAIL Subject],
    [MAIL MessageID] as MAILMessageID,
    [MAIL Attachment Count] as MAILAttachmentCount,
    [S - Ref #] as ReferenceNumber
    -- [S - Customer Name],
    -- [S - Job #],
    -- [S - Vendor Name],
    -- [S - Created By User],
    -- [S - Skip AutoReceive],
    -- [S - Recon],
    -- [S - Large Credits],
    -- [Ingestion Source],
    -- [S - Statement Exists In Batch]
FROM
    dbo.cc_STStatementEmailDocs
;
