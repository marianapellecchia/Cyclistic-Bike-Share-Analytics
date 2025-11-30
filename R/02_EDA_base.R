#############################################
# Cyclistic Bike-Share - 02_EDA_base
# R + PostgreSQL (dbplyr per computing remoto) 
#(tabella trips_with_weather)
# 
#Obiettivo: Analisi Esplorativa (EDA) per identificare i pattern strutturali
# distintivi tra utenti 'Member' e 'Casual' (Dicotomia Comportamentale).
# L'analisi copre Volumi, Durate, Pattern Temporali e Distribuzione Spaziale
# (2021-2025).
#############################################

# ------------------------------
# 0. SETUP E CONNESSIONE DB
# ------------------------------

# Caricamento delle librerie necessarie per l'interazione con il database e la visualizzazione.
library(DBI)
library(RPostgres)
library(dplyr)
library(dbplyr) # Strumento chiave per la computazione remota
library(ggplot2)
library(scales) # Necessaria per la formattazione degli assi (milioni, percentuali)
library(tidyr)
#############################################
# 0. CONNESSIONE AL DATABASE E TAB. PRINCIPALE
#############################################

con <- dbConnect(
  Postgres(),
  dbname   = "cyclistic",
  host     = "***",
  port     = **,
  user     = "**",
  password = "**" 
)

# Riferimento alla tabella remota principale (il Gold Dataset)
# Tutte le operazioni successive con 'trips' saranno eseguite su PostgreSQL
trips <- tbl(con, "trips_with_weather")

# Controlli veloci
trips %>% tally()          # Verifica il numero totale di righe (~20.5M)
trips %>% glimpse()        # Visualizzazione remota della struttura delle colonne


# ----------------------------------------------------------------------
# 1. VISTA D'INSIEME: COMPOSIZIONE UTENTI E DURATA MEDIA (Driver Primari)
# ----------------------------------------------------------------------

# 1.1 Distribuzione Member vs Casual (conteggi totali)
# Quantifica il mix di base su cui si costruisce la domanda totale.dist_user_type <- trips %>%
  count(member_casual) %>%
  collect()

dist_user_type

# 1.2 Distribuzione Member vs Casual (percentuali)
dist_user_type_prop <- trips %>%
  count(member_casual) %>%
  mutate(prop = n / sum(n)) %>%
  collect()

dist_user_type_prop

# Grafico a Torta
ggplot(dist_user_type_prop, aes(x = "", y = n, fill = member_casual)) +
    geom_col(width = 1, color = "white", linewidth = 1.5) +
    coord_polar(theta = "y", start = 0) +
    geom_text(
    aes(
      # Posiziona l'etichetta al centro di ogni segmento
      y = cumsum(n) - n / 2, 
      # Formatta il testo come percentuale
      label = scales::percent(prop, accuracy = 0.1) 
    ),
    color = "black", 
    size = 5
  ) +  
  scale_fill_manual(values = c("casual" = "#E69F00", "member" = "#56B4E9")) + 
    labs(
    title = "Composizione Utenti: Member vs. Casual",
    fill = "Tipo Utente",
    x = NULL, # Rimuovi l'etichetta dell'asse X
    y = NULL  # Rimuovi l'etichetta dell'asse Y
  ) +
    theme_void() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold")
  )

# Grafico: Proporzione Utenti per Anno (Tendenza di lungo periodo)

# 1. Calcolo delle percentuali annuali (operazione remota)
user_prop_year <- trips %>%
  count(ride_year, member_casual) %>%
  group_by(ride_year) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup() %>%
  rename(year = ride_year)

