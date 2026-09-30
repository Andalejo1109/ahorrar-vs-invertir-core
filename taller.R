# =============================================================================
# taller.R — Ahorrar vs Invertir (core renta variable)
# =============================================================================
# Material de clase (data analytics). Un solo archivo: abre y corre.
#
# Uso:  Rscript taller.R   (o Source en RStudio)
# Solo cambia el bloque CONFIG abajo.
#
# Escenarios de ejemplo:
#   A) 2013 / aporte 200  — horizonte largo
#   B) 2020 / aporte 500  — DEFAULT de clase (activo abajo)
#
# Autor: Andres Alejandro Rodriguez Lozano (@Andalejo1109)
# Disclaimer: NO es consejo de inversion. Solo material educativo.
# =============================================================================

# =============================================================================
# >>> CONFIG <<<  <-- cambia SOLO este bloque
# =============================================================================
# Escenario A (2013/$200) — descomenta y comenta las de B:
#   start <- as.Date("2013-01-01"); capital_inicial <- 1000
#   aporte_mensual <- 200; rf_annual <- 0.05
#
# Escenario B (2020/$500) — DEFAULT de clase:

start           <- as.Date("2020-01-01")
end             <- Sys.Date()
capital_inicial <- 1000
aporte_mensual  <- 500
rf_annual       <- 0.05
cost_bps        <- 0

weights <- c(SPYG=0.31, SMH=0.22, `BRK-B`=0.20, IEMG=0.20, VTI=0.07)
tickers <- names(weights)

color_soft_orange <- "#F4A261"
color_orange_line <- "#E76F51"
color_dark_green  <- "#2E7D32"
color_equity_line <- "#1B5E20"
color_bg          <- "#F5F5F5"
color_text        <- "#333333"
# =============================================================================
# >>> FIN CONFIG <<<
# =============================================================================

# --- 0) Rutas ---
args_cmd <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_cmd, value = TRUE)
root_dir <- if (length(file_arg) > 0) {
  dirname(normalizePath(sub("^--file=", "", file_arg[1])))
} else normalizePath(".", winslash = "/")
setwd(root_dir)
data_dir   <- file.path(root_dir, "data")
output_dir <- file.path(root_dir, "output")
cache_file <- file.path(data_dir, "adj_close.rds")
cache_max_hours <- 24
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
message("=== Ahorrar vs Invertir (taller de clase) ===")
message("ROOT=", root_dir, " start=", start, " end=", end,
        " capital=", capital_inicial, " aporte=", aporte_mensual,
        " rf=", rf_annual, " costos=", cost_bps, " bps")

# --- 1) Paquetes ---
paquetes <- c("quantmod","dplyr","tidyr","zoo","ggplot2","scales","patchwork","magick")
asegurar_paquete <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Instalando: ", pkg)
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  if (!require(pkg, character.only = TRUE, quietly = TRUE))
    stop("No se pudo cargar: ", pkg)
  message("  OK — ", pkg)
}
message("--- Paquetes ---")
invisible(lapply(paquetes, asegurar_paquete))

# --- 2) Datos (Yahoo Adjusted Close + cache) ---
cache_es_fresco <- function(path, max_hours) {
  if (!file.exists(path)) return(FALSE)
  as.numeric(difftime(Sys.time(), file.info(path)$mtime, units = "hours")) < max_hours
}
descargar_ticker <- function(ticker, from, to, intentos = 3) {
  for (i in seq_len(intentos)) {
    res <- tryCatch(
      getSymbols(ticker, src="yahoo", from=from, to=to, auto.assign=FALSE, warnings=FALSE),
      error = function(e) { message("  Intento ", i, " fallo ", ticker, ": ", conditionMessage(e)); Sys.sleep(2*i); NULL }
    )
    if (!is.null(res) && NROW(res) > 0) {
      adj <- Ad(res); colnames(adj) <- ticker; return(adj)
    }
  }
  stop("No se pudo descargar ", ticker)
}
cargar_precios <- function() {
  if (cache_es_fresco(cache_file, cache_max_hours)) {
    message("[datos] Cache: ", cache_file)
    precios <- readRDS(cache_file)
  } else {
    message("[datos] Descargando Yahoo: ", paste(tickers, collapse=", "))
    lista <- lapply(tickers, function(tk) { message("  -> ", tk); descargar_ticker(tk, start, end) })
    names(lista) <- tickers
    panel_xts <- na.omit(do.call(merge, lista))
    precios <- data.frame(date=as.Date(index(panel_xts)), coredata(panel_xts), check.names=FALSE)
    colnames(precios) <- c("date", tickers)
    saveRDS(precios, cache_file)
    message("[datos] Guardado cache (", nrow(precios), " filas)")
  }
  precios <- precios[precios$date >= start & precios$date <= end, , drop=FALSE]
  stopifnot(all(tickers %in% colnames(precios)), nrow(precios) >= 50)
  message("[datos] Panel: ", min(precios$date), " -> ", max(precios$date), " (", nrow(precios), ")")
  precios
}
message("--- Datos ---")
precios <- cargar_precios()

