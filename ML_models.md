# **Modelli di Machine Learning: Validazione dei Pattern Comportamentali**

![Machine Learning](https://img.shields.io/badge/Goal-Model%20Validation-orange?style=for-the-badge) ![Logistic Regression](https://img.shields.io/badge/Model-Logistic%20Regression-blue?style=for-the-badge) ![Random Forest](https://img.shields.io/badge/Model-Random%20Forest-green?style=for-the-badge)

Obiettivo: verificare in modo quantitativo se durata, tempo, stazioni e meteo spiegano in modo robusto la differenza tra utenti *Member* e *Casual*.

## 1. Setup & Dataset

*Dataset:* `trips_with_weather` (campione stratificato da \~21M record)\
*Target:* `user_type` = Member vs Casual\
*Train/Test split:* 70/30, stratificato

*Feature principali utilizzate:*

-   *Utilizzo & tempo*
    -   `duration_min`
    -   `time_bin` (Notte, Mattina, Pomeriggio, Sera)
    -   `is_weekend`
    -   `year`
-   *Tipo bici*
    -   `bike_type` (classic, electric, other)
-   *Stazioni (senza leakage)*
    -   `start_station_cat` (tourist, commuter, mixed)
    -   `end_station_cat` (tourist, commuter, mixed)
-   *Meteo*
    -   `season` (Inverno, Primavera, Estate, Autunno)
    -   `temp_bin` (\<5°C, 5–15°C, 15–25°C, ≥25°C)
    -   `rain`
    -   `is_snowing`
    -   `wspd_category` (debole, moderato, forte)

## 2. Modelli Addestrati

1.  *Logistic Regression*
    -   baseline interpretabile
    -   output in odds ratio
2.  *Random Forest*
    -   modello non lineare
    -   capacità di catturare interazioni complesse
    -   addestrato su sotto-campione stratificato del train (5% per classe), valutato sul test completo

## 3. Performance (alto livello)

| Metrica              | Logistic Regression | Random Forest |
|----------------------|---------------------|---------------|
| Accuracy             | \~0.703             | \~**0.706**   |
| AUC ROC              | \~0.737             | \~**0.744**   |
| Sensitivity (Casual) | \~0.41              | \~0.43        |
| Specificity (Member) | \~0.89              | \~0.88        |

-   Entrambi i modelli superano il *No Information Rate* (\~0.61).\
-   La *Random Forest* è leggermente migliore in AUC e accuracy.\
-   Entrambi i modelli sono *più precisi nel riconoscere i Member* (comportamento più regolare).

## 4. Driver Principali (Logistic Regression)

I coefficienti sono stati interpretati come *odds ratio* (OR) rispetto alla probabilità di essere *Member*.

**Durata (duration_min)** - OR \~0.98 per minuto\
- Ogni +10 minuti di corsa ≈ −20% odds di essere Member\
➡ Le corse lunghe sono fortemente associate ai Casual.

*Tempo & calendario* - time_binMattina / Pomeriggio / Sera → OR \> 1 rispetto alla Notte\
- is_weekend → OR \< 1\
➡ Mattina e feriali sono tipici dei Member; weekend sposta il mix verso i Casual.

*Evoluzione temporale* - year → OR \> 1\
➡ Nel tempo aumenta la quota relativa di Member: il servizio si consolida come mezzo di trasporto regolare.

*Tipo di bici* - bike_typeother → OR ≪ 1\
- bike_typeelectric → OR \< 1\
➡ Docked/other quasi solo Casual; e-bike più associata a utilizzi “Casual-friendly”.

*Stazioni* - station_cattourist → OR \< 1\
- tation_catcommuter → OR \> 1\
➡ Le categorie di stazione sono un forte discriminante tra turismo e commuting.

*Stagioni & meteo* - Stagioni non invernali → OR \< 1 rispetto all’inverno\
- Pioggia/neve → OR \> 1\
➡ In condizioni avverse restano soprattutto utenti Member.

## 5. Feature Importance (Random Forest)

Ordine di importanza (schematizzato):

1.  **`duration_min`**\
2.  **`end_station_cat`**\
3.  **`bike_type`**\
4.  `start_station_cat`
5.  `is_weekend`
6.  `temp_bin`
7.  `time_bin`
8.  `year, season`
9.  `rain, wspd_category, is_snowing`

➡ Il modello non lineare conferma la stessa gerarchia osservata in EDA: *durata, stazioni, tempo* dominano il comportamento; il meteo modula il mix utenti.

## 6. Interpretazione & Limiti

-   I modelli sono progettati per *validare pattern*, non per deployment in produzione.
-   Sono particolarmente forti nel riconoscere i Member, meno nel distinguere tutti i casi di Casual (comportamento più rumoroso).
-   Per obiettivi orientati alla conversione Casual si potrebbero:
    -   variare la soglia di classificazione (≠ 0.5),
    -   usare class weights/cost-sensitive learning,
    -   costruire un modello dedicato a “Casual ad alto potenziale”.

## 7. Collegamenti

-   EDA: [EDA.md](EDA.md)
-   Pipeline: [pipeline_details.md](pipeline_details.md)
-   Strategia: [Strategic_Recommendations.md](Strategic_Recommendations.md)
-   Script R: r/04_machine_learning_models.R
