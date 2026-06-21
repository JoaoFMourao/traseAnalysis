# =============================================================================
# Atribuicao do desmatamento a soja e pasto (gado), por bioma
# Fonte: Trase SEI-PCS Brazil (beef v2.2, soy v2.6)
#
# Metodologia (da documentacao oficial do Trase):
#   - pasture_deforestation(X) = pasto mapeado em X sobre desmatamento [X-4, X]
#     (5 anos, INCLUI X).
#   - soy_deforestation(X)     = soja mapeada em X sobre desmatamento [X-5, X-1]
#     (5 anos com lag de 1, NAO inclui X).
#   - Para a MESMA janela de desmatamento, casa-se pasture(X) com soy(X+1).
#   - Os "5 year totals" NAO podem ser somados entre anos diferentes.
# =============================================================================

# ----- Configuracao -----------------------------------------------------------
# Caminhos OneDrive (Windows). Use barras "/" para evitar problemas de escape.
INPUT_DIR  <- "C:/Users/14647512770/OneDrive - Ministério do Meio Ambiente/DPCD_SECD - General/07_CGIE/04_Cadeias_Verdes/dados/input"
OUTPUT_DIR <- "C:/Users/14647512770/OneDrive - Ministério do Meio Ambiente/DPCD_SECD - General/07_CGIE/04_Cadeias_Verdes/dados/output"

FILE_TERRITORIAL <- "territorial_deforestation_biome.csv"
FILE_PASTURE     <- "pasture_deforestation_5_year_total_biome.csv"
FILE_SOY         <- "soy_deforestation_5_year_total_biome.csv"

# Periodos selecionados para figuras (janela de desmatamento -> X de pasture):
#   2019-2023 -> X = 2023 (pasture 2023, soy 2024)
#   2014-2018 -> X = 2018 (pasture 2018, soy 2019)
#   2009-2013 -> X = 2013 (pasture 2013, soy 2014)
PERIODOS_FIGURAS <- c(2013, 2018, 2023)

BIOMA_ORDER <- c("AMAZONIA", "CERRADO", "MATA ATLANTICA",
                 "CAATINGA", "PAMPA", "PANTANAL")

CORES <- c(soja     = "#E69F00",
           pasto    = "#009E73",
           outros   = "#999999")

# ----- Pacotes ----------------------------------------------------------------
pkgs <- c("dplyr", "tidyr", "readr", "ggplot2", "scales", "stringr", "fs")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
}
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr)
  library(ggplot2); library(scales); library(stringr); library(fs)
})

# ----- Criar pastas de output -------------------------------------------------
dir_tables       <- file.path(OUTPUT_DIR, "tables")
dir_fig_pct      <- file.path(OUTPUT_DIR, "figures", "stacked_pct_by_biome")
dir_fig_facet    <- file.path(OUTPUT_DIR, "figures", "facet_comparison")
dir_fig_ha       <- file.path(OUTPUT_DIR, "figures", "stacked_hectares")
dir_fig_brasil   <- file.path(OUTPUT_DIR, "figures", "brazil_aggregate")
for (d in c(dir_tables, dir_fig_pct, dir_fig_facet, dir_fig_ha, dir_fig_brasil)) {
  dir_create(d, recurse = TRUE)
}

# ----- Carregar dados ---------------------------------------------------------
read_trase <- function(file, value_col) {
  path <- file.path(INPUT_DIR, file)
  df <- read_csv(path, show_col_types = FALSE)
  df[[value_col]] <- as.numeric(df[[value_col]])
  df$year <- as.integer(df$year)
  df
}

territorial <- read_trase(FILE_TERRITORIAL, "deforestation_hectares")
pasture     <- read_trase(FILE_PASTURE,     "pasture_deforestation_hectares")
soy         <- read_trase(FILE_SOY,         "soy_deforestation_hectares")

