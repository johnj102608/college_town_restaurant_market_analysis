-- 05_create_mart_views.sql
-- Analytics layer (views) used for exploration + Tableau
-- Demographic-aware version

/* ------------------------------------------------------------
   1) City summary (primary overview view)
------------------------------------------------------------ */
CREATE OR ALTER VIEW mart.v_city_summary AS
WITH base AS (
    SELECT
        city,
        COUNT(*) AS total_places,
        SUM(CASE WHEN amenity = 'restaurant' THEN 1 ELSE 0 END) AS restaurants,
        SUM(CASE WHEN amenity = 'cafe' THEN 1 ELSE 0 END) AS cafes,
        SUM(CASE WHEN amenity = 'fast_food' THEN 1 ELSE 0 END) AS fast_food,
        AVG(CAST(completeness_score AS FLOAT)) AS avg_completeness_score,
        AVG(CASE WHEN has_name = 1 THEN 1.0 ELSE 0.0 END) AS pct_has_name,
        AVG(CASE WHEN has_brand = 1 THEN 1.0 ELSE 0.0 END) AS pct_has_brand,
        AVG(CASE WHEN has_website = 1 THEN 1.0 ELSE 0.0 END) AS pct_has_website,
        AVG(CASE WHEN has_opening_hours = 1 THEN 1.0 ELSE 0.0 END) AS pct_has_opening_hours
    FROM core.food_places
    GROUP BY city
)
SELECT
    b.city,
    b.total_places,
    b.restaurants,
    b.cafes,
    b.fast_food,

    CAST(b.avg_completeness_score AS DECIMAL(10,3)) AS avg_completeness_score,
    CAST(b.pct_has_name AS DECIMAL(10,3)) AS pct_has_name,
    CAST(b.pct_has_brand AS DECIMAL(10,3)) AS pct_has_brand,
    CAST(b.pct_has_website AS DECIMAL(10,3)) AS pct_has_website,
    CAST(b.pct_has_opening_hours AS DECIMAL(10,3)) AS pct_has_opening_hours,

    cr.population,
    cr.land_area_sq_miles,
    cr.population_density_per_sq_mile,

    CAST(
        CASE WHEN cr.population IS NULL OR cr.population = 0 THEN NULL
             ELSE b.total_places * 10000.0 / cr.population
        END AS DECIMAL(10,3)
    ) AS places_per_10k_people,

    CAST(
        CASE WHEN cr.land_area_sq_miles IS NULL OR cr.land_area_sq_miles = 0 THEN NULL
             ELSE b.total_places / cr.land_area_sq_miles
        END AS DECIMAL(10,3)
    ) AS places_per_sq_mile

FROM base b
LEFT JOIN core.city_reference cr
    ON b.city = cr.input_city;
GO

