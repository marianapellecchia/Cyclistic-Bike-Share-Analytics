# Advanced Exploratory Data Analysis (EDA)

![R](https://img.shields.io/badge/R-276DC3?style=for-the-badge&logo=r&logoColor=white)
![DBPLYR](https://img.shields.io/badge/DBPLYR-316192?style=for-the-badge&logo=r&logoColor=white)
![Meteostat](https://img.shields.io/badge/Meteostat-Weather-blue?style=for-the-badge)
![EDA](https://img.shields.io/badge/Exploratory%20Analysis-Business%20Insights-blue?style=for-the-badge)
![Segmentation](https://img.shields.io/badge/Segmentation-Behavioral%20Dichotomy-red?style=for-the-badge)
![Geospatial](https://img.shields.io/badge/Analysis%20Scope-Geospatial%2FLocation-orange?style=for-the-badge)

Descriptive analysis on **20M+ rides** to identify behavioral patterns useful for modeling and business strategy.  
Segments: **Member (commuters)** vs **Casual (leisure/tourism)**.

Dataset: `trips_with_weather`

---

## 1) User Mix

The two segments show very different volume patterns and stability.

| Segment | Mix % | Insight |
|---|---:|---|
| **Member** | **61%** | More stable and predictable demand |
| **Casual** | **39%** | Highly seasonal demand |

![](images/composizioneutenti.png)

**Key pattern:** Members sustain year-round usage; Casual riders drive concentrated peaks.

---

## 2) Ride Duration (Primary Driver)

Ride duration is the most discriminative variable.

| Segment | Avg. | Median | Interpretation |
|---|---:|---:|---|
| **Member** | ~**12.7 min** | 9.1 min | Functional / commuting usage |
| **Casual** | ~**24.9 min** | 14.3 min | Leisure / tourist usage |

![](images/duratadellecorse.png)

➡ Longer rides are a strong signal of Casual behavior and will be a key driver in downstream modeling.

---

## 3) Temporal Patterns

### 3.1 Day of Week
| Dimension | Member | Casual |
|---|---|---|
| Peak days | Mon–Thu | Fri–Sun |
| Behavior | commuting | leisure |

![](images/weekendvsweekday.png)

### 3.2 Time of Day
- **7–9 / 16–18** → Member dominance (commuting peaks)
- **12–18** → Casual dominance (leisure window)

![](images/oredelgiorno.png)

![](images/fasciaoraria.png)

### 3.3 Annual Seasonality
- **Members:** moderate winter decline
- **Casual:** volume concentrated in **Apr–Sep**, peak in **Jul–Aug**

![](images/stagioni.png)

➡ Seasonality is one of the most informative dimensions for the Casual segment.

---

## 4) Spatial Dimension

### 4.1 Stations
Geographic distribution is consistent with the two segments:

| Segment | Typical locations |
|---|---|
| **Member** | commuting hubs, business/residential areas |
| **Casual** | waterfront, museums, parks, tourist areas |

![](images/stazioni.png)

➡ Stations act as a behavioral proxy (commuting vs leisure context).

### 4.2 Bike Type
- **Classic bike:** dominant across both segments
- **E-bike:** increasing, more used by Casual riders
- **Docked / electric scooter:** mostly Casual

![](images/bike.png)

---

## 5) Weather: Effects on Volume and Segment Mix

Weather impacts not only overall volume, but also **who** uses the service.

### 5.1 Temperature
Temperature is the strongest weather driver and shows distinct behavioral profiles:

- **< 5°C (Cold):** sharp drop in Casual demand (~−80%); Members remain relatively more active  
- **5–15°C (Cool):** transition phase; weekday Members show higher resilience  
- **15–25°C (Mild):** ideal conditions → highest baseline usage for both segments  
- **≥ 25°C (Hot):** larger reduction for Members (especially on weekends)

![](images/sensibilitàtermica.png)

➡ Extreme temperatures widen the gap between the two segments.

### 5.2 Rain
Rain reduces volume for both segments, but tends to leave a higher share of functional riders.

- **Casual:** −67%  
- **Member:** −63%

![](images/pioggia.png)

➡ Members keep relatively higher usage → closer to “necessary” commuting behavior rather than leisure.

### 5.3 Snow
Snow is a system-wide constraint rather than a behavioral filter:
- usage drops close to zero for both segments
- service becomes less practical even for commuters

![](images/neve.png)

➡ Snow is a boundary condition: it suppresses demand across the board.

### 5.4 Wind
Wind has a material impact, especially at moderate levels (20–40 km/h):

- **Light wind (< 20 km/h):** baseline  
- **Moderate wind (20–40 km/h):** strong reduction for both  
  1) Casual: −82.7%  
  2) Member: −78.9%  
- **Strong wind (≥ 40 km/h):** near-zero rides (prohibitive conditions)

![](images/vento.png)

➡ Wind behaves as a physical barrier more than a segment differentiator.

---

## Operational Outputs from EDA

This EDA supports the predictive and strategy phase by:
- identifying truly informative features (reducing redundancy and leakage risk)
- showing that Member/Casual patterns are structured and stable over time
- highlighting behaviors that remain consistent across years
- providing a coherent basis for business recommendations and conversion strategy

---

## Links
- Pipeline: [pipeline_details.md](pipeline_details.md)  
- ML models: [ML_models.md](ML_models.md)