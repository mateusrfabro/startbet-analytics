CREATE OR REPLACE VIEW vw_analytics_daily_campaign_finance AS
WITH cte_campaign AS (
    SELECT
        btq,
        MAX(CASE WHEN tipo_do_evento = 'registro' THEN utm1 END) AS utm1,
        MAX(CASE WHEN tipo_do_evento = 'registro' THEN utm2 END) AS utm2,
        MAX(CASE WHEN tipo_do_evento = 'registro' THEN utm3 END) AS utm3,
        MAX(CASE WHEN tipo_do_evento = 'registro' THEN utm4 END) AS utm4,
        MAX(CASE WHEN tipo_do_evento = 'registro' THEN utm5 END) AS utm5
    FROM mkt_tagueamento
    GROUP BY btq
),
cte_daily_client AS (
    SELECT
        d.tx_date,
        d.client_id,
        d.total_deposit,
        d.total_withdraw,
        d.net
    FROM vw_analytics_daily_finance d
),
cte_client_campaign AS (
    SELECT
        dc.tx_date,
        c.client_id,
        c.project_id,
        c.btq,
        cc.utm1,
        cc.utm2,
        cc.utm3,
        cc.utm4,
        cc.utm5,
        dc.total_deposit,
        dc.total_withdraw,
        dc.net
    FROM cte_daily_client dc
    LEFT JOIN vw_analytics_client_finance c
        ON dc.client_id = c.client_id
    LEFT JOIN cte_campaign cc
        ON c.btq = cc.btq
)
SELECT
    tx_date,
    project_id,
    btq,
    utm1,
    utm2,
    utm3,
    utm4,
    utm5,
    SUM(total_deposit) AS total_deposit,
    SUM(total_withdraw) AS total_withdraw,
    SUM(net) AS net
FROM cte_client_campaign
GROUP BY
    tx_date,
    project_id,
    btq,
    utm1,
    utm2,
    utm3,
    utm4,
    utm5;
