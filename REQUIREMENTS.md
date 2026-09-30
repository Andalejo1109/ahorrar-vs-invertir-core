# Dependencias R

Instalar en R (una vez):

```r
install.packages(c(
  "quantmod",
  "ggplot2", "dplyr", "tidyr", "scales", "patchwork", "zoo",
  "gganimate", "gifski",
  "magick"
), repos = "https://cloud.r-project.org")
```

En Debian/Ubuntu:

```bash
sudo apt-get install -y r-base r-base-dev \
  libcurl4-openssl-dev libssl-dev libxml2-dev \
  libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
  libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
  libmagick++-dev
```

Version de R recomendada: >= 4.3.
