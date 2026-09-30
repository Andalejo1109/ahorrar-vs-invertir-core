# Ahorrar vs Invertir - core renta variable (2013-hoy)

Con los **mismos aportes mensuales**, cuanto crece una cuenta de **renta fija USD al 5 % anual** frente al **core de renta variable** (SPYG, SMH, BRK.B, IEMG, VTI) usando precios reales Adjusted Close?

> **Disclaimer:** Esto **no es consejo de inversion**. Los retornos pasados no predicen resultados futuros. Material educativo y medible.

Autor: **Andres Alejandro Rodriguez Lozano** | [@Andalejo1109](https://github.com/Andalejo1109) | [andalejo1109.github.io](https://andalejo1109.github.io) | eToro [@Andalejo1109](https://www.etoro.com/people/andalejo1109)

## Parametros [DEFAULT]

| Parametro | Valor |
|-----------|------:|
| `start` | 2013-01-01 |
| `end` | fecha de corrida (`Sys.Date()`) |
| **`aporte_mensual`** | **200 USD** |
| `capital_inicial` | 1000 USD |
| **`rf_annual`** | **5 % constante** |
| Capitalizacion RF | diaria: `(1 + 0.05)^(dias/365.25)` |
| Costos | **0 bps** |
| Dia de aporte | primer dia habil de cada mes |
| Rebalance equity | mensual en el dia de aporte |

### Pesos del core

| Ticker (Yahoo) | Peso |
|----------------|-----:|
| SPYG | 0.31 |
| SMH | 0.22 |
| BRK-B (BRK.B) | 0.20 |
| IEMG | 0.20 |
| VTI | 0.07 |

## Hallazgos (corrida real)

Muestra: **2013-01-02 -> 2026-09-29** (3456 dias habiles, ~**13.74 anos**). Costos = **0 bps**.

| Metrica | Valor |
|---------|------:|
| Capital aportado | **$33,800** |
| TV renta fija 5 % | **$48,665** |
| TV core equity | **$140,346** |
| Ratio equity / RF | **2.88x** |
| Multiplo RF | 1.44x |
| Multiplo equity | 4.15x |
| CAGR aprox. RF (sobre aportado) | ~ 2.7 % |
| CAGR aprox. equity (sobre aportado) | ~ 10.9 % |
| Max drawdown equity | **-30.7 %** |

**CAGR aprox. sobre aportado** = `(TV / capital_aportado)^(1/anos) - 1`. No es TWR.

### Lectura rapida

Con los mismos $33,800 aportados, el core termino cerca de **2.9 veces** el valor de la cuenta al 5 %, con volatilidad (max DD ~ -31 %).

## Como leer los graficos

- Panel superior: RF 5 % (suave).
- Panel inferior: core con volatilidad; area clara = capital aportado; linea punteada = RF.
- GIF: `output/comparar_animado.gif` (generar con `Rscript main.R`).
- Vista web: `output/galeria.html` (PNG embebido).

## Como correr

```bash
Rscript -e 'install.packages(c("quantmod","ggplot2","dplyr","tidyr","scales","patchwork","zoo","gganimate","magick"), repos="https://cloud.r-project.org")'
cd ahorrar-vs-invertir-core
Rscript main.R
```

Ver tambien `REQUIREMENTS.md`.

## Limitaciones

- RF 5 % constante; costos = 0; un solo camino historico 2013-hoy (alcista US/tech); sin FX; Adjusted Close Yahoo.

## Licencia

MIT (c) Andres Alejandro Rodriguez Lozano
