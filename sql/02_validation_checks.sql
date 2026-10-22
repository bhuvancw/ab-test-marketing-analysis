-- total rows
SELECT COUNT(*) AS total_rows
FROM dbo.ab_test_users;

-- users and conversions per group
SELECT
    test_group,
    COUNT(*) AS users,
    SUM(CAST(converted AS INT)) AS conversions
FROM dbo.ab_test_users
GROUP BY test_group;

-- range of total_ads
SELECT
    MIN(total_ads) AS min_ads,
    MAX(total_ads) AS max_ads
FROM dbo.ab_test_users;