# 2. Grafico Quote Utenti
# Obiettivo: Visualizzare se la quota Member è stabile o in crescita.
ggplot(user_prop_year, 
       aes(x = factor(year), y = prop, fill = member_casual)) +
    geom_col(position = "fill", width = 0.7) + 
    geom_text(aes(label = scales::percent(prop, accuracy = 0.1)), 
            position = position_fill(vjust = 0.5), 
            color = "white", 
            fontface = "bold",
            size = 4) +
  # Formattazione asse Y in percentuale
  scale_y_continuous(labels = scales::percent) +
  # Colori e titoli
  scale_fill_manual(values = c("casual" = "#E69F00", "member" = "#56B4E9")) + 
  labs(
    title = "Evoluzione della quota Member vs Casual (2021-2025)",
    x = "Anno",
    y = "Proporzione (%)",
    fill = "Tipo Utente"
  ) +
  
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "top"
  )

# 1.3 Durata media/mediana complessiva per tipo di utente
duration_by_user <- trips %>%
  group_by(member_casual) %>%
  summarise(
    mean_min   = mean(ride_duration_min),
    median_min = median(ride_duration_min),
    n          = n(),
    .groups    = "drop"
  ) %>%
  collect() # Trasferimento dei risultati aggregati in R

duration_by_user

# Grafico della distribuzione della durata
# Usa scala logaritmica per evidenziare le differenze nelle corse brevi
ggplot(trips %>% filter(ride_duration_min < 120) %>% collect(), # Limita a 120 min per chiarezza
       aes(x = ride_duration_min, fill = member_casual)) +
  geom_density(alpha = 0.6) +
  scale_fill_manual(values = c("casual" = "#E69F00", "member" = "#56B4E9")) + 
  scale_x_log10(breaks = c(1, 5, 10, 30, 60, 120)) + # Scala logaritmica per vedere i dettagli
  labs(
    title = "Distribuzione della durata delle corse (scala log)",
    x = "Durata corsa (minuti)",
    y = "Densità",
    fill = "Tipo Utente"
  ) +
  theme_minimal()

# -------------------------------------------------------------
# DISTRIBUZIONE: DURATA (BOXPLOT)
# -------------------------------------------------------------
# Boxplot della durata (ride_duration_min) per tipo di utente
# NOTA: Usiamo coord_cartesian per fare zoom sull'intervallo 0-60 min senza filtrare
# il dataset originale, mantenendo la correttezza statistica del boxplot.

ggplot(trips %>% collect(), 
       aes(x = member_casual, y = ride_duration_min, fill = member_casual)) +
  geom_boxplot(outlier.alpha = 0.1) +
  # Zoom sull'intervallo 0-60 minuti
  coord_cartesian(ylim = c(0, 60)) + 
  labs(
    title = "Distribuzione della durata delle corse per tipo di utente",
    subtitle = "Visualizzato solo l'intervallo 0-60 minuti per chiarezza",
    x = "Tipo di Utente",
    y = "Durata Corsa (minuti)",
    fill = "Tipo Utente"
  ) +
  theme_minimal()

# -------------------------------------------------------------
# 2. ANALISI TEMPORALE GENERALE PER ANNO (2021-2025)
# -------------------------------------------------------------

# 2.1 Numero di corse per anno e tipo di utente 
trips_year <- trips %>%
  group_by(ride_year, member_casual) %>%
  summarise(rides = n(), .groups = "drop") %>%
  collect()

trips_year

