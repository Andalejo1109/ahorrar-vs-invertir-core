# =============================================================================
# 01_data.R - Descarga de precios ajustados (Yahoo Finance via quantmod)
# Cache local en data/adj_close.rds (valido CACHE_MAX_HOURS horas)
# =============================================================================

suppressPackageStartupMessages({
  library(quantmod)
  library(dplyr)
  library(tidyr)
  library(zoo)
})

cache_es_fresco <- function(path, max_hours) {
  if (!file.exists(path)) return(FALSE)
  age_h <- as.numeric(difftime(Sys.time(), file.info(path)$mtime, units = "hours"))
  age_h < max_hours
}

descargar_ticker <- function(ticker, from, to, intentos = 3) {
  for (i in seq_len(intentos)) {
    res <- tryCatch({
      getSymbols(
        ticker,
        src     = "yahoo",
        from    = from,
        to      = to,
        auto.assign = FALSE,
        warnings = FALSE
      )
    }, error = function(e) {
      message("  Intento ", i, " fallo para ", ticker, ": ", conditionMessage(e))
      Sys.sleep(2 * i)
      NULL
    })
    if (!is.null(res) && NROW(res) > 0) {
      adj <- Ad(res)
      colnames(adj) <- ticker
      return(adj)
    }
  }
  stop("No se pudo descargar ", ticker, " tras ", intentos, " intentos.")
}

cargar_precios <- function() {
  if (cache_es_fresco(CACHE_FILE, CACHE_MAX_HOURS)) {
    message("[01_data] Usando cache: ", CACHE_FILE)
    precios <- readRDS(CACHE_FILE)
    return(precios)
  }

  message("[01_data] Descargando precios Adjusted Close de Yahoo Finance...")
  message("  Tickers: ", paste(TICKERS, collapse = ", "))
  message("  Rango: ", START_DATE, " -> ", END_DATE)

  lista <- lapply(TICKERS, function(tk) {
    message("  -> ", tk)
    descargar_ticker(tk, START_DATE, END_DATE)
  })
  names(lista) <- TICKERS

  panel_xts <- do.call(merge, lista)
  panel_xts <- na.omit(panel_xts)

  precios <- data.frame(
    date = as.Date(index(panel_xts)),
    coredata(panel_xts),
    check.names = FALSE
  )
  colnames(precios) <- c("date", TICKERS)

  saveRDS(precios, CACHE_FILE)
  message("[01_data] Guardado cache: ", CACHE_FILE,
          " (", nrow(precios), " dias habiles, ",
          min(precios$date), " -> ", max(precios$date), ")")
  precios
}

precios <- cargar_precios()

stopifnot(all(TICKERS %in% colnames(precios)))
stopifnot(nrow(precios) > 100)
message("[01_data] OK - ", nrow(precios), " filas, columnas: ",
        paste(colnames(precios), collapse = ", "))
