############################################################
# 04_machine_learning_models.R
# Cyclistic Bike-Share - Modellazione Predittiva
#
# OBIETTIVO:
# Prevedere se un utente è "casual" o "member" e
# quantificare l'impatto delle principali feature
# (temporalità, meteo, stazioni, tipo di bici).
############################################################

#############################
# 0. PACCHETTI
#############################
library(dplyr)
library(forcats)
library(ggplot2)
library(caret)
library(broom)
library(pROC)
library(ranger)
library(tibble)
library(tidyr)
library(rlang)

#############################
# 0.1 CHECK: trips_weather esiste?
#############################
if (!exists("trips_weather")) {
  stop("ERRORE: 'trips_weather' non trovato. Esegui prima lo script 03_EDA_meteo.R per crearlo.")
}

# Creo una copia locale per sicurezza
df_raw <- trips_weather
 
############################################################
# 1. FEATURE ENGINEERING DI BASE (senza leakage)
#    - qui facciamo SOLO trasformazioni "row-wise"
#      (nessuna aggregazione sulle stazioni).
############################################################

message("--- Fase 1: Feature engineering di base ---")

df_clean <- df_raw %>%
  mutate(
    # Fattore "casual"/"member" 
    user_type = member_casual,   
    
    # Durata in minuti
    duration_min = ride_duration_min,
    
    # Neve (qualunque valore > 0 conta come "giorno con neve")
    is_snowing = snow > 0,
    
    # Fasce di velocità del vento (km/h)
    wspd_category = case_when(
      wspd < 20 ~ "Vento Debole (<20 km/h)",
      wspd >= 20 & wspd < 40 ~ "Vento Moderato (20-40 km/h)",
      wspd >= 40 ~ "Vento Forte (≥40 km/h)"
    )
  ) %>%
  
  # Selezioniamo SOLO le colonne che ci servono per ML
  select(
    user_type,
    duration_min,
    ride_year,
    time_of_day,
    is_weekend,
    season,
    temp_category,
    rain = is_rain,
    is_snowing,
    wspd_category,
    rideable_type,
    start_station_name,
    end_station_name
  ) %>%
  
  # Per sicurezza: togliamo eventuali NA residui
  na.omit()

############################################################
# 2. TRAIN–TEST SPLIT (70/30, NO LEAKAGE)
#    - Splittiamo PRIMA di calcolare le categorie stazioni.
############################################################

message("--- Fase 2: Train/Test split (70/30) ---")

set.seed(123)

# Usiamo createDataPartition per bilanciare le classi
train_index <- createDataPartition(df_clean$user_type,
                                   p = 0.70,
                                   list = FALSE)

train_base <- df_clean[train_index, ]
test_base  <- df_clean[-train_index, ]

############################################################
# 3. CATEGORIE STAZIONI (tourist / commuter / mixed)
#    - calcolate SOLO sul TRAIN (per evitare data leakage)
############################################################

message("--- Fase 3: Creazione categorie stazioni (solo su TRAIN) ---")

# Funzione helper per creare la mappa delle stazioni
create_station_map <- function(data, station_col_name) {
  data %>%
    group_by(.data[[station_col_name]], user_type) %>%
    summarise(count = n(), .groups = "drop") %>%
    group_by(.data[[station_col_name]]) %>%
    mutate(
      total = sum(count),
      prop  = count / total
    ) %>%
    # ci basta guardare la proporzione di "casual"
    filter(user_type == "casual") %>%
    summarise(
      station_cat = case_when(
        prop >= 0.65 ~ "tourist",   # stazione dominata dai casual
        prop <= 0.35 ~ "commuter",  # stazione dominata dai member
        TRUE         ~ "mixed"      # via di mezzo
      ),
      .groups = "drop"
    ) %>%
    select(station_name = .data[[station_col_name]], station_cat)
}

# Mappe stazioni dal SOLO train_base
start_map <- create_station_map(train_base, "start_station_name")
end_map   <- create_station_map(train_base, "end_station_name")

