-- 09_create_executive_summary_view.sql
-- Executive summary view (one row per city) for Tableau + README

CREATE OR ALTER VIEW mart.v_city_executive_summary AS
SELECT
    ms.city,

    -- Demographics
    ms.population,
    ms.land_area_sq_miles,
    cr.population_density_per_sq_mile,

    -- Market size & mix
    cs.total_places,
    cs.restaurants,
    cs.cafes,
    cs.fast_food,

    -- Density
    cs.places_per_10k_people,
    gd.official_places_per_sq_mile,

    -- Competition
    ms.pct_branded_places,
    ms.distinct_brands,
    ms.brand_hhi,

    -- Data quality
    cs.avg_completeness_score,
    cs.pct_has_name,
    cs.pct_has_brand,
    cs.pct_has_website,
    cs.pct_has_opening_hours,

    -- Ranks
    DENSE_RANK() OVER (ORDER BY gd.official_places_per_sq_mile DESC) AS official_density_rank,
    DENSE_RANK() OVER (ORDER BY ms.brand_hhi DESC) AS concentration_rank,
    DENSE_RANK() OVER (ORDER BY ms.pct_branded_places DESC) AS chain_penetration_rank,
    DENSE_RANK() OVER (ORDER BY cs.places_per_10k_people DESC) AS per_capita_rank

FROM mart.v_city_market_structure ms
LEFT JOIN mart.v_city_summary cs
    ON ms.city = cs.city
LEFT JOIN mart.v_city_geo_density gd
    ON ms.city = gd.city
LEFT JOIN core.city_reference cr
    ON ms.city = cr.input_city;
GO

/*
--checks
SELECT TOP 10 *
FROM mart.v_city_executive_summary
ORDER BY official_density_rank;

SELECT TOP 10 *
FROM mart.v_city_executive_summary
ORDER BY concentration_rank;

SELECT *
FROM mart.v_city_executive_summary
WHERE population IS NULL
   OR land_area_sq_miles IS NULL
   OR total_places IS NULL;

*/