# --- 3) Simulacion RF vs equity ---
fechas_aporte <- function(fechas) {
  df <- data.frame(date = fechas, ym = format(fechas, "%Y-%m"))
  df %>% group_by(ym) %>% summarise(date = min(date), .groups = "drop") %>% pull(date)
}
simular_rf <- function(fechas, capital_inicial, aporte_mensual, rf_annual) {
  n <- length(fechas); aportes_dias <- fechas_aporte(fechas)
  rf_daily_factor <- function(d0, d1) (1 + rf_annual)^(as.numeric(difftime(d1, d0, units="days")) / 365.25)
  valor <- capital_aportado <- numeric(n); saldo <- aportado <- 0
  for (i in seq_len(n)) {
    if (i > 1) saldo <- saldo * rf_daily_factor(fechas[i-1], fechas[i])
    if (fechas[i] %in% aportes_dias) {
      add <- if (aportado == 0) capital_inicial else aporte_mensual
      saldo <- saldo + add; aportado <- aportado + add
    }
    valor[i] <- saldo; capital_aportado[i] <- aportado
  }
  data.frame(date=fechas, capital_aportado=capital_aportado, valor_rf=valor)
}
simular_equity <- function(precios, pesos, capital_inicial, aporte_mensual, cost_bps=0) {
  fechas <- precios$date; tks <- names(pesos); n <- length(fechas)
  px <- as.matrix(precios[, tks, drop=FALSE]); aportes_dias <- fechas_aporte(fechas)
  shares <- setNames(rep(0, length(tks)), tks)
  valor <- capital_aportado <- numeric(n); aportado <- 0; cost_rate <- cost_bps/10000
  for (i in seq_len(n)) {
    p <- px[i, ]
    if (fechas[i] %in% aportes_dias) {
      cash_in <- if (aportado == 0) capital_inicial else aporte_mensual
      aportado <- aportado + cash_in
      mv <- sum(shares * p); total <- mv + cash_in
      target_value <- total * pesos[tks]
      if (cost_rate > 0) {
        fee <- if (mv > 0) sum(abs(target_value - shares * p)) * cost_rate else cash_in * cost_rate
        total <- total - fee; target_value <- total * pesos[tks]
      }
      shares <- target_value / p
    }
    valor[i] <- sum(shares * p); capital_aportado[i] <- aportado
  }
  data.frame(date=fechas, capital_aportado=capital_aportado, valor_equity=valor)
}
message("--- Simulacion ---")
sim_rf <- simular_rf(precios$date, capital_inicial, aporte_mensual, rf_annual)
sim_eq <- simular_equity(precios, weights, capital_inicial, aporte_mensual, cost_bps)
sim <- sim_rf %>% left_join(sim_eq %>% select(date, valor_equity), by="date")

