#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[grep("^--file=", args)]
script_dir <- if (length(file_arg) > 0) dirname(normalizePath(sub("^--file=", "", file_arg[1]), mustWork = TRUE)) else getwd()

source(file.path(script_dir, "preflight.R"))
source(file.path(script_dir, "sample_data.R"))
source(file.path(script_dir, "analysis_template.R"))

invisible(run_preflight(path = file.path(tempdir(), "glm_skill_preflight.txt"), stop_on_missing = TRUE))

fixture <- make_sample_frequency_data(n = 2000)
out_dir <- file.path(tempdir(), "glm_skill_smoke_test")
result <- run_frequency_validation(fixture, output_dir = out_dir)

required_files <- c(
  file.path(out_dir, "outputs", "diagnostics", "performance.csv"),
  file.path(out_dir, "outputs", "diagnostics", "calibration_decile.csv"),
  file.path(out_dir, "outputs", "relativities", "frequency_relativity_table.csv"),
  file.path(out_dir, "artifacts", "preprocessing_maps", "area_map.csv"),
  file.path(out_dir, "artifacts", "session_info.txt")
)

if (requireNamespace("openxlsx", quietly = TRUE)) {
  required_files <- c(required_files, file.path(out_dir, "outputs", "glm_outputs.xlsx"))
}

missing <- required_files[!file.exists(required_files)]
if (length(missing) > 0) {
  stop("Smoke test missing output files: ", paste(missing, collapse = ", "), call. = FALSE)
}

if (!inherits(result$model, "glm")) {
  stop("Smoke test did not produce a glm model.", call. = FALSE)
}

message("GLM skill smoke test passed: ", out_dir)
