# =============================================================================
# 03_plots.R - Figura estatica de dos paneles (estilo "Ahorrar vs Invertir")
# Top: RF 5% suave | Bottom: equity con volatilidad + baseline aportes
# =============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(patchwork)
  library(grid)
})

burbuja <- function(label, x, y, fill = "white") {
  list(
    annotate(
      "label",
      x = x, y = y,
      label = label,
      fill = fill,
      color = COLOR_TEXT,
      fontface = "bold",
      size = 3.8,
      label.padding = unit(0.35, "lines"),
      label.r = unit(0.25, "lines"),
      label.size = 0.3
    )
  )
}

tema_base <- theme_minimal(base_size = 12) +
  theme(
    plot.background  = element_rect(fill = COLOR_BG, color = NA),
    panel.background = element_rect(fill = COLOR_BG, color = NA),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#E0E0E0", linewidth = 0.3),
    axis.title       = element_text(color = COLOR_TEXT),
    axis.text        = element_text(color = COLOR_TEXT),
    plot.title       = element_text(face = "bold", color = COLOR_TEXT, size = 14),
    plot.subtitle    = element_text(color = "#666666", size = 10),
    plot.caption     = element_text(color = "#888888", size = 8, hjust = 0),
    plot.margin      = margin(10, 16, 10, 12)
  )

hacer_panel_rf <- function(sim) {
  xmax <- max(sim$date)
  ymax <- max(sim$valor_rf)
  ggplot(sim, aes(x = date)) +
    geom_area(aes(y = valor_rf), fill = COLOR_LIGHT_GREEN, alpha = 0.85) +
    geom_line(aes(y = valor_rf), color = COLOR_DARK_GREEN, linewidth = 0.6) +
    burbuja("Ahorrar\nRenta fija 5%", xmax - 400, ymax * 0.55) +
    scale_y_continuous(labels = label_dollar(accuracy = 1), expand = expansion(mult = c(0, 0.08))) +
    scale_x_date(expand = expansion(mult = c(0.01, 0.02))) +
    labs(
      title = "Ahorrar vs Invertir - core renta variable",
      subtitle = paste0(
        "Aportes: $", CAPITAL_INICIAL, " inicial + $", APORTE_MENSUAL,
        "/mes | RF constante ", RF_ANNUAL * 100, "% anual | costos = ", COST_BPS, " bps"
      ),
      x = NULL, y = "USD"
    ) +
    tema_base
}

hacer_panel_eq <- function(sim) {
  xmax <- max(sim$date)
  ymax <- max(sim$valor_equity, na.rm = TRUE)
  ggplot(sim, aes(x = date)) +
    geom_area(aes(y = capital_aportado), fill = COLOR_LIGHT_GREEN, alpha = 0.55) +
    geom_area(aes(y = valor_equity), fill = COLOR_DARK_GREEN, alpha = 0.75) +
    geom_line(aes(y = valor_equity), color = "#1B5E20", linewidth = 0.5) +
    geom_line(aes(y = valor_rf), color = "#66BB6A", linewidth = 0.7, linetype = "dashed") +
    burbuja("Invertir\nCore RV", xmax - 400, ymax * 0.55, fill = "#E8F5E9") +
    scale_y_continuous(labels = label_dollar(accuracy = 1), expand = expansion(mult = c(0, 0.08))) +
    scale_x_date(expand = expansion(mult = c(0.01, 0.02))) +
    labs(
      x = NULL, y = "USD",
      caption = paste0(
        "Area clara = capital aportado | Area oscura = valor de mercado del core | ",
        "Linea punteada = path RF 5% | ",
        "Pesos: SPYG 31%, SMH 22%, BRK.B 20%, IEMG 20%, VTI 7% | ",
        "Precios Adjusted Close Yahoo | No es consejo de inversion.\n",
        "Andres Alejandro Rodriguez Lozano | @Andalejo1109 | andalejo1109.github.io | eToro @Andalejo1109"
      )
    ) +
    tema_base
}

message("[03_plots] Generando figura estatica de dos paneles...")

p_top <- hacer_panel_rf(sim)
p_bot <- hacer_panel_eq(sim)
fig <- p_top / p_bot + plot_layout(heights = c(1, 1.15))

out_png <- file.path(OUTPUT_DIR, "comparar_estatico.png")
ggsave(out_png, fig, width = 11, height = 9, dpi = 150, bg = COLOR_BG)
message("[03_plots] Guardado: ", out_png)
