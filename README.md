# College Town Restaurant Market Entry Analysis  
Evaluating Structural Attractiveness of U.S. College Towns for New Restaurant Entry

---

## Overview

This project evaluates which U.S. college towns are structurally attractive for launching a new restaurant by analyzing demand scale, competitive saturation, market concentration, and operator ecosystem characteristics.

Rather than focusing purely on correlations, the analysis builds a structured market entry decision framework grounded in economic reasoning and competitive structure.

Positioning: Data Analyst → Business / Strategy Analyst

---

## Business Question

What type of college town offers the most structurally attractive entry conditions for a new restaurant?

The objective is to move beyond surface metrics (e.g., population size) and evaluate:

- Where demand meaningfully exceeds competitive saturation  
- How concentrated or fragmented the competitive landscape is  
- What structural risks would a new entrant face  

---

## Data Sources

- OpenStreetMap (OSM) — Restaurant Points of Interest  
- U.S. Census API — Population and Land Area Data  

---

## Architecture and Methodology

### 1. Data Collection (Python)
- Pulled restaurant POIs via OSM  
- Retrieved population and land area data via Census API  
- Cleaned and standardized datasets  

### 2. SQL Layered Modeling

Structured pipeline:

- Staging layer (clean ingestion)  
- Core fact table  
- Analytical views  
- Competitive typology classification  

### Engineered Metrics

- Population  
- Population density  
- Restaurant count  
- Restaurants per 10,000 residents  
- Restaurants per square mile  
- Distinct brands  
- Percent branded (chain penetration)  
- Brand HHI (market concentration)  
- Percent with website  
- Website advantage gap (chain vs. independent)  

---

## Key Structural Insights

### 1. Market Size Drives Ecosystem Scale
- Population strongly predicts total restaurant count  
- Population strongly predicts distinct brand count  

Larger markets support deeper ecosystems, but not necessarily higher concentration.

---

### 2. Spatial Density Drives Clustering
- Population density predicts restaurant density per square mile  
- Density does not strongly predict brand diversity or concentration  

Urban form influences clustering, not dominance.

---

### 3. Chain Penetration Does Not Equal Market Concentration
- High percent branded does not automatically imply high HHI  
- Some chain-heavy markets remain fragmented  

Competitive structure must be measured directly rather than inferred.

---

## Market Entry Quadrant Framework

Cities are segmented using:

- X-axis: Population (Demand Strength)  
- Y-axis: Restaurants per 10,000 residents (Competitive Saturation)  

| Quadrant | Interpretation |
|----------|----------------|
| High Demand / Low Saturation | Structurally Attractive |
| High Demand / High Saturation | Competitive Large Market |
| Low Demand / Low Saturation | Niche Opportunity |
| Low Demand / High Saturation | Structurally Challenging |

This reframes the evaluation from descriptive metrics to a decision-oriented strategy.

---

## Competitive Typology

Markets are further segmented by:

- Saturation level  
- Competitive dominance (HHI and chain penetration)  

Resulting types:

- Saturated and Dominated  
- Saturated and Fragmented  
- Sparse and Dominated  
- Sparse and Fragmented  


---

## Digital Signal (Supplementary)

- Chains outperform independents in website presence  
- Digital maturity appears operator-driven rather than structurally driven  

Digital presence acts as a competitive enhancer, not a primary structural determinant.

---

## Dashboard Overview (Tableau Public)

1. Market Entry Landscape – Decision framework and quadrant segmentation  
2. Structural Market Dynamics – Explains scaling and density effects  
3. Competitive Environment Profile – Competitive battlefield analysis  

Tableau Public Link:  
https://public.tableau.com/views/college-town-restaurant-market-analysis/QuadrantDashboard?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link

---

## Project Structure

```
college-town-restaurant-market-analysis/
│
├── python/     # Data collection, cleaning, and analysis scripts
├── sql/        # SQL schema, transformations, and queries
├── data/       # Raw and processed datasets
├── tableau/    # Tableau workbook and dashboard files
│
└── README.md   # Project documentation
```

---

## What This Project Demonstrates

- End-to-end data engineering workflow  
- Structured metric design  
- Competitive market decomposition  
- Decision-oriented analytical framing  
- Executive-level communication clarity  

This project builds a defensible market entry evaluation framework grounded in economic structure rather than surface-level correlation analysis.