# Grafico
ggplot(trips_year,
       aes(x = factor(ride_year), y = rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(
    title = "Numero di corse per anno e tipo di utente",
    x = "Anno",
    y = "Numero di corse",
    fill = "User Type"
  ) +
  theme_minimal()

# 2.2 Proporzione Member vs Casual per anno
trips_year_prop <- trips %>%
  group_by(ride_year, member_casual) %>%
  summarise(rides = n(), .groups = "drop") %>%
  group_by(ride_year) %>%
  mutate(prop = rides / sum(rides)) %>%
  ungroup() %>%
  collect()

trips_year_prop

# Grafico
ggplot(trips_year_prop,
       aes(x = factor(ride_year), y = prop, fill = member_casual)) +
  geom_col(position = "stack") +
  labs(
    title = "Proporzione Member vs Casual per anno",
    x = "Anno",
    y = "Percentuale",
    fill = "User Type"
  ) +
  scale_y_continuous(labels = scales::percent) +
  theme_minimal()

# 2.3 Durata media per anno e tipo di utente
# Verifica se la durata media (e quindi l'intenzione d'uso) si è modificata nel tempo.
duration_year_user <- trips %>%
  group_by(ride_year, member_casual) %>%
  summarise(
    mean_min   = mean(ride_duration_min),
    median_min = median(ride_duration_min),
    n          = n(),
    .groups    = "drop"
  ) %>%
  collect()

duration_year_user

# Grafico
ggplot(duration_year_user,
       aes(x = factor(ride_year), y = mean_min, color = member_casual, group = member_casual)) +
  geom_line(linewidth = 1) +
  geom_point() +
  labs(
    title = "Durata media delle corse per anno e tipo di utente",
    x = "Anno",
    y = "Durata media (minuti)",
    color = "User Type"
  ) +
  theme_minimal()


# -------------------------------------------------------------
# 3. ANALISI MENSILE (2021-2025) - STAGIONALITÀ
# -------------------------------------------------------------

# 3.1 Rides per anno-mese e tipo di utente
# Individua i picchi di domanda e verifica la resilienza dei Member alla bassa stagione.
trips_month <- trips %>%
  group_by(
    ride_year,
    ride_month_num = ride_month,
    ride_month_name,
    member_casual
  ) %>%
  summarise(
    rides = n(),
    .groups = "drop"
  ) %>%
  collect() %>%
  mutate(
    ride_month_name = factor(
      ride_month_name,
      levels = c("Gennaio","Febbraio","Marzo","Aprile","Maggio","Giugno",
                 "Luglio","Agosto","Settembre","Ottobre","Novembre","Dicembre"),
      ordered = TRUE
    ),
    ride_year = factor(ride_year)
  )

trips_month

# Grafico
ggplot(trips_month,
       aes(x = ride_month_name, y = rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  facet_wrap(~ ride_year, nrow = 2) +
  labs(
    title = "Numero di corse per mese, anno e tipo di utente",
    x = "Mese",
    y = "Numero di corse",
    fill = "User Type"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# -------------------------------------------------------------
# 4. ANALISI SETTIMANALE (2021-2025)
# -------------------------------------------------------------

# 4.1 Uso per giorno della settimana (1 = lun ... 7 = dom)
# Analisi per confermare i pattern pendolari (Member feriale) vs ricreativi (Casual weekend).
trips_weekday <- trips %>%
  group_by(member_casual, ride_weekday_num, ride_weekday_name) %>%
  summarise(
    rides         = n(),
    mean_duration = mean(ride_duration_min),
    .groups       = "drop"
  ) %>%
  collect() %>%
  mutate(
    ride_weekday_name = factor(
      ride_weekday_name,
      levels = c("Lunedì","Martedì","Mercoledì","Giovedì","Venerdì","Sabato","Domenica"),
      ordered = TRUE
    )
  )

trips_weekday

# Grafico
ggplot(trips_weekday,
       aes(x = ride_weekday_name, y = rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(
    title = "Numero di corse per giorno della settimana e tipo di utente",
    x = "Giorno della settimana",
    y = "Numero di corse",
    fill = "User Type"
  ) +
  theme_minimal()

# 4.2 Weekday vs Weekend (is_weekend = TRUE se ven-sab-dom)
# Rappresentazione aggregata del comportamento feriale/festivo.
trips_wk_summary <- trips %>%
  group_by(member_casual, is_weekend) %>%
  summarise(rides = n(), .groups = "drop") %>%
  mutate(
    day_type = ifelse(is_weekend, "Weekend", "Weekday")
  ) %>%
  collect()

trips_wk_summary

# Grafico
ggplot(trips_wk_summary,
       aes(x = day_type, y = rides, fill = member_casual)) +
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
    title = "Volume Corse: Confronto Giorni Feriali vs Weekend",
    subtitle = "I Member dominano nei giorni feriali, i Casual aumentano nel weekend.",
    x = "Tipo di giorno"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    legend.position = "top"
  )

# -------------------------------------------------------------
# 5. ANALISI GIORNALIERA: ORE E FASCE ORARIE (2021-2025)
# -------------------------------------------------------------

# 5.1 Uso per ora del giorno (0–23)
# Identifica i picchi di pendolarismo (Member) e le ore di punta ricreativa (Casual).
trips_hour <- trips %>%
  group_by(member_casual, ride_start_hour) %>%
  summarise(
    rides = n(),
    .groups = "drop"
  ) %>%
  collect()

trips_hour

# Grafico
ggplot(trips_hour,
       aes(x = ride_start_hour, y = rides, color = member_casual, group = member_casual)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  scale_color_manual(
    values = c("casual" = "#E69F00", "member" = "#56B4E9"),
    name = "Tipo Utente"
  ) +
  scale_y_continuous(
    labels = label_number(scale = 1e-6, suffix = "M"), 
    name = "Numero di corse"
  ) +
  labs(
    title = "Volume Corse per Ora del Giorno e Tipo Utente",
    x = "Ora di inizio corsa"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    legend.position = "top"
  )


# 5.2 Uso per fascia oraria (time_of_day)
# Sintesi delle ore per l'uso strategico
trips_time_of_day <- trips %>%
  group_by(member_casual, time_of_day) %>%
  summarise(
    rides = n(),
    .groups = "drop"
  ) %>%
  collect() %>%
  mutate(
    time_of_day = factor(
      time_of_day,
      levels = c("Notte","Mattina","Pomeriggio","Sera"),
      ordered = TRUE
    )
  )

trips_time_of_day

# Grafico
ggplot(trips_time_of_day,
       aes(x = time_of_day, y = rides, fill = member_casual)) +
  geom_col(position = "dodge", width = 0.7) +
    scale_y_continuous(
    labels = label_number(scale = 1e-6, suffix = "M"), # Formatta in Milioni (es. 4M)
    name = "Numero di corse"
  ) +
  scale_fill_manual(
    values = c("casual" = "#E69F00", "member" = "#56B4E9"), # Applica i colori esatti
    name = "Tipo Utente"
  ) +
    labs(
    title = "Volume Corse per Fascia Oraria e Tipo Utente",
    subtitle = "I Member dominano nel pendolarismo (Mattina/Pomeriggio), i Casual nel tempo libero.",
    x = "Fascia oraria"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    legend.position = "top"
  )


# -------------------------------------------------------------
# 6. COMPORTAMENTO D'USO: TIPO DI BICI (2021-2025)
# -------------------------------------------------------------

# 6.1 Distribuzione tipi di bici per tipo di utente
# Insight sulla strategia di flotta (Investire in E-bike vs dismettere Docked).
trips_bikes <- trips %>%
  group_by(member_casual, rideable_type) %>%
  summarise(
    rides = n(),
    .groups = "drop"
  ) %>%
  collect()

trips_bikes

# Grafico
ggplot(trips_bikes,
       aes(x = rideable_type, y = rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(
    title = "Tipo di bici utilizzate per categoria di utente",
    x = "Tipo di bici",
    y = "Numero di corse",
    fill = "User Type"
  ) +
  theme_minimal()

# Definizione dell'ordine logico delle tipologie di bici per il grafico
bike_type_order <- c("classic_bike", "electric_bike", "docked_bike", "electric_scooter")

bike_type_summary <- trips_bikes %>%
  mutate(
    rideable_type = factor(rideable_type, levels = bike_type_order, ordered = TRUE)
  )

# Grafico
ggplot(bike_type_summary,
       aes(x = rideable_type, y = rides, fill = member_casual)) +
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
    title = "Preferenze di Bici per Categoria di Utente",
    subtitle = "Le tipologie dominanti: Classic e E-bike.",
    x = "Tipologia di bici"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    legend.position = "top"
  )

# 6.2 Tipo di bici per anno e tipo di utente (Trend di Adozione)
# Traccia l'evoluzione delle preferenze di flotta nel tempo.
trips_bikes_year <- trips %>%
  group_by(ride_year, member_casual, rideable_type) %>%
  summarise(
    rides = n(),
    .groups = "drop"
  ) %>%
  collect()

trips_bikes_year

# Grafico
ggplot(trips_bikes_year,
       aes(x = factor(ride_year), y = rides, fill = rideable_type)) +
  geom_col(position = "dodge") +
  facet_wrap(~ member_casual) +
  labs(
    title = "Tipo di bici per anno e tipo di utente",
    x = "Anno",
    y = "Numero di corse",
    fill = "Rideable Type"
  ) +
  theme_minimal()


# -------------------------------------------------------------
# 7. STAZIONI: ANALISI GEOSPAZIALE INIZIALE
# -------------------------------------------------------------

# 7.1 Top 20 start stations GLOBALE (TUTTI GLI UTENTI)
# Identifica i nodi di traffico generale, ma non il mix comportamentale.
top_start_stations <- trips %>%
  group_by(start_station_name) %>%
  summarise(
    rides = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(rides)) %>%
  head(20) %>%
  collect()

top_start_stations

#GRAFICO TOP 20 STAZIONI (Volume aggregato)
ggplot(top_start_stations,
       aes(x = reorder(start_station_name, rides), y = rides)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Top 20 stazioni di partenza (tutti gli utenti)",
    x = "Stazione di partenza",
    y = "Numero di corse"
  ) +
  theme_minimal()

# 7.2 Top 20 end stations GLOBALE (Volume aggregato)
top_end_stations <- trips %>%
  group_by(end_station_name) %>%
  summarise(
    rides = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(rides)) %>%
  head(20) %>%
  collect()

top_end_stations

# Grafico
ggplot(top_end_stations,
       aes(x = reorder(end_station_name, rides), y = rides)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Top 20 stazioni di arrivo (tutti gli utenti)",
    x = "Stazione di arrivo",
    y = "Numero di corse"
  ) +
  theme_minimal()

# -------------------------------------------------------------
# ANALISI DIFFERENZIATA DELLE STAZIONI (Member vs Casual)
# -------------------------------------------------------------

# Top 20 stazioni di partenza per Member e Casual (analisi a gruppi separati)
# Obiettivo: Rivelare la separazione geografica (hub pendolari vs punti ricreativi). 
top_start_by_type <- trips %>%
  group_by(member_casual, start_station_name) %>%
  summarise(rides = n(), .groups = "drop") %>%
  group_by(member_casual) %>%
  slice_max(order_by = rides, n = 20) %>%
  collect()
top_start_by_type

# Grafico 
ggplot(top_start_by_type, 
       aes(x = rides, y = reorder(start_station_name, rides), fill = member_casual)) +
  geom_col() +
  facet_wrap(~ member_casual, scales = "free") +
  labs(title = "Top 20 stazioni di partenza per categoria di utente",
       x = "Numero di corse", y = "Stazione di partenza") +
  theme_minimal()


# Top 20 stazioni di arrivo per Member e Casual
top_end_by_type <- trips %>%
  group_by(member_casual, end_station_name) %>%
  summarise(rides = n(), .groups = "drop") %>%
  group_by(member_casual) %>%
  slice_max(order_by = rides, n = 20) %>%
  collect()
top_end_by_type

# Grafico
ggplot(top_end_by_type, 
       aes(x = rides, y = reorder(end_station_name, rides), fill = member_casual)) +
  geom_col() +
  facet_wrap(~ member_casual, scales = "free") +
  labs(title = "Top 20 stazioni di arrivo per categoria di utente",
       x = "Numero di corse", y = "Stazione di partenza") +
  theme_minimal()

# -------------------------------------------------------------
# Continuo: Analisi del MIX Member/Casual nelle Stazioni di Maggior Volume
# -------------------------------------------------------------

# Top 20 stazioni di partenza per numero totale di corse (base per il mix)
top_start_global <- trips %>%
  group_by(start_station_name) %>%
  summarise(rides_total = n(), .groups = "drop") %>%
  slice_max(order_by = rides_total, n = 20) %>%
  collect()   

top_start_global

# Calcolo del mix Member/Casual solo su queste stazioni (efficiente: si filtra in remoto, si aggrega in locale)
station_mix_start_top <- trips %>%
  # Applicare il filtro remoto prima di aggregare
  filter(start_station_name %in% top_start_global$start_station_name) %>%
  group_by(start_station_name, member_casual) %>%
  summarise(rides = n(), .groups = "drop") %>%
  collect() %>%  
  # Operazioni finali in R (calcolo della proporzione)
  group_by(start_station_name) %>%
  mutate(
    total_rides = sum(rides),
    prop = rides / total_rides
  ) %>%
  ungroup() %>%
  arrange(desc(total_rides), start_station_name)

station_mix_start_top

# Heatmap stazioni di partenza: Visualizza il mix di utenti in ogni stazione top
ggplot(station_mix_start_top,
       aes(x = member_casual,
           y = reorder(start_station_name, total_rides), 
           fill = prop)) +
  geom_tile(color = "white", linewidth = 0.5) +
    geom_text(aes(label = scales::percent(prop, accuracy = 1)),
            color = "white", 
            fontface = "bold", 
            size = 3.5) +
    scale_fill_gradient(
    name = "Proporzione",
    labels = scales::percent,
    limits = c(0, 1),
    low = "#56B4E9", 
    high = "#004488" 
  ) +
  
  labs(
    title = "Mix Member vs Casual nelle Top 20 Stazioni di Partenza",
    subtitle = "Member: zone business. Casual: zone turistiche. ",
    x = "Tipo di utente",
    y = "Stazione di partenza"
  ) +
  theme_minimal() +
  theme(
    axis.text.y = element_text(size = 8),
    legend.position = "right",
    legend.title = element_text(face = "bold")
  )

# Top 20 stazioni di arrivo per numero totale di corse (base per il mix)
top_end_global <- trips %>%
  group_by(end_station_name) %>%
  summarise(rides_total = n(), .groups = "drop") %>%
  slice_max(order_by = rides_total, n = 20) %>%
  collect()   

top_end_global

# Calcolo il mix Member/Casual solo su queste stazioni di arrivo
station_mix_end_top <- trips %>%
  # filtro solo le stazioni top usando un vettore (più semplice di semi_join su remoto)
  filter(end_station_name %in% top_end_global$end_station_name) %>%
  group_by(end_station_name, member_casual) %>%
  summarise(rides = n(), .groups = "drop") %>%
  collect() %>% 
  group_by(end_station_name) %>%
  mutate(
    total_rides = sum(rides),
    prop = rides / total_rides
  ) %>%
  ungroup() %>%
  arrange(desc(total_rides), end_station_name)

station_mix_end_top

# Heatmap stazioni di arrivo: Visualizza il mix di utenti in ogni stazione top
ggplot(station_mix_end_top,
       aes(x = member_casual,
           y = reorder(end_station_name, total_rides),
           fill = prop)) +
  geom_tile() +
  geom_text(aes(label = scales::percent(prop, accuracy = 1))) +
  scale_fill_gradient(
    name   = "Proporzione",
    labels = scales::percent,
    limits = c(0, 1)
  ) +
  labs(
    title = "Mix Member vs Casual nelle top 20 stazioni di arrivo",
    x = "Tipo di utente",
    y = "Stazione di arrivo"
  ) +
  theme_minimal() +
  theme(
    axis.text.y = element_text(size = 8),
    legend.position = "right"
  )

# Chiude la connessione al database per liberare risorse
dbDisconnect(con)

############ FINE EDA_base #################### 
# -------------------------------------------------------------
# Nel prossimo script "03_EDA_meteo.R" ci concentreremo
# sull'impatto di fattori esterni: Temperatura, Pioggia e Stagione.
# -------------------------------------------------------------
# NOTA: La classificazione sistematica 'tourist/commuter/mixed' usata nel ML
# sarà creata in uno script separato, calcolando il mix su tutte le stazioni del train set.
# -------------------------------------------------------------

