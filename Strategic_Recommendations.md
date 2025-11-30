# **Strategic Recommendations — Data-Driven Actions**

![Users Breakdown](https://img.shields.io/badge/Casual%2038.9%25%20%7C%20Member%2061.1%25-blue) ![Primary Driver](https://img.shields.io/badge/Top%20Driver-Durata%20Corsa-purple) ![Peak Conversion](https://img.shields.io/badge/Conversion%20Window-Estate%20%7C%20Weekend-yellow) ![Low Conversion](https://img.shields.io/badge/NO%20Conversion-Freddo%20%7C%20Pioggia-red) ![Geo Insight](https://img.shields.io/badge/Hotspots-Turistici%20vs%20Commuter-orange) ![Resource Strategy](https://img.shields.io/badge/Flotta-Redistribuzione%20Stagionale-green)

Le analisi (EDA) e i modelli predittivi (Logit + Random Forest) mostrano due segmenti distinti e stabili nel tempo:

-   *Member (pendolari)* → utilizzo breve, ricorrente, “all-weather”
-   *Casual (turismo/tempo libero)* → utilizzo lungo, stagionale, sensibile al meteo

I driver principali validati dal ML:

-   Durata della corsa (feature #1),

-   Categoria delle stazioni (tourist vs commuter),

-   Tempo (fasce orarie, weekend),

-   Stagionalità e condizioni meteo.

Queste evidenze guidano le seguenti raccomandazioni.

## 1. Strategia per i Member (Retention & Commuting)

*Obiettivo:* aumentare rinnovi, fidelizzare utilizzo pendolare, sostenere uso in condizioni avverse.

### Azioni

-   *Potenziare il commuting*
    -   partnership con aziende
    -   incentivi casa-lavoro
    -   promozioni per fasce 7–9 e 16–18\
        Razionale: commuting hub = OR \> 1, pattern stabile tutto l’anno
-   *Inverno: campagne “all-weather”*
    -   kit sicurezza
    -   visibilità delle e-bike\
        Razionale: pioggia/neve aumentano odds Member → messaging realistico
-   *Upgrade comfort*
    -   priorità alle e-bike
    -   stazioni ad alta densità nelle zone business\
        Razionale: e-bike più associate all’uso funzionale quando non turistiche

## 2. Strategia per i Casual (Conversione Selettiva)

*Obiettivo:* convertire solo quando il comportamento Casual assomiglia a quello Member.

### Finestra di conversione ad alta probabilità

-   stagione mite (15–25°C)
-   weekend
-   hotspot turistici
-   corse lunghe

### Azioni

-   *Offerte mirate nei punti turistici*
    -   “3-day pass → upgrade annuale”\
        Razionale: stazioni turistiche → OR \< 1 (segmento Casual chiaro)
-   *Push post-corsa lunga*
    -   notifiche di risparmio / bundle upgrade\
        Razionale: +10 min durata = −20% odds Member → forte segnale ricorrente
-   *Target giovani/lifestyle*
    -   iniziative gamification, social, micro-incentivi\
        Razionale: utilizzo concentrato in estate/pomeriggio

## 3. Strategia sulla Flotta (Ottimizzazione Operativa)

### Azioni

-   *Aumentare e-bike*

    -   riducono sforzo in caldo/vento moderato\
        Razionale: bike_type tra le feature top del modello\*

-   *Ridurre flotta docked obsolete*\
    Razionale: OR ≪ 1 → quasi esclusivamente Casual a bassa conversione\*

-   *Redistribuzione stagionale dinamica*

    -   estate: più mezzi nelle aree turistiche
    -   inverno: rinforzo nei commuting hub\
        Razionale: ciclicità stabile Member vs stagionalità Casual\*

## 4. Dove NON investire (Bassa ROI)

### Contesti da evitare

| Condizione | Motivo |
|----|----|
| *Freddo \<5°C* | domanda Casual \~−80% |
| *Pioggia/vento forte* | quasi solo Member residui → nessuna conversione |
| *Caldo \>25°C* | uso frammentato, motivazione non orientata all’abbonamento |

➡ Campagne marketing e promozioni in queste condizioni hanno ROI molto basso.

## 5. Sintesi Finale

Le analisi mostrano pattern coerenti, stabili e predittivi.\
Le leve operative con maggiore impatto sono:

-   *durata della corsa* (driver #1),
-   *categoria stazione*,
-   *fascia oraria / weekend*,
-   *stagione e meteo*,
-   *tipo di bici*.

L’approccio strategico ottimale è duale:

1.  *Consolidare i Member* → commuting, comfort, inverno
2.  *Convertire i Casual solo nei contesti ad alta propensione* → estate, weekend, hotspot, corse lunghe

Questo massimizza conversioni e utilizzo della flotta con investimenti mirati.

## 🔗 Collegamenti

-   Modelli ML: [ML_models.md](ML_models.md)
-   EDA: [EDA.md](EDA.md)
-   Pipeline: [pipeline_details.md](pipeline_details.md)
