# =============================================================================
# 04_gif.R - GIF animado del crecimiento RF vs Core
# Preferimos magick (frame-a-frame); gganimate+gifski si estan disponibles.
# =============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(grid)
})

out_gif <- file.path(OUTPUT_DIR, "comparar_animado.gif")

n_frames <- 80
idx <- unique(round(seq(1, nrow(sim), length.out = n_frames)))
message("[04_gif] Preparando animacion (", length(idx), " frames)...")

ymax_global <- max(sim$valor_equity, na.rm = TRUE) * 1.05
xlims <- range(sim$date)

hacer_frame <- function(hasta_i) {
  d <- sim[1:hasta_i, ]
  last <- d[nrow(d), ]
  ggplot(d, aes(x = date)) +
    geom_area(aes(y = valor_rf), fill = COLOR_SOFT_ORANGE, alpha = 0.75) +
    geom_line(aes(y = valor_rf), color = COLOR_ORANGE_LINE, linewidth = 0.9) +
    geom_area(aes(y = valor_equity), fill = COLOR_DARK_GREEN, alpha = 0.55) +
    geom_line(aes(y = valor_equity), color = COLOR_EQUITY_LINE, linewidth = 0.7) +
    annotate(
      "label",
      x = xlims[1] + 120,
      y = ymax_global * 0.90,
      label = paste0(
        format(last$date, "%Y-%m"),
        "\nRF 5%: $", format(round(last$valor_rf), big.mark = ",", scientific = FALSE),
        "\nCore:  $", format(round(last$valor_equity), big.mark = ",", scientific = FALSE)
      ),
      hjust = 0, size = 3.3, fill = "white", color = COLOR_TEXT,
      label.padding = unit(0.3, "lines")
    ) +
    scale_y_continuous(
      limits = c(0, ymax_global),
      labels = label_dollar(accuracy = 1),
      expand = expansion(mult = c(0, 0.02))
    ) +
    scale_x_date(limits = xlims, expand = expansion(mult = c(0.01, 0.02))) +
    labs(
      title = "Ahorrar (RF 5%) vs Invertir (Core RV)",
      subtitle = paste0(
        "Aportes $", CAPITAL_INICIAL, " + $", APORTE_MENSUAL,
        "/mes · Area naranja = RF · Area verde = core equity"
      ),
      x = NULL, y = "USD",
      caption = "@Andalejo1109 · No es consejo de inversion"
    ) +
    theme_minimal(base_size = 11) +
    theme(
      plot.background  = element_rect(fill = COLOR_BG, color = NA),
      panel.background = element_rect(fill = COLOR_BG, color = NA),
      panel.grid.minor = element_blank(),
      plot.title       = element_text(face = "bold", color = COLOR_TEXT),
      plot.subtitle    = element_text(color = "#666666", size = 9),
      plot.caption     = element_text(color = "#888888", size = 8)
    )
}

tmpdir <- file.path(tempdir(), "ahorrar_gif_frames")
dir.create(tmpdir, showWarnings = FALSE, recursive = TRUE)
old_frames <- list.files(tmpdir, full.names = TRUE)
if (length(old_frames)) unlink(old_frames)

for (i in seq_along(idx)) {
  p <- hacer_frame(idx[i])
  fpath <- file.path(tmpdir, sprintf("frame_%03d.png", i))
  ggsave(fpath, p, width = 9, height = 5.5, dpi = 100, bg = COLOR_BG)
  if (i %% 20 == 0 || i == length(idx)) message("  frame ", i, "/", length(idx))
}

frame_files <- sort(list.files(tmpdir, full.names = TRUE, pattern = "\\.png$"))
stopifnot(length(frame_files) > 0)

if (requireNamespace("magick", quietly = TRUE)) {
  suppressPackageStartupMessages(library(magick))
  imgs <- image_read(frame_files)
  imgs <- image_scale(imgs, "900x")
  anim <- image_animate(imgs, fps = 10, loop = 0, dispose = "previous")
  image_write(anim, out_gif)
  message("[04_gif] Guardado (magick): ", out_gif)
} else if (nzchar(Sys.which("convert"))) {
  cmd <- sprintf(
    'convert -delay 10 -loop 0 %s "%s"',
    paste(shQuote(frame_files), collapse = " "),
    out_gif
  )
  stopifnot(system(cmd) == 0)
  message("[04_gif] Guardado (ImageMagick CLI): ", out_gif)
} else {
  stop("Ni magick ni convert disponibles para escribir el GIF.")
}

stopifnot(file.exists(out_gif))
message("[04_gif] OK - tamano: ", round(file.info(out_gif)$size / 1e6, 2), " MB")
