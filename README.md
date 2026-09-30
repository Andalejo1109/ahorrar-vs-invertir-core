# Ahorrar vs Invertir — core renta variable

¿Con los **mismos aportes mensuales**, cuánto crece una cuenta de **renta fija USD al 5 % anual** frente al **core de renta variable** (SPYG, SMH, BRK.B, IEMG, VTI) usando precios reales Adjusted Close?

> **Disclaimer:** Esto **no es consejo de inversión**. Los retornos pasados no predicen resultados futuros. Material educativo y medible. No hay garantía de que la renta variable supere a la renta fija en el futuro.

Autor: **Andrés Alejandro Rodríguez Lozano** · [@Andalejo1109](https://github.com/Andalejo1109) · [andalejo1109.github.io](https://andalejo1109.github.io) · eToro [@Andalejo1109](https://www.etoro.com/people/andalejo1109)

---

## Para clase (data analytics)

**Abre y corre un solo archivo:** `ahorrarvsinvertir.R`

```bash
cd ahorrar-vs-invertir-core
Rscript ahorrarvsinvertir.R
```

O ábrelo en RStudio / R y haz *Source*.

**Cambia solo el bloque `CONFIG` al inicio de `ahorrarvsinvertir.R`.** No hace falta editar el resto del pipeline.

### Escenarios de ejemplo (comentados en CONFIG)

| Escenario | start | capital_inicial | aporte_mensual | rf_annual | Notas |
|-----------|-------|----------------:|---------------:|----------:|-------|
| **B — DEFAULT de clase** | 2020-01-01 | 1000 | **500** | 0.05 | Horizonte más corto; bueno para clase |
| A — horizonte largo | 2013-01-01 | 1000 | **200** | 0.05 | Default histórico anterior |

Para pasar al escenario A: en el bloque CONFIG de `ahorrarvsinvertir.R`, comenta las líneas de B y descomenta las de A (están documentadas arriba del CONFIG).

### Salidas

- `output/comparar_estatico.png` — figura de dos paneles
- `output/comparar_animado.gif` — animación RF vs core
- `output/metricas.csv` — tabla de métricas
- `data/adj_close.rds` — cache de precios (&lt; 24 h se reutiliza)

---

## La pregunta (en una frase)

Si cada mes aportas lo mismo, ¿qué pasa si ese dinero se queda en una cuenta “segura” al 5 % USD versus si se invierte en el core long-only de ETFs?

## Parámetros [DEFAULT de clase = 2020 / $500]

| Parámetro | Valor |
|-----------|------:|
| `start` | **2020-01-01** |
| `end` | fecha de corrida (`Sys.Date()`) |
| **`aporte_mensual`** | **500 USD** |
| `capital_inicial` | 1000 USD |
| **`rf_annual`** | **5 % constante** (sin curva de tasas) |
| Capitalización RF | diaria por días calendario, factor `(1 + 0.05)^(días/365.25)` |
| Costos | **0 bps** (claridad educativa; sin comisiones, TER, impuestos ni FX) |
| Día de aporte | primer día hábil de cada mes (mismo calendario para RF y equity) |
| Rebalance equity | mensual en el día de aporte, a pesos objetivo |

### Pesos del core

| Ticker (Yahoo) | Peso |
|----------------|-----:|
| SPYG | 0.31 |
| SMH | 0.22 |
| BRK-B (BRK.B) | 0.20 |
| IEMG | 0.20 |
| VTI | 0.07 |

## Cómo leer los gráficos

![Comparar estático](output/comparar_estatico.png)

- **Panel superior — Ahorrar / Renta fija 5 %:** área naranja = valor de la cuenta RF (aportes + interés compuesto).
- **Panel inferior — Invertir / Core RV:** área naranja = capital aportado; área verde = valor de mercado del portafolio; línea punteada = path RF de referencia.
- **GIF** (`output/comparar_animado.gif`): anima el crecimiento de ambas series en el tiempo.

## Dependencias

Ver `REQUIREMENTS.md`. Resumen:

```r
install.packages(c(
  "quantmod","ggplot2","dplyr","tidyr","scales","patchwork","zoo","magick"
), repos = "https://cloud.r-project.org")
```

`ahorrarvsinvertir.R` intenta instalar solo lo que falte la primera vez que lo corres.

## Estructura del repo

| Ruta | Rol |
|------|-----|
| **`ahorrarvsinvertir.R`** | **Script único para clase** (CONFIG + pipeline completo) |
| `README.md` | Este archivo |
| `LICENSE` | MIT |
| `REQUIREMENTS.md` | Dependencias R / sistema |
| `output/` | PNG, GIF, CSV generados |
| `data/` | Cache local de precios (no versionado) |
| `legacy/` | Scripts modulares antiguos (`config.R`, `main.R`, `01_*.R` …) |

## Limitaciones

- RF al 5 % **constante**; no usa Treasuries reales ni inflación.
- Costos = 0: en la vida real hay TER, spreads y posibles impuestos.
- Un solo camino histórico: el periodo puede ser en general alcista para acciones US/tech.
- El “CAGR sobre aportado” no es TWR; no sirve para comparar gestores.
- Sin FX: todo en USD.
- Precios Adjusted Close (dividendos reinvertidos en el ajuste de Yahoo).

## Licencia

MIT © Andrés Alejandro Rodríguez Lozano
