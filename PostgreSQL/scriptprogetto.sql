-- Database: cyclistic
--CREAZIONE TABELLA CON DATI GREZZI
CREATE TABLE IF NOT EXISTS trip_raw (
ride_id TEXT,
rideable_type TEXT,
started_at TIMESTAMP,
ended_at TIMESTAMP,
start_station_name TEXT,
start_station_id TEXT,
end_station_name TEXT,
end_station_id TEXT,
start_lat NUMERIC,
start_lng NUMERIC,
end_lat	NUMERIC,
end_lng NUMERIC,
member_casual TEXT
);

--- CONTROLLO SE IL COLLEGAMENTO CON R FUNZIONA, NB: IL TEST SU R
SELECT COUNT (*) trip_raw; --CONTEGGIO DEL CSV CHE è 1
SELECT*FROM trip_raw LIMIT 10; ---TABELLA CON I DATI DEL 1° CSV, QUINDI FUNZIONA!
--IL COLLEGAMENTO FUNZIONA QUINDI SVUOTO LA TABELLA E PROCEDO A IMPORTARE TUTTI I CSV SU R..
TRUNCATE TABLE trip_raw;

--..UNA VOLTA CHE SU R HO IMPORTATO I DATASET VEDIAMO LA TABELLA CON TUTTI QUESTI..
SELECT COUNT(*) 
FROM trip_raw; ---conteggio totale 27.899.057

-- CREO LA TABELLA TRIP_PREP DEFINITIVA
DROP TABLE IF EXISTS trip_prepared;
CREATE TABLE trip_prepared AS
SELECT
	ride_id,
	rideable_type,
	started_at,
	ended_at,
	start_station_name,
	start_station_id,
	end_station_name,
	end_station_id,
	member_casual,
-- DURATA IN SEC, MIN, ORE
EXTRACT (EPOCH FROM (ended_at - started_at)) as ride_duration_sec,
EXTRACT (EPOCH FROM (ended_at - started_at)) / 60.0 as ride_duration_min,
EXTRACT (EPOCH FROM (ended_at - started_at)) /3600.0 as ride_duration_hour,
--DATA PIENA
DATE(started_at) as ride_date,
--COMPONENTI NUMERICHE 
EXTRACT (YEAR from started_at) as ride_year,
EXTRACT (MONTH from started_at) as ride_month,
EXTRACT (DAY from started_at) as ride_day,
EXTRACT (HOUR from started_at) as ride_start_hour,
--GIORNO DELLA SETT DAL LUN ALLA DOM, NUM E TESTUALE
CASE
	WHEN EXTRACT (DOW FROM started_at)=0 THEN 7
ELSE EXTRACT (DOW FROM started_at)::int
END AS ride_weekday_num,
--NOME GIORNO
CASE EXTRACT (DOW FROM started_at)
WHEN 1 THEN 'Lunedì'
WHEN 2 THEN 'Martedì'
WHEN 3 THEN 'Mercoledì'
WHEN 4 THEN 'Giovedì'
WHEN 5 THEN 'Venerdì'
WHEN 6 THEN 'Sabato'
WHEN 0 THEN 'Domenica'
END AS ride_weekday_name,
---NOMI MESI 
CASE EXTRACT (MONTH FROM started_at)
WHEN 1 THEN 'Gennaio'
WHEN 2 THEN 'Febbraio'
WHEN 3 THEN 'Marzo'
WHEN 4 THEN 'Aprile'
WHEN 5 THEN 'Maggio'
WHEN 6 THEN 'Giugno'
WHEN 7 THEN 'Luglio'
WHEN 8 THEN 'Agosto'
WHEN 9 THEN 'Settembre'
WHEN 10 THEN 'Ottobre'
WHEN 11 THEN 'Novembre'
WHEN 12 THEN 'Dicembre'
END AS ride_month_name,
--- WEEKEND SI O NO
CASE 
	WHEN EXTRACT (DOW FROM started_at) IN (0,5,6) THEN TRUE ELSE FALSE END AS is_weekend,
---FASCIA ORARIA	
CASE 
	WHEN EXTRACT (HOUR FROM started_at) BETWEEN 0 AND 5 THEN 'Notte'
	WHEN EXTRACT (HOUR FROM started_at) BETWEEN 6 AND 11 THEN 'Mattina'
	WHEN EXTRACT (HOUR FROM started_at) BETWEEN 12 AND 17 THEN 'Pomeriggio'
	ELSE 'Sera'
END AS time_of_day
---ELIMINO VALORI MANCANTI
FROM trip_raw WHERE started_at IS NOT NULL 
AND ended_at IS NOT NULL
AND COALESCE (start_station_name, '') <> ''
AND COALESCE (end_station_name, '') <> ''
AND COALESCE (start_station_id, '') <> ''
AND COALESCE (end_station_id, '') <> '';

----ORA CREO UN ULTERIORE TABELLA TRIP_FILTERED DOVE VADO AD ELIMINARE
----- LE CORSE INFERIORI A 1MIN E SUPERIORI A 1440MINUTI 
DROP TABLE IF EXISTS trip_filtered;
CREATE TABLE trip_filtered AS 
SELECT * FROM trip_prepared
WHERE ride_duration_min BETWEEN 1 AND 1440; 

