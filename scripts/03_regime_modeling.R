#' 03: Regime Modeling via Gaussian Mixture Models (GMM)
#'
#' @description
#' This script identifies persistent market regimes using Gaussian
#' Mixture Models applied to equity market and volatility features.
#' It assigns regimes probabilistically, applies temporal smoothing,
#' enforces minimum regime durations, and labels regimes with
#' economic interpretations (Bull, Bear, Neutral). The resulting
#' dataset is ready for analysis, visualization, and computation of
#' regime transition probabilities.
#'
#' @details
#' **Key steps performed:**
#'
#' 1. **Feature selection**
#'    - Selects relevant features from `df_features`:
#'      `log_return`, `vol_20`, `mean_ret_20`, `drawdown`, `VIX_level`.
#'    - Removes rows with missing values to ensure complete cases for clustering.
#'
#' 2. **Feature scaling**
#'    - Standardizes features using z-score scaling to normalize magnitudes.
#'
#' 3. **Gaussian Mixture Model (GMM) fitting**
#'    - Fits GMM using 2–4 components and model types "EEE" and "VEE".
#'    - Produces cluster probabilities (`z`) and most-likely cluster assignment.
#'
#' 4. **Confidence-based assignment**
#'    - Assigns a regime only if the maximum probability ≥ 0.6.
#'    - Low-confidence points temporarily marked as `NA`.
#'
#' 5. **Temporal smoothing**
#'    - Forward- and backward-fills short gaps (`na.locf`).
#'    - Enforces a minimum regime duration (`min_len`) to remove spurious switches.
#'
#' 6. **Mapping regimes to full timeline**
#'    - Aligns smoothed regimes with original `df_features` rows.
#'    - Optional final fill ensures continuity for plotting and analysis.
#'
#' 7. **Regime characterization**
#'    - Computes per-regime statistics: mean return, volatility (`vol_20`),
#'      average drawdown, and average VIX level.
#'
#' 8. **Economic relabeling**
#'    - Labels regimes as "Bull", "Bear", or "Neutral" based on
#'      mean return and volatility relative to the median.
#'
#' 9. **Transition matrix computation**
#'    - Computes empirical probabilities of transitioning between economic regimes.
#'
#' @section Notes:
#' - Temporal smoothing is applied manually; this is **not** an HMM.
#' - Confidence threshold and minimum regime duration are adjustable.
#'
#' @dependencies
#' - \pkg{mclust} for Gaussian Mixture Model fitting
#' - \pkg{dplyr} for data manipulation
#' - \pkg{zoo} for forward/backward filling (`na.locf`)
#' - \pkg{data.table} for efficient run-length operations
#'
#' @seealso
#' \itemize{
#'   \item `02_feature_engineering.R` for feature construction
#'   \item `mclust::Mclust()` for GMM modeling
#'   \item `zoo::na.locf()` for temporal smoothing
#'   \item `data.table::rleid()` for identifying contiguous regime segments
#' }
#'
#' @examples
#' \dontrun{
#' source("03_regime_modeling.R")
#' head(df_regimes)           # View regime-labeled data
#' transition_matrix          # Inspect regime transitions
#' }
NULL

# -----------------------
# Load feature-engineered data
# -----------------------
source("02_feature_engineering.R")

# Load required libraries
library(mclust)      # Gaussian Mixture Models
library(dplyr)       # Data manipulation
library(zoo)         # Time-series operations (na.locf)
library(data.table)  # Efficient run-length encoding operations

# -----------------------
# Feature selection
# -----------------------
# Select only the relevant features for regime clustering
cluster_data <- df_features %>%
  select(
    log_return,   # Daily log returns
    vol_20,       # 20-day rolling volatility
    mean_ret_20,  # 20-day rolling mean return
    drawdown,     # Running drawdown
    VIX_level     # VIX index level
  )

# Identify rows with complete cases only
# Necessary because GMM cannot handle missing values
valid_idx <- which(complete.cases(cluster_data))
cluster_data_clean <- cluster_data[valid_idx, ]

