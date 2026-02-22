-- 03_create_core_table.sql

IF OBJECT_ID('core.food_places', 'U') IS NOT NULL
    DROP TABLE core.food_places;
GO

CREATE TABLE core.food_places (
    osm_type            NVARCHAR(50)  NOT NULL,
    osm_id              BIGINT        NOT NULL,
    city                NVARCHAR(100) NOT NULL,
    amenity             NVARCHAR(50)  NOT NULL,
    name                NVARCHAR(255) NULL,
    brand               NVARCHAR(255) NULL,
    website             NVARCHAR(255) NULL,
    opening_hours       NVARCHAR(255) NULL,
    lat                 FLOAT         NOT NULL,
    lon                 FLOAT         NOT NULL,
    has_name            BIT           NOT NULL,
    has_brand           BIT           NOT NULL,
    has_website         BIT           NOT NULL,
    has_opening_hours   BIT           NOT NULL,
    completeness_score  TINYINT       NOT NULL,

    CONSTRAINT PK_core_food_places PRIMARY KEY (osm_type, osm_id),

    CONSTRAINT CK_core_food_places_completeness_score
        CHECK (completeness_score BETWEEN 0 AND 4),

    CONSTRAINT CK_core_food_places_lat_range
        CHECK (lat BETWEEN -90 AND 90),

    CONSTRAINT CK_core_food_places_lon_range
        CHECK (lon BETWEEN -180 AND 180)
);
GO


IF OBJECT_ID('core.city_reference', 'U') IS NOT NULL
    DROP TABLE core.city_reference;
GO

CREATE TABLE core.city_reference (
    geoid                          NVARCHAR(20)  NOT NULL,
    input_city                     NVARCHAR(100) NOT NULL,
    state_usps                     NVARCHAR(10)  NOT NULL,
    gazetteer_name                 NVARCHAR(255) NULL,
    acs_name                       NVARCHAR(255) NULL,
    population                     INT           NULL,
    land_area_sq_miles             FLOAT         NULL,
    population_density_per_sq_mile FLOAT         NULL,

    CONSTRAINT PK_core_city_reference
        PRIMARY KEY (geoid),

    CONSTRAINT CK_core_city_reference_population_nonneg
        CHECK (population IS NULL OR population >= 0),

    CONSTRAINT CK_core_city_reference_land_area_positive
        CHECK (land_area_sq_miles IS NULL OR land_area_sq_miles > 0),

    CONSTRAINT CK_core_city_reference_density_nonneg
        CHECK (population_density_per_sq_mile IS NULL OR population_density_per_sq_mile >= 0)
);
GO

