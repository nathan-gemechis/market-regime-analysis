#' 05: Out-of-Sample Validation & Tableau Export
#'
#' @description
#' This script evaluates the stability and performance of market regimes
#' previously identified in `04_regime_analysis.R` using a temporal
#' train–test split. It computes regime-level statistics, simulates a
#' simple regime-based strategy in the out-of-sample period, and
#' calculates regime transition probabilities for the test set. The
#' outputs are prepared for further analysis or Tableau visualization.
#'
#' @details
#' **Key steps performed:**
#'
#' 1. **Train–test split**
#'    - Splits `df_regimes` based on a specified `split_date`.
#'    - Labels observations as "Train" or "Test".
#'
#' 2. **Regime-level comparison**
#'    - Aggregates mean return, volatility, average drawdown, and
#'      observation counts for each regime in both train and test samples.
#'
#' 3. **Out-of-sample strategy simulation**
#'    - Simulates a simple trading strategy: invest during Bull regimes,
#'      otherwise cash (zero return).
#'    - Computes cumulative strategy returns for the test period.
#'
#' 4. **Regime transitions (OOS)**
#'    - Calculates empirical transition counts and probabilities
#'      for consecutive regimes in the test set.
#'
#' 5. **Export for further analysis**
#'    - Prepares datasets for Tableau or other visualization/analysis tools.
#'
#' @dependencies
#' - \pkg{dplyr} for data manipulation
#'
#' @seealso
#' \itemize{
#'   \item `04_regime_analysis.R` for enriched regime-labeled data
#'   \item `dplyr::group_by()` and `summarise()` for per-regime statistics
#'   \item `prop.table()` for calculating transition probabilities
#' }
#'
#' @examples
#' \dontrun{
#' source("05_out_of_sample_validation.R")
#' head(df_oos)               # Inspect train/test combined dataset
#' regime_comparison           # View train vs. test regime metrics
#' oos_transition_probs        # Inspect out-of-sample regime transitions
#' }
NULL

# -----------------------
# Load regime-labeled data
# -----------------------
source("04_regime_analysis.R")

# Load required libraries
library(dplyr)

# -----------------------
# Train–test split
# -----------------------
# Define the temporal split date for out-of-sample validation
split_date <- as.Date("2023-01-05")

# Split the dataset into training and test periods
train <- df_regimes %>% filter(DATE < split_date)
test  <- df_regimes %>% filter(DATE >= split_date)

# Label each observation as Train or Test
train$sample <- "Train"
test$sample  <- "Test"

# Combine train and test for convenience
df_oos <- bind_rows(train, test)

# -----------------------
# Regime-level comparison
# -----------------------
# Compute regime statistics for train and test periods
regime_comparison <- df_oos %>%
  group_by(sample, econ_regime) %>%
  summarise(
    mean_return = mean(log_return, na.rm = TRUE),
    vol = mean(vol_20, na.rm = TRUE),
    avg_drawdown = mean(drawdown, na.rm = TRUE),
    n_obs = n(),   # Number of observations per regime
    .groups = "drop"
  )

# -----------------------
# Strategy simulation (OOS only)
# -----------------------
# Simple strategy: invest during Bull regimes only
test <- test %>%
  mutate(
    strategy_return = ifelse(econ_regime == "Bull", log_return, 0),
    cum_strategy = exp(cumsum(strategy_return))   # cumulative return
  )

# -----------------------
# Regime transitions (OOS)
# -----------------------
# Compute the number of transitions between consecutive regimes
oos_transitions <- table(
  test$econ_regime[-nrow(test)],
  test$econ_regime[-1]
)

# Convert counts to row-normalized transition probabilities
oos_transition_probs <- prop.table(oos_transitions, 1)

# -----------------------
# Save outputs for further analysis
# -----------------------
# Uncomment to export datasets
# write.csv(
#   df_oos,
#   "out_of_sample_regimes.csv",
#   row.names = FALSE
# )
# write.csv(
#   regime_comparison,
#   "oos_regime_comparison.csv",
#   row.names = FALSE
# )
# write.csv(
#   oos_transition_probs,
#   "oos_transition_matrix.csv"
# )
