SELECT
    JobNo, --
    -- JobTier,
    CustomerName, --
    -- CustVendorID,
    VendorNo, --
    -- CustVendorGroupID,
    WNC,
    StatementWNC, --
    VendorGroupName, --
    Volume, --
    VolumeTier, --
    VolumeLast12, --
    RequestDate,
    ReferenceNumber, --
    Status,
    RequestMethod,
    RequestType,
    Contact,
    RequesterFullName,
    -- RequestText,
    LastActivityDate,
    LastStatementReceivedDate,
    -- CreatedDate,
    CallsheetNo, --
    ObjectID,
    CallerStatus, --
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
    WebsiteVendor, --
    WNCSpecialHandling, --
    NeedLeadVendor --
    -- VendorGroupPrimaryAccountType
FROM
    hsi.rm_DVStatementRequests