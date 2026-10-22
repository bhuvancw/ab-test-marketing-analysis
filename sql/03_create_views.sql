-- 1. Overall result
CREATE OR ALTER VIEW dbo.vw_overall_lift AS
WITH g AS (
    SELECT
        test_group,
        COUNT(*) AS users,
        SUM(CAST(converted AS INT)) AS conversions
    FROM dbo.ab_test_users
    GROUP BY test_group
)
SELECT
    a.users AS ad_users,
    a.conversions AS ad_conversions,
    p.users AS psa_users,
    p.conversions AS psa_conversions,
    ROUND(100.0 * a.conversions / a.users, 2) AS ad_rate_pct,
    ROUND(100.0 * p.conversions / p.users, 2) AS psa_rate_pct,
    ROUND(100.0 * a.conversions / a.users - 100.0 * p.conversions / p.users, 2) AS lift_pp,
    ROUND(100.0 * ((1.0 * a.conversions / a.users) / (1.0 * p.conversions / p.users) - 1), 1) AS relative_lift_pct
FROM g AS a
JOIN g AS p ON a.test_group = 'ad' AND p.test_group = 'psa';
GO

-- 2. By day of week
CREATE OR ALTER VIEW dbo.vw_lift_by_day AS
WITH counts AS (
    SELECT
        most_ads_day AS day_name,
        CASE most_ads_day
            WHEN 'Monday' THEN 1 WHEN 'Tuesday' THEN 2 WHEN 'Wednesday' THEN 3
            WHEN 'Thursday' THEN 4 WHEN 'Friday' THEN 5 WHEN 'Saturday' THEN 6
            WHEN 'Sunday' THEN 7
        END AS day_order,
        SUM(CASE WHEN test_group = 'ad'  THEN 1 ELSE 0 END) AS ad_users,
        SUM(CASE WHEN test_group = 'psa' THEN 1 ELSE 0 END) AS psa_users,
        SUM(CASE WHEN test_group = 'ad'  AND converted = 1 THEN 1 ELSE 0 END) AS ad_conversions,
        SUM(CASE WHEN test_group = 'psa' AND converted = 1 THEN 1 ELSE 0 END) AS psa_conversions
    FROM dbo.ab_test_users
    GROUP BY most_ads_day
)
SELECT
    day_name, day_order, ad_users, psa_users, ad_conversions, psa_conversions,
    ROUND(100.0 * ad_conversions  / NULLIF(ad_users, 0), 2)  AS ad_rate_pct,
    ROUND(100.0 * psa_conversions / NULLIF(psa_users, 0), 2) AS psa_rate_pct,
    ROUND(100.0 * ad_conversions / NULLIF(ad_users, 0)
        - 100.0 * psa_conversions / NULLIF(psa_users, 0), 2) AS lift_pp
FROM counts;
GO

-- 3. By time of day
CREATE OR ALTER VIEW dbo.vw_lift_by_time_band AS
WITH banded AS (
    SELECT
        test_group,
        converted,
        CASE WHEN most_ads_hour <= 11 THEN 'Overnight/Morning (0-11)'
             WHEN most_ads_hour <= 17 THEN 'Afternoon (12-17)'
             ELSE 'Evening (18-23)' END AS time_band,
        CASE WHEN most_ads_hour <= 11 THEN 1
             WHEN most_ads_hour <= 17 THEN 2
             ELSE 3 END AS band_order
    FROM dbo.ab_test_users
),
counts AS (
    SELECT
        time_band, band_order,
        SUM(CASE WHEN test_group = 'ad'  THEN 1 ELSE 0 END) AS ad_users,
        SUM(CASE WHEN test_group = 'psa' THEN 1 ELSE 0 END) AS psa_users,
        SUM(CASE WHEN test_group = 'ad'  AND converted = 1 THEN 1 ELSE 0 END) AS ad_conversions,
        SUM(CASE WHEN test_group = 'psa' AND converted = 1 THEN 1 ELSE 0 END) AS psa_conversions
    FROM banded
    GROUP BY time_band, band_order
)
SELECT
    time_band, band_order, ad_users, psa_users, ad_conversions, psa_conversions,
    ROUND(100.0 * ad_conversions  / NULLIF(ad_users, 0), 2)  AS ad_rate_pct,
    ROUND(100.0 * psa_conversions / NULLIF(psa_users, 0), 2) AS psa_rate_pct,
    ROUND(100.0 * ad_conversions / NULLIF(ad_users, 0)
        - 100.0 * psa_conversions / NULLIF(psa_users, 0), 2) AS lift_pp
FROM counts;
GO

-- 4. By number of ads seen
CREATE OR ALTER VIEW dbo.vw_lift_by_ads_seen AS
WITH bucketed AS (
    SELECT
        test_group,
        converted,
        CASE WHEN total_ads <= 4  THEN '1-4'
             WHEN total_ads <= 13 THEN '5-13'
             WHEN total_ads <= 27 THEN '14-27'
             WHEN total_ads <= 57 THEN '28-57'
             ELSE '58+' END AS ads_bucket,
        CASE WHEN total_ads <= 4  THEN 1
             WHEN total_ads <= 13 THEN 2
             WHEN total_ads <= 27 THEN 3
             WHEN total_ads <= 57 THEN 4
             ELSE 5 END AS bucket_order
    FROM dbo.ab_test_users
),
counts AS (
    SELECT
        ads_bucket, bucket_order,
        SUM(CASE WHEN test_group = 'ad'  THEN 1 ELSE 0 END) AS ad_users,
        SUM(CASE WHEN test_group = 'psa' THEN 1 ELSE 0 END) AS psa_users,
        SUM(CASE WHEN test_group = 'ad'  AND converted = 1 THEN 1 ELSE 0 END) AS ad_conversions,
        SUM(CASE WHEN test_group = 'psa' AND converted = 1 THEN 1 ELSE 0 END) AS psa_conversions
    FROM bucketed
    GROUP BY ads_bucket, bucket_order
)
SELECT
    ads_bucket, bucket_order, ad_users, psa_users, ad_conversions, psa_conversions,
    ROUND(100.0 * ad_conversions  / NULLIF(ad_users, 0), 2)  AS ad_rate_pct,
    ROUND(100.0 * psa_conversions / NULLIF(psa_users, 0), 2) AS psa_rate_pct,
    ROUND(100.0 * ad_conversions / NULLIF(ad_users, 0)
        - 100.0 * psa_conversions / NULLIF(psa_users, 0), 2) AS lift_pp
FROM counts;
GO