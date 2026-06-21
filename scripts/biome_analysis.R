#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

input_one <- if (length(args) >= 1) args[[1]] else "data/commodity_volume.csv"
input_two <- if (length(args) >= 2) args[[2]] else "data/deforestation.csv"
output_dir <- if (length(args) >= 3) args[[3]] else "output"

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("Package 'ggplot2' is required. Install it with install.packages('ggplot2').")
}

read_table <- function(path) {
  if (!file.exists(path)) {
    stop(sprintf("Input file not found: %s", path))
  }

  table <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)

  if (!("biome" %in% names(table))) {
    stop(sprintf("Input file must contain a 'biome' column: %s", path))
  }

  table
}

left_table <- read_table(input_one)
right_table <- read_table(input_two)

merged <- merge(left_table, right_table, by = "biome", all = TRUE)
merged <- merged[order(merged$biome), ]

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

merged_csv <- file.path(output_dir, "merged_biome_data.csv")
write.csv(merged, merged_csv, row.names = FALSE)

plot_data <- merged[!is.na(merged$biome), , drop = FALSE]

if (nrow(plot_data) == 0) {
  stop("Merged data has no non-missing biome values to plot.")
}

numeric_columns <- names(plot_data)[sapply(plot_data, is.numeric)]

if (length(numeric_columns) == 0) {
  stop("Merged data has no numeric columns to plot.")
}

long_data <- data.frame(
  biome = rep(plot_data$biome, times = length(numeric_columns)),
  metric = rep(numeric_columns, each = nrow(plot_data)),
  value = unlist(plot_data[numeric_columns], use.names = FALSE)
)

bar_plot <- ggplot2::ggplot(long_data, ggplot2::aes(x = biome, y = value, fill = metric)) +
  ggplot2::geom_col(position = "dodge", na.rm = TRUE) +
  ggplot2::theme_minimal() +
  ggplot2::labs(
    title = "Brazil biome-level indicators",
    x = "Biome",
    y = "Value",
    fill = "Metric"
  )

ggplot2::ggsave(
  filename = file.path(output_dir, "biome_metrics_barplot.png"),
  plot = bar_plot,
  width = 10,
  height = 6,
  dpi = 300
)

if (length(numeric_columns) >= 2) {
  scatter_data <- data.frame(
    x = plot_data[[numeric_columns[[1]]]],
    y = plot_data[[numeric_columns[[2]]]],
    biome = plot_data$biome
  )

  scatter_plot <- ggplot2::ggplot(
    scatter_data,
    ggplot2::aes(x = x, y = y, label = biome)
  ) +
    ggplot2::geom_point(size = 3, na.rm = TRUE) +
    ggplot2::geom_text(vjust = -0.6, size = 3, check_overlap = TRUE, na.rm = TRUE) +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      title = "Biome comparison",
      x = numeric_columns[[1]],
      y = numeric_columns[[2]]
    )

  ggplot2::ggsave(
    filename = file.path(output_dir, "biome_metrics_scatter.png"),
    plot = scatter_plot,
    width = 8,
    height = 6,
    dpi = 300
  )
}

message(sprintf("Merged data written to %s", merged_csv))
message(sprintf("Plots saved to %s", output_dir))