# --- 4) Metricas ---
calcular_metricas <- function(sim_rf, sim_eq) {
  fechas <- sim_rf$date
  years <- as.numeric(difftime(max(fechas), min(fechas), units="days")) / 365.25
  cap <- max(sim_eq$capital_aportado)
  tv_rf <- tail(sim_rf$valor_rf, 1); tv_eq <- tail(sim_eq$valor_equity, 1)
  cagr <- function(tv, contrib, y) if (contrib<=0 || y<=0) NA_real_ else (tv/contrib)^(1/y)-1
  eq <- sim_eq$valor_equity; max_dd <- min((eq - cummax(eq)) / cummax(eq), na.rm=TRUE)
  data.frame(
    metrica = c("fecha_inicio","fecha_fin","anios","capital_aportado","tv_renta_fija","tv_core_equity",
                "ratio_equity_rf","multiplo_rf","multiplo_equity",
                "cagr_aprox_rf_sobre_aportado","cagr_aprox_equity_sobre_aportado","max_drawdown_equity",
                "aporte_mensual","capital_inicial","rf_annual","cost_bps"),
    valor = c(as.character(min(fechas)), as.character(max(fechas)), sprintf("%.2f", years),
              sprintf("%.2f", cap), sprintf("%.2f", tv_rf), sprintf("%.2f", tv_eq),
              sprintf("%.3f", tv_eq/tv_rf), sprintf("%.3f", tv_rf/cap), sprintf("%.3f", tv_eq/cap),
              sprintf("%.4f", cagr(tv_rf,cap,years)), sprintf("%.4f", cagr(tv_eq,cap,years)),
              sprintf("%.4f", max_dd), as.character(aporte_mensual), as.character(capital_inicial),
              as.character(rf_annual), as.character(cost_bps)),
    stringsAsFactors = FALSE
  )
}
metricas <- calcular_metricas(sim_rf, sim_eq)
write.csv(metricas, file.path(output_dir, "metricas.csv"), row.names=FALSE)
message("--- Metricas ---"); print(metricas, row.names=FALSE)

# --- 5) PNG dos paneles ---
burbuja <- function(label, x, y, fill="white") {
  list(annotate("label", x=x, y=y, label=label, fill=fill, color=color_text,
                fontface="bold", size=3.8, label.padding=unit(0.35,"lines"),
                label.r=unit(0.25,"lines"), label.size=0.3))
}
tema_base <- theme_minimal(base_size=12) +
  theme(plot.background=element_rect(fill=color_bg, color=NA),
        panel.background=element_rect(fill=color_bg, color=NA),
        panel.grid.minor=element_blank(),
        panel.grid.major=element_line(color="#E0E0E0", linewidth=0.3),
        axis.title=element_text(color=color_text), axis.text=element_text(color=color_text),
        plot.title=element_text(face="bold", color=color_text, size=14),
        plot.subtitle=element_text(color="#666666", size=10),
        plot.caption=element_text(color="#888888", size=8, hjust=0),
        plot.margin=margin(10,16,10,12))
hacer_panel_rf <- function(sim) {
  xmax <- max(sim$date); ymax <- max(sim$valor_rf)
  ggplot(sim, aes(x=date)) +
    geom_area(aes(y=valor_rf), fill=color_soft_orange, alpha=0.85) +
    geom_line(aes(y=valor_rf), color=color_orange_line, linewidth=0.7) +
    burbuja("Ahorrar\nRenta fija 5%", xmax-200, ymax*0.55, fill="#FFF3E8") +
    scale_y_continuous(labels=label_dollar(accuracy=1), expand=expansion(mult=c(0,0.08))) +
    scale_x_date(expand=expansion(mult=c(0.01,0.02))) +
    labs(title="Ahorrar vs Invertir — core renta variable",
         subtitle=paste0("Aportes: $", capital_inicial, " + $", aporte_mensual,
                         "/mes · RF ", rf_annual*100, "% · costos=", cost_bps, " bps"),
         x=NULL, y="USD") + tema_base
}
hacer_panel_eq <- function(sim) {
  xmax <- max(sim$date); ymax <- max(sim$valor_equity, na.rm=TRUE)
  ggplot(sim, aes(x=date)) +
    geom_area(aes(y=capital_aportado), fill=color_soft_orange, alpha=0.55) +
    geom_area(aes(y=valor_equity), fill=color_dark_green, alpha=0.75) +
    geom_line(aes(y=valor_equity), color=color_equity_line, linewidth=0.5) +
    geom_line(aes(y=valor_rf), color=color_orange_line, linewidth=0.8, linetype="dashed") +
    burbuja("Invertir\nCore RV", xmax-200, ymax*0.55, fill="#E8F5E9") +
    scale_y_continuous(labels=label_dollar(accuracy=1), expand=expansion(mult=c(0,0.08))) +
    scale_x_date(expand=expansion(mult=c(0.01,0.02))) +
    labs(x=NULL, y="USD",
         caption=paste0("Naranja=aportes/RF · Verde=core · Punteada=RF · ",
                        "Pesos SPYG/SMH/BRK.B/IEMG/VTI · Yahoo Adj Close · No es consejo.\n",
                        "@Andalejo1109 · andalejo1109.github.io · eToro @Andalejo1109")) + tema_base
}
message("--- Grafico estatico ---")
fig <- hacer_panel_rf(sim) / hacer_panel_eq(sim) + plot_layout(heights=c(1,1.15))
out_png <- file.path(output_dir, "comparar_estatico.png")
ggsave(out_png, fig, width=11, height=9, dpi=150, bg=color_bg)
message("[plot] ", out_png)

