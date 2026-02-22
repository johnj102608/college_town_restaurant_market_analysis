-- 11_create_distribution_views.sql
-- Distribution-level analytical views


------------------------------------------------------------
-- 1) Completeness distribution by city
------------------------------------------------------------
CREATE OR ALTER VIEW mart.v_city_completeness_distribution AS
WITH base AS (
    SELECT
        city,
        completeness_score
    FROM core.food_places
),
score_counts AS (
    SELECT
        city,
        completeness_score,
        COUNT(*) AS score_count
    FROM base
    GROUP BY city, completeness_score
),
city_agg AS (
    SELECT
        city,
        COUNT(*) AS total_places,
        AVG(CAST(completeness_score AS FLOAT)) AS avg_completeness
    FROM base
    GROUP BY city
),
city_median AS (
    SELECT DISTINCT
        city,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY completeness_score)
            OVER (PARTITION BY city) AS median_completeness
    FROM base
)
SELECT
    sc.city,
    sc.completeness_score,
    CONCAT('Score ', sc.completeness_score) AS score_label,
    sc.score_count,
    ca.total_places,
    CAST(sc.score_count * 1.0 / NULLIF(ca.total_places, 0) AS DECIMAL(10,4)) AS score_pct,
    CAST(ca.avg_completeness AS DECIMAL(10,3)) AS avg_completeness,
    CAST(cm.median_completeness AS DECIMAL(10,3)) AS median_completeness
FROM score_counts sc
JOIN city_agg ca
    ON sc.city = ca.city
JOIN city_median cm
    ON sc.city = cm.city;
GO



------------------------------------------------------------
-- 2) Chain vs Independent distribution by amenity
------------------------------------------------------------
CREATE OR ALTER VIEW mart.v_amenity_chain_distribution AS
WITH base AS (
    SELECT
        city,
        amenity,
        CASE WHEN brand IS NOT NULL THEN 'Chain'
             ELSE 'Independent' END AS place_type
    FROM core.food_places
),
counts AS (
    SELECT
        city,
        amenity,
        place_type,
        COUNT(*) AS place_count
    FROM base
    GROUP BY city, amenity, place_type
),
totals AS (
    SELECT
        city,
        amenity,
        COUNT(*) AS total_amenity_places
    FROM core.food_places
    GROUP BY city, amenity
)
SELECT
    c.city,
    c.amenity,
    c.place_type,
    c.place_count,
    t.total_amenity_places,
    CAST(c.place_count * 1.0 / NULLIF(t.total_amenity_places,0)
         AS DECIMAL(10,4)) AS place_pct
FROM counts c
JOIN totals t
    ON c.city = t.city
   AND c.amenity = t.amenity;
GO

