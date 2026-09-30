# =============================================================================
# run_scenario_2020_500.R — Scenario B (sin modificar los defaults de main.R)
# =============================================================================
# Ejecutar desde cualquier directorio:
#   Rscript legacy/run_scenario_2020_500.R
#
# El runner conserva la configuracion 2013/$200 de main.R, reutiliza el cache
# completo de data/ cuando esta disponible y filtra el panel al horizonte pedido.

args_cmd <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_cmd, value = TRUE)
if (length(file_arg) > 0) {
  ROOT_DIR <- dirname(normalizePath(sub("^--file=", "", file_arg[1])))
  # Si corremos desde legacy/, subir un nivel a la raiz del proyecto
  if (basename(ROOT_DIR) == "legacy") ROOT_DIR <- dirname(ROOT_DIR)
} else {
  ROOT_DIR <- normalizePath(".", winslash = "/")
}
setwd(ROOT_DIR)

message("=== Ahorrar vs Invertir — Scenario B ===")
message("ROOT_DIR = ", ROOT_DIR)

source("legacy/config.R", local = FALSE)
START_DATE      <- as.Date("2020-01-01")
END_DATE        <- Sys.Date()
CAPITAL_INICIAL <- 1000
APORTE_MENSUAL  <- 500
RF_ANNUAL       <- 0.05
COST_BPS        <- 0
OUTPUT_DIR      <- file.path(ROOT_DIR, "output", "scenario_2020_500")
dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)

if (file.exists(CACHE_FILE)) {
  message("[scenario] Usando cache existente: ", CACHE_FILE)
  precios <- readRDS(CACHE_FILE)
} else {
  source("legacy/01_data.R", local = FALSE)
}

stopifnot(all(TICKERS %in% colnames(precios)))
precios <- precios[precios$date >= START_DATE & precios$date <= END_DATE, , drop = FALSE]
if (nrow(precios) < 100) {
  stop("El cache no contiene suficientes precios para el horizonte Scenario B.")
}
message("[scenario] Panel filtrado: ", min(precios$date), " -> ", max(precios$date), " (", nrow(precios), " filas)")
source("legacy/02_simulate.R", local = FALSE)
source("legacy/03_plots.R", local = FALSE)
source("legacy/04_gif.R", local = FALSE)

message("")
message("=== Scenario B listo ===")
message("PNG : ", file.path(OUTPUT_DIR, "comparar_estatico.png"))
message("GIF : ", file.path(OUTPUT_DIR, "comparar_animado.gif"))
message("CSV : ", file.path(OUTPUT_DIR, "metricas.csv"))
