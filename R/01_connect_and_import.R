############################################################
# Cyclistic Bike-Share - 01_connect_and_import.R
# OBIETTIVO: Importare tutti i file CSV grezzi dei viaggi
# in un'unica tabella raw sul database PostgreSQL per la
# successiva fase di pulizia e trasformazione (ETL).
############################################################
# ----------------------------------------------------------
# 1. CARICAMENTO LIBRERIE
# ----------------------------------------------------------

# DBI: Interfaccia standard R per la connessione a database
library(DBI)
# RPostgres: Driver specifico per PostgreSQL
library(RPostgres)
# data.table: Utilizzato per la lettura veloce dei file CSV (funzione fread)
library(data.table)

# ----------------------------------------------------------
# 2. CONNESSIONE AL DATABASE POSTGRESQL
# ----------------------------------------------------------
con <- dbConnect(
  RPostgres::Postgres(),
  dbname="cyclistic",
  host="***",
  port=****,
  user="****",
  password="***"
)

message("Connessione a PostgreSQL riuscita.")
# ----------------------------------------------------------
# 3. IDENTIFICAZIONE DEI FILE CSV
# ----------------------------------------------------------

# Crea la lista completa dei percorsi di tutti i file .csv
data_path <- "data_raw" #percorso relativo dal mio progetto R
files<-list.files(
  path = data_path,
  pattern = "\\.csv$",
  full.names = TRUE # Ottiene il percorso completo per fread
)

# Verifica: controlla se sono stati trovati tutti i 58 file trimestrali
message(paste0("Trovati ", length(files), " file CSV da importare."))

# Test: importo solo un file per prova 
test_file<- files[1]
dt<-fread(test_file)
str(dt) #colonne
head(dt) #se sembra ok
dbWriteTable(
  con,
  name = "trip_raw", #tabella su DB POSTGRESQL
  value = dt,
  append= TRUE,
  row.names= FALSE
) #IL COLLEGAMENTO FUNZIONA E QUINDI PROCEDO A IMPORTARE TUTTI I DATASET NELLA TABELLA IN POSTGRESQL

# ----------------------------------------------------------
# 4. INGESTIONE DATI: Importazione sequenziale su DB
# ----------------------------------------------------------
# Loop per importare e accodare (append) tutti i file CSV
for (f in files) {
  message ("Importo: ", f)
  dt<-fread(f) # Legge il file CSV rapidamente
  # Scrive la tabella su PostgreSQL, creando la struttura la prima volta
  # e accodando i dati per le iterazioni successive.
  dbWriteTable(
    con,
    name = "trip_raw",
    value = dt,
    append=TRUE,
    row.names= FALSE
  )
}

# Disconnessione dal database
dbDisconnect(con)
############################################################
# Prossimi passi:
# 02_EDA_base
# 03_EDA_weather
# 04_machine_learning_models
############################################################
