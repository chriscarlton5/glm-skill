safe_divide <- function(numerator, denominator) {
  ifelse(is.na(denominator) | denominator == 0, NA_real_, numerator / denominator)
}

check_required_columns <- function(data, columns) {
  missing <- setdiff(columns, names(data))
  if (length(missing) > 0) {
    stop("Missing required columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}

load_modeling_data <- function(path, sheet = NULL, ...) {
  if (!file.exists(path)) {
    stop("Data file does not exist: ", path, call. = FALSE)
  }

  ext <- tolower(tools::file_ext(path))
  if (ext %in% c("csv", "txt")) {
    return(utils::read.csv(path, stringsAsFactors = FALSE, ...))
  }
  if (ext %in% c("xlsx", "xlsm", "xls")) {
    if (!requireNamespace("openxlsx", quietly = TRUE)) {
      stop("Package openxlsx is required to read Excel files.", call. = FALSE)
    }
    if (is.null(sheet)) {
      sheet <- openxlsx::getSheetNames(path)[1]
    }
    return(openxlsx::read.xlsx(path, sheet = sheet, ...))
  }
  if (ext == "rds") {
    return(readRDS(path))
  }
  if (ext == "parquet") {
    if (!requireNamespace("arrow", quietly = TRUE)) {
      stop("Optional package arrow is required to read Parquet files.", call. = FALSE)
    }
    return(arrow::read_parquet(path, ...))
  }

  stop(
    "Unsupported data file extension: .", ext,
    ". Supported formats: csv, txt, xlsx, xlsm, xls, rds, parquet.",
    call. = FALSE
  )
}

validate_exposure <- function(data, exposure_col = "Exposure") {
  check_required_columns(data, exposure_col)
  exposure <- data[[exposure_col]]
  invalid <- is.na(exposure) | exposure <= 0
  list(
    total_rows = nrow(data),
    invalid_rows = sum(invalid),
    total_exposure = sum(exposure[!invalid], na.rm = TRUE),
    valid_data = data[!invalid, , drop = FALSE]
  )
}

profile_data <- function(data, exposure_col, claim_col = NULL, loss_col = NULL) {
  out <- data.frame(
    measure = c("records", "exposure"),
    value = c(nrow(data), sum(data[[exposure_col]], na.rm = TRUE))
  )
  if (!is.null(claim_col) && claim_col %in% names(data)) {
    out <- rbind(out, data.frame(measure = "claims", value = sum(data[[claim_col]], na.rm = TRUE)))
  }
  if (!is.null(loss_col) && loss_col %in% names(data)) {
    out <- rbind(out, data.frame(measure = "loss", value = sum(data[[loss_col]], na.rm = TRUE)))
  }
  out
}

leakage_screen <- function(columns) {
  bad_patterns <- c(
    "paid", "incurred", "claimamount", "lossamount", "loss_amount",
    "salvage", "recovery", "litigation", "adjuster", "closedate",
    "close_date", "claimstatus", "claim_status", "reportlag", "report_lag"
  )
  lowered <- tolower(columns)
  flagged <- vapply(lowered, function(x) any(grepl(paste(bad_patterns, collapse = "|"), x)), logical(1))
  data.frame(field = columns, leakage_flag = flagged, stringsAsFactors = FALSE)
}

split_by_period <- function(data, period_col, train_end, valid_end) {
  check_required_columns(data, period_col)
  period <- as.Date(data[[period_col]])
  list(
    train = data[period <= as.Date(train_end), , drop = FALSE],
    valid = data[period > as.Date(train_end) & period <= as.Date(valid_end), , drop = FALSE],
    test = data[period > as.Date(valid_end), , drop = FALSE]
  )
}

split_random <- function(data, train = 0.6, valid = 0.2, seed = 20260507) {
  set.seed(seed)
  idx <- sample.int(nrow(data))
  n_train <- floor(nrow(data) * train)
  n_valid <- floor(nrow(data) * valid)
  list(
    train = data[idx[seq_len(n_train)], , drop = FALSE],
    valid = data[idx[(n_train + 1):(n_train + n_valid)], , drop = FALSE],
    test = data[idx[(n_train + n_valid + 1):nrow(data)], , drop = FALSE]
  )
}

make_sparse_level_map <- function(data, field, exposure_col, claim_col = NULL,
                                  min_exposure = 100, min_claims = 10,
                                  other_label = "Low credibility") {
  check_required_columns(data, c(field, exposure_col))
  grouped <- stats::aggregate(data[[exposure_col]], list(level = data[[field]]), sum, na.rm = TRUE)
  names(grouped)[2] <- "exposure"
  if (!is.null(claim_col) && claim_col %in% names(data)) {
    claims <- stats::aggregate(data[[claim_col]], list(level = data[[field]]), sum, na.rm = TRUE)
    names(claims)[2] <- "claims"
    grouped <- merge(grouped, claims, by = "level", all.x = TRUE)
  } else {
    grouped$claims <- NA_real_
  }
  grouped$mapped_level <- ifelse(
    grouped$exposure < min_exposure | (!is.na(grouped$claims) & grouped$claims < min_claims),
    other_label,
    as.character(grouped$level)
  )
  grouped
}

apply_level_map <- function(data, field, map, new_field = paste0(field, "_group"),
                            new_label = "New/Other") {
  matched <- match(as.character(data[[field]]), as.character(map$level))
  data[[new_field]] <- ifelse(is.na(matched), new_label, map$mapped_level[matched])
  data[[new_field]] <- as.factor(data[[new_field]])
  data
}

fit_frequency_glm <- function(train, formula_terms, claim_col = "ClaimNb", exposure_col = "Exposure") {
  check_required_columns(train, c(claim_col, exposure_col))
  train$.glm_exposure <- train[[exposure_col]]
  formula <- stats::as.formula(paste(claim_col, "~", formula_terms, "+ offset(log(.glm_exposure))"))
  model <- stats::glm(
    formula,
    family = poisson(link = "log"),
    data = train
  )
  attr(model, "exposure_col") <- exposure_col
  model
}

score_expected <- function(model, data) {
  exposure_col <- attr(model, "exposure_col")
  if (!is.null(exposure_col) && !(".glm_exposure" %in% names(data))) {
    data$.glm_exposure <- data[[exposure_col]]
  }
  stats::predict(model, newdata = data, type = "response")
}

performance_table <- function(model, datasets, claim_col = "ClaimNb", exposure_col = "Exposure") {
  rows <- lapply(names(datasets), function(name) {
    dat <- datasets[[name]]
    expected <- score_expected(model, dat)
    actual <- dat[[claim_col]]
    data.frame(
      dataset = name,
      records = nrow(dat),
      exposure = sum(dat[[exposure_col]], na.rm = TRUE),
      actual = sum(actual, na.rm = TRUE),
      expected = sum(expected, na.rm = TRUE),
      ae_ratio = safe_divide(sum(actual, na.rm = TRUE), sum(expected, na.rm = TRUE)),
      mean_frequency = safe_divide(sum(actual, na.rm = TRUE), sum(dat[[exposure_col]], na.rm = TRUE))
    )
  })
  do.call(rbind, rows)
}

calibration_by_decile <- function(model, data, claim_col = "ClaimNb", exposure_col = "Exposure", n = 10) {
  expected <- score_expected(model, data)
  rank_value <- expected / data[[exposure_col]]
  decile <- cut(rank(rank_value, ties.method = "first"), breaks = n, labels = FALSE)
  out <- stats::aggregate(
    cbind(actual = data[[claim_col]], expected = expected, exposure = data[[exposure_col]]),
    list(decile = decile),
    sum,
    na.rm = TRUE
  )
  out$ae_ratio <- safe_divide(out$actual, out$expected)
  out$actual_frequency <- safe_divide(out$actual, out$exposure)
  out$expected_frequency <- safe_divide(out$expected, out$exposure)
  out
}

overdispersion_ratio <- function(model) {
  sum(stats::residuals(model, type = "pearson")^2) / model$df.residual
}

extract_relativity_table <- function(model) {
  coef_values <- stats::coef(model)
  data.frame(
    term = names(coef_values),
    coefficient = as.numeric(coef_values),
    raw_relativity = exp(as.numeric(coef_values)),
    selected_relativity = exp(as.numeric(coef_values)),
    manual_override = FALSE,
    notes = "",
    stringsAsFactors = FALSE
  )
}

write_session_info <- function(path = "artifacts/session_info.txt") {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  capture.output(utils::sessionInfo(), file = path)
  invisible(path)
}
