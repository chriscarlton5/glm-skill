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

load_fremtpl2_frequency <- function() {
  if (!requireNamespace("CASdatasets", quietly = TRUE)) {
    stop(
      paste(
        "Optional package CASdatasets is required for the freMTPL demo.",
        "Install it from the appropriate R repository or use user-provided data.",
        "The full freMTPL dataset is intentionally not bundled with this skill."
      ),
      call. = FALSE
    )
  }
  data("freMTPL2freq", package = "CASdatasets", envir = environment())
  freMTPL2freq
}

prepare_fremtpl2_frequency <- function(data) {
  data |>
    dplyr::filter(!is.na(Exposure), Exposure > 0) |>
    dplyr::mutate(
      ClaimNb = pmin(ClaimNb, 4),
      VehPower = as.factor(VehPower),
      VehBrand = as.factor(VehBrand),
      VehGas = as.factor(VehGas),
      Area = as.factor(Area),
      Region = as.factor(Region),
      DensityLog = log1p(Density),
      demo_period = as.Date("2018-01-01") + (as.integer(IDpol) %% 1095)
    )
}

make_fremtpl_fixture <- function(n = 5000, seed = 20260507) {
  set.seed(seed)
  freq <- load_fremtpl2_frequency()
  prepared <- prepare_fremtpl2_frequency(freq)
  if (nrow(prepared) <= n) return(prepared)
  prepared[sample.int(nrow(prepared), n), , drop = FALSE]
}

write_fremtpl_fixture <- function(path = file.path(tempdir(), "fremtpl2_frequency_fixture.csv"),
                                  n = 5000,
                                  seed = 20260507) {
  fixture <- make_fremtpl_fixture(n = n, seed = seed)
  utils::write.csv(fixture, path, row.names = FALSE)
  path
}

if (sys.nframe() == 0 && !interactive()) {
  path <- write_fremtpl_fixture()
  message("Wrote freMTPL demo fixture to: ", path)
}