# Validacao: mesmos biomas / region_trase_id entre as tres tabelas
biomas_t <- sort(unique(territorial$region_trase_id))
biomas_p <- sort(unique(pasture$region_trase_id))
biomas_s <- sort(unique(soy$region_trase_id))
if (!identical(biomas_t, biomas_p) || !identical(biomas_t, biomas_s)) {
  warning("Os region_trase_id diferem entre os tres CSVs. Confira:\n",
          "territorial: ", paste(biomas_t, collapse = ", "), "\n",
          "pasture: ",     paste(biomas_p, collapse = ", "), "\n",
          "soy: ",         paste(biomas_s, collapse = ", "))
}

# ----- Helper: somar desmatamento territorial na janela [X-4, X] --------------
territorial_window <- function(region_id, X) {
  territorial |>
    filter(region_trase_id == region_id, year >= X - 4, year <= X) |>
    summarise(ha = sum(deforestation_hectares, na.rm = TRUE)) |>
    pull(ha)
}

# ----- Construir trios (bioma, X) para X em 2013..2023 ------------------------
# Limites:
#   - pasture(X) requer X em [2010, 2023]
#   - soy(X+1) requer X+1 em [2014, 2024] => X em [2013, 2023]
#   - territorial [X-4, X] requer X-4 >= 2008 => X >= 2012
# Intersecao: X em [2013, 2023] (11 trios por bioma).
X_RANGE <- 2013:2023

biomas_meta <- territorial |>
  distinct(region, region_trase_id)

build_trios <- function() {
  rows <- list()
  for (i in seq_len(nrow(biomas_meta))) {
    rid <- biomas_meta$region_trase_id[i]
    rname <- biomas_meta$region[i]
    for (X in X_RANGE) {
      ha_window <- territorial_window(rid, X)
      ha_pasture <- pasture |>
        filter(region_trase_id == rid, year == X) |>
        pull(pasture_deforestation_hectares)
      ha_soy <- soy |>
        filter(region_trase_id == rid, year == X + 1) |>
        pull(soy_deforestation_hectares)
      rows[[length(rows) + 1]] <- tibble(
        bioma = rname,
        region_trase_id = rid,
        pasture_year = X,
        janela_desmatamento = paste0(X - 4, "-", X),
        desmatamento_territorial_total_ha = ha_window,
        pasture_deforestation_ha = ifelse(length(ha_pasture) == 0, NA_real_, ha_pasture),
        soy_deforestation_ha     = ifelse(length(ha_soy)     == 0, NA_real_, ha_soy)
      )
    }
  }
  bind_rows(rows)
}

trios_biomas <- build_trios()

# ----- Brasil total: agregar por X e RECALCULAR (nao somar percentuais) -------
trios_brasil <- trios_biomas |>
  group_by(pasture_year, janela_desmatamento) |>
  summarise(
    bioma = "BRASIL",
    region_trase_id = "BR",
    desmatamento_territorial_total_ha = sum(desmatamento_territorial_total_ha, na.rm = TRUE),
    pasture_deforestation_ha = sum(pasture_deforestation_ha, na.rm = TRUE),
    soy_deforestation_ha     = sum(soy_deforestation_ha, na.rm = TRUE),
    .groups = "drop"
  )

trios <- bind_rows(trios_biomas, trios_brasil) |>
  mutate(
    pct_soy     = soy_deforestation_ha     / desmatamento_territorial_total_ha,
    pct_pasture = pasture_deforestation_ha / desmatamento_territorial_total_ha,
    pct_outros  = 1 - pct_soy - pct_pasture,
    overlap_warning = (pct_soy + pct_pasture) > 1
  ) |>
  select(bioma, region_trase_id, pasture_year, janela_desmatamento,
         desmatamento_territorial_total_ha,
         soy_deforestation_ha, pasture_deforestation_ha,
         pct_soy, pct_pasture, pct_outros, overlap_warning) |>
  arrange(pasture_year, match(bioma, c(BIOMA_ORDER, "BRASIL")))

# ----- Sinalizar overlaps no console ------------------------------------------
overlaps <- trios |> filter(overlap_warning)
if (nrow(overlaps) > 0) {
  message("ATENCAO: ", nrow(overlaps),
          " trio(s) com pct_soy + pct_pasture > 1 (possivel sobreposicao espacial):")
  print(overlaps |>
          select(bioma, janela_desmatamento, pct_soy, pct_pasture, pct_outros),
        n = Inf)
} else {
  message("Nenhum trio com pct_soy + pct_pasture > 1.")
}

