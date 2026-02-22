CREATE OR ALTER VIEW mart.v_city_competitive_typology AS
WITH base AS (
    SELECT
        city,
        places_per_10k_people,
        brand_hhi
    FROM mart.v_city_executive_summary
),
medians AS (
    SELECT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY places_per_10k_people)
            OVER () AS median_per_capita,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY brand_hhi)
            OVER () AS median_hhi
    FROM base
)
SELECT DISTINCT
    b.city,
    b.places_per_10k_people,
    b.brand_hhi,
    CASE
        WHEN b.places_per_10k_people >= m.median_per_capita
             AND b.brand_hhi >= m.median_hhi
            THEN 'Saturated & Dominated'
        WHEN b.places_per_10k_people >= m.median_per_capita
             AND b.brand_hhi < m.median_hhi
            THEN 'Saturated & Fragmented'
        WHEN b.places_per_10k_people < m.median_per_capita
             AND b.brand_hhi >= m.median_hhi
            THEN 'Sparse & Dominated'
        ELSE 'Sparse & Fragmented'
    END AS competitive_type
FROM base b
CROSS JOIN (SELECT TOP 1 * FROM medians) m;
GO


CREATE OR ALTER VIEW mart.v_city_brand_concentration_detail AS
WITH brand_counts AS (
    SELECT
        city,
        brand,
        COUNT(*) AS brand_locations
    FROM core.food_places
    WHERE brand IS NOT NULL
    GROUP BY city, brand
),
ranked AS (
    SELECT
        city,
        brand,
        brand_locations,
        DENSE_RANK() OVER (
            PARTITION BY city
            ORDER BY brand_locations DESC
        ) AS brand_rank
    FROM brand_counts
),
totals AS (
    SELECT
        city,
        SUM(brand_locations) AS total_branded
    FROM brand_counts
    GROUP BY city
)
SELECT
    r.city,
    CAST(
        CAST(SUM(CASE WHEN r.brand_rank = 1 THEN r.brand_locations ELSE 0 END) AS FLOAT)
        / NULLIF(CAST(t.total_branded AS FLOAT), 0)
    AS DECIMAL(10,4)) AS top_1_share,
    CAST(
        CAST(SUM(CASE WHEN r.brand_rank <= 3 THEN r.brand_locations ELSE 0 END) AS FLOAT)
        / NULLIF(CAST(t.total_branded AS FLOAT), 0)
    AS DECIMAL(10,4)) AS top_3_share
FROM ranked r
JOIN totals t
    ON r.city = t.city
GROUP BY
    r.city,
    t.total_branded;
GO



CREATE OR ALTER VIEW mart.v_city_digital_advantage_gap AS
WITH base AS (
    SELECT
        city,
        CASE WHEN brand IS NOT NULL THEN 1 ELSE 0 END AS is_chain,
        has_website,
        has_opening_hours
    FROM core.food_places
),
agg AS (
    SELECT
        city,
        is_chain,
        AVG(CASE WHEN has_website = 1 THEN 1.0 ELSE 0.0 END) AS pct_website,
        AVG(CASE WHEN has_opening_hours = 1 THEN 1.0 ELSE 0.0 END) AS pct_hours
    FROM base
    GROUP BY city, is_chain
)
SELECT
    a.city,
    MAX(CASE WHEN is_chain = 1 THEN pct_website END)
      - MAX(CASE WHEN is_chain = 0 THEN pct_website END)
      AS website_advantage_gap,
    MAX(CASE WHEN is_chain = 1 THEN pct_hours END)
      - MAX(CASE WHEN is_chain = 0 THEN pct_hours END)
      AS hours_advantage_gap
FROM agg a
GROUP BY a.city;
GO
