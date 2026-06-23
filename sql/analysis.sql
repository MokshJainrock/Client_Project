-- ============================================================
-- Client Data Management & Analytics System
-- analysis.sql  —  the analysis queries
-- ============================================================
-- Run after the data is loaded into MySQL by etl.py.
-- The data's last date is 2011-12-09, which we treat as "today"
-- for recency / churn calculations.

USE client_analytics;

-- ------------------------------------------------------------
-- 1. Overall scale
-- 5,878 clients | £17,374,804 revenue | £2,956 avg | 41 countries
-- ------------------------------------------------------------
SELECT
    COUNT(*)                       AS total_clients,
    SUM(total_spend)               AS total_revenue,
    ROUND(AVG(total_spend), 2)     AS avg_client_value,
    COUNT(DISTINCT country)        AS countries
FROM clients;

-- ------------------------------------------------------------
-- 2. Revenue concentration (Pareto)
-- Result: top 20% of clients = 77.2% of revenue
-- ------------------------------------------------------------
SELECT
    ROUND(100.0 * SUM(CASE WHEN rn <= 0.2 * total THEN total_spend ELSE 0 END)
          / SUM(total_spend), 1) AS pct_revenue_from_top20pct
FROM (
    SELECT total_spend,
           ROW_NUMBER() OVER (ORDER BY total_spend DESC) AS rn,
           COUNT(*)     OVER ()                          AS total
    FROM clients
) ranked;

-- ------------------------------------------------------------
-- 3. Latest date in the data (our "today")
-- Result: 2011-12-09
-- ------------------------------------------------------------
SELECT MAX(invoice_date) AS data_end FROM transactions;

-- ------------------------------------------------------------
-- 4. Recency + churn flag per client
-- Churn = no purchase in 90+ days
-- ------------------------------------------------------------
SELECT
    customer_id,
    last_seen,
    DATEDIFF('2011-12-09', last_seen) AS days_since_last_purchase,
    CASE WHEN DATEDIFF('2011-12-09', last_seen) > 90 THEN 1 ELSE 0 END AS is_churned
FROM clients
ORDER BY days_since_last_purchase DESC;

-- ------------------------------------------------------------
-- 5. Overall churn rate
-- Result: 50.9% (2,989 of 5,878 clients churned)
-- ------------------------------------------------------------
SELECT
    COUNT(*) AS total_clients,
    SUM(CASE WHEN DATEDIFF('2011-12-09', last_seen) > 90 THEN 1 ELSE 0 END) AS churned_clients,
    ROUND(100.0 * SUM(CASE WHEN DATEDIFF('2011-12-09', last_seen) > 90 THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS churn_rate_pct
FROM clients;

-- ------------------------------------------------------------
-- 6. High-value threshold (top 20% by spend)
-- Result: £2,910.23
-- ------------------------------------------------------------
SELECT total_spend AS high_value_threshold
FROM clients
ORDER BY total_spend DESC
LIMIT 1 OFFSET 1175;   -- 20% of 5,878 ≈ 1,175th client

-- ------------------------------------------------------------
-- 7. Value x Risk segmentation (the 2x2)
-- High-Value / Active     968    £11.88M
-- Low-Value  / Active    1,921    £2.11M
-- Low-Value  / At-Risk   2,781    £1.84M
-- High-Value / At-Risk     208    £1.55M   <- the worth-saving segment
-- ------------------------------------------------------------
SELECT
    CASE WHEN total_spend >= 2910.23 THEN 'High-Value' ELSE 'Low-Value' END AS value_tier,
    CASE WHEN DATEDIFF('2011-12-09', last_seen) > 90 THEN 'At-Risk' ELSE 'Active' END AS risk_tier,
    COUNT(*)                  AS num_clients,
    ROUND(SUM(total_spend),0) AS segment_revenue
FROM clients
GROUP BY value_tier, risk_tier
ORDER BY segment_revenue DESC;

-- ------------------------------------------------------------
-- 8. Write the segment label back into the clients table
-- (used by the Power BI dashboard)
-- ------------------------------------------------------------
UPDATE clients
SET segment = CONCAT(
    CASE WHEN total_spend >= 2910.23 THEN 'High-Value' ELSE 'Low-Value' END,
    ' / ',
    CASE WHEN DATEDIFF('2011-12-09', last_seen) > 90 THEN 'At-Risk' ELSE 'Active' END
);

-- Verify the segment split
SELECT segment, COUNT(*) AS num_clients
FROM clients
GROUP BY segment;

-- ------------------------------------------------------------
-- 9. ROI inputs (targeted vs broad retention)
-- worth_saving_revenue = £1,546,445   (High-Value / At-Risk)
-- all_atrisk_revenue   = £3,391,384   (every churned client)
-- all_atrisk_clients   = 2,989
-- ------------------------------------------------------------
SELECT
    SUM(CASE WHEN segment = 'High-Value / At-Risk' THEN total_spend ELSE 0 END) AS worth_saving_revenue,
    SUM(CASE WHEN DATEDIFF('2011-12-09', last_seen) > 90 THEN total_spend ELSE 0 END) AS all_atrisk_revenue,
    SUM(CASE WHEN DATEDIFF('2011-12-09', last_seen) > 90 THEN 1 ELSE 0 END) AS all_atrisk_clients
FROM clients;

-- ------------------------------------------------------------
-- ROI comparison (computed from the inputs above, stated assumptions):
--   cost = £10 per client contacted
--   targeted win-back rate = 30%,  broad win-back rate = 10%
--
--   Targeted (208):   cost £2,080   recovers ~£464K   ~222x return
--   Broad   (2,989):  cost £29,890  recovers ~£339K   ~10x  return
--
-- Recommendation: target the 208 worth-saving clients.
-- ------------------------------------------------------------
