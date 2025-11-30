#############################################
# Cyclistic Bike-Share - 03_EDA_meteo
# R+ PostgreSQL (dbplyr per computing remoto) 
#(tabella trips_with_weather)
#
# Obiettivo: Analisi della Sensibilità Esterna. Quantificare l'impatto
# di variabili ambientali (stagione, pioggia, temperatura, neve, vento)
# per misurare la resilienza dei Member e la dipendenza dei Casual
# dalle condizioni ottimali.
#############################################################

# ------------------------------
# 0. SETUP E CONNESSIONE DB
# ------------------------------

# Caricamento delle librerie
library(DBI)
library(RPostgres)
library(dplyr)
library(dbplyr)
library(ggplot2)
library(scales) # Necessaria per la formattazione degli assi (milioni, percentuali)
library(tidyr)
# Connessione al database (operazioni di aggregazione pesante su PostgreSQL)
con <- dbConnect(
  Postgres(),
  dbname   = "cyclistic",
  host     = "**",
  port     = **,
  user     = "**",
  password = "**"  
)

# Riferimento alla tabella remota principale (il Gold Dataset)
trips_db <- tbl(con, "trips_with_weather")

# Controlli veloci (eseguiti in remoto)
trips_db %>% tally()      # Verifica il numero totale di righe
trips_db %>% glimpse()    # Visualizzazione remota della struttura

# -------------------------------------------------------------------
# 1. CREAZIONE DEL DATASET LOCALE "trips_weather"
#    (Necessario per ggplot e manipolazione fattoriale complessa)
# -------------------------------------------------------------------

# Si collega l'intero dataset in R, in quanto tutte le variabili meteo sono
# già associate (la dimensione della RAM è gestibile) e le analisi successive
# (specie quelle interattive e la creazione di fattori) beneficiano della
# velocità di calcolo locale.
trips_weather <- trips_db %>%
  collect() %>%
  mutate( # Assicuriamo l'ordine logico delle stagioni per i grafici
    season = factor(
      season,
      levels = c("Inverno", "Primavera", "Estate", "Autunno")
    ), # Assicuriamo l'ordine logico delle fasce di temperatura
    temp_category = factor(
      temp_category,
      levels = c("<5°C (Freddo)",
                 "5-15°C (Fresco)",
                 "15-25°C (Mite)",
                 "≥25°C (Caldo)")
    )
  )

# Check rapido dei valori mancanti (NA) sulle variabili meteo principali
# (Si presume che i NA siano stati gestiti in fase di ETL/Data Cleaning)
trips_weather %>%
  summarise(
    n            = n(),
    na_tavg      = sum(is.na(tavg)),
    na_prcp      = sum(is.na(prcp)),
    na_snow      = sum(is.na(snow)),
    na_wspd      = sum(is.na(wspd)),
    na_pres      = sum(is.na(pres)),
    na_season    = sum(is.na(season)),
    na_temp_cat  = sum(is.na(temp_category)),
    na_is_rain   = sum(is.na(is_rain))
  )

# -------------------------------------------------------------
# 2. ANALISI PER STAGIONE
# -------------------------------------------------------------

# Riassunto volumi e durate per stagione (misura della stagionalità complessiva)
season_summary <- trips_weather %>%
  group_by(season, member_casual) %>%
  summarise(
    rides           = n(),
    mean_duration   = mean(ride_duration_min),
    median_duration = median(ride_duration_min),
    .groups         = "drop"
  )

season_summary

# Grafico: Volume di corse per stagione
ggplot(season_summary,
       aes(x = season, y = rides, fill = member_casual)) +
  
  geom_col(position = "dodge", width = 0.7) +
    scale_y_continuous(
    labels = label_number(scale = 1e-6, suffix = "M"), # Formatta in Milioni
    name = "Numero di corse"
  ) +
  scale_fill_manual(
    values = c("casual" = "#E69F00", "member" = "#56B4E9"), 
    name = "Tipo Utente"
  ) +
    labs(
    title = "Volume Corse per Stagione e Tipo Utente",
    subtitle = "I Casual sono concentrati in Primavera/Estate; i Member sono più distribuiti.",
    x = "Stagione"
  ) +
    theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    legend.position = "top"
  )

