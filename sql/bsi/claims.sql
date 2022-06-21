SELECT
    CLAIMID,
    JID,
    CLVendorCode,
    CLStatus,
    CLAmount
FROM
    Claims
WHERE
    JID IS NOT NULL