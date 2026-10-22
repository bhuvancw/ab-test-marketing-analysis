CREATE TABLE dbo.ab_test_users (
    user_id        INT         NOT NULL PRIMARY KEY,
    test_group     VARCHAR(5)  NOT NULL,
    converted      BIT         NOT NULL,
    total_ads      INT         NOT NULL,
    most_ads_day   VARCHAR(10) NOT NULL,
    most_ads_hour  TINYINT     NOT NULL,
    CONSTRAINT chk_test_group CHECK (test_group IN ('ad', 'psa'))
);