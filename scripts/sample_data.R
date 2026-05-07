#!/usr/bin/env Rscript

make_sample_frequency_data <- function(n = 5000, seed = 20260507) {
  set.seed(seed)

  area <- sample(c("Urban", "Suburban", "Rural", "High density"), n, replace = TRUE,
                 prob = c(0.32, 0.34, 0.24, 0.10))
  veh_power <- sample(4:12, n, replace = TRUE)
  veh_gas <- sample(c("Diesel", "Regular"), n, replace = TRUE, prob = c(0.45, 0.55))
  veh_age <- pmax(0, round(rgamma(n, shape = 2.2, scale = 4)))
  driv_age <- pmin(90, pmax(18, round(rnorm(n, mean = 48, sd = 16))))
  density <- round(exp(rnorm(n, mean = 6.4, sd = 1.0)))
  exposure <- round(runif(n, min = 0.1, max = 1.0), 4)

  area_effect <- c("Urban" = 0.18, "Suburban" = 0.05, "Rural" = -0.12, "High density" = 0.30)
  gas_effect <- c("Diesel" = 0.08, "Regular" = 0)
  log_frequency <- -2.7 +
    area_effect[area] +
    gas_effect[veh_gas] +
    0.025 * pmax(veh_power - 6, 0) +
    0.012 * pmin(veh_age, 20) -
    0.006 * pmin(pmax(driv_age - 35, 0), 35) +
    0.035 * log1p(density)

  claim_nb <- stats::rpois(n, lambda = exposure * exp(log_frequency))
  accident_period <- as.Date("2018-01-01") + sample(0:1095, n, replace = TRUE)

  data.frame(
    Exposure = exposure,
    ClaimNb = claim_nb,
    Area = factor(area),
    VehPower = veh_power,
    VehGas = factor(veh_gas),
    VehAge = veh_age,
    DrivAge = driv_age,
    Density = density,
    accident_period = accident_period,
    stringsAsFactors = FALSE
  )
}

write_sample_frequency_data <- function(path = file.path(tempdir(), "glm_sample_frequency.csv"),
                                        n = 5000,
                                        seed = 20260507) {
  data <- make_sample_frequency_data(n = n, seed = seed)
  utils::write.csv(data, path, row.names = FALSE)
  path
}

if (sys.nframe() == 0 && !interactive()) {
  path <- write_sample_frequency_data()
  message("Wrote sample frequency data to: ", path)
}
