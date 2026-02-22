import pandas as pd
from pathlib import Path
import re
from get_raw_data import COMBINED_DATA_PATH

RAW_PATH = Path(COMBINED_DATA_PATH)
OUT_PATH = Path("food_places_clean.csv")

TEXT_COLS = ["name", "amenity", "opening_hours", "brand", "website", "city", "osm_type"]

KEEP_COLS = [
    "osm_type","osm_id","city","amenity",
    "name","brand","website","opening_hours",
    "lat","lon",
    "has_name","has_brand","has_website","has_opening_hours",
    "completeness_score"
]

def normalize_website(url):
    if not isinstance(url, str) or not url.strip():
        return None
    url = url.strip()
    if not re.match(r"^https?://", url, flags=re.I):
        url = "https://" + url
    return url

def clean():
    df = pd.read_csv(RAW_PATH)

    # Standardize text columns
    for col in TEXT_COLS:
        df[col] = df[col].astype("string").str.strip()
    df[TEXT_COLS] = df[TEXT_COLS].replace({"": pd.NA, "None": pd.NA, "nan": pd.NA})

    # Normalize website
    df["website"] = df["website"].apply(normalize_website)

    # Ensure numeric coordinates
    df["lat"] = pd.to_numeric(df["lat"], errors="coerce")
    df["lon"] = pd.to_numeric(df["lon"], errors="coerce")
    df = df[df["lat"].between(-90, 90) & df["lon"].between(-180, 180)]

    # Flag missing data
    df["has_name"] = df["name"].notna()
    df["has_brand"] = df["brand"].notna()
    df["has_website"] = df["website"].notna()
    df["has_opening_hours"] = df["opening_hours"].notna()

    # Completeness score
    df["completeness_score"] = (
        df["has_name"].astype(int)
        + df["has_brand"].astype(int)
        + df["has_website"].astype(int)
        + df["has_opening_hours"].astype(int)
    )

    # Deduplicate keeping most complete record
    df = df.sort_values("completeness_score", ascending=False)
    df = df.drop_duplicates(subset=["osm_type", "osm_id"], keep="first")

    # Lock schema
    df = df[KEEP_COLS]

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(OUT_PATH, index=False)

    # Small report
    print(f"Saved cleaned -> {OUT_PATH}")
    print("Rows:", len(df))
    print("Avg completeness:", round(df["completeness_score"].mean(), 2))

if __name__ == "__main__":
    clean()
