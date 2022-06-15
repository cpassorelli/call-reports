WITH
_calls AS (
    SELECT
        EMPLOYEE_ID,
        CALL_DATE,
        CASE IS_OUTGOING
            WHEN false
                THEN CALL_DURATION
        END as INBOUND_DURATION,
        CASE IS_OUTGOING
            WHEN true
                THEN CALL_DURATION
        END as OUTBOUND_DURATION
    FROM
        EMPLOYEE_CALLS
    WHERE
        CALL_RESULT = 'Call connected'
        AND CALL_DATE BETWEEN
            cast((current_timestamp() - interval '1 day') as date)
            AND cast(current_timestamp() as date)
),
calls AS (
    SELECT
        EMPLOYEE_ID,
        date_format(
            to_utc_timestamp(
                from_unixtime(
                    cast(floor(sum(INBOUND_DURATION)) as int),
                    'yyyy-MM-dd HH:mm:ss'
                ),
                'America/New_York'
            ),
            'HH:mm:ss'
        ) as INBOUND_TIME,
        date_format(
            to_utc_timestamp(
                from_unixtime(
                    cast(floor(sum(OUTBOUND_DURATION)) as int),
                    'yyyy-MM-dd HH:mm:ss'
                ),
                'America/New_York'
            ),
            'HH:mm:ss'
        ) as OUTBOUND_TIME,
        count(INBOUND_DURATION) as INBOUND_CALLS,
        count(OUTBOUND_DURATION) as OUTBOUND_CALLS,
        date_format(
            to_utc_timestamp(
                from_unixtime(
                    cast(floor(avg(INBOUND_DURATION)) as int),
                    'yyyy-MM-dd HH:mm:ss'
                ),
                'America/New_York'
            ),
            'HH:mm:ss'
        ) as AVERAGE_INBOUND_TIME,
        date_format(
            to_utc_timestamp(
                from_unixtime(
                    cast(floor(avg(OUTBOUND_DURATION)) as int),
                    'yyyy-MM-dd HH:mm:ss'
                ),
                'America/New_York'
            ),
            'HH:mm:ss'
        ) as AVERAGE_OUTBOUND_TIME,
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
            cast((current_timestamp() - interval '1 day') as date)
            AND cast(current_timestamp() as date)
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
                        cast((current_timestamp() - interval '1 day') as date)
                        AND cast(current_timestamp() as date)
                    AND ACTIVITY_DATE BETWEEN
                        cast((current_timestamp() - interval '1 day') as date)
                        AND cast(current_timestamp() as date)
    GROUP BY
        EMPLOYEE_ID
),
statements AS (
    SELECT
        EMPLOYEE_ID,
        count(STATEMENT_DATE) as STATEMENTS_RECEIVED,
        count(DISTINCT STATEMENTS_RECEIVED.REFERENCE_ID) as REFERENCES
    FROM
        STATEMENT_ACTIVITIES
            INNER JOIN
                STATEMENTS_RECEIVED ON
                    STATEMENT_ACTIVITIES.REFERENCE_ID = STATEMENTS_RECEIVED.REFERENCE_ID
                    AND EMPLOYEE_REFERENCE_RANK = 1
                    AND ACTIVITY_DATE BETWEEN
                        cast((current_timestamp() - interval '1 day') as date)
                        AND cast(current_timestamp() as date)
                    AND STATEMENT_DATE BETWEEN
                        cast((current_timestamp() - interval '1 day') as date)
                        AND cast(current_timestamp() as date)
    GROUP BY
        EMPLOYEE_ID
),
buckets AS (
    SELECT
        EMPLOYEE_ID,
        count(*) as ACTIVITIES,
        sum(CASE BUCKET WHEN '12AM' THEN 1 ELSE 0 END) as 12AM,
        sum(CASE BUCKET WHEN '01AM' THEN 1 ELSE 0 END) as 01AM,
        sum(CASE BUCKET WHEN '02AM' THEN 1 ELSE 0 END) as 02AM,
        sum(CASE BUCKET WHEN '03AM' THEN 1 ELSE 0 END) as 03AM,
        sum(CASE BUCKET WHEN '04AM' THEN 1 ELSE 0 END) as 04AM,
        sum(CASE BUCKET WHEN '05AM' THEN 1 ELSE 0 END) as 05AM,
        sum(CASE BUCKET WHEN '06AM' THEN 1 ELSE 0 END) as 06AM,
        sum(CASE BUCKET WHEN '07AM' THEN 1 ELSE 0 END) as 07AM,
        sum(CASE BUCKET WHEN '08AM' THEN 1 ELSE 0 END) as 08AM,
        sum(CASE BUCKET WHEN '09AM' THEN 1 ELSE 0 END) as 09AM,
        sum(CASE BUCKET WHEN '10AM' THEN 1 ELSE 0 END) as 10AM,
        sum(CASE BUCKET WHEN '11AM' THEN 1 ELSE 0 END) as 11AM,
        sum(CASE BUCKET WHEN '12PM' THEN 1 ELSE 0 END) as 12PM,
        sum(CASE BUCKET WHEN '01PM' THEN 1 ELSE 0 END) as 01PM,
        sum(CASE BUCKET WHEN '02PM' THEN 1 ELSE 0 END) as 02PM,
        sum(CASE BUCKET WHEN '03PM' THEN 1 ELSE 0 END) as 03PM,
        sum(CASE BUCKET WHEN '04PM' THEN 1 ELSE 0 END) as 04PM,
        sum(CASE BUCKET WHEN '05PM' THEN 1 ELSE 0 END) as 05PM,
        sum(CASE BUCKET WHEN '06PM' THEN 1 ELSE 0 END) as 06PM,
        sum(CASE BUCKET WHEN '07PM' THEN 1 ELSE 0 END) as 07PM,
        sum(CASE BUCKET WHEN '08PM' THEN 1 ELSE 0 END) as 08PM,
        sum(CASE BUCKET WHEN '09PM' THEN 1 ELSE 0 END) as 09PM,
        sum(CASE BUCKET WHEN '10PM' THEN 1 ELSE 0 END) as 10PM,
        sum(CASE BUCKET WHEN '11PM' THEN 1 ELSE 0 END) as 11PM
    FROM (
        SELECT
            EMPLOYEE_ID,
            date_format(ACTIVITY_DATE, 'hha') as BUCKET
        FROM
            STATEMENT_ACTIVITIES
        WHERE
            ACTIVITY_DATE BETWEEN
                cast((current_timestamp() - interval '1 day') as date)
                AND cast(current_timestamp() as date)
    )
    GROUP BY
        EMPLOYEE_ID
)
SELECT
    employees.EMPLOYEE_NAME,
    employees.TEAM,
    coalesce(calls.INBOUND_TIME, '00:00:00') as INBOUND_TIME,
    coalesce(calls.OUTBOUND_TIME, '00:00:00') as OUTBOUND_TIME,
    coalesce(calls.INBOUND_CALLS, 0) as INBOUND_CALLS,
    calls.OUTBOUND_CALLS,
    calls.AVERAGE_INBOUND_TIME,
    calls.AVERAGE_OUTBOUND_TIME,
    calls.EARLIEST_CALL_DATE,
    calls.LATEST_CALL_DATE,
    send_emails.EMAILS_SENT,
    receive_emails.EMAILS_RECEIVED,
    statements.STATEMENTS_RECEIVED,
    statements.REFERENCES,
    buckets.ACTIVITIES,
    buckets.12AM,
    buckets.01AM,
    buckets.02AM,
    buckets.03AM,
    buckets.04AM,
    buckets.05AM,
    buckets.06AM,
    buckets.07AM,
    buckets.08AM,
    buckets.09AM,
    buckets.10AM,
    buckets.11AM,
    buckets.12PM,
    buckets.01PM,
    buckets.02PM,
    buckets.03PM,
    buckets.04PM,
    buckets.05PM,
    buckets.06PM,
    buckets.07PM,
    buckets.08PM,
    buckets.09PM,
    buckets.10PM,
    buckets.11PM
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
    calls.EMPLOYEE_ID IS NOT NULL
    OR send_emails.EMPLOYEE_ID IS NOT NULL
    OR receive_emails.EMPLOYEE_ID IS NOT NULL
    OR statements.EMPLOYEE_ID IS NOT NULL
    OR buckets.EMPLOYEE_ID IS NOT NULL
    AND EMPLOYEES.EMPLOYEE_ID = 47514957