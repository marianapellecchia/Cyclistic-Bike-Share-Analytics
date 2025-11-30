# Data Pipeline — SQL + R (2021–2025)

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-316192?logo=postgresql&logoColor=white) ![R](https://img.shields.io/badge/R-4.5.1-276DC3?logo=r&logoColor=white) ![ETL](https://img.shields.io/badge/ETL-%20Pipeline-orange)![Data Cleaning](https://img.shields.io/badge/Data%20Quality-High-green)![Big Data](https://img.shields.io/badge/Data%20Volume-Big%20Data-red)

Documentazione tecnica della pipeline utilizzata per ingestione, pulizia, integrazione meteo e costruzione del dataset analitico finale (`trips_with_weather`).

## Architettura

Pipeline ibrida R + PostgreSQL progettata per gestire \~28M record:

-   **R (data.table)** → ingestione CSV ad alta velocità
-   *PostgreSQL* → storage, cleaning, feature engineering
-   **R (dbplyr)** → analisi e derivazioni leggere senza scaricare i dati grezzi
-   *Meteostat* → arricchimento meteo multi-anno (temperatura, pioggia, neve, vento)

## Workflow della Pipeline

### 1. Ingestione (R → PostgreSQL)

-   58 file mensili (2021–2025), \~28M righe totali
-   Import con `fread()` per massima velocità
-   Append nella tabella grezza `trip_raw`

*Script principale:* *r/*01_connect_and_import.R

``` r
dt <- fread(f)
dbWriteTable(con, "trip_raw", value = dt, append = TRUE)
```

### 2. Cleaning & Feature Engineering (SQL)

Creazione tabella `trip_prepared`:

1\. Calcolo durata (ended_at - started_at)

2\. Estrazione: anno, mese, giorno, ora

3\. Flag weekend (Ven–Sab–Dom)

4\. Fasce orarie (Mattina, Pomeriggio, Sera, Notte)

*Parte dello script sql/:*

``` sql
CREATE TABLE trip_prepared AS
SELECT ride_id, rideable_type, started_at, ended_at, start_station_name, start_station_id, end_station_name, end_station_id, member_casual,
--- ...
CASE 
    WHEN EXTRACT (HOUR FROM started_at) BETWEEN 0 AND 5 THEN 'Notte'
    WHEN EXTRACT (HOUR FROM started_at) BETWEEN 6 AND 11 THEN 'Mattina'
--- ...
FROM trip_raw WHERE started_at IS NOT NULL 
AND ended_at IS NOT NULL;
```

### 3. Filtraggio Outlier

Tabella `trip_filtered`:

1.  Durata \<1 min → errori di sgancio
2.  Durata \>24h → problemi di sistema

**→ Rimozione corse tecnicamente impossibili**

### 4. Deduplicazione

**121** **duplicati rimossi** tramite window function:

``` sql
CREATE TABLE trips_final AS
SELECT * FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ride_id ORDER BY ended_at) AS rn
    FROM trip_filtered) t
WHERE rn = 1;
```

### 5. Integrazione Meteo (Meteostat)

Dataset importato e unito a livello giornaliero:

-   Variabili: tavg, tmin, tmax, prcp, snow, wspd, pres

-   *Feature derivate*: season, temp_category, is_rain

Join:

``` sql
CREATE TABLE trips_with_weather AS
SELECT t., w.
FROM trips_final t
LEFT JOIN weather_daily w
ON t.ride_date = w.date;
```

**Missing handling**: 5 valori → imputazione *mediana*.

## Schema Finale delle Tabelle

| Tabella | Descrizione | Stato |
|:-----------------------|:-----------------------|:-----------------------|
| `trip_raw` | Import grezzo dai CSV | 🔴 Raw |
| `trip_prepared` | Feature engineering temporale | 🟡 Staging |
| `trip_filtered` | Filtri durata applicati | 🟡 Staging |
| `trips_final` | Deduplicata e pulita | 🟢 **Ready for Analysis** |
| `trips_with_weather` | Arricchita con dati meteo e nuove variabili | ⭐ **Gold Dataset** |
