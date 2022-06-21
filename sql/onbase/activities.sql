SELECT
    ObjectID,
    CreatedDate,
    ReferenceNumber,
    CustomerVendorName,
    JobNumber,
    JobName,
    ContactType,
    ActivityUser,
    -- ActivityDate,
    -- FollowUpDate,
    -- STNID,
    Notes, --
    Outcome,
    ActivityType,
    -- CustVendorObjectID,
    VendorContactObjectID,
    StatementRequestObjectID
    -- CreatedBy,
    -- MessageID
FROM
    hsi.rm_DVStatementRequestActivityRecords