# Grafico: Durata media per stagione (verificando la stabilità della durata)
ggplot(season_summary,
       aes(x = season, y = mean_duration,
           color = member_casual, group = member_casual)) +
  geom_line(linewidth = 1) +
  geom_point() +
  labs(
    title = "Durata media delle corse per stagione e tipo di utente",
    x = "Stagione",
    y = "Durata media (minuti)",
    color = "User type"
  ) +
  theme_minimal()

# -------------------------------------------------------------
# 3. IMPATTO DELLA PIOGGIA (is_rain TRUE/FALSE)
# -------------------------------------------------------------

# Riassunto volumi e durate (misura della resilienza alla pioggia)
rain_summary <- trips_weather %>%
  group_by(is_rain, member_casual) %>%
  summarise(
    rides           = n(),
    mean_duration   = mean(ride_duration_min),
    median_duration = median(ride_duration_min),
    .groups         = "drop"
  ) %>%
  mutate(
    rain_label = ifelse(is_rain, "Giorni con pioggia", "Giorni senza pioggia")
  )

rain_summary

# Grafico: Volume di corse con/senza pioggia
ggplot(rain_summary,
       aes(x = rain_label, y = rides, fill = member_casual)) +
  
  geom_col(position = "dodge", width = 0.7) +
    scale_y_continuous(
    labels = label_number(scale = 1e-6, suffix = "M"), 
    name = "Numero di corse"
  ) +
    scale_fill_manual(
    values = c("casual" = "#E69F00", "member" = "#56B4E9"),
    name = "Tipo Utente"
  ) +
  
  labs(
    title = "Volume Corse: Confronto Giorni con e senza Pioggia",
    subtitle = "Nonostante il calo generalizzato, in caso di pioggia i Member mantengono 
un volume di corse superiore a quello dei Casual.",
    x = "Condizione meteo"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "top"
  )

