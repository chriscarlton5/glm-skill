#!/usr/bin/env Rscript

write_sheet <- function(wb, name, data) {
  openxlsx::addWorksheet(wb, name)
  openxlsx::writeData(wb, name, data)
  header_style <- openxlsx::createStyle(
    fgFill = "#1F4E79",
    fontColour = "#FFFFFF",
    textDecoration = "bold"
  )
  if (ncol(data) > 0) {
    openxlsx::addStyle(wb, name, header_style, rows = 1, cols = seq_len(ncol(data)), gridExpand = TRUE)
    openxlsx::setColWidths(wb, name, cols = seq_len(ncol(data)), widths = "auto")
  }
}

export_glm_workbook <- function(path,
                                inputs = data.frame(),
                                data_qa = data.frame(),
                                model_summary = data.frame(),
                                diagnostics = data.frame(),
                                relativities = data.frame(),
                                validation = data.frame(),
                                change_log = data.frame()) {
  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    stop("Package openxlsx is required to export glm_outputs.xlsx.", call. = FALSE)
  }
  wb <- openxlsx::createWorkbook()
  write_sheet(wb, "Inputs", inputs)
  write_sheet(wb, "Data QA", data_qa)
  write_sheet(wb, "Model Summary", model_summary)
  write_sheet(wb, "Diagnostics", diagnostics)
  write_sheet(wb, "Relativities", relativities)
  write_sheet(wb, "Validation", validation)
  write_sheet(wb, "Change Log", change_log)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  openxlsx::saveWorkbook(wb, path, overwrite = TRUE)
  invisible(path)
}
