#' Master Pipeline: End-to-End Market Regime Analysis
#'
#' @description
#' This script serves as the main execution pipeline for the full
#' market regime analysis project.
#'
#' It sequentially sources all component scripts required to load
#' and clean data, engineer features, identify market regimes,
#' validate regime behavior, and produce out-of-sample results
#' suitable for visualization and analysis.
#'
#' Running this script reproduces the complete analysis from raw
#' data ingestion through final exported outputs.
#'
#' @details
#' **Execution order:**
#'
#' 1. `01_load_clean.R` – Data ingestion and preprocessing
#' 2. `02_feature_engineering.R` – Feature construction
#' 3. `03_regime_clustering.R` – Regime identification
#' 4. `04_regime_analysis.R` – Regime validation and diagnostics
#' 5. `05_out_of_sample_validation.R` – Out-of-sample testing and export
#'
#' @section Reproducibility:
#' This script clears the workspace before execution to ensure
#' results are fully reproducible and free from residual objects.
#'
#' @note
#' This script is intended to be run as a top-level entry point
#' and does not return objects directly.
#'
#' @examples
#' \dontrun{
#' source("master_pipeline.R")
#' }
NULL

# -----------------------
# Initialize clean session
# -----------------------

rm(list = ls())

# garbage collection
gc()


# -----------------------
# Execute full analysis pipeline
# -----------------------

# Load and clean raw market data
source("01_load_clean.R")

# Construct modeling-ready features
source("02_feature_engineering.R")

# Identify latent market regimes
source("03_regime_modeling.R")

# Validate regime behavior and risk characteristics
source("04_regime_analysis.R")

# Perform out-of-sample validation and export results
source("05_out_of_sample_validation.R")
