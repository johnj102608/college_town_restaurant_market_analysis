API_KEY = ""
# API_KEY removed for Github purpose

import requests
import pandas as pd
from io import BytesIO
import zipfile
import difflib
import re

# ==========================
# CONFIG
# ==========================
YEAR = "2022"  # use the same year for ACS and Gazetteer

TARGETS = [
    ("Champaign", "IL"),
    ("Madison", "WI"),
    ("Ann Arbor", "MI"),
    ("College Station", "TX"),
    ("West Lafayette", "IN"),
    ("Bellingham", "WA"),
    ("Pittsburgh", "PA"),
    ("Princeton", "NJ"),
    ("Davis", "CA"),
    ("Chapel Hill", "NC")
]

# ==========================
# HELPERS
# ==========================
def normalize_place_name(s: str) -> str:
    """Normalize to compare user input with Gazetteer NAME."""
    s = s.lower().strip()
    s = s.replace("saint", "st")  # help match Saint vs St
    s = re.sub(r"[^\w\s]", "", s)  # remove punctuation
    s = re.sub(r"\s+", " ", s)
    # remove common place type words to reduce mismatch
    for token in [" city", " town", " village", " borough", " cdp", " municipality"]:
        s = s.replace(token, "")
    return s.strip()

def load_gazetteer_places(year: str) -> pd.DataFrame:
    """Download and load the Gazetteer places file for the given year."""
    gaz_zip_url = (
        f"https://www2.census.gov/geo/docs/maps-data/data/gazetteer/"
        f"{year}_Gazetteer/{year}_Gaz_place_national.zip"
    )
    resp = requests.get(gaz_zip_url, timeout=60)
    resp.raise_for_status()

    with zipfile.ZipFile(BytesIO(resp.content)) as z:
        txt_name = next((n for n in z.namelist() if n.lower().endswith(".txt")), None)
        if not txt_name:
            raise FileNotFoundError("No .txt found inside Gazetteer zip.")
        with z.open(txt_name) as f:
            df = pd.read_csv(f, sep="\t", dtype=str)

    # Make numeric columns numeric where helpful
    for col in ["ALAND_SQMI", "AWATER_SQMI", "INTPTLAT", "INTPTLONG"]:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    # Add normalized name for matching
    df["NAME_norm"] = df["NAME"].astype(str).map(normalize_place_name)
    return df

def find_place_row(gaz_df: pd.DataFrame, city: str, usps: str) -> pd.Series:
    """Find the best matching Gazetteer place row for a city in a specific state."""
    subset = gaz_df[gaz_df["USPS"] == usps].copy()
    if subset.empty:
        raise ValueError(f"No Gazetteer entries found for state USPS={usps}")

    want = normalize_place_name(city)

    # 1) exact normalized match
    exact = subset[subset["NAME_norm"] == want]
    if len(exact) == 1:
        return exact.iloc[0]
    if len(exact) > 1:
        # pick the largest land area if duplicates exist (rare but possible)
        return exact.sort_values("ALAND_SQMI", ascending=False).iloc[0]

    # 2) fuzzy match within the state
    choices = subset["NAME_norm"].tolist()
    best = difflib.get_close_matches(want, choices, n=1, cutoff=0.75)
    if not best:
        # helpful debug: show a few close-ish candidates
        near = difflib.get_close_matches(want, choices, n=5, cutoff=0.6)
        raise ValueError(
            f"Could not confidently match '{city}, {usps}'. "
            f"Try one of these Gazetteer-style names in {usps}: {near}"
        )

    match_norm = best[0]
    matched = subset[subset["NAME_norm"] == match_norm]
    return matched.sort_values("ALAND_SQMI", ascending=False).iloc[0]

def get_acs_population(year: str, state_fips: str, place_fips: str, api_key: str) -> dict:
    """Fetch ACS population for a place."""
    url = f"https://api.census.gov/data/{year}/acs/acs5"
    params = {
        "get": "NAME,B01003_001E",
        "for": f"place:{place_fips}",
        "in": f"state:{state_fips}",
        "key": api_key,
    }
    r = requests.get(url, params=params, timeout=60)
    r.raise_for_status()
    j = r.json()
    row = dict(zip(j[0], j[1]))
    return {
        "acs_name": row["NAME"],
        "population": int(row["B01003_001E"]),
    }

# ==========================
# MAIN
# ==========================
gaz_df = load_gazetteer_places(YEAR)

rows = []
for city, usps in TARGETS:
    place_row = find_place_row(gaz_df, city, usps)

    geoid = place_row["GEOID"]          # state(2) + place(5)
    state_fips = geoid[:2]
    place_fips = geoid[2:]

    acs = get_acs_population(YEAR, state_fips, place_fips, API_KEY)

    land_sqmi = float(place_row["ALAND_SQMI"])
    density = acs["population"] / land_sqmi if land_sqmi else None

    rows.append({
        "input_city": city,
        "state_usps": usps,

        # "actual names in the data"
        "gazetteer_name": place_row["NAME"],     # e.g., "Champaign city"
        "acs_name": acs["acs_name"],             # e.g., "Champaign city, Illinois"

        #"state_fips": state_fips,
        #"place_fips": place_fips,
        "geoid": geoid,

        "population": acs["population"],
        "land_area_sq_miles": land_sqmi,
        "population_density_per_sq_mile": density,
    })

out = pd.DataFrame(rows).sort_values(["state_usps", "input_city"])
print(out)

# output to csv
out.to_csv("city_data.csv", index=False)



