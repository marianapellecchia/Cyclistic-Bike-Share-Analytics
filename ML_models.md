# Machine Learning Models — Behavioral Pattern Validation

![Machine Learning](https://img.shields.io/badge/Goal-Model%20Validation-orange?style=for-the-badge)
![Logistic Regression](https://img.shields.io/badge/Model-Logistic%20Regression-blue?style=for-the-badge)
![Random Forest](https://img.shields.io/badge/Model-Random%20Forest-green?style=for-the-badge)

**Goal:** quantitatively validate whether **duration**, **time patterns**, **stations**, and **weather** robustly explain the difference between **Member** and **Casual** riders.

---

## 1) Setup & Dataset

- **Dataset:** `trips_with_weather` (stratified sample from ~21M records)  
- **Target:** `user_type` = Member vs Casual  
- **Train/Test split:** 70/30 (stratified)

**Main feature groups**

- **Usage & time**
  - `duration_min`
  - `time_bin` (Night, Morning, Afternoon, Evening)
  - `is_weekend`
  - `year`

- **Bike type**
  - `bike_type` (classic, electric, other)

- **Stations (leakage-aware)**
  - `start_station_cat` (tourist, commuter, mixed)
  - `end_station_cat` (tourist, commuter, mixed)

- **Weather**
  - `season` (Winter, Spring, Summer, Autumn)
  - `temp_bin` (<5°C, 5–15°C, 15–25°C, ≥25°C)
  - `rain`
  - `is_snowing`
  - `wspd_category` (light, moderate, strong)

---

## 2) Trained Models

1) **Logistic Regression**
- interpretable baseline
- coefficients reported as **odds ratios**

2) **Random Forest**
- non-linear model capturing interactions
- trained on a stratified train sub-sample (5% per class), evaluated on the full test set

---

## 3) High-level Performance

| Metric | Logistic Regression | Random Forest |
|---|---:|---:|
| Accuracy | ~0.703 | **~0.706** |
| ROC AUC | ~0.737 | **~0.744** |
| Sensitivity (Casual) | ~0.41 | ~0.43 |
| Specificity (Member) | ~0.89 | ~0.88 |

- Both models exceed the **No Information Rate** (~0.61).  
- Random Forest is slightly better in AUC and accuracy.  
- Both are more accurate at identifying **Members** (more regular patterns) than **Casual** riders (noisier behavior).

---

## 4) Key Drivers (Logistic Regression)

Coefficients are interpreted as **odds ratios (OR)** for the probability of being a **Member**.

**Duration (`duration_min`)** — OR ~0.98 per minute  
- Every +10 minutes ≈ ~20% lower odds of being a Member  
➡ Longer rides are strongly associated with Casual behavior.

**Time & calendar**  
- Morning / Afternoon / Evening vs Night → OR > 1  
- `is_weekend` → OR < 1  
➡ Weekdays and morning peaks align with commuting; weekends shift the mix toward Casual riders.

**Temporal evolution (`year`)** — OR > 1  
➡ Over time, the relative share of Members increases, consistent with the service consolidating as a regular transport option.

**Bike type**  
- `bike_type = other` → OR ≪ 1  
- `bike_type = electric` → OR < 1  
➡ “Docked/other” skews heavily Casual; e-bikes are more associated with leisure-friendly usage.

**Stations**  
- `station_cat = tourist` → OR < 1  
- `station_cat = commuter` → OR > 1  
➡ Station categories strongly differentiate tourism vs commuting contexts.

**Season & weather**  
- Non-winter seasons → OR < 1 (vs winter)  
- Rain/snow → OR > 1  
➡ Under adverse conditions, the remaining demand tends to skew toward Members.

---

## 5) Feature Importance (Random Forest)

Approximate importance ranking:

1. **`duration_min`**  
2. **`end_station_cat`**  
3. **`bike_type`**  
4. `start_station_cat`  
5. `is_weekend`  
6. `temp_bin`  
7. `time_bin`  
8. `year`, `season`  
9. `rain`, `wspd_category`, `is_snowing`

➡ The non-linear model confirms the same hierarchy observed in EDA: **duration, stations, and time** dominate; **weather** modulates the segment mix.

---

## 6) Interpretation & Limitations

- Models are designed for **pattern validation**, not production deployment.
- Stronger at recognizing Members; less precise on all Casual cases (more heterogeneous behavior).
- For conversion-oriented objectives (e.g., “high-potential Casual”), next steps could include:
  - threshold tuning (≠ 0.5)
  - class weights / cost-sensitive learning
  - a dedicated model for “high conversion propensity” Casual riders

---

## 7) Links
- EDA: [EDA.md](EDA.md)  
- Pipeline: [pipeline_details.md](pipeline_details.md)  
- Strategy: [Strategic_Recommendations.md](Strategic_Recommendations.md)  
- R script: `r/04_machine_learning_models.R`