# ----- Escrever tabelas -------------------------------------------------------
# Etapa 1: trio mais recente (X = 2023, janela 2019-2023)
trio_recente <- trios |> filter(pasture_year == 2023)
write_csv(trio_recente,
          file.path(dir_tables, "trio_mais_recente_2019_2023.csv"))

# Etapa 2: serie completa 2013-2023 (todos os 11 trios)
write_csv(trios,
          file.path(dir_tables, "serie_completa_2013_2023.csv"))

message("Tabelas escritas em: ", dir_tables)

# ----- Funcoes de figuras -----------------------------------------------------

# Versao especifica para hectares (derivamos 'outros' do total)
to_long_ha <- function(df) {
  df |>
    mutate(outros_ha = pmax(desmatamento_territorial_total_ha
                            - soy_deforestation_ha
                            - pasture_deforestation_ha, 0)) |>
    select(bioma, janela_desmatamento,
           soja = soy_deforestation_ha,
           pasto = pasture_deforestation_ha,
           outros = outros_ha) |>
    pivot_longer(c(soja, pasto, outros),
                 names_to = "componente", values_to = "valor") |>
    mutate(componente = factor(componente, levels = c("soja", "pasto", "outros")))
}

to_long_pct <- function(df) {
  df |>
    select(bioma, janela_desmatamento,
           soja = pct_soy, pasto = pct_pasture, outros = pct_outros) |>
    pivot_longer(c(soja, pasto, outros),
                 names_to = "componente", values_to = "valor") |>
    mutate(componente = factor(componente, levels = c("soja", "pasto", "outros")))
}

bioma_factor <- function(x) factor(x, levels = BIOMA_ORDER)

theme_traseplot <- function() {
  theme_minimal(base_size = 12) +
    theme(panel.grid.major.x = element_blank(),
          panel.grid.minor   = element_blank(),
          legend.position    = "bottom",
          legend.title       = element_blank(),
          plot.title         = element_text(face = "bold"))
}

# ----- Figuras: stacked_pct_by_biome (3 PNGs, uma por periodo) ---------------
for (px in PERIODOS_FIGURAS) {
  janela <- paste0(px - 4, "-", px)
  df <- trios |>
    filter(pasture_year == px, bioma %in% BIOMA_ORDER) |>
    to_long_pct() |>
    mutate(bioma = bioma_factor(bioma))

  p <- ggplot(df, aes(x = bioma, y = valor, fill = componente)) +
    geom_col(position = "stack") +
    scale_y_continuous(labels = percent_format(accuracy = 1),
                       expand = expansion(mult = c(0, 0.05))) +
    scale_fill_manual(values = CORES) +
    labs(title = paste0("% do desmatamento de ", janela,
                        " atribuido a soja e pasto, por bioma"),
         subtitle = "pasture(X) + soy(X+1) -- mesma janela [X-4, X]",
         x = NULL, y = "% do desmatamento territorial da janela") +
    theme_traseplot()

  ggsave(file.path(dir_fig_pct,
                   paste0("pct_por_bioma_", janela, ".png")),
         p, width = 9, height = 5.5, dpi = 200)
}

# ----- Figura: facet_comparison (1 PNG com 3 periodos lado a lado) -----------
df_facet <- trios |>
  filter(pasture_year %in% PERIODOS_FIGURAS, bioma %in% BIOMA_ORDER) |>
  to_long_pct() |>
  mutate(bioma = bioma_factor(bioma),
         janela_desmatamento = factor(janela_desmatamento,
                                      levels = c("2009-2013",
                                                 "2014-2018",
                                                 "2019-2023")))

