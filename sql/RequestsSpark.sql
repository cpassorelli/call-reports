WITH
claims AS (
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
activities AS (
    SELECT
        REFERENCE_ID,
        EMPLOYEE_ID,
        NOTE_REFERENCE_RANK,
        datediff(current_date(), activities.ACTIVITY_DATE) as ACTIVITY_DAYS,
        cast(activities.ACTIVITY_DATE as date) as ACTIVITY_DATE,
        activities.NOTES,
        count(ACTIVITY_ID) OVER (
            PARTITION BY
                REFERENCE_ID
        ) as ACTIVITY_COUNT
    FROM
        activities
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
        WHEN true THEN 'Y'
    END as VENDOR_WILL_NOT_COMPLY
    /*requests.*,
    statements.STATEMENT_DATE,
    activities.ACTIVITY_DAYS,
    activities.ACTIVITY_DATE,
    activities.NOTES,
    activities.ACTIVITY_COUNT,
    employees.EMPLOYEE_NAME,
    coalesce(claims.VENDOR_CLAIMS, 0) as VENDOR_CLAIMS,
    coalesce(claims.VENDOR_CLAIMS_AMOUNT, 0) as VENDOR_CLAIMS_AMOUNT,
    descriptions.DESCRIPTION_DATE as RELEASE_DATE*/
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
            activities ON
                requests.REFERENCE_ID = activities.REFERENCE_ID
                AND activities.NOTE_REFERENCE_RANK = 1
        LEFT JOIN
            employees ON
                activities.EMPLOYEE_ID = employees.EMPLOYEE_ID
        LEFT JOIN
            claims ON
                requests.JOB_ID = claims.JOB_ID
        LEFT JOIN
            descriptions ON
                requests.REFERENCE_ID = descriptions.REFERENCE_ID
                AND descriptions.RELEASE_RANK = 1
WHERE
    NOT EXISTS (
        SELECT 1
        FROM
            projects
        WHERE
            requests.JOB_ID = projects.JOB_ID
            AND projects.STATUS = 'Closed'
    )
;
