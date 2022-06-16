WITH
_calls AS (
    SELECT
        EMPLOYEE_ID,
        CALL_DATE,
        CASE IS_OUTGOING
            WHEN 0
                THEN CALL_DURATION
        END as INBOUND_DURATION,
        CASE IS_OUTGOING
            WHEN 1
                THEN CALL_DURATION
        END as OUTBOUND_DURATION
    FROM
        EMPLOYEE_CALLS
    WHERE
        CALL_RESULT = 'Call connected'
        AND CALL_DATE BETWEEN
            CAST(GETDATE() - 1 AS DATE)
            AND CAST(GETDATE() AS DATE)
),
calls AS (
    SELECT
        EMPLOYEE_ID,
        FORMAT(DATEADD(SECOND, SUM(INBOUND_DURATION), '1900-01-01'), 'HH:mm:ss') as INBOUND_TIME,
        FORMAT(DATEADD(SECOND, SUM(OUTBOUND_DURATION), '1900-01-01'), 'HH:mm:ss') as OUTBOUND_TIME,
        COUNT(INBOUND_DURATION) as INBOUND_CALLS,
        COUNT(OUTBOUND_DURATION) as OUTBOUND_CALLS,
        FORMAT(DATEADD(SECOND, AVG(INBOUND_DURATION), '1900-01-01'), 'HH:mm:ss') as AVERAGE_INBOUND_TIME,
        FORMAT(DATEADD(SECOND, AVG(OUTBOUND_DURATION), '1900-01-01'), 'HH:mm:ss') as AVERAGE_OUTBOUND_TIME,
        MIN(CALL_DATE) as EARLIEST_CALL_DATE,
        MAX(CALL_DATE) as LATEST_CALL_DATE
    FROM
        _calls
    GROUP BY
        EMPLOYEE_ID
),
send_emails AS (
    SELECT
        EMPLOYEE_ID,
        count(*) as EMAILS_SENT
    FROM
        STATEMENT_ACTIVITIES
    WHERE
        ACTIVITY = 'EMAIL'
        AND ACTIVITY_DATE BETWEEN
            CAST(GETDATE() - 1 AS DATE)
            AND CAST(GETDATE() AS DATE)
    GROUP BY
        EMPLOYEE_ID
),
receive_emails AS (
    SELECT
        EMPLOYEE_ID,
        count(EMAIL_DATE) as EMAILS_RECEIVED
    FROM
        STATEMENT_ACTIVITIES
            INNER JOIN
                STATEMENT_EMAILS_RECEIVED ON
                    STATEMENT_ACTIVITIES.REFERENCE_ID = STATEMENT_EMAILS_RECEIVED.REFERENCE_ID
                    AND EMPLOYEE_REFERENCE_RANK = 1
                    AND EMAIL_DATE BETWEEN
                        CAST(GETDATE() - 1 AS DATE)
                        AND CAST(GETDATE() AS DATE)
                    AND ACTIVITY_DATE BETWEEN
                        CAST(GETDATE() - 1 AS DATE)
                        AND CAST(GETDATE() AS DATE)
    GROUP BY
        EMPLOYEE_ID
),
statements AS (
    SELECT
        EMPLOYEE_ID,
        count(STATEMENT_DATE) as STATEMENTS_RECEIVED,
        count(DISTINCT STATEMENTS_RECEIVED.REFERENCE_ID) as REFERENCE_NUMBERS
    FROM
        STATEMENT_ACTIVITIES
            INNER JOIN
                STATEMENTS_RECEIVED ON
                    STATEMENT_ACTIVITIES.REFERENCE_ID = STATEMENTS_RECEIVED.REFERENCE_ID
                    AND EMPLOYEE_REFERENCE_RANK = 1
                    AND ACTIVITY_DATE BETWEEN
                        CAST(GETDATE() - 1 AS DATE)
                        AND CAST(GETDATE() AS DATE)
                    AND STATEMENT_DATE BETWEEN
                        CAST(GETDATE() - 1 AS DATE)
                        AND CAST(GETDATE() AS DATE)
    GROUP BY
        EMPLOYEE_ID
),
buckets AS (
    SELECT
        EMPLOYEE_ID,
        count(*) as ACTIVITIES,
        sum(CASE BUCKET WHEN '12AM' THEN 1 ELSE 0 END) as [12AM],
        sum(CASE BUCKET WHEN '01AM' THEN 1 ELSE 0 END) as [01AM],
        sum(CASE BUCKET WHEN '02AM' THEN 1 ELSE 0 END) as [02AM],
        sum(CASE BUCKET WHEN '03AM' THEN 1 ELSE 0 END) as [03AM],
        sum(CASE BUCKET WHEN '04AM' THEN 1 ELSE 0 END) as [04AM],
        sum(CASE BUCKET WHEN '05AM' THEN 1 ELSE 0 END) as [05AM],
        sum(CASE BUCKET WHEN '06AM' THEN 1 ELSE 0 END) as [06AM],
        sum(CASE BUCKET WHEN '07AM' THEN 1 ELSE 0 END) as [07AM],
        sum(CASE BUCKET WHEN '08AM' THEN 1 ELSE 0 END) as [08AM],
        sum(CASE BUCKET WHEN '09AM' THEN 1 ELSE 0 END) as [09AM],
        sum(CASE BUCKET WHEN '10AM' THEN 1 ELSE 0 END) as [10AM],
        sum(CASE BUCKET WHEN '11AM' THEN 1 ELSE 0 END) as [11AM],
        sum(CASE BUCKET WHEN '12PM' THEN 1 ELSE 0 END) as [12PM],
        sum(CASE BUCKET WHEN '01PM' THEN 1 ELSE 0 END) as [01PM],
        sum(CASE BUCKET WHEN '02PM' THEN 1 ELSE 0 END) as [02PM],
        sum(CASE BUCKET WHEN '03PM' THEN 1 ELSE 0 END) as [03PM],
        sum(CASE BUCKET WHEN '04PM' THEN 1 ELSE 0 END) as [04PM],
        sum(CASE BUCKET WHEN '05PM' THEN 1 ELSE 0 END) as [05PM],
        sum(CASE BUCKET WHEN '06PM' THEN 1 ELSE 0 END) as [06PM],
        sum(CASE BUCKET WHEN '07PM' THEN 1 ELSE 0 END) as [07PM],
        sum(CASE BUCKET WHEN '08PM' THEN 1 ELSE 0 END) as [08PM],
        sum(CASE BUCKET WHEN '09PM' THEN 1 ELSE 0 END) as [09PM],
        sum(CASE BUCKET WHEN '10PM' THEN 1 ELSE 0 END) as [10PM],
        sum(CASE BUCKET WHEN '11PM' THEN 1 ELSE 0 END) as [11PM]
    FROM (
        SELECT
            EMPLOYEE_ID,
            FORMAT(ACTIVITY_DATE, 'hhtt') as BUCKET
        FROM
            STATEMENT_ACTIVITIES
        WHERE
            ACTIVITY_DATE BETWEEN
                CAST(GETDATE() - 1 AS DATE)
                AND CAST(GETDATE() AS DATE)
    ) as _statements
    GROUP BY
        EMPLOYEE_ID
)
SELECT
    employees.EMPLOYEE_NAME,
    employees.ROLE,
    employees.TEAM,
    coalesce(calls.INBOUND_TIME, '00:00:00') as INBOUND_TIME,
    coalesce(calls.OUTBOUND_TIME, '00:00:00') as OUTBOUND_TIME,
    coalesce(calls.INBOUND_CALLS, 0) as INBOUND_CALLS,
    coalesce(calls.OUTBOUND_CALLS, 0) as OUTBOUND_CALLS,
    coalesce(calls.AVERAGE_INBOUND_TIME, '00:00:00') as AVERAGE_INBOUND_TIME,
    coalesce(calls.AVERAGE_OUTBOUND_TIME, '00:00:00') as AVERAGE_OUTBOUND_TIME,
    calls.EARLIEST_CALL_DATE,
    calls.LATEST_CALL_DATE,
    coalesce(send_emails.EMAILS_SENT, 0) as EMAILS_SENT,
    coalesce(receive_emails.EMAILS_RECEIVED, 0) as EMAILS_RECEIVED,
    coalesce(statements.STATEMENTS_RECEIVED, 0) as STATEMENTS_RECEIVED,
    coalesce(statements.REFERENCE_NUMBERS, 0) as REFERENCE_NUMBERS,
    coalesce(buckets.ACTIVITIES, 0) as ACTIVITIES,
    coalesce(buckets.[12AM], 0) as [12AM],
    coalesce(buckets.[01AM], 0) as [01AM],
    coalesce(buckets.[02AM], 0) as [02AM],
    coalesce(buckets.[03AM], 0) as [03AM],
    coalesce(buckets.[04AM], 0) as [04AM],
    coalesce(buckets.[05AM], 0) as [05AM],
    coalesce(buckets.[06AM], 0) as [06AM],
    coalesce(buckets.[07AM], 0) as [07AM],
    coalesce(buckets.[08AM], 0) as [08AM],
    coalesce(buckets.[09AM], 0) as [09AM],
    coalesce(buckets.[10AM], 0) as [10AM],
    coalesce(buckets.[11AM], 0) as [11AM],
    coalesce(buckets.[12PM], 0) as [12PM],
    coalesce(buckets.[01PM], 0) as [01PM],
    coalesce(buckets.[02PM], 0) as [02PM],
    coalesce(buckets.[03PM], 0) as [03PM],
    coalesce(buckets.[04PM], 0) as [04PM],
    coalesce(buckets.[05PM], 0) as [05PM],
    coalesce(buckets.[06PM], 0) as [06PM],
    coalesce(buckets.[07PM], 0) as [07PM],
    coalesce(buckets.[08PM], 0) as [08PM],
    coalesce(buckets.[09PM], 0) as [09PM],
    coalesce(buckets.[10PM], 0) as [10PM],
    coalesce(buckets.[11PM], 0) as [11PM]
FROM
    EMPLOYEES as employees
        LEFT JOIN
            calls ON
                employees.EMPLOYEE_ID = calls.EMPLOYEE_ID
        LEFT JOIN
            send_emails ON
                employees.EMPLOYEE_ID = send_emails.EMPLOYEE_ID
        LEFT JOIN
            receive_emails ON
                employees.EMPLOYEE_ID = receive_emails.EMPLOYEE_ID
        LEFT JOIN
            statements ON
                employees.EMPLOYEE_ID = statements.EMPLOYEE_ID
        LEFT JOIN
            buckets ON
                employees.EMPLOYEE_ID = buckets.EMPLOYEE_ID
WHERE
    (
        calls.EMPLOYEE_ID IS NOT NULL
        OR send_emails.EMPLOYEE_ID IS NOT NULL
        OR receive_emails.EMPLOYEE_ID IS NOT NULL
        OR statements.EMPLOYEE_ID IS NOT NULL
        OR buckets.EMPLOYEE_ID IS NOT NULL
    )
    AND employees.ROLE IN (
        'WNC Auditor',
        'Statement Caller' 
    )
ORDER BY
    employees.EMPLOYEE_NAME





