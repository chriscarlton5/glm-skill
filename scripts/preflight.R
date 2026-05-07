#!/usr/bin/env Rscript

required_packages <- c(
  "dplyr", "lubridate", "broom", "ggplot2",
  "MASS", "mgcv", "statmod"
)

optional_packages <- c(
  "openxlsx", "tweedie", "rsample", "yardstick", "arrow", "duckdb", "quarto"
)

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

check_packages <- function(required = required_packages, optional = optional_packages) {
  is_available <- function(pkg) {
    requireNamespace(pkg, quietly = TRUE)
  }
  list(
    r_version = paste(R.version$major, R.version$minor, sep = "."),
    required = data.frame(
      package = required,
      installed = unname(vapply(required, is_available, logical(1))),
      stringsAsFactors = FALSE
    ),
    optional = data.frame(
      package = optional,
      installed = unname(vapply(optional, is_available, logical(1))),
      stringsAsFactors = FALSE
    )
  )
}

write_preflight_report <- function(result, path = "preflight_report.txt") {
  missing_required <- result$required$package[!result$required$installed]
  missing_optional <- result$optional$package[!result$optional$installed]
  lines <- c(
    paste0("R version: ", result$r_version),
    "",
    "Required packages:",
    paste0("  - ", result$required$package, ": ", ifelse(result$required$installed, "installed", "missing")),
    "",
    "Optional packages:",
    paste0("  - ", result$optional$package, ": ", ifelse(result$optional$installed, "installed", "missing")),
    ""
  )
  if (length(missing_required) > 0) {
    lines <- c(lines, "Install missing required packages with:", paste0(
      "install.packages(c(",
      paste(sprintf('\"%s\"', missing_required), collapse = ", "),
      "))"
    ))
  }
  if (length(missing_optional) > 0) {
    lines <- c(lines, "", "Optional packages missing:", paste(missing_optional, collapse = ", "))
  }
  writeLines(lines, path)
  invisible(path)
}

run_preflight <- function(path = "preflight_report.txt", stop_on_missing = FALSE) {
  result <- check_packages()
  write_preflight_report(result, path)
  missing_required <- result$required$package[!result$required$installed]
  if (length(missing_required) > 0) {
    msg <- paste("Missing required R packages:", paste(missing_required, collapse = ", "))
    if (stop_on_missing) stop(msg, call. = FALSE)
    message(msg)
  } else {
    message("All required R packages are installed.")
  }
  result
}

if (sys.nframe() == 0 && !interactive()) {
  invisible(run_preflight())
}
