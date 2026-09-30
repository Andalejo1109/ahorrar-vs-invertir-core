# =============================================================================
# main.R — Orquestador: config -> data -> simulate -> plots -> gif
# Uso (desde la raiz del proyecto):
#   Rscript main.R
# =============================================================================

args_cmd <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_cmd, value = TRUE)
if (length(file_arg) > 0) {
  ROOT_DIR <- dirname(normalizePath(sub("^--file=", "", file_arg[1])))
} else {
  ROOT_DIR <- normalizePath(".", winslash = "/")
}
setwd(ROOT_DIR)
message("=== Ahorrar vs Invertir (Core) ===")
message("ROOT_DIR = ", ROOT_DIR)
message("Fecha de corrida: ", Sys.Date())

source("config.R", local = FALSE)
source("01_data.R", local = FALSE)
source("02_simulate.R", local = FALSE)
source("03_plots.R", local = FALSE)
source("04_gif.R", local = FALSE)

message("")
message("=== Listo ===")
message("PNG : ", file.path(OUTPUT_DIR, "comparar_estatico.png"))
message("GIF : ", file.path(OUTPUT_DIR, "comparar_animado.gif"))
message("CSV : ", file.path(OUTPUT_DIR, "metricas.csv"))
