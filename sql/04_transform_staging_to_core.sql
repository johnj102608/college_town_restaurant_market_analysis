-- 04_transform_staging_to_core.sql
-- Load core table from staging, with dedupe + safety conversions

TRUNCATE TABLE core.food_places;
GO

WITH dedup AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY osm_type, osm_id
            ORDER BY (SELECT 0)
        ) AS rn
    FROM stg.food_places_raw
)
INSERT INTO core.food_places (
    osm_type, osm_id, city, amenity, name, brand, website, opening_hours,
    lat, lon, has_name, has_brand, has_website, has_opening_hours, completeness_score
)
SELECT
    d.osm_type,
    d.osm_id,
    LTRIM(RTRIM(d.city)) AS city,
    LTRIM(RTRIM(d.amenity)) AS amenity,
    NULLIF(LTRIM(RTRIM(d.name)), '') AS name,
    NULLIF(LTRIM(RTRIM(d.brand)), '') AS brand,
    NULLIF(LTRIM(RTRIM(d.website)), '') AS website,
    NULLIF(LTRIM(RTRIM(d.opening_hours)), '') AS opening_hours,
    TRY_CONVERT(FLOAT, d.lat) AS lat,
    TRY_CONVERT(FLOAT, d.lon) AS lon,
    TRY_CONVERT(BIT, d.has_name) AS has_name,
    TRY_CONVERT(BIT, d.has_brand) AS has_brand,
    TRY_CONVERT(BIT, d.has_website) AS has_website,
    TRY_CONVERT(BIT, d.has_opening_hours) AS has_opening_hours,
    TRY_CONVERT(TINYINT, d.completeness_score) AS completeness_score
FROM dedup d
WHERE d.rn = 1
  AND TRY_CONVERT(FLOAT, d.lat) IS NOT NULL
  AND TRY_CONVERT(FLOAT, d.lon) IS NOT NULL
  AND TRY_CONVERT(TINYINT, d.completeness_score) BETWEEN 0 AND 4
  AND d.city IS NOT NULL
  AND LTRIM(RTRIM(d.city)) <> ''
  AND d.amenity IS NOT NULL
  AND LTRIM(RTRIM(d.amenity)) <> '';
GO

/*
SELECT COUNT(*) AS stg_rows FROM stg.food_places_raw;
SELECT COUNT(*) AS core_rows FROM core.food_places;

SELECT
  SUM(CASE WHEN lat IS NULL THEN 1 ELSE 0 END) AS lat_nulls,
  SUM(CASE WHEN lon IS NULL THEN 1 ELSE 0 END) AS lon_nulls
FROM core.food_places;

SELECT TOP 10 *
FROM core.food_places
ORDER BY completeness_score ASC;

*/



TRUNCATE TABLE core.city_reference;
GO

WITH dedup AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY geoid
            ORDER BY (SELECT 0)
        ) AS rn
    FROM stg.city_reference_raw
)
INSERT INTO core.city_reference (
    geoid, input_city, state_usps, gazetteer_name, acs_name,
    population, land_area_sq_miles, population_density_per_sq_mile
)
SELECT
    LTRIM(RTRIM(d.geoid)) AS geoid,
    LTRIM(RTRIM(d.input_city)) AS input_city,
    LTRIM(RTRIM(d.state_usps)) AS state_usps,
    NULLIF(LTRIM(RTRIM(d.gazetteer_name)), '') AS gazetteer_name,
    NULLIF(LTRIM(RTRIM(d.acs_name)), '') AS acs_name,
    TRY_CONVERT(INT, d.population) AS population,
    TRY_CONVERT(FLOAT, d.land_area_sq_miles) AS land_area_sq_miles,
    COALESCE(
        TRY_CONVERT(FLOAT, d.population_density_per_sq_mile),
        CASE
            WHEN TRY_CONVERT(INT, d.population) IS NOT NULL
             AND TRY_CONVERT(FLOAT, d.land_area_sq_miles) IS NOT NULL
             AND TRY_CONVERT(FLOAT, d.land_area_sq_miles) > 0
                THEN TRY_CONVERT(INT, d.population) / TRY_CONVERT(FLOAT, d.land_area_sq_miles)
            ELSE NULL
        END
    ) AS population_density_per_sq_mile
FROM dedup d
WHERE d.rn = 1
  AND d.geoid IS NOT NULL
  AND LTRIM(RTRIM(d.geoid)) <> ''
  AND d.input_city IS NOT NULL
  AND LTRIM(RTRIM(d.input_city)) <> ''
  AND d.state_usps IS NOT NULL
  AND LTRIM(RTRIM(d.state_usps)) <> ''
  AND (TRY_CONVERT(INT, d.population) IS NULL OR TRY_CONVERT(INT, d.population) >= 0)
  AND (TRY_CONVERT(FLOAT, d.land_area_sq_miles) IS NULL OR TRY_CONVERT(FLOAT, d.land_area_sq_miles) > 0)
  AND (
        COALESCE(
            TRY_CONVERT(FLOAT, d.population_density_per_sq_mile),
            CASE
                WHEN TRY_CONVERT(INT, d.population) IS NOT NULL
                 AND TRY_CONVERT(FLOAT, d.land_area_sq_miles) IS NOT NULL
                 AND TRY_CONVERT(FLOAT, d.land_area_sq_miles) > 0
                    THEN TRY_CONVERT(INT, d.population) / TRY_CONVERT(FLOAT, d.land_area_sq_miles)
                ELSE NULL
            END
        ) IS NULL
        OR COALESCE(
            TRY_CONVERT(FLOAT, d.population_density_per_sq_mile),
            CASE
                WHEN TRY_CONVERT(INT, d.population) IS NOT NULL
                 AND TRY_CONVERT(FLOAT, d.land_area_sq_miles) IS NOT NULL
                 AND TRY_CONVERT(FLOAT, d.land_area_sq_miles) > 0
                    THEN TRY_CONVERT(INT, d.population) / TRY_CONVERT(FLOAT, d.land_area_sq_miles)
                ELSE NULL
            END
        ) >= 0
      );
GO

/*
SELECT COUNT(*) AS stg_rows FROM stg.city_reference_raw;
SELECT COUNT(*) AS core_rows FROM core.city_reference;

SELECT
  SUM(CASE WHEN population IS NULL THEN 1 ELSE 0 END) AS population_nulls,
  SUM(CASE WHEN land_area_sq_miles IS NULL THEN 1 ELSE 0 END) AS land_area_nulls,
  SUM(CASE WHEN population_density_per_sq_mile IS NULL THEN 1 ELSE 0 END) AS density_nulls
FROM core.city_reference;

SELECT TOP 25 *
FROM core.city_reference
ORDER BY state_usps, input_city;

*/