# Funzione per applicare le mappe a train/test
apply_station_cat <- function(dataset, start_map, end_map) {
  dataset %>%
    # aggiungo categoria stazione di PARTENZA
    left_join(start_map, by = c("start_station_name" = "station_name")) %>%
    rename(start_station_cat = station_cat) %>%
    
    # aggiungo categoria stazione di ARRIVO
    left_join(end_map, by = c("end_station_name" = "station_name")) %>%
    rename(end_station_cat = station_cat) %>%
    
    mutate(
      # Stazioni mai viste nel TRAIN -> "mixed"
      start_station_cat = replace_na(start_station_cat, "mixed"),
      end_station_cat   = replace_na(end_station_cat, "mixed"),
      
      start_station_cat = factor(start_station_cat,
                                 levels = c("mixed", "tourist", "commuter")),
      end_station_cat   = factor(end_station_cat,
                                 levels = c("mixed", "tourist", "commuter"))
    ) %>%
    # non servono più i nomi stazione testuali per il modello
    select(-start_station_name, -end_station_name)
}

train_stations <- apply_station_cat(train_base, start_map, end_map)
test_stations  <- apply_station_cat(test_base,  start_map, end_map)

############################################################
# 4. PREPARAZIONE FINALE FEATURE PER IL MODELLO
#    - una sola variabile per concetto (no ridondanze)
############################################################

message("--- Fase 4: Preparazione finale feature (df_train_model / df_test_model) ---")

prepare_for_model <- function(dataset) {
  dataset %>%
    mutate(
      # TARGET
      user_type = factor(user_type,
                         levels = c("casual", "member")),
      
      # Tempo (usiamo SOLO le versioni "business-friendly")
      time_bin = factor(
        time_of_day,
        levels = c("Notte", "Mattina", "Pomeriggio", "Sera")
      ),
      is_weekend = factor(
        is_weekend,
        levels = c(FALSE, TRUE),
        labels = c("weekday", "weekend")
      ),
      year = ride_year,
      
      # Stagione (calendario civile)
      season = factor(
        season,
        levels = c("Inverno", "Primavera", "Estate", "Autunno")
      ),
      
      # Meteo
      temp_bin = factor(
        temp_category,
        levels = c("<5°C (Freddo)",
                   "5-15°C (Fresco)",
                   "15-25°C (Mite)",
                   "≥25°C (Caldo)"),
        ordered = TRUE
      ),
      rain = factor(
        rain,
        levels = c(FALSE, TRUE),
        labels = c("dry", "rain")
      ),
      is_snowing = factor(
        is_snowing,
        levels = c(FALSE, TRUE),
        labels = c("no_snow", "snow")
      ),
      wspd_category = factor(
        wspd_category,
        levels = c("Vento Debole (<20 km/h)",
                   "Vento Moderato (20-40 km/h)",
                   "Vento Forte (≥40 km/h)"),
        ordered = TRUE
      ),
      
      # Tipo di bici
      bike_type = fct_collapse(
        rideable_type,
        classic  = "classic_bike",
        electric = "electric_bike",
        other    = c("docked_bike", "electric_scooter")
      ),
      bike_type = fct_relevel(bike_type, "classic"),
      
      # Categorie stazioni 
      start_station_cat = factor(start_station_cat,
                                 levels = c("mixed", "tourist", "commuter")),
      end_station_cat   = factor(end_station_cat,
                                 levels = c("mixed", "tourist", "commuter"))
    ) %>%
    transmute(
      user_type,
      duration_min,
      time_bin,
      is_weekend,
      year,
      bike_type,
      start_station_cat,
      end_station_cat,
      season,
      temp_bin,
      rain,
      is_snowing,
      wspd_category
    ) %>%
    na.omit()
}

train_model <- prepare_for_model(train_stations)
test_model  <- prepare_for_model(test_stations)

############################################################
# 5. REGRESSIONE LOGISTICA
############################################################

message("--- Fase 5: Regressione logistica ---")

mod_logit <- glm(
  user_type ~ duration_min +
    time_bin +
    is_weekend +
    year +
    bike_type +
    start_station_cat +
    end_station_cat +
    season +
    temp_bin +
    rain +
    is_snowing +
    wspd_category,
  data   = train_model,
  family = binomial(link = "logit")
)

# Riassunto modello
summary(mod_logit)

# Odds Ratio per interpretazione
logit_or <- exp(coef(mod_logit))
logit_or

