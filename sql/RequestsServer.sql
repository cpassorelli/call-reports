WITH
_claims AS (
    SELECT
        JOB_ID,
        count(CLAIM_ID) as VENDOR_CLAIMS,
        round(sum(AMOUNT), 2) as VENDOR_CLAIMS_AMOUNT
    FROM
        claims
    WHERE
        STATUS = 2
    GROUP BY
        JOB_ID
),
_activities AS (
    SELECT
        REFERENCE_ID,
        employees.EMPLOYEE_NAME as ACTIVITY_USER,
        NOTE_REFERENCE_RANK,
        datediff(day, activities.ACTIVITY_DATE, GETDATE()) as ACTIVITY_DAYS,
        cast(activities.ACTIVITY_DATE as date) as ACTIVITY_DATE,
        activities.NOTES,
        count(ACTIVITY_ID) OVER (
            PARTITION BY
                REFERENCE_ID
        ) as ACTIVITY_COUNT
    FROM
        activities
            LEFT JOIN
                employees ON
                    activities.EMPLOYEE_ID = employees.EMPLOYEE_ID
    WHERE
        NOTE_REFERENCE_RANK IS NOT NULL
)
SELECT
    states.STATE_NAME, -- queue
    requests.REFERENCE_NUMBER,
    jobs.TEAM, -- pod
    jobs.JOB_NUMBER,
    requests.CUSTOMER_NAME,
    managers.EMPLOYEE_NAME as MANAGER_NAME,
    supervisors.EMPLOYEE_NAME as SUPERVISOR_NAME,
    requests.VENDOR_NUMBER,
    requests.VENDOR_GROUP_NAME,
    requests.VOLUME_LEVEL, -- scope
    requests.VOLUME,
    requests.VOLUME_PREVIOUS_YEAR,
    requests.CALL_SHEET_NUMBER,
    employees.EMPLOYEE_NAME, -- current assignee
    requests.REQUEST_STATUS, -- recon status
    requests.CALL_STATUS,
    requests.REQUEST_METHOD,
    requests.REQUEST_TYPE,
    CASE requests.STATEMENT_WILL_NOT_COMPLY
        WHEN 1 THEN 'Y'
    END as VENDOR_WILL_NOT_COMPLY,
    CASE requests.HAS_SPECIAL_HANDLING
        WHEN 1 THEN 'Y'
    END as HAS_SPECIAL_HANDLING,
    CASE requests.NEEDS_LEAD_VENDOR
        WHEN 1 THEN 'Y'
    END as NEEDS_LEAD_VENDOR,
    CASE requests.VENDOR_HAS_WEBSITE
        WHEN 1 THEN 'Y'
    END as VENDOR_HAS_WEBSITE,
    requests.REQUEST_DATE,
    requests.LAST_ACTIVITY_DATE,
    statements.STATEMENT_DATE, -- last statement received date
    descriptions.DESCRIPTION_DATE as RELEASE_DATE,
    coalesce(claims.VENDOR_CLAIMS, 0) as VENDOR_CLAIMS, -- approved vendor claim count
    coalesce(claims.VENDOR_CLAIMS_AMOUNT, 0) as VENDOR_CLAIMS_AMOUNT, -- approved vendor claim volume
    activities.ACTIVITY_COUNT,
    activities.ACTIVITY_DAYS, -- days since last activity'
    activities.ACTIVITY_USER, -- last note by
    activities.ACTIVITY_DATE, -- last note date
    activities.NOTES -- last notes
FROM
    requests
        INNER JOIN
            processes ON
                requests.REQUEST_ID = processes.PROCESS_ID
                AND processes.PROCESS_CODE = 160
                AND processes.STATE_CODE NOT IN (441, 447)
                AND processes.STATUS_CODE = 0
                AND requests.REQUEST_STATUS NOT IN (
                    'Fully Received',
                    'Partial Receipt'
                )
        INNER JOIN
            states ON
                processes.STATE_CODE = states.STATE_CODE
        INNER JOIN
            jobs ON
                requests.JOB_ID = jobs.JOB_ID
        LEFT JOIN
            employees as managers ON
                jobs.MANAGER_ID = managers.EMPLOYEE_ID
        LEFT JOIN
            employees as supervisors ON
                jobs.MANAGER_ID = supervisors.EMPLOYEE_ID
        LEFT JOIN
            statements ON
                requests.REFERENCE_ID = statements.REFERENCE_ID
                AND statements.REFERENCE_RANK = 1
        LEFT JOIN
            _activities as activities ON
                requests.REFERENCE_ID = activities.REFERENCE_ID
                AND activities.NOTE_REFERENCE_RANK = 1
        LEFT JOIN
            employees ON
                requests.EMPLOYEE_ID = employees.EMPLOYEE_ID
        LEFT JOIN
            _claims as claims ON
                requests.JOB_ID = claims.JOB_ID
        LEFT JOIN
            descriptions ON
                requests.REFERENCE_ID = descriptions.REFERENCE_ID
                AND descriptions.RELEASE_RANK = 1
WHERE
    EXISTS (
        SELECT 1
        FROM
            projects
        WHERE
            requests.JOB_ID = projects.JOB_ID
            AND projects.STATUS <> 'Closed'
    )
ORDER BY
    states.STATE_NAME,
    jobs.JOB_NUMBER