# Durata media con/senza pioggia
ggplot(rain_summary,
       aes(x = rain_label, y = mean_duration, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(
    title = "Durata media delle corse con e senza pioggia",
    x = "Condizione meteo",
    y = "Durata media (minuti)",
    fill = "User type"
  ) +
  theme_minimal()

# Calcolo della variazione percentuale per la sensibilità
rain_sensitivity <-rain_summary %>%
  group_by(member_casual) %>%
  mutate( 
    # Variazione % del volume in caso di pioggia (vs No Pioggia)
    pct_change = (rides-first(rides))/first(rides)
  ) %>%
  ungroup()

# -------------------------------------------------------------
# 4. IMPATTO DELLE FASCE DI TEMPERATURA (temp_category)
# -------------------------------------------------------------

# Riassunto volumi e durate per fasce (misura della sensibilità termica)
temp_summary <- trips_weather %>%
  group_by(temp_category, member_casual) %>%
  summarise(
    rides           = n(),
    mean_duration   = mean(ride_duration_min),
    median_duration = median(ride_duration_min),
    .groups         = "drop"
  )

temp_summary

# Grafico: Numero di corse per fascia di temperatura
ggplot(temp_summary,
       aes(x = temp_category, y = rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(
    title = "Numero di corse per fascia di temperatura e tipo di utente",
    x = "Fascia di temperatura media giornaliera",
    y = "Numero di corse",
    fill = "User type"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))

# Grafico: Durata media per fascia di temperatura
ggplot(temp_summary,
       aes(x = temp_category, y = mean_duration, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(
    title = "Durata media delle corse per fascia di temperatura",
    x = "Fascia di temperatura",
    y = "Durata media (minuti)",
    fill = "User type"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))

# -------------------------------------------------------------
# 5. ANALISI INTERATTIVA: TEMPERATURA × WEEKDAY/WEEKEND
# -------------------------------------------------------------

# Aggregazione incrociata per isolare l'uso pendolare (Member Weekday)
temp_weekday_summary <- trips_weather %>%
  mutate(
    day_type = ifelse(is_weekend, "Weekend", "Weekday")
  ) %>%
  group_by(temp_category, day_type, member_casual) %>%
  summarise(
    rides = n(),
    .groups = "drop"
  )

temp_weekday_summary

# Grafico: Volume corse per temperatura, separato per Weekday/Weekend
ggplot(temp_weekday_summary,
       aes(x = temp_category, y = rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  # Uso scales = "free_y" per apprezzare i volumi relativi in ogni fascia
  facet_wrap(~ day_type, scales = "free_y") +
  labs(
    title = "Corse per fascia di temperatura: confronto Weekday vs Weekend",
    x = "Fascia di temperatura media giornaliera",
    y = "Numero di corse",
    fill = "Tipo Utente"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Line plot dei volumi per mostrare l’andamento (trend di caduta)
temp_volume_summary <- trips_weather %>%
  group_by(temp_category, member_casual, is_weekend) %>%
  summarise(
    rides_count = n(),
    .groups = "drop"
  )

# Grafico
ggplot(temp_volume_summary,
       aes(x = temp_category, y = rides_count,
           group = member_casual, color = member_casual)) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  facet_wrap(
    ~ is_weekend,
    labeller = labeller(is_weekend = c("FALSE" = "Giorni Feriali",
                                       "TRUE"  = "Weekend")),
    scales = "free_y"
  ) +
  labs(
    title = "Volume di corse per fascia di temperatura (Line Plot)",
    subtitle = "I Member sono più resilienti al freddo nei giorni feriali",
    x = "Fascia di Temperatura (°C)",
    y = "Conteggio corse",
    color = "Tipo Utente"
  ) +
  scale_y_continuous(
    labels = scales::label_number(scale_cut = scales::cut_short_scale())
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# -------------------------------------------------------------
# 5bis. MISURA DELLA SENSIBILITÀ TERMICA (Variazione % vs Baseline)
# -------------------------------------------------------------

# Baseline generale: 15–25°C (Mite), considerata la condizione ottimale per l'uso generale.
baseline <- temp_weekday_summary %>%
  filter(temp_category == "15-25°C (Mite)") %>%
  select(member_casual, day_type, rides) %>%
  rename(baseline_rides = rides)

temp_sensitivity <- temp_weekday_summary %>%
  left_join(baseline, by = c("member_casual", "day_type")) %>%
  mutate(
    # Calcolo della variazione % rispetto al volume Mite (15-25°C)
    pct_change = (rides - baseline_rides) / baseline_rides
  )

# Baseline Strategica per Member Weekday: Per i Member, l'uso è primariamente funzionale
# e la fascia 5–15°C (Fresco) è spesso più rappresentativa di un "normale" giorno
# di pendolarismo. Quindi ricalcoliamo la resilienza solo su questo segmento.
resilience <- temp_weekday_summary %>%
  filter(day_type == "Weekday", member_casual == "member") %>%
  mutate(
    baseline_rides = rides[temp_category == "5-15°C (Fresco)"],
    pct_change_resilience = (rides - baseline_rides) / baseline_rides
  )

# Unione dei dati e scelta della metrica finale
temp_combined <- temp_sensitivity %>%
  left_join(
    resilience %>% select(temp_category, pct_change_resilience),
    by = "temp_category"
  ) %>%
  mutate(
    # Usa la Baseline Strategica solo per l'analisi specifica Member/Weekday
    pct_final = case_when(
      member_casual == "member" & day_type == "Weekday" ~ pct_change_resilience,
      TRUE ~ pct_change
    ),
    day_type_label = ifelse(day_type == "Weekday",
                            "Giorni Feriali", "Weekend")
  )

# Grafico finale di sensibilità termica
temp_order_logical <- c("<5°C (Freddo)", "5-15°C (Fresco)", "15-25°C (Mite)", "≥25°C (Caldo)")
temp_combined <- temp_combined %>%
  mutate(
    temp_category = factor(temp_category, levels = temp_order_logical, ordered = TRUE)
  )

ggplot(temp_combined,
       aes(x = temp_category, y = pct_final,
           group = member_casual, color = member_casual)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_line(linewidth = 1.2) +
  geom_point(size = 4) +
 
  facet_wrap(~ day_type_label, scales = "free_y") +
   scale_color_manual(
    values = c("casual" = "#E69F00", "member" = "#56B4E9"),
    name = "Tipo Utente"
  ) +
  labs(
    title = "Sensibilità Termica per Segmento: Variazione % del Volume Corse
(Member vs Casual)",
    subtitle = "Variazione % rispetto alla condizione ideale (15–25°C).
Per i Member nei giorni feriali è mostrata una baseline addizionale a 5–15°C, 
più rappresentativa del commuting.",
    x = "Fascia di temperatura (°C)",
    y = "Variazione Percentuale (vs baseline)",
    color = "Tipo Utente"
  ) +
  scale_y_continuous(labels = scales::percent) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    plot.title = element_text(face = "bold")
  )

# -------------------------------------------------------------
# 6. IMPATTO DELLA NEVE (SNOW)
# -------------------------------------------------------------

# Creazione della flag 'is_snowing' (qualsiasi precipitazione nevosa > 0 mm)
trips_weather <- trips_weather %>%
  mutate(
    is_snowing = snow > 0        
  )

snow_summary <- trips_weather %>%
  group_by(is_snowing, member_casual) %>%
  summarise(
    rides = n(),
    mean_duration = mean(ride_duration_min),
    .groups = "drop"
  )

snow_summary

# Grafico: Volume di corse con e senza neve
ggplot(snow_summary,
       aes(x = is_snowing, y = rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(
    title = "Corse con e senza neve per tipo di utente",
    x = "Neve (TRUE = giorno con precipitazioni nevose)",
    y = "Numero di corse",
    fill = "User type"
  ) +
  scale_x_discrete(
    labels = c("FALSE" = "Assenza Neve", "TRUE" = "Presenza Neve")
  ) +
  theme_minimal()

# Variazione % rispetto a giorni senza neve
snow_sensitivity <- snow_summary %>%
  group_by(member_casual) %>%
  mutate(
    pct_change = (rides-first(rides)) / first(rides)
  ) %>%
  ungroup()

snow_sensitivity <- snow_sensitivity %>%
  mutate(
    # Rinominazione delle etichette per l'asse X
    snow_label = case_when(
      is_snowing == FALSE ~ "Nessuna Neve",
      is_snowing == TRUE  ~ "Neve Presente"
    ),
    # Ordine logico
    snow_label = factor(snow_label, levels = c("Nessuna Neve", "Neve Presente"), ordered = TRUE)
  )

# Grafico 
ggplot(snow_sensitivity,
       aes(x = snow_label, y = rides, fill = member_casual)) +
  geom_col(position = "dodge", width = 0.7) +
    scale_y_continuous(
    labels = label_number(scale = 1e-6, suffix = "M"), 
    name = "Numero di corse"
  ) +
    scale_fill_manual(
    values = c("casual" = "#E69F00", "member" = "#56B4E9"),
    name = "Tipo Utente"
  ) +
    labs(
    title = "Impatto della Neve sul Volume Totale di Corse",
    subtitle = "La neve annulla quasi completamente l'uso ricreativo.
I Member mantengono una quota proporzionalmente più alta → uso da necessità.",
    x = "Condizione Meteo"
  ) +
  
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    legend.position = "top"
  )

# -------------------------------------------------------------
# 7. IMPATTO DEL VENTO (WSPD, km/h)
# -------------------------------------------------------------

# Statistiche di base della velocità del vento
wspd_stats <- trips_weather %>%
  group_by(member_casual) %>%
  summarise(
    mean_wspd   = mean(wspd, na.rm = TRUE),
    median_wspd = median(wspd, na.rm = TRUE),
    .groups = "drop"
  )

wspd_stats

# Distribuzione continua della velocità del vento
ggplot(trips_weather,
       aes(x = wspd, color = member_casual)) +
  geom_density() +
  labs(
    title = "Distribuzione della velocità del vento (km/h) per tipo di utente",
    x = "Velocità vento (km/h)",
    y = "Densità",
    color = "User type"
  ) +
  theme_minimal()

# Creazione delle fasce di velocità del vento (feature engineering)
trips_weather <- trips_weather %>%
  mutate(
    wspd_category = case_when(
      wspd < 20              ~ "Vento Debole (<20 km/h)",
      wspd >= 20 & wspd < 40 ~ "Vento Moderato (20-40 km/h)",
      wspd >= 40             ~ "Vento Forte (≥40 km/h)"
    ),
    wspd_category = factor(
      wspd_category,
      levels = c("Vento Debole (<20 km/h)",
                 "Vento Moderato (20-40 km/h)",
                 "Vento Forte (≥40 km/h)"),
      ordered = TRUE
    )
  )

# Riassunto volumi per fasce di vento pt.1
wspd_summary <- trips_weather %>%
  group_by(wspd_category, member_casual) %>%
  summarise(
    rides          = n(),
    mean_duration  = mean(ride_duration_min),
    median_duration = median(ride_duration_min),
    .groups = "drop"
  )

wspd_summary

# Riassunto volumi per fasce di vento pt.2
wspd_summary_fixed <- trips_weather %>%
  group_by(wspd_category, member_casual) %>%
  summarise(
    rides = n(),
    .groups = "drop"
  ) %>%
  ungroup() %>% # Uso complete() per assicurare che tutte le combinazioni di (fascia x utente)
  # siano presenti, anche se il conteggio è 0 (importante per il grafico)
  complete(wspd_category, member_casual, fill = list(rides = 0))

# Variazione % rispetto a vento debole <20 km/h
wspd_sensitivity <- wspd_summary_fixed %>%
  group_by(member_casual) %>%
  mutate(
    baseline_rides = first(rides),
    pct_change = (rides-baseline_rides)/baseline_rides
  ) %>%
  ungroup()

# Grafico: Numero di corse per fascia di vento
ggplot(wspd_summary_fixed,
       aes(x = wspd_category, y = rides, fill = member_casual)) +
  
  geom_col(position = "dodge", width = 0.7) +
    scale_y_continuous(
    labels = label_number(scale = 1e-6, suffix = "M"), 
    name = "Numero di corse"
  ) +
  
  scale_fill_manual(
    values = c("casual" = "#E69F00", "member" = "#56B4E9"),
    name = "Tipo Utente"
  ) +
  
  labs(
    title = "Volume Corse per Fascia di Velocità del Vento",
    subtitle = "Entrambi i gruppi utilizzano il servizio prevalentemente con vento debole (<20 km/h).",
    x = "Fascia di Velocità del Vento"
  ) +
  
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    plot.title = element_text(face = "bold"),
    legend.position = "top"
  )


# Durata media per fascia di vento
ggplot(wspd_summary,
       aes(x = wspd_category, y = mean_duration, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(
    title = "Durata media delle corse per fascia di velocità del vento",
    x = "Fascia di Velocità del Vento",
    y = "Durata Media (minuti)",
    fill = "Tipo Utente"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Chiude la connessione al database
dbDisconnect(con)

############################################################
# PROSSIMO PASSO: 04_machine_learning_models.R
############################################################