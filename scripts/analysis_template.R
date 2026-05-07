#!/usr/bin/env Rscript

this_script_path <- function() {
  frames <- sys.frames()
  ofiles <- vapply(frames, function(frame) {
    if (!is.null(frame$ofile)) frame$ofile else NA_character_
  }, character(1))
  ofiles <- ofiles[!is.na(ofiles)]
  if (length(ofiles) > 0) return(normalizePath(tail(ofiles, 1), mustWork = FALSE))
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- args[grep("^--file=", args)]
  if (length(file_arg) > 0) return(normalizePath(sub("^--file=", "", file_arg[1]), mustWork = FALSE))
  NA_character_
}

script_path <- this_script_path()
script_dir <- if (!is.na(script_path)) dirname(script_path) else getwd()

source(file.path(script_dir, "glm_helpers.R"))
source(file.path(script_dir, "export_workbook.R"))

run_frequency_demo <- function(data, output_dir = "glm_demo_output") {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(output_dir, "outputs", "diagnostics"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(output_dir, "outputs", "relativities"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(output_dir, "artifacts", "preprocessing_maps"), recursive = TRUE, showWarnings = FALSE)

  exposure_check <- validate_exposure(data, "Exposure")
  modeling <- exposure_check$valid_data

  splits <- split_by_period(
    modeling,
    period_col = "demo_period",
    train_end = "2019-12-31",
    valid_end = "2020-09-30"
  )

  area_map <- make_sparse_level_map(splits$train, "Area", "Exposure", "ClaimNb", min_exposure = 25, min_claims = 3)
  for (nm in names(splits)) {
    splits[[nm]] <- apply_level_map(splits[[nm]], "Area", area_map, "Area_group")
  }

  model <- fit_frequency_glm(
    splits$train,
    "Area_group + VehPower + VehGas + pmin(VehAge, 20) + pmin(DrivAge, 85) + log1p(Density)",
    claim_col = "ClaimNb",
    exposure_col = "Exposure"
  )

  performance <- performance_table(model, splits, "ClaimNb", "Exposure")
  calibration <- calibration_by_decile(model, splits$valid, "ClaimNb", "Exposure")
  relativities <- extract_relativity_table(model)
  qa <- profile_data(modeling, "Exposure", "ClaimNb")
  leakage <- leakage_screen(names(modeling))
  model_summary <- data.frame(
    item = c("target", "family", "link", "offset", "overdispersion"),
    value = c("ClaimNb", "Poisson", "log", "log(Exposure)", round(overdispersion_ratio(model), 4))
  )

  utils::write.csv(area_map, file.path(output_dir, "artifacts", "preprocessing_maps", "area_map.csv"), row.names = FALSE)
  utils::write.csv(performance, file.path(output_dir, "outputs", "diagnostics", "performance.csv"), row.names = FALSE)
  utils::write.csv(calibration, file.path(output_dir, "outputs", "diagnostics", "calibration_decile.csv"), row.names = FALSE)
  utils::write.csv(relativities, file.path(output_dir, "outputs", "relativities", "frequency_relativity_table.csv"), row.names = FALSE)
  write_session_info(file.path(output_dir, "artifacts", "session_info.txt"))

  export_glm_workbook(
    file.path(output_dir, "outputs", "glm_outputs.xlsx"),
    inputs = data.frame(field = c("target", "exposure", "source"), value = c("ClaimNb", "Exposure", "freMTPL2 demo fixture")),
    data_qa = qa,
    model_summary = model_summary,
    diagnostics = calibration,
    relativities = relativities,
    validation = performance,
    change_log = data.frame(date = as.character(Sys.Date()), change = "Initial demo model", rationale = "Smoke test")
  )

  list(
    model = model,
    performance = performance,
    calibration = calibration,
    relativities = relativities,
    leakage = leakage,
    output_dir = output_dir
  )
}

if (sys.nframe() == 0 && !interactive()) {
  source(file.path(script_dir, "load_fremtpl_demo.R"))
  fixture <- make_fremtpl_fixture(n = 5000)
  result <- run_frequency_demo(fixture)
  message("Wrote GLM demo output to: ", normalizePath(result$output_dir, mustWork = FALSE))
}