---PRIMA DI PASSARE A CREARE LA TABELLA FINALE DOVE DEVO ELIMINARE I DUPLICATI SU RIDE_ID VEDO PRIMA QUALI SONO
---casi in cui stesso id e stessa ora di partenza= 1 RIDE_ID solo cioè "2F9BC5B5C50E3E3C" alle "2024-05-31 23:55:44" N_ROWS 2
SELECT ride_id, started_at, COUNT (*) AS n_rows
FROM trip_filtered GROUP BY ride_id, started_at HAVING COUNT(*)>1 ORDER BY n_rows DESC, ride_id, started_at;
----casi in cui lo stesso id ha partenza diversa: 120 RIDE_ID COMPAIONO ALMENO 2 VOLTE E CON ORARI  DI PARTENZA DIVERSI
SELECT ride_id, COUNT (*) AS n_rows, 
	COUNT(DISTINCT started_at) AS n_diff_started_at 
	FROM trip_filtered GROUP BY ride_id
	HAVING COUNT(DISTINCT started_at)>1
	ORDER BY n_diff_started_at DESC, n_rows DESC;
---PERTANTO
SELECT COUNT(*) FROM trip_filtered; ---20566272 RIGHE TOTALI
SELECT SUM(n_rows-1) AS total_exact_duplicates
	FROM (
		SELECT ride_id, started_at, COUNT(*) AS n_rows
		FROM trip_filtered
		GROUP BY ride_id, started_at
		HAVING COUNT(*)>1
	) t; ----- 1 coppie ride_id e started_at duplicate 
SELECT COUNT (*) AS reused_ids
FROM(
	SELECT ride_id
	FROM trip_filtered GROUP BY ride_id
	HAVING COUNT(DISTINCT started_at)>1
) x; ------ 120 ride_id riutilizzati con started_at diversi

-----ORA VEDIAMO PER I 120 RIDE_ID RIUTILIZZATI TUTTE LE COLONNE DEL DATASET
SELECT* FROM trip_filtered WHERE ride_id IN (
	SELECT ride_id
	FROM trip_filtered
	GROUP BY ride_id
	HAVING COUNT(DISTINCT started_at)>1
	)
	ORDER BY ride_id, started_at;-----"05D27072A33A290C"
---in questa query(sopra a questo commento) si è scoperto che quelli che inizialmente avevo pensato
---fossero riutilizzi di ride_id nei diversi anni, sono invece duplicati veri e propri questo perchè 
---cambiano i millisecondi!! pertanto si procede all'eliminazione di 121 duplicati
---NELLA NUOVA E FINALE TABELLA
DROP TABLE IF EXISTS trips_final;
CREATE TABLE trips_final AS
SELECT* FROM(
		SELECT*,ROW_NUMBER()OVER(
				PARTITION BY ride_id, DATE_TRUNC('second', started_at)
				ORDER BY ended_at
			)AS rn
	FROM trip_filtered ) t
WHERE rn=1; --questa query unisce i duplicati perfetti, 
---quelli quasi perfetti e mantiene eventuali ride_id riutilizzati in anni diversi (che nn esistono!)

---per essere sicura..
---[1] controllo su un ride_id prima duplicato a caso= zero, ED E' OK
SELECT*FROM trips_final WHERE ride_id='05D27072A33A290C' ORDER BY started_at;
---[2] controllo su tutto=zero, ED E' OK
SELECT ride_id, DATE_TRUNC('second', started_at), COUNT(*) 
FROM trips_final GROUP BY ride_id, DATE_TRUNC('second', started_at)
HAVING COUNT(*)>1;
----[3] controllo ride_id riutilizzati=zero ED E' OK
SELECT ride_id, COUNT(DISTINCT DATE_TRUNC('second', started_at))
FROM trips_final GROUP BY ride_id
HAVING COUNT(DISTINCT DATE_TRUNC('second', started_at))>1;
----NUMERO TOT RIGHE= 20566151 PRIMA 20566272=121 DUPLICATI RIMOSSI, E SI TROVA!
SELECT COUNT(*) FROM trips_final;

-----CREO TABELLA CON DATI  METEO
DROP TABLE IF EXISTS weather_daily;
CREATE TABLE weather_daily(
	weather_date DATE,
	tavg NUMERIC,	
	tmin NUMERIC,
	tmax NUMERIC,	
	prcp NUMERIC,
	snow NUMERIC,	
	wspd NUMERIC,	
	pres NUMERIC
);
---POI HO IMPORTATO DIRETTAMENTE IL DATASET DEI DATI METEO TRAMITE SQL, SENZA ANDARE SU R.

----- CREO TABELLA NUOVA CON I VALORI METEO TRAMITE JOIN 
DROP TABLE IF EXISTS trips_with_weather;
CREATE TABLE trips_with_weather AS 
SELECT
	t.*,
	w.tavg,
	w.tmin,
	w.tmax,
	w.prcp,
	w.snow,
	w.wspd,
	w.pres,

--STAGIONE
CASE
	WHEN EXTRACT (MONTH FROM t.ride_date) IN (12,1,2) THEN 'Inverno'
	WHEN EXTRACT (MONTH FROM t.ride_date) IN (3,4,5) THEN 'Primavera'
	WHEN EXTRACT (MONTH FROM t.ride_date) IN (6,7,8) THEN 'Estate'
	WHEN EXTRACT (MONTH FROM t.ride_date) IN (9,10,11) THEN 'Autunno'
END AS season,

-- FASCE TEMPERATURA
CASE 
	WHEN w.tavg <5 THEN '<5°C (Freddo)'
	WHEN w.tavg >=5  AND w.tavg <15 THEN '5-15°C (Fresco)'
	WHEN w.tavg >=15 AND w.tavg <25 THEN '15-25°C (Mite)'
	WHEN w.tavg >=25 THEN '≥25°C (Caldo)'
END AS temp_category,

-- PIOGGIA SI/NO
CASE 
	WHEN w.prcp >0 THEN TRUE ELSE FALSE END AS is_rain
	
FROM trips_final t
LEFT JOIN weather_daily w 
	ON t.ride_date=w.weather_date;
----CONTROLLO
SELECT COUNT(*) FROM trips_final; ---20566151
SELECT COUNT(*) FROM trips_with_weather;---20566151