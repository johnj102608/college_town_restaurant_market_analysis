import requests
import pandas as pd
from pathlib import Path

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
CITY_NAMES = ["Champaign", "Madison", "Ann Arbor", "College Station", "West Lafayette",
              "Bellingham", "Pittsburgh", "Princeton", "Davis", "Chapel Hill"]
CSV_PATH = "_food_places_raw.csv"
COMBINED_DATA_PATH = "Combined" + CSV_PATH

def create_query(city):
    query = f"""
[out:json][timeout:60];
area["name"="{city}"]["boundary"="administrative"]->.a;
(
    nwr(area.a)["amenity"="restaurant"];
    nwr(area.a)["amenity"="cafe"];
    nwr(area.a)["amenity"="fast_food"];
);
out center tags;
"""
    #print(query)
    return query

def call_overpass(city):
    # A descriptive User-Agent is good practice for public services
    headers = {
        "User-Agent": "portfolio-osm-accessibility/1.0"
    }
    query = create_query(city)
    resp = requests.post(OVERPASS_URL, data={"data": query}, headers=headers, timeout=120)
    resp.raise_for_status()
    data = resp.json()

    rows = []
    for el in data.get("elements", []):
        tags = el.get("tags", {}) or {}

        # Nodes have lat/lon directly.
        if "lat" in el and "lon" in el:
            lat, lon = el["lat"], el["lon"]
        elif "center" in el:
            lat, lon = el["center"]["lat"], el["center"]["lon"]
        else:
            continue  # skip anything without a usable point

        rows.append({
            "osm_type": el.get("type"),
            "osm_id": el.get("id"),
            "name": tags.get("name"),
            "amenity": tags.get("amenity"),
            "lat": lat,
            "lon": lon,
            "opening_hours": tags.get("opening_hours"),
            "brand": tags.get("brand"),
            "website": tags.get("website"),
        })

    temp_df = pd.DataFrame(rows)
    print("Rows:", len(temp_df))
    print(temp_df.head(10))
    
    temp_df.to_csv(city + CSV_PATH, index=False)
    print("Saved -> "+ city + CSV_PATH)

    return temp_df

def main():
    df_cities = {}
    for city in CITY_NAMES:
        if Path(city + CSV_PATH).exists():
            print("Using cached data for " + city)
            df_cities[city] = pd.read_csv(city + CSV_PATH)
        else:
            df_cities[city] = call_overpass(city)

    # Add city column
    for city, df in df_cities.items():
        df["city"] = city

    # Combine
    df_combined = pd.concat(df_cities.values(), ignore_index=True)
    out_path = COMBINED_DATA_PATH
    df_combined.to_csv(out_path, index=False)
    print("Saved combined -> " + out_path)


'''
    print("Missing names:", df["name"].isna().mean())
    print("Missing opening_hours:", df["opening_hours"].isna().mean())
    print("Unique osm objects:", df[["osm_type", "osm_id"]].drop_duplicates().shape[0])
'''

if __name__ == "__main__":
    main()
