/* ------------------------------------------------------------
   1. Row counts
------------------------------------------------------------ */
SELECT COUNT(*) AS staging_rows
FROM stg.food_places_raw;

SELECT COUNT(*) AS core_rows
FROM core.food_places;


/* ------------------------------------------------------------
   2. Duplicate check (should be zero)
------------------------------------------------------------ */
SELECT
    osm_type,
    osm_id,
    COUNT(*) AS duplicate_count
FROM core.food_places
GROUP BY osm_type, osm_id
HAVING COUNT(*) > 1;


/* ------------------------------------------------------------
   3. Coordinate sanity check
------------------------------------------------------------ */
SELECT
    SUM(CASE WHEN lat NOT BETWEEN -90 AND 90 THEN 1 ELSE 0 END) AS invalid_lat,
    SUM(CASE WHEN lon NOT BETWEEN -180 AND 180 THEN 1 ELSE 0 END) AS invalid_lon
FROM core.food_places;


/* ------------------------------------------------------------
   4. Missing data summary
------------------------------------------------------------ */
SELECT
    city,
    COUNT(*) AS total_places,
    SUM(CASE WHEN has_website = 0 THEN 1 ELSE 0 END) AS missing_website,
    SUM(CASE WHEN has_opening_hours = 0 THEN 1 ELSE 0 END) AS missing_opening_hours,
    SUM(CASE WHEN has_brand = 0 THEN 1 ELSE 0 END) AS missing_brand
FROM core.food_places
GROUP BY city
ORDER BY total_places DESC;


/* ------------------------------------------------------------
   5. Amenity distribution
------------------------------------------------------------ */
SELECT
    amenity,
    COUNT(*) AS total_places
FROM core.food_places
GROUP BY amenity
ORDER BY total_places DESC;
