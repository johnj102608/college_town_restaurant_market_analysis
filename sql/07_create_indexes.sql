CREATE INDEX IX_food_places_city
ON core.food_places(city);

CREATE INDEX IX_food_places_city_amenity
ON core.food_places(city, amenity);

CREATE INDEX IX_food_places_brand
ON core.food_places(brand)
WHERE brand IS NOT NULL;