# -----------------------
# Feature scaling
# -----------------------
# Standardize features to have mean 0, SD 1
# Prevents variables with larger scale from dominating the clustering
x_scaled <- scale(cluster_data_clean)

# -----------------------
# Gaussian Mixture Model fitting
# -----------------------
# Fit GMM using 2-4 components and selected covariance models
gmm_model <- Mclust(
  x_scaled,
  G = 2:4,
  modelNames = c("EEE", "VEE")
)

# Print model summary (for diagnostic purposes)
summary(gmm_model)

# -----------------------
# Probabilistic regime assignment
# -----------------------
# Extract posterior probabilities for each component
regime_probs <- gmm_model$z

# Maximum probability for each observation
max_prob <- apply(regime_probs, 1, max)

# Assign regime only if confidence ≥ 0.6, else NA
regime_raw <- ifelse(
  max_prob >= 0.60,
  gmm_model$classification,
  NA_real_
)

# -----------------------
# Temporal smoothing
# -----------------------
# Forward-fill missing regimes
regime_smooth <- na.locf(regime_raw, na.rm = FALSE)
# Backward-fill remaining NAs
regime_smooth <- na.locf(regime_smooth, fromLast = TRUE)

# Enforce minimum regime duration to avoid spurious switches
min_len <- 10
regime_dt <- data.table(regime = as.numeric(regime_smooth))
regime_dt[
  ,
  regime := if (.N < min_len) as.numeric(NA) else regime,
  by = rleid(regime)
]

# Forward-fill NAs again after enforcing minimum length
regime_final <- na.locf(regime_dt$regime, na.rm = FALSE)

# -----------------------
# Map regimes back to full timeline
# -----------------------
regime_full <- rep(NA_real_, nrow(df_features))
regime_full[valid_idx] <- regime_final

# -----------------------
# Attach regimes to feature dataset
# -----------------------
df_regimes <- df_features %>%
  mutate(regime = regime_full)

# Optional final fill for continuity (useful for plotting)
df_regimes <- df_regimes %>%
  mutate(regime = na.locf(regime, na.rm = FALSE)) %>%
  mutate(regime = na.locf(regime, fromLast = TRUE))

# -----------------------
# Regime characterization
# -----------------------
# Compute mean return, volatility, drawdown, and VIX per regime
regime_summary <- df_regimes %>%
  group_by(regime) %>%
  summarise(
    mean_return = mean(log_return, na.rm = TRUE),
    vol = mean(vol_20, na.rm = TRUE),
    avg_drawdown = mean(drawdown, na.rm = TRUE),
    avg_vix = mean(VIX_level, na.rm = TRUE),
    .groups = "drop"
  )

# -----------------------
# Economic relabeling of regimes
# -----------------------
# Label regimes as Bull, Bear, or Neutral based on mean return & volatility
regime_summary <- regime_summary %>%
  mutate(
    econ_regime = case_when(
      mean_return > 0 & vol < median(vol, na.rm = TRUE) ~ "Bull",
      mean_return < 0 & vol > median(vol, na.rm = TRUE) ~ "Bear",
      TRUE ~ "Neutral"
    )
  )

# Merge economic labels back into main dataset
df_regimes <- df_regimes %>%
  left_join(
    regime_summary %>% select(regime, econ_regime),
    by = "regime"
  )

# -----------------------
# Compute regime transition matrix
# -----------------------
# Counts transitions between consecutive economic regimes
transitions <- table(
  df_regimes$econ_regime[-nrow(df_regimes)],
  df_regimes$econ_regime[-1]
)

# Convert to row-normalized probabilities
transition_matrix <- prop.table(transitions, 1)

# -----------------------
# Save outputs as needed
# -----------------------
# Uncomment to export data
# write.csv(
#   df_regimes,
#   "regime_labeled_data.csv",
#   row.names = FALSE
# )
# write.csv(
#   transition_matrix,
#   "regime_transition_matrix.csv"
# )