p_facet <- ggplot(df_facet, aes(x = bioma, y = valor, fill = componente)) +
  geom_col(position = "stack") +
  facet_wrap(~ janela_desmatamento, nrow = 1) +
  scale_y_continuous(labels = percent_format(accuracy = 1),
                     expand = expansion(mult = c(0, 0.05))) +
  scale_fill_manual(values = CORES) +
  labs(title = "% do desmatamento atribuido a soja e pasto, por bioma",
       subtitle = "Tres janelas de 5 anos nao sobrepostas",
       x = NULL, y = "% do desmatamento territorial da janela") +
  theme_traseplot() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

ggsave(file.path(dir_fig_facet, "comparacao_3_periodos.png"),
       p_facet, width = 13, height = 5.5, dpi = 200)

# ----- Figuras: stacked_hectares (3 PNGs, uma por periodo) -------------------
for (px in PERIODOS_FIGURAS) {
  janela <- paste0(px - 4, "-", px)
  df <- trios |>
    filter(pasture_year == px, bioma %in% BIOMA_ORDER) |>
    to_long_ha() |>
    mutate(bioma = bioma_factor(bioma))

  p <- ggplot(df, aes(x = bioma, y = valor / 1e6, fill = componente)) +
    geom_col(position = "stack") +
    scale_y_continuous(labels = label_number(accuracy = 0.1),
                       expand = expansion(mult = c(0, 0.05))) +
    scale_fill_manual(values = CORES) +
    labs(title = paste0("Desmatamento ", janela,
                        " atribuido a soja e pasto (hectares), por bioma"),
         subtitle = "pasture(X) + soy(X+1); 'outros' = total - soja - pasto",
         x = NULL, y = "Milhoes de hectares") +
    theme_traseplot()

  ggsave(file.path(dir_fig_ha,
                   paste0("hectares_por_bioma_", janela, ".png")),
         p, width = 9, height = 5.5, dpi = 200)
}

# ----- Figuras: brazil_aggregate (1 % + 1 hectares) --------------------------
df_br_pct <- trios |>
  filter(pasture_year %in% PERIODOS_FIGURAS, bioma == "BRASIL") |>
  to_long_pct() |>
  mutate(janela_desmatamento = factor(janela_desmatamento,
                                      levels = c("2009-2013",
                                                 "2014-2018",
                                                 "2019-2023")))

p_br_pct <- ggplot(df_br_pct, aes(x = janela_desmatamento, y = valor,
                                  fill = componente)) +
  geom_col(position = "stack") +
  scale_y_continuous(labels = percent_format(accuracy = 1),
                     expand = expansion(mult = c(0, 0.05))) +
  scale_fill_manual(values = CORES) +
  labs(title = "Brasil: % do desmatamento atribuido a soja e pasto",
       subtitle = "Tres janelas de 5 anos nao sobrepostas",
       x = "Janela de desmatamento",
       y = "% do desmatamento territorial da janela") +
  theme_traseplot()

ggsave(file.path(dir_fig_brasil, "brasil_pct_3_periodos.png"),
       p_br_pct, width = 8, height = 5.5, dpi = 200)

df_br_ha <- trios |>
  filter(pasture_year %in% PERIODOS_FIGURAS, bioma == "BRASIL") |>
  to_long_ha() |>
  mutate(janela_desmatamento = factor(janela_desmatamento,
                                      levels = c("2009-2013",
                                                 "2014-2018",
                                                 "2019-2023")))

p_br_ha <- ggplot(df_br_ha, aes(x = janela_desmatamento, y = valor / 1e6,
                                fill = componente)) +
  geom_col(position = "stack") +
  scale_y_continuous(labels = label_number(accuracy = 0.1),
                     expand = expansion(mult = c(0, 0.05))) +
  scale_fill_manual(values = CORES) +
  labs(title = "Brasil: desmatamento atribuido a soja e pasto (hectares)",
       subtitle = "Tres janelas de 5 anos nao sobrepostas",
       x = "Janela de desmatamento",
       y = "Milhoes de hectares") +
  theme_traseplot()

ggsave(file.path(dir_fig_brasil, "brasil_hectares_3_periodos.png"),
       p_br_ha, width = 8, height = 5.5, dpi = 200)

message("Figuras escritas em: ", file.path(OUTPUT_DIR, "figures"))
message("Pronto. Tabelas e 8 figuras geradas.")
