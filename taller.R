# =============================================================================
# taller.R — Ahorrar vs Invertir (core renta variable)
# =============================================================================
# Material de clase (data analytics). Un solo archivo: abre y corre.
#
# Uso:
#   Rscript taller.R
#   # o abre en RStudio / R y Source
#
# Solo cambia el bloque CONFIG abajo. No hace falta tocar el resto.
#
# Escenarios de ejemplo (comentados en CONFIG):
#   A) 2013 / aporte 200  — horizonte largo (default anterior)
#   B) 2020 / aporte 500  — DEFAULT de clase (mas corto, aportes mayores)
#
# Autor: Andres Alejandro Rodriguez Lozano (@Andalejo1109)
# Disclaimer: NO es consejo de inversion. Solo material educativo.
# =============================================================================


# =============================================================================
# >>> CONFIG <<<  <-- cambia SOLO este bloque
# =============================================================================
#
# Escenario A (2013 / $200) — descomenta estas 4 lineas y comenta las de B:
#   start           <- as.Date("2013-01-01")
#   capital_inicial <- 1000
#   aporte_mensual  <- 200
#   rf_annual       <- 0.05
#
# Escenario B (2020 / $500) — DEFAULT de clase (activo abajo):
#   start 2020-01-01, capital 1000, aporte 500, rf 5%

start           <- as.Date("2020-01-01")   # inicio del horizonte
end             <- Sys.Date()             # fin = hoy (o fija una fecha)
capital_inicial <- 1000                   # USD al primer dia de aporte
aporte_mensual  <- 500                    # USD cada mes (mismo para RF y equity)
rf_annual       <- 0.05                   # renta fija constante 5% anual
cost_bps        <- 0                      # costos en basis points (0 = claridad)

# Pesos del core (deben sumar 1). Yahoo usa BRK-B para Berkshire B.
weights <- c(
  SPYG    = 0.31,
  SMH     = 0.22,
  `BRK-B` = 0.20,
  IEMG    = 0.20,
  VTI     = 0.07
)
tickers <- names(weights)

# Colores (naranja = ahorrar / RF ; verde = invertir / equity)
color_soft_orange <- "#F4A261"
color_orange_line <- "#E76F51"
color_dark_green  <- "#2E7D32"
color_equity_line <- "#1B5E20"
color_bg          <- "#F5F5F5"
color_text        <- "#333333"

# Carpetas de salida y cache (relativas a este script)
# =============================================================================
# >>> FIN CONFIG <<<
# =============================================================================
