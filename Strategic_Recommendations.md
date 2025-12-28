# Strategic Recommendations — Data-Driven Actions

![Users Breakdown](https://img.shields.io/badge/Casual%2038.9%25%20%7C%20Member%2061.1%25-blue)
![Primary Driver](https://img.shields.io/badge/Top%20Driver-Ride%20Duration-purple)
![Peak Conversion](https://img.shields.io/badge/Conversion%20Window-Summer%20%7C%20Weekend-yellow)
![Low Conversion](https://img.shields.io/badge/NO%20Conversion-Cold%20%7C%20Rain-red)
![Geo Insight](https://img.shields.io/badge/Hotspots-Tourist%20vs%20Commuter-orange)
![Resource Strategy](https://img.shields.io/badge/Fleet-Seasonal%20Rebalancing-green)

EDA and predictive checks (Logistic Regression + Random Forest) consistently highlight two distinct rider segments:

- **Members (commuters)** → shorter, recurring, “all-weather” usage  
- **Casual riders (leisure/tourism)** → longer trips, highly seasonal, weather-sensitive  

Key behavioral drivers supported by the models include:
- **Ride duration** (top feature)
- **Station category** (tourist vs commuter hubs)
- **Time patterns** (time-of-day, weekend effect)
- **Seasonality and weather conditions**

These findings inform the recommendations below.

---

## 1) Member Strategy (Retention & Commuting)

**Goal:** increase renewals, reinforce commuter usage, and sustain demand in adverse conditions.

### Actions

- **Strengthen commuting usage**
  - corporate partnerships  
  - home–work incentives  
  - targeted offers for **7–9 AM** and **4–6 PM**  
  *Rationale:* commuter hubs show stable year-round patterns and strong association with Member behavior.

- **Winter “all-weather” retention campaigns**
  - safety kit messaging  
  - e-bike visibility and comfort positioning  
  *Rationale:* in poor weather, the remaining demand tends to skew toward Members → realistic messaging supports retention rather than conversion.

- **Upgrade comfort in business areas**
  - prioritize e-bike availability  
  - increase station density in business districts  
  *Rationale:* e-bikes are often associated with functional rides when stations are not primarily tourist-oriented.

---

## 2) Casual Strategy (Selective Conversion)

**Goal:** convert only when Casual behavior resembles high-intent, membership-like usage.

### High-probability conversion window
- mild season (**15–25°C**)  
- weekends  
- tourist hotspots  
- longer rides  

### Actions

- **Targeted offers at tourist hotspots (Apr–Sep)**
  - “3-day pass → annual membership upgrade”  
  *Rationale:* tourist stations are strongly associated with Casual usage, making them ideal campaign entry points.

- **Post-long-ride prompts**
  - in-app/email nudges after long rides (savings message, upgrade bundles)  
  *Rationale:* longer ride duration is a strong signal of Casual behavior and a practical trigger for conversion prompts.

- **Lifestyle / younger audience targeting**
  - gamification, social initiatives, micro-incentives  
  *Rationale:* usage concentrates in summer and leisure time (often afternoons/weekends), where engagement tactics perform best.

---

## 3) Fleet Strategy (Operational Optimization)

### Actions

- **Increase e-bike availability**
  - reduces effort under heat and moderate wind  
  *Rationale:* bike type is among the most relevant model signals and can improve perceived convenience.

- **Reduce obsolete docked fleet**
  *Rationale:* docked bikes are strongly skewed toward low-conversion Casual usage and may deliver lower ROI vs modern bike types.

- **Dynamic seasonal rebalancing**
  - summer: allocate more bikes to tourist areas  
  - winter: reinforce commuting hubs  
  *Rationale:* Member demand is more stable while Casual demand is highly seasonal → fleet should follow predictable cycles.

---

## 4) Where NOT to Invest (Low ROI)

### Avoid these contexts

| Condition | Why |
|---|---|
| **Cold < 5°C** | Casual demand drops sharply |
| **Rain / strong wind** | demand skews heavily toward residual Members → low conversion potential |
| **Hot > 25°C** | fragmented usage and lower membership intent |

➡ Marketing and promotions in these conditions typically generate **low ROI**.

---

## 5) Final Summary

Across EDA and modeling checks, patterns are coherent and stable. The highest-impact levers are:
- **ride duration** (top driver)  
- **station category**  
- **time-of-day / weekend effect**  
- **seasonality and weather**  
- **bike type**

The optimal strategy is dual:

1) **Consolidate Members** → commuting, comfort, winter retention  
2) **Selectively convert Casual riders** only in high-propensity contexts → summer + weekend + hotspots + long rides  

This maximizes conversions and fleet utilization through targeted investments.

---

## 🔗 Links

- ML models: [ML_models.md](ML_models.md)  
- EDA: [EDA.md](EDA.md)  
- Pipeline: [pipeline_details.md](pipeline_details.md)