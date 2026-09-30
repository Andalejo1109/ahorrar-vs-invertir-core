# =============================================================================
# config.R - Parametros por defecto [DEFAULT]
# Simulacion educativa: Ahorrar (RF 5%) vs Invertir (core renta variable)
# Autor: Andres Alejandro Rodriguez Lozano (@Andalejo1109)
# =============================================================================

ROOT_DIR   <- if (exists("ROOT_DIR")) ROOT_DIR else normalizePath(".", winslash = "/")
DATA_DIR   <- file.path(ROOT_DIR, "data")
OUTPUT_DIR <- file.path(ROOT_DIR, "output")

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)

START_DATE <- as.Date("2013-01-01")
END_DATE   <- Sys.Date()

CAPITAL_INICIAL <- 1000   # USD
APORTE_MENSUAL  <- 200    # USD

RF_ANNUAL <- 0.05         # 5% anual
COST_BPS <- 0

PESOS <- c(
  SPYG   = 0.31,
  SMH    = 0.22,
  `BRK-B` = 0.20,
  IEMG   = 0.20,
  VTI    = 0.07
)

TICKERS <- names(PESOS)

CACHE_FILE <- file.path(DATA_DIR, "adj_close.rds")
CACHE_MAX_HOURS <- 24

COLOR_LIGHT_GREEN <- "#A8D5A2"
COLOR_DARK_GREEN  <- "#2E7D32"
COLOR_BG          <- "#F5F5F5"
COLOR_TEXT        <- "#333333"

message("[config] start=", START_DATE, " end=", END_DATE,
        " aporte=", APORTE_MENSUAL, " rf=", RF_ANNUAL,
        " costos=", COST_BPS, " bps")
