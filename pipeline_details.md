# Data Pipeline — SQL + R (2021–2025)

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-316192?logo=postgresql&logoColor=white)
![R](https://img.shields.io/badge/R-4.5.1-276DC3?logo=r&logoColor=white)
![ETL](https://img.shields.io/badge/ETL-Pipeline-orange)
![Data Cleaning](https://img.shields.io/badge/Data%20Quality-High-green)
![Big Data](https://img.shields.io/badge/Data%20Volume-Big%20Data-red)

Technical documentation of the pipeline used to ingest, clean, enrich with weather data, and build the final analytics dataset (`trips_with_weather`).

---

## Architecture

Hybrid **R + PostgreSQL** pipeline designed to handle ~28M records:

- **R (data.table)** → high-speed CSV ingestion
- **PostgreSQL** → storage, cleaning, feature engineering
- **R (dbplyr)** → light transformations/analysis without exporting raw data
- **Meteostat** → multi-year weather enrichment (temperature, rain, snow, wind)

---

## Pipeline Workflow

### 1) Ingestion (R → PostgreSQL)
- 58 monthly files (2021–2025), ~28M total rows
- Import via `fread()` for speed
- Append into raw table `trip_raw`

**Main script:** `r/01_connect_and_import.R`

```r
dt <- fread(f)
dbWriteTable(con, "trip_raw", value = dt, append = TRUE)
```
### 2) Cleaning & Feature Engineering (SQL)

Create `trip_prepared`:

1. Compute ride duration (ended_at - started_at)
2. Extract time attributes (year, month, day, hour)
3. Weekend flag (Fri–Sun)
4. Time-of-day bands (Night, Morning, Afternoon, Evening)

*Example sql/:*

``` sql
CREATE TABLE trip_prepared AS
SELECT ride_id, rideable_type, started_at, ended_at, start_station_name, start_station_id, end_station_name, end_station_id, member_casual,
--- ...
CASE 
    WHEN EXTRACT (HOUR FROM started_at) BETWEEN 0 AND 5 THEN 'Night'
    WHEN EXTRACT (HOUR FROM started_at) BETWEEN 6 AND 11 THEN 'Morning'
--- ...
FROM trip_raw WHERE started_at IS NOT NULL 
AND ended_at IS NOT NULL;
```

### 3) Outlier Filtering

Create `trip_filtered` by removing technically implausible rides:
1.  Duration < 1 minute → docking/unlocking errors
2.  Duration > 24 hours → system issues

### 4) Deduplication

Remove **121 duplicates** using a window function:
``` sql
CREATE TABLE trips_final AS
SELECT * FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ride_id ORDER BY ended_at) AS rn
    FROM trip_filtered) t
WHERE rn = 1;
```

### 5) Weather Integration (Meteostat)

Import and join daily weather data:
- Variables: `tavg`, `tmin`, `tmax`, `prcp`, `snow`, `wspd`, `pres`
- Derived features: `season`, `temp_category`, `is_rain`

Join:
``` sql
CREATE TABLE trips_with_weather AS
SELECT t., w.
FROM trips_final t
LEFT JOIN weather_daily w
ON t.ride_date = w.date;
```
**Missing handling**: 5 values → *median* imputation.

## Final Table Stages

| Table | Description | Stage |
|:-----------------------|:-----------------------|:-----------------------|
| `trip_raw` | Raw import from CSV | 🔴 Raw |
| `trip_prepared` | Time-based feature engineering | 🟡 Staging |
| `trip_filtered` | Duration filters applied | 🟡 Staging |
| `trips_final` | Cleaned + deduplicated | 🟢 **Ready for Analysis** |
| `trips_with_weather` | Weather-enriched dataset + derived features | ⭐ **Gold Dataset** |
