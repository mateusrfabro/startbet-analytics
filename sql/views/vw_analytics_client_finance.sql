CREATE OR REPLACE VIEW vw_analytics_client_finance AS
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
cte_finance AS (
    SELECT
        client_id,
        SUM(CASE WHEN operation_type = 'DEPOSIT' THEN amount ELSE 0 END) AS total_deposit,
        SUM(CASE WHEN operation_type = 'WITHDRAWAL' THEN amount ELSE 0 END) AS total_withdraw,
        SUM(
            CASE 
                WHEN operation_type = 'DEPOSIT' THEN amount
                WHEN operation_type = 'WITHDRAWAL' THEN -amount
                ELSE 0
            END
        ) AS net
    FROM cte_payment
    GROUP BY client_id
)
SELECT
    c.client_id,
    c.registration_date,
    c.create_time,
    c.project_id,
    c.btag,
    c.last_login,
    ftd.ftd_date,
    ftd.ftd_amount,
    f.total_deposit,
    f.total_withdraw,
    f.net
FROM cte_client c
LEFT JOIN cte_ftd ftd ON c.client_id = ftd.client_id
LEFT JOIN cte_finance f ON c.client_id = f.client_id;
