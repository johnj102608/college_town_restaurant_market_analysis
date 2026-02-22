/*
02_create_staging_tables.sql
Loads cleaned food places CSV into staging table
*/

IF OBJECT_ID('stg.food_places_raw','U') IS NOT NULL
    DROP TABLE stg.food_places_raw;
GO

CREATE TABLE stg.food_places_raw (
    osm_type            NVARCHAR(50)  NULL,
    osm_id              BIGINT        NULL,
    city                NVARCHAR(100) NULL,
    amenity             NVARCHAR(50)  NULL,
    name                NVARCHAR(255) NULL,
    brand               NVARCHAR(255) NULL,
    website             NVARCHAR(255) NULL,
    opening_hours       NVARCHAR(255) NULL,
    lat                 FLOAT         NULL,
    lon                 FLOAT         NULL,
    has_name            NVARCHAR(10)          NULL,
    has_brand           NVARCHAR(10)           NULL,
    has_website         NVARCHAR(10)           NULL,
    has_opening_hours   NVARCHAR(10)           NULL,
    completeness_score  TINYINT       NULL
);
GO

BULK INSERT stg.food_places_raw
FROM 'C:\SQLdata\food_places_clean.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

/*
-- Checking
SELECT COUNT(*) AS rows_loaded FROM stg.food_places_raw;
SELECT TOP 10 * FROM stg.food_places_raw;
GO
*/


IF OBJECT_ID('stg.city_reference_raw','U') IS NOT NULL
    DROP TABLE stg.city_reference_raw;
GO

CREATE TABLE stg.city_reference_raw (
    input_city NVARCHAR(100) NULL,
    state_usps NVARCHAR(10) NULL,
    gazetteer_name NVARCHAR(255) NULL,
    acs_name NVARCHAR(255) NULL,
    geoid NVARCHAR(20) NULL,
    population INT NULL,
    land_area_sq_miles FLOAT NULL,
    population_density_per_sq_mile FLOAT NULL
);
GO

BULK INSERT stg.city_reference_raw
FROM 'C:\SQLdata\city_data.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO

--SELECT * FROM stg.city_reference_raw