# --- 6) GIF ---
message("--- GIF ---")
out_gif <- file.path(output_dir, "comparar_animado.gif")
n_frames <- 60
idx <- unique(round(seq(1, nrow(sim), length.out=n_frames)))
ymax_global <- max(sim$valor_equity, na.rm=TRUE)*1.05
xlims <- range(sim$date)
hacer_frame <- function(hasta_i) {
  d <- sim[1:hasta_i, ]; last <- d[nrow(d), ]
  ggplot(d, aes(x=date)) +
    geom_area(aes(y=valor_rf), fill=color_soft_orange, alpha=0.75) +
    geom_line(aes(y=valor_rf), color=color_orange_line, linewidth=0.9) +
    geom_area(aes(y=valor_equity), fill=color_dark_green, alpha=0.55) +
    geom_line(aes(y=valor_equity), color=color_equity_line, linewidth=0.7) +
    annotate("label", x=xlims[1]+60, y=ymax_global*0.90,
             label=paste0(format(last$date,"%Y-%m"),
                          "\nRF:   $", format(round(last$valor_rf), big.mark=",", scientific=FALSE),
                          "\nCore: $", format(round(last$valor_equity), big.mark=",", scientific=FALSE)),
             hjust=0, size=3.3, fill="white", color=color_text, label.padding=unit(0.3,"lines")) +
    scale_y_continuous(limits=c(0,ymax_global), labels=label_dollar(accuracy=1), expand=expansion(mult=c(0,0.02))) +
    scale_x_date(limits=xlims, expand=expansion(mult=c(0.01,0.02))) +
    labs(title="Ahorrar (RF) vs Invertir (Core RV)",
         subtitle=paste0("Aportes $", capital_inicial, " + $", aporte_mensual, "/mes"),
         x=NULL, y="USD", caption="@Andalejo1109 · No es consejo de inversion") +
    theme_minimal(base_size=11) +
    theme(plot.background=element_rect(fill=color_bg, color=NA),
          panel.background=element_rect(fill=color_bg, color=NA),
          panel.grid.minor=element_blank(),
          plot.title=element_text(face="bold", color=color_text),
          plot.subtitle=element_text(color="#666666", size=9),
          plot.caption=element_text(color="#888888", size=8))
}
tmpdir <- file.path(tempdir(), "ahorrar_gif_frames")
dir.create(tmpdir, showWarnings=FALSE, recursive=TRUE)
unlink(list.files(tmpdir, full.names=TRUE))
for (i in seq_along(idx)) {
  ggsave(file.path(tmpdir, sprintf("frame_%03d.png", i)), hacer_frame(idx[i]),
         width=9, height=5.5, dpi=100, bg=color_bg)
  if (i %% 20 == 0 || i == length(idx)) message("  frame ", i, "/", length(idx))
}
frame_files <- sort(list.files(tmpdir, full.names=TRUE, pattern="\\.png$"))
stopifnot(length(frame_files) > 0)
if (requireNamespace("magick", quietly=TRUE)) {
  imgs <- image_scale(image_read(frame_files), "900x")
  image_write(image_animate(imgs, fps=10, loop=0, dispose="previous"), out_gif)
} else if (nzchar(Sys.which("convert"))) {
  stopifnot(system(sprintf('convert -delay 10 -loop 0 %s "%s"',
                           paste(shQuote(frame_files), collapse=" "), out_gif)) == 0)
} else stop("Ni magick ni convert disponibles.")
message("[gif] ", out_gif, " (", round(file.info(out_gif)$size/1e6, 2), " MB)")

message("=== Listo ===")
message("PNG: ", out_png)
message("GIF: ", out_gif)
message("CSV: ", file.path(output_dir, "metricas.csv"))
message("Tip: cambia solo CONFIG. A=2013/200 · B(default)=2020/500")
