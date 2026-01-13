#' 02: Feature Engineering for Equity Market & Volatility Data
#'
#' @description
#' This script constructs a feature matrix from cleaned equity market data
#' and VIX data for use in quantitative finance, econometric modeling,
#' or machine learning workflows.
#'
#' The pipeline merges market price data with implied volatility data,
#' computes log returns, rolling statistics, cumulative performance metrics,
#' drawdowns, and volatility-related features, and exports both a clean
#' feature matrix and a full Tableau-ready dataset.
#'
#' @details
#' **Key steps performed:**
#'
#' 1. **Data integration**
#'    - Merges `market_data` and `vix_data` on the `DATE` column.
#'    - Ensures chronological ordering for time-series consistency.
#'
#' 2. **Return construction**
#'    - Computes log returns using adjusted close prices:
#'      \deqn{r_t = \log(P_t / P_{t-1})}
#'    - Missing initial returns are replaced with zero to preserve alignment.
#'
#' 3. **Rolling statistics (20-day window)**
#'    - Rolling volatility (standard deviation of log returns)
#'    - Rolling mean return
#'    - Right-aligned to avoid look-ahead bias.
#'
#' 4. **Cumulative performance metrics**
#'    - Cumulative log returns and price-space returns
#'    - Running maximum and drawdown computation
#'
#' 5. **Volatility (VIX) features**
#'    - VIX index level
#'    - Log returns of VIX as a proxy for volatility shocks
#'
#' 6. **Feature matrix construction**
#'    - Selects modeling-relevant features
#'    - Removes rows with insufficient rolling history
#'
#' 7. **Output generation**
#'    - `market_features.csv`: modeling-ready feature matrix
#'    - `tableau_ready.csv`: enriched dataset for visualization
#'
#' @section Look-ahead bias:
#' All rolling computations are explicitly right-aligned to ensure that
#' features at time \eqn{t} depend only on information available at or
#' before \eqn{t}.
#'
#' @dependencies
#' - \pkg{tidyverse}
#' - \pkg{tidyr}
#' - \pkg{zoo}
#'
#' @seealso
#' \itemize{
#'   \item `01_load_clean.R` for data ingestion and preprocessing
#'   \item `zoo::rollapply()` for rolling-window computations
#' }
#'
#' @note
#' This script assumes that `market_data` and `vix_data` are already loaded
#' into the environment and contain a shared `DATE` column.
#'
#' @examples
#' \dontrun{
#' source("02_feature_engineering.R")
#' }
NULL


# -----------------------
# Load cleaned data
# -----------------------

# Source the data loading and cleaning pipeline
source("01_load_clean.R")

library(zoo)
library(tidyr)
library(tidyverse)


# -----------------------
# Merge market and VIX data
# -----------------------

# Combine equity market data with VIX data
# and ensure chronological ordering
df <- left_join(market_data, vix_data, by = "DATE") %>%
  arrange(DATE)


# -----------------------
# Return construction
# -----------------------

# Compute daily log returns using adjusted close prices
# Replace initial missing return with zero for alignment
df <- df %>%
  mutate(
    log_return = log(ADJ_CLOSE / lag(ADJ_CLOSE)),
    log_return = replace_na(log_return, 0)
  )


# -----------------------
# Rolling window parameters
# -----------------------

# Define rolling window length (20 trading days)
window <- 20


# -----------------------
# Feature engineering
# -----------------------

# Construct rolling statistics, cumulative performance,
# drawdowns, and volatility-related features
df <- df %>%
  mutate(
    vol_20 = rollapply(
      log_return, window, sd,
      na.rm = TRUE, fill = NA, align = "right"
    ),
    mean_ret_20 = rollapply(
      log_return, window, mean,
      fill = NA, align = "right"
    ),
    cum_log_return = cumsum(log_return),
    cum_return = exp(cum_log_return),
    running_max = cummax(cum_return),
    drawdown = (cum_return / running_max) - 1,
    VIX_level = VIX_CLOSE,
    VIX_return = replace_na(log(VIX_CLOSE / lag(VIX_CLOSE)), 0)
  )


# -----------------------
# Construct feature matrix
# -----------------------

# Select modeling-relevant features and
# remove rows lacking sufficient rolling history
df_features <- df %>%
  select(
    DATE,
    log_return,
    vol_20,
    mean_ret_20,
    drawdown,
    VIX_level
  ) %>%
  filter(!is.na(vol_20))


# -----------------------
# Save outputs as needed
# -----------------------

# Export modeling-ready feature matrix
# write.csv(
# df_features,
#  "market_features.csv",
#  row.names = FALSE
#)

# Export full dataset for visualization
#write.csv(
#  df,
#  "tableau_ready.csv",
#  row.names = FALSE
#)
