-- 08_market_geo_views.sql
-- Market structure + geographic density (demographic-aware)

------------------------------------------------------------
-- 1) City chain penetration + HHI + per-capita metrics
------------------------------------------------------------
CREATE OR ALTER VIEW mart.v_city_market_structure AS
WITH base AS (
    SELECT
        city,
        COUNT(*) AS total_places,
        SUM(CASE WHEN brand IS NOT NULL THEN 1 ELSE 0 END) AS branded_places
    FROM core.food_places
    GROUP BY city
),
brand_counts AS (
    SELECT
        city,
        brand,
        COUNT(*) AS brand_locations
    FROM core.food_places
    WHERE brand IS NOT NULL
    GROUP BY city, brand
),
brand_shares AS (
    SELECT
        city,
        brand,
        brand_locations,
        CAST(brand_locations AS FLOAT) /
        NULLIF(SUM(CAST(brand_locations AS FLOAT)) OVER (PARTITION BY city), 0) AS brand_share
    FROM brand_counts
)
SELECT
    b.city,
    b.total_places,
    b.branded_places,

    CAST(
        CASE WHEN b.total_places = 0 THEN 0.0
             ELSE CAST(b.branded_places AS FLOAT)/b.total_places
        END AS DECIMAL(10,3)
    ) AS pct_branded_places,

    COUNT(DISTINCT bs.brand) AS distinct_brands,
    CAST(SUM(bs.brand_share * bs.brand_share) AS DECIMAL(10,4)) AS brand_hhi,

    cr.population,
    cr.land_area_sq_miles,

    CAST(
        CASE WHEN cr.population IS NULL OR cr.population = 0 THEN NULL
             ELSE b.total_places * 10000.0 / cr.population
        END AS DECIMAL(10,3)
    ) AS places_per_10k_people,

    CAST(
        CASE WHEN cr.population IS NULL OR cr.population = 0 THEN NULL
             ELSE b.branded_places * 10000.0 / cr.population
        END AS DECIMAL(10,3)
    ) AS branded_per_10k_people

FROM base b
LEFT JOIN brand_shares bs
    ON b.city = bs.city
LEFT JOIN core.city_reference cr
    ON b.city = cr.input_city
GROUP BY
    b.city,
    b.total_places,
    b.branded_places,
    cr.population,
    cr.land_area_sq_miles;
GO

------------------------------------------------------------
-- 2) Geographic density (bounding box vs official area)
------------------------------------------------------------
CREATE OR ALTER VIEW mart.v_city_geo_density AS
SELECT
    fp.city,
    COUNT(*) AS total_places,
    cr.land_area_sq_miles,

    CAST(
        CASE WHEN cr.land_area_sq_miles IS NULL OR cr.land_area_sq_miles = 0 THEN NULL
             ELSE COUNT(*) / cr.land_area_sq_miles
        END AS DECIMAL(12,4)
    ) AS official_places_per_sq_mile

FROM core.food_places fp
LEFT JOIN core.city_reference cr
    ON fp.city = cr.input_city
GROUP BY
    fp.city,
    cr.land_area_sq_miles;
GO



/*
------------------------------------------------------------
--Checks – Market Structure
------------------------------------------------------------

-- Highest concentration (most dominated markets)
SELECT TOP 10 *
FROM mart.v_city_market_structure
ORDER BY brand_hhi DESC;

-- Most fragmented markets
SELECT TOP 10 *
FROM mart.v_city_market_structure
ORDER BY brand_hhi ASC;

-- Most competitive per capita
SELECT TOP 10 *
FROM mart.v_city_market_structure
ORDER BY places_per_10k_people DESC;

-- Check for unexpected NULL demographic joins
SELECT *
FROM mart.v_city_market_structure
WHERE population IS NULL;

------------------------------------------------------------
--Checks – Geographic Density
------------------------------------------------------------

-- Highest official density
SELECT TOP 10 *
FROM mart.v_city_geo_density
ORDER BY official_places_per_sq_mile DESC;

-- Highest modeled density (bounding box)
SELECT TOP 10 *
FROM mart.v_city_geo_density
ORDER BY approx_places_per_km2 DESC;

-- Check for NULL area issues
SELECT *
FROM mart.v_city_geo_density
WHERE land_area_sq_miles IS NULL;

*/