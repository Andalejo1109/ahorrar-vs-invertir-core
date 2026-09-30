# =============================================================================
# config.R — Parametros por defecto [DEFAULT]
# Simulacion educativa: Ahorrar (RF 5%) vs Invertir (core renta variable)
# Autor: Andres Alejandro Rodriguez Lozano (@Andalejo1109)
# =============================================================================

# Rutas del proyecto
ROOT_DIR   <- if (exists("ROOT_DIR")) ROOT_DIR else normalizePath(".", winslash = "/")
DATA_DIR   <- file.path(ROOT_DIR, "data")
OUTPUT_DIR <- file.path(ROOT_DIR, "output")

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)

# Horizonte
START_DATE <- as.Date("2013-01-01")
END_DATE   <- Sys.Date()

# Capital y aportes (mismos para ambas estrategias)
CAPITAL_INICIAL <- 1000   # USD
APORTE_MENSUAL  <- 200    # USD

# Renta fija constante (sin curva de tasas)
RF_ANNUAL <- 0.05         # 5% anual
# Capitalizacion: mensual (equivalente continuo/mensual documentado en README)
# rf_monthly = (1 + rf_annual)^(1/12) - 1

# Costos: 0 para claridad de la historia "ahorrar vs invertir"
# (sin comisiones, sin TER, sin impuestos, sin FX)
COST_BPS <- 0

# Pesos del core (suma = 1). Yahoo usa BRK-B para BRK.B
PESOS <- c(
  SPYG   = 0.31,
  SMH    = 0.22,
  `BRK-B` = 0.20,
  IEMG   = 0.20,
  VTI    = 0.07
)

TICKERS <- names(PESOS)

# Cache de precios
CACHE_FILE <- file.path(DATA_DIR, "adj_close.rds")
CACHE_MAX_HOURS <- 24

# Estilo visual
# Naranja suave = ahorrar / renta fija / aportes; verde oscuro = equity
COLOR_SOFT_ORANGE <- "#F4A261"   # fill RF y baseline de aportes
COLOR_ORANGE_LINE <- "#E76F51"   # linea RF / dashed ahorro
COLOR_DARK_GREEN  <- "#2E7D32"   # fill equity
COLOR_EQUITY_LINE <- "#1B5E20"   # linea equity
COLOR_BG          <- "#F5F5F5"
COLOR_TEXT        <- "#333333"
# Alias por compatibilidad con scripts antiguos
COLOR_LIGHT_GREEN <- COLOR_SOFT_ORANGE

message("[config] start=", START_DATE, " end=", END_DATE,
        " aporte=", APORTE_MENSUAL, " rf=", RF_ANNUAL,
        " costos=", COST_BPS, " bps")
