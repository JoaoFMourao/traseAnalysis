# traseAnalysis

Repositório para análise de dados do Trase (SEI-PCS Brazil).

## `R/deforestation_attribution.R`

Calcula, por bioma, o percentual do desmatamento territorial atribuível a soja e pasto (gado), usando a metodologia oficial do Trase (beef v2.2, soy v2.6).

### Lógica

- `pasture(X)` cobre desmatamento de `[X-4, X]` (5 anos, inclui X).
- `soy(X)` cobre desmatamento de `[X-5, X-1]` (5 anos, lag 1, não inclui X).
- Para a mesma janela: casa-se `pasture(X)` com `soy(X+1)`.
- Os "5 year totals" não somam entre anos diferentes — cada trio é uma foto isolada.

### Inputs (3 CSVs Trase em `INPUT_DIR`)

- `territorial_deforestation_biome.csv` (2008–2024, anual)
- `pasture_deforestation_5_year_total_biome.csv` (2010–2023)
- `soy_deforestation_5_year_total_biome.csv` (2014–2024)

### Outputs (em `OUTPUT_DIR`)

```
output/
├── tables/
│   ├── trio_mais_recente_2019_2023.csv
│   └── serie_completa_2013_2023.csv     (11 trios por unidade: X de 2013 a 2023)
└── figures/
    ├── stacked_pct_by_biome/         (3 PNGs, 1 por período)
    ├── facet_comparison/             (1 PNG, 3 períodos lado a lado)
    ├── stacked_hectares/             (3 PNGs, valores absolutos)
    └── brazil_aggregate/             (2 PNGs, Brasil em % e em ha)
```

Períodos das figuras: 2009-2013, 2014-2018, 2019-2023 (3 janelas de 5 anos não sobrepostas).

### Como rodar

1. Edite `INPUT_DIR` e `OUTPUT_DIR` no topo de `R/deforestation_attribution.R`.
2. Em R / RStudio:

```r
source("R/deforestation_attribution.R")
```

Pacotes necessários: `dplyr`, `tidyr`, `readr`, `ggplot2`, `scales`, `stringr`, `fs` (instalados automaticamente se faltarem).

### Pendências (fora desta etapa)

- Como tratar a série 2014–2023 sem dupla contagem entre janelas vizinhas (compartilham 4 anos).
- Tratamento da possível sobreposição espacial entre soja e pasto (sinalizada via `overlap_warning`).
