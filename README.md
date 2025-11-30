# 🚴 Cyclistic Bike-Share (Chicago) — Behavioral Analytics & Data Strategy

![Records](https://img.shields.io/badge/Records-28M-blue) ![Period](https://img.shields.io/badge/Period-2021--2025-lightgrey) ![SQL](https://img.shields.io/badge/SQL-PostgreSQL-316192?logo=postgresql&logoColor=white) ![R](https://img.shields.io/badge/R-4.5.1-276DC3?logo=r&logoColor=white) ![ML](https://img.shields.io/badge/ML-Logit%20%7C%20RandomForest-orange) ![EDA](https://img.shields.io/badge/EDA-Exploratory%20Analysis-green) ![Weather](https://img.shields.io/badge/Data-Meteostat-blueviolet)![Power BI](https://img.shields.io/badge/PowerBI-Dashboard-F2C811?logo=powerbi&logoColor=white)

***Dataset finale**:* \~21M corse · ***Periodo**:* 2021–2025 · ***Stack**:* PostgreSQL · R · SQL · ML\
***Repository**:* End-to-end data project con pipeline, EDA, modellazione e raccomandazioni

## Obiettivo del Progetto

Analizzare 58 mesi di dati del servizio Cyclistic per:

1.  Identificare pattern d’uso dei segmenti Member vs Casual,

2.  Costruire una pipeline scalabile su dataset di grandi dimensioni,

3.  Integrare dati meteo multi-anno,

4.  Validare i driver comportamentali via modelli predittivi,

5.  Proporre raccomandazioni operative basate sui dati.

## Architettura del Progetto

1.  *Data Engineering*
    -   ingestione automatizzata dei CSV
    -   pulizia, deduplicazione e feature engineering in SQL
    -   integrazione dati Meteostat\
        → vedi [pipeline_details.md](pipeline_details.md)
2.  *EDA (Exploratory Data Analysis)*
    -   comportamento Member vs Casual
    -   pattern temporali, geografici, meteo\
        → vedi [EDA.md](EDA.md)
3.  *Modelli Predittivi*
    -   Logistic Regression + Random Forest
    -   AUC \~0.74, accuracy \~70%\
        → vedi [ML_models.md](ML_models.md)
4.  *Strategic Insights*
    -   conversione selettiva dei Casual
    -   consolidamento commuting
    -   ottimizzazione stagionale della flotta\
        → vedi [Strategic_Recommendations.md](Strategic_Recommendations.md)

## Risultati Chiave

-   *Durata* = principale driver comportamentale
-   *Stazioni* = commuter hub vs hotspot turistici
-   *Tempo* = feriali/mattina → Member; weekend/estate → Casual
-   *Meteo* = condizioni miti (15–25°C) amplificano uso ricreativo
-   I modelli confermano statisticamente i pattern (AUC \~0.74)

## Dashboard (Power BI)

La dashboard di Cyclistic fornisce un'analisi comportamentale completa, traducendo oltre 21 milioni di corse in un piano d'azione strategico per massimizzare la fidelizzazione e la crescita degli abbonati. Il report è suddiviso in tre sezioni (**Executive Overview, Context & Predictive Insights, Strategy & Actions**) per garantire un flusso narrativo coerente e orientato alla decisione. ![](PowerBI/dashboard_page1.png)

### Key Features & Techniques Used

-   *Analisi Comportamentale (EDA):* Delinea i pattern opposti di Member (61%) vs Casual (39%), identificando la *durata della corsa* come principale driver di differenziazione.
-   *Integrazione Meteo & Stagionalità:* Valuta la *resilienza dei Member* alle condizioni avverse e quantifica la dipendenza dei Casual dalle condizioni climatiche e dalla stagione (indice di stagionalità ≈ 5:1 tra estate e inverno).
-   *Driver Predittivi (ML):* Utilizza l'output di modelli di Regressione Logistica e Random Forest per identificare e quantificare i fattori più influenti tramite *feature importance* e *odds ratio*.
-   *Mappa Strategica Spazio/Tempo:* Analizza la domanda per fasce orarie (mattina/sera) e categorie di stazioni (commuter/turistica) per mappare l’uso funzionale vs ricreativo.
-   *Piano d’Azione Segmentato:* Le raccomandazioni sono chiaramente divise in Member Strategy (consolidamento) e Casual Strategy (conversione selettiva).

### Value & Impact

✔ *Validazione statistica:* Le ipotesi dell’EDA sono supportate da odds ratio che quantificano l’effetto di variabili chiave (es. durata e tipo di stazione) sulla probabilità di appartenere a ciascun segmento.\
✔ *Strategia mirata:* Sostiene iniziative come la promozione delle e-bike e il *push post-corsa* come leve per intercettare i Casual ad alto potenziale di conversione.\
✔ *Ottimizzazione operativa:* Guida il rebalancing della flotta concentrandosi sugli hub di pendolarismo e sulle campagne stagionali per mitigare il calo invernale.\
✔ *Visione end-to-end:* Collega comportamento utente, meteo e output dei modelli predittivi in un unico framework decisionale.

## Struttura del Repository

``` text
Cyclistic-Bike-Share-Analytics/
├── README.md 
├── pipeline_details.md 
├── EDA.md 
├── ML_models.md 
├── Strategic_Recommendations.md 
├── sql/ 
├── r/
├── PowerBI/
└── images/                        
```

## Riproducibilità

-   Database: PostgreSQL
-   Linguaggi: R (tidyverse, dbplyr, data.table) & SQL
-   Pipeline e script disponibili nelle cartelle sql/ e r/
