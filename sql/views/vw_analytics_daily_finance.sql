CREATE OR REPLACE VIEW vw_analytics_daily_finance AS
WITH cte_client AS (
    SELECT
        c.id AS client_id,
        c.registration_date,
        c.create_time,
        c.project_id,
        c.btag,
        c.last_login
    FROM client c
),
cte_payment AS (
    SELECT
        p.client_id,
        p.amount,
        p.operation_type,
        p.status,
        p.create_time
    FROM payment p
    WHERE p.status <> 'FAILED'
),
cte_ftd AS (
    SELECT
        client_id,
        MIN(create_time) AS ftd_date,
        MIN(amount) AS ftd_amount
    FROM cte_payment
    WHERE operation_type = 'DEPOSIT'
    GROUP BY client_id
),
cte_daily_payments AS (
    SELECT
        DATE(p.create_time) AS tx_date,
        c.project_id,
        c.btag,
        COUNT(DISTINCT p.client_id) AS users_with_activity,
        SUM(CASE WHEN p.operation_type = 'DEPOSIT' THEN p.amount ELSE 0 END) AS total_deposit,
        SUM(CASE WHEN p.operation_type = 'WITHDRAWAL' THEN p.amount ELSE 0 END) AS total_withdraw,
        SUM(
            CASE
                WHEN p.operation_type = 'DEPOSIT' THEN p.amount
                WHEN p.operation_type = 'WITHDRAWAL' THEN -p.amount
                ELSE 0
            END
        ) AS net
    FROM cte_payment p
    JOIN cte_client c ON c.client_id = p.client_id
    GROUP BY
        DATE(p.create_time),
        c.project_id,
        c.btag
),
cte_daily_ftd AS (
    SELECT
        DATE(f.ftd_date) AS tx_date,
        c.project_id,
        c.btag,
        COUNT(*) AS ftd_count,
        SUM(f.ftd_amount) AS ftd_amount
    FROM cte_ftd f
    JOIN cte_client c ON c.client_id = f.client_id
    GROUP BY
        DATE(f.ftd_date),
        c.project_id,
        c.btag
)
SELECT
    d.tx_date,
    d.project_id,
    d.btag,
    d.users_with_activity,
    COALESCE(f.ftd_count, 0) AS ftd_count,
    COALESCE(f.ftd_amount, 0) AS ftd_amount,
    d.total_deposit,
    d.total_withdraw,
    d.net
FROM cte_daily_payments d
LEFT JOIN cte_daily_ftd f
    ON d.tx_date = f.tx_date
   AND d.project_id = f.project_id
   AND d.btag = f.btag;