############################################################
# 6. VALUTAZIONE LOGISTICA (Accuracy, CM, ROC, AUC)
############################################################

message("--- Fase 6: Valutazione logistica su Test Set ---")

# Probabilità di essere MEMBER
prob_logit <- predict(mod_logit, newdata = test_model, type = "response")

# Classe predetta con soglia 0.5
pred_logit <- ifelse(prob_logit > 0.5, "member", "casual")
pred_logit <- factor(pred_logit, levels = c("casual", "member"))

# Accuratezza
logit_acc <- mean(pred_logit == test_model$user_type)
logit_acc

# Confusion Matrix completa
cm_logit <- confusionMatrix(pred_logit, test_model$user_type)
cm_logit

# ROC e AUC
roc_logit <- roc(
  response  = test_model$user_type,
  predictor = prob_logit,
  levels    = c("casual", "member"),
  direction = "<"
)

plot(roc_logit,
     col  = "blue",
     lwd  = 2,
     main = "ROC Curve - Logistic Regression")

auc_logit <- auc(roc_logit)
auc_logit

############################################################
# 7. RANDOM FOREST (su campione stratificato del TRAIN)
############################################################

message("--- Fase 7: Random Forest (train su campione stratificato) ---")

set.seed(123)

# Campioniamo una frazione del TRAIN per non esplodere la RAM
train_sample_rf <- train_model %>%
  group_by(user_type) %>%
  sample_frac(0.05) %>%  # 5% per classe (aumenta se hai più RAM)
  ungroup()

nrow(train_sample_rf)

rf_model <- ranger(
  formula       = user_type ~ .,
  data          = train_sample_rf,
  num.trees     = 100,
  mtry          = 4,
  min.node.size = 100,
  probability   = TRUE,
  importance    = "impurity"
)

rf_model

############################################################
# 8. VALUTAZIONE RANDOM FOREST (su TUTTO il Test Set)
############################################################

message("--- Fase 8: Valutazione Random Forest su Test Set ---")

rf_pred_obj    <- predict(rf_model, data = test_model)
rf_prob_member <- rf_pred_obj$predictions[, "member"]

rf_class <- ifelse(rf_prob_member > 0.5, "member", "casual")
rf_class <- factor(rf_class, levels = c("casual", "member"))

# Accuratezza
rf_acc <- mean(rf_class == test_model$user_type)
rf_acc

# Confusion Matrix
rf_cm <- confusionMatrix(rf_class, test_model$user_type)
rf_cm

# ROC + AUC RF
rf_roc <- roc(
  response  = test_model$user_type,
  predictor = rf_prob_member,
  levels    = c("casual", "member"),
  direction = "<"
)

plot(rf_roc,
     col  = "darkgreen",
     lwd  = 2,
     main = "ROC Curve - Random Forest")

auc_rf <- auc(rf_roc)
auc_rf

############################################################
# 9. CONFRONTO ROC LOGIT vs RF (opzionale)
############################################################

plot(roc_logit,
     col  = "blue",
     lwd  = 2,
     main = "Confronto ROC - Logistic vs Random Forest")

plot(rf_roc,
     col  = "darkgreen",
     lwd  = 2,
     add  = TRUE)

legend("bottomright",
       legend = c(
         paste0("Logistic (AUC = ", round(auc_logit, 3), ")"),
         paste0("Random Forest (AUC = ", round(auc_rf, 3), ")")
       ),
       col = c("blue", "darkgreen"),
       lwd = 2)

############################################################
# 10. FEATURE IMPORTANCE (Random Forest)
############################################################

imp_df <- enframe(rf_model$variable.importance,
                  name  = "variable",
                  value = "importance") %>%
  arrange(desc(importance))

imp_df

ggplot(imp_df,
       aes(x = reorder(variable, importance),
           y = importance,
           fill = importance)) + 
  
  geom_col(show.legend = FALSE) + 
  coord_flip() +
    scale_fill_gradient(low = "#CFE2F3", high = "#004488") +
  
  labs(
    title = "Feature Importance - Random Forest",
    subtitle = "La durata della corsa è il predittore dominante.",
    x = "Variabile",
    y = "Importanza (impurity)"
  ) +
  
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    axis.text.y = element_text(size = 10) 
  )
############################################################
# FINE SCRIPT
############################################################