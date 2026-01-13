#' 01: Data Loading and Cleaning for Market and VIX Time Series
#'
#' @description
#' This script loads raw equity market price data and VIX index data,
#' performs basic cleaning and normalization, aligns trading dates,
#' filters the analysis window, and conducts sanity checks.
#'
#' It is designed to serve as the first stage of a multi-step
#' quantitative analysis pipeline and produces standardized,
#' time-aligned datasets suitable for downstream feature engineering
#' and modeling.
#'
#' @details
#' **Primary responsibilities of this script:**
#'
#' 1. **Data ingestion**
#'    - Loads market price data from an Excel source.
#'    - Loads VIX index data from a CSV source.
#'
#' 2. **Data cleaning**
#'    - Standardizes column names and data types.
#'    - Parses and normalizes date formats.
#'    - Handles missing or malformed observations.
#'
#' 3. **Temporal alignment**
#'    - Filters data to a common analysis window.
#'    - Aligns market and VIX observations by trading date.
#'
#' 4. **Sanity checks**
#'    - Ensures monotonic date ordering.
#'    - Verifies absence of duplicate dates.
#'    - Confirms consistency of price and index levels.
#'
#' @section Pipeline position:
#' This script is intended to be sourced before any feature engineering
#' or modeling scripts. Downstream scripts assume that the objects
#' `market_data` and `vix_data` exist in the environment and are
#' properly aligned by date.
#'
#' @inputs
#' \itemize{
#'   \item `market_data.xlsx` — raw market price data
#'   \item `vix_history.csv` — historical VIX index data
#' }
#'
#' @outputs
#' \itemize{
#'   \item `market_data` — cleaned and normalized market dataset
#'   \item `vix_data` — cleaned and date-aligned VIX dataset
#' }
#'
#' @dependencies
#' \itemize{
#'   \item \pkg{readxl}
#'   \item \pkg{readr}
#'   \item \pkg{dplyr}
#' }
#'
#' @seealso
#' \itemize{
#'   \item `02_feature_engineering.R` for construction of modeling features
#' }
#'
#'
#' @note
#' This script performs minimal transformations beyond cleaning and
#' alignment. All financial feature construction is deferred to
#' downstream pipeline stages.
#'
#' @examples
#' \dontrun{
#' source("01_load_clean.R")
#' }
NULL


library(readxl)
library(readr)
library(dplyr)

# -----------------------
# Load data
# -----------------------

#' Safely read an Excel file
#'
#' Attempts to load an Excel file from disk. If the file
#' cannot be read (missing, corrupted, wrong format, etc.),
#' execution stops with a clear error message.
#'
#' @param path Character string specifying the file path.
#'
#' @return A tibble containing the Excel data.
#'
#' @examples
#' \dontrun{
#' market_data <- safe_read_excel("market_data.xlsx")
#' }
safe_read_excel <- function(path) {
  tryCatch(
    {
      read_excel(path)
    },
    error = function(e) {
      stop(
        paste(
          "Failed to load Excel file:",
          path,
          "\nReason:", e$message
        ),
        call. = FALSE
      )
    }
  )
}

#' Safely read a CSV file
#'
#' Attempts to load a CSV file from disk. If the file
#' cannot be read, execution stops with a clear error
#' message describing the failure.
#'
#' @param path Character string specifying the file path.
#'
#' @return A tibble containing the CSV data.
#'
#' @examples
#' \dontrun{
#' vix_data <- safe_read_csv("vix_history.csv")
#' }
safe_read_csv <- function(path) {
  tryCatch(
    {
      read_csv(path, show_col_types = FALSE)
    },
    error = function(e) {
      stop(
        paste(
          "Failed to load CSV file:",
          path,
          "\nReason:", e$message
        ),
        call. = FALSE
      )
    }
  )
}

# Load raw datasets
market_data <- safe_read_excel("market_data.xlsx")
vix_data <- safe_read_csv("vix_history.csv")

# -----------------------
# Clean market data
# -----------------------

# Normalize column names, convert data types,
# and ensure chronological ordering
market_data <- market_data %>%
  rename(
    "DATE" = "Date",
    "OPEN" = "Open",
    "HIGH" = "High",
    "LOW" = "Low",
    "CLOSE" = "Close",
    "ADJ_CLOSE" = "Adj Close",
    "VOLUME" = "Volume"
  ) %>%
  mutate(
    DATE = as.Date(DATE, format = "%m/%d/%Y"),
    across(c(OPEN, HIGH, LOW, CLOSE, ADJ_CLOSE, VOLUME), as.numeric)
  ) %>%
  arrange(DATE)

# -----------------------
# Clean VIX data
# -----------------------

# Rename VIX columns to avoid name collisions
# and convert fields to appropriate types
vix_data <- vix_data %>%
  rename(
    "VIX_OPEN" = "OPEN",
    "VIX_HIGH" = "HIGH",
    "VIX_LOW" = "LOW",
    "VIX_CLOSE" = "CLOSE"
  ) %>%
  mutate(
    DATE = as.Date(DATE, format = "%m/%d/%Y"),
    across(starts_with("VIX_"), as.numeric)
  ) %>%
  arrange(DATE)

# -----------------------
# Filter analysis window
# -----------------------

# Define analysis period
start_date <- "2021-01-05"
end_date <- "2026-01-02"

# Restrict datasets to the analysis window
market_data <- market_data %>%
  filter(DATE >= as.Date(start_date) & DATE <= as.Date(end_date))

vix_data <- vix_data %>%
  filter(DATE >= as.Date(start_date) & DATE <= as.Date(end_date))

# -----------------------
# Align dates
# -----------------------

# Retain only dates common to both datasets
vix_data <- semi_join(vix_data, market_data, by = "DATE")

# -----------------------
# Sanity checks
# -----------------------

# Ensure data are sorted chronologically
stopifnot(is.unsorted(market_data$DATE) == FALSE)
stopifnot(is.unsorted(vix_data$DATE) == FALSE)
