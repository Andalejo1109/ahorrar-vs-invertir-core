# =============================================================================
# 02_simulate.R - Simulacion RF 5% + Core renta variable (DCA + rebalance mensual)
# Costos = 0 (claridad educativa). Mismos dias de aporte para ambas estrategias.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(zoo)
})

rf_mensual <- function(rf_annual) {
  (1 + rf_annual)^(1 / 12) - 1
}

fechas_aporte <- function(fechas) {
  df <- data.frame(date = fechas)
  df$ym <- format(df$date, "%Y-%m")
  df %>%
    group_by(ym) %>%
    summarise(date = min(date), .groups = "drop") %>%
    pull(date)
}

simular_rf <- function(fechas, capital_inicial, aporte_mensual, rf_annual) {
  n <- length(fechas)
  aportes_dias <- fechas_aporte(fechas)
  rf_daily_factor <- function(d0, d1) {
    days <- as.numeric(difftime(d1, d0, units = "days"))
    (1 + rf_annual)^(days / 365.25)
  }
  valor <- numeric(n)
  capital_aportado <- numeric(n)
  saldo <- 0
  aportado <- 0
  for (i in seq_len(n)) {
    if (i > 1) {
      saldo <- saldo * rf_daily_factor(fechas[i - 1], fechas[i])
    }
    if (fechas[i] %in% aportes_dias) {
      if (aportado == 0) {
        saldo <- saldo + capital_inicial
        aportado <- aportado + capital_inicial
      } else {
        saldo <- saldo + aporte_mensual
        aportado <- aportado + aporte_mensual
      }
    }
    valor[i] <- saldo
    capital_aportado[i] <- aportado
  }
  data.frame(date = fechas, capital_aportado = capital_aportado, valor_rf = valor)
}

simular_equity <- function(precios, pesos, capital_inicial, aporte_mensual, cost_bps = 0) {
  fechas <- precios$date
  tickers <- names(pesos)
  n <- length(fechas)
  k <- length(tickers)
  px <- as.matrix(precios[, tickers, drop = FALSE])
  aportes_dias <- fechas_aporte(fechas)
  shares <- rep(0, k)
  names(shares) <- tickers
  valor <- numeric(n)
  capital_aportado <- numeric(n)
  aportado <- 0
  cost_rate <- cost_bps / 10000
  for (i in seq_len(n)) {
    p <- px[i, ]
    if (fechas[i] %in% aportes_dias) {
      cash_in <- if (aportado == 0) capital_inicial else aporte_mensual
      aportado <- aportado + cash_in
      mv <- sum(shares * p)
      total <- mv + cash_in
      target_value <- total * pesos[tickers]
      if (cost_rate > 0 && mv > 0) {
        turnover <- sum(abs(target_value - shares * p))
        fee <- turnover * cost_rate
        total <- total - fee
        target_value <- total * pesos[tickers]
      } else if (cost_rate > 0 && mv == 0) {
        fee <- cash_in * cost_rate
        total <- total - fee
        target_value <- total * pesos[tickers]
      }
      shares <- target_value / p
    }
    valor[i] <- sum(shares * p)
    capital_aportado[i] <- aportado
  }
  data.frame(date = fechas, capital_aportado = capital_aportado, valor_equity = valor)
}

calcular_metricas <- function(sim_rf, sim_eq) {
  stopifnot(identical(sim_rf$date, sim_eq$date))
  fechas <- sim_rf$date
  years <- as.numeric(difftime(max(fechas), min(fechas), units = "days")) / 365.25
  cap <- max(sim_eq$capital_aportado)
  tv_rf <- tail(sim_rf$valor_rf, 1)
  tv_eq <- tail(sim_eq$valor_equity, 1)
  cagr_on_contrib <- function(tv, contrib, y) {
    if (contrib <= 0 || y <= 0) return(NA_real_)
    (tv / contrib)^(1 / y) - 1
  }
  eq <- sim_eq$valor_equity
  peak <- cummax(eq)
  dd <- (eq - peak) / peak
  max_dd <- min(dd, na.rm = TRUE)
  data.frame(
    metrica = c(
      "fecha_inicio", "fecha_fin", "anios", "capital_aportado",
      "tv_renta_fija_5pct", "tv_core_equity", "ratio_equity_rf",
      "multiplo_rf", "multiplo_equity",
      "cagr_aprox_rf_sobre_aportado", "cagr_aprox_equity_sobre_aportado",
      "max_drawdown_equity", "aporte_mensual", "capital_inicial", "rf_annual", "cost_bps"
    ),
    valor = c(
      as.character(min(fechas)), as.character(max(fechas)),
      sprintf("%.2f", years), sprintf("%.2f", cap),
      sprintf("%.2f", tv_rf), sprintf("%.2f", tv_eq),
      sprintf("%.3f", tv_eq / tv_rf),
      sprintf("%.3f", tv_rf / cap), sprintf("%.3f", tv_eq / cap),
      sprintf("%.4f", cagr_on_contrib(tv_rf, cap, years)),
      sprintf("%.4f", cagr_on_contrib(tv_eq, cap, years)),
      sprintf("%.4f", max_dd),
      as.character(APORTE_MENSUAL), as.character(CAPITAL_INICIAL),
      as.character(RF_ANNUAL), as.character(COST_BPS)
    ),
    stringsAsFactors = FALSE
  )
}

message("[02_simulate] Simulando renta fija ", RF_ANNUAL * 100, "% ...")
sim_rf <- simular_rf(
  fechas = precios$date, capital_inicial = CAPITAL_INICIAL,
  aporte_mensual = APORTE_MENSUAL, rf_annual = RF_ANNUAL
)
message("[02_simulate] Simulando core equity (rebalance mensual, costos=", COST_BPS, " bps) ...")
sim_eq <- simular_equity(
  precios = precios, pesos = PESOS, capital_inicial = CAPITAL_INICIAL,
  aporte_mensual = APORTE_MENSUAL, cost_bps = COST_BPS
)
sim <- sim_rf %>% left_join(sim_eq %>% select(date, valor_equity), by = "date")
metricas <- calcular_metricas(sim_rf, sim_eq)
write.csv(metricas, file.path(OUTPUT_DIR, "metricas.csv"), row.names = FALSE)
message("[02_simulate] Metricas:")
print(metricas, row.names = FALSE)
message("[02_simulate] OK - series diarias: ", nrow(sim))
