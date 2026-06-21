# traseAnalysis

Simple repository to analyze tabular data on the biome level in Brazil by merging datasets and generating ggplot2 graphs.

## Requirements

- R (>= 4.0 recommended)
- `ggplot2`

Install ggplot2 in R if needed:

```r
install.packages("ggplot2")
```

## Run

Use sample data included in `/data`:

```bash
Rscript scripts/biome_analysis.R
```

Or pass custom files and output folder:

```bash
Rscript scripts/biome_analysis.R <input_csv_1> <input_csv_2> <output_dir>
```

Both input tables must contain a `biome` column.

## Output

The script generates:

- `merged_biome_data.csv`
- `biome_metrics_barplot.png`
- `biome_metrics_scatter.png` (when at least two numeric columns exist)
