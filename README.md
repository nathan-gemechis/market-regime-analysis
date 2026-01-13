# Market Regime Analysis Pipeline

End-to-end analysis of equity market regimes using Gaussian Mixture Models, risk metrics, and a regime-based trading strategy.

## Overview

This project provides a modular, reproducible pipeline to identify, validate, and analyze persistent market regimes in equity and volatility data. The workflow includes feature engineering, probabilistic clustering, temporal smoothing, risk/return validation, and a simple regime-based trading strategy, with outputs ready for visualization and analysis.

## Key Highlights

- Feature engineering of market returns and VIX
- Regime detection using Gaussian Mixture Models (GMM)
- Confidence-based and temporally smoothed regime assignment
- Validation of regime behavior: risk, returns, and durations
- Simulation of a simple regime-based trading strategy
- Out-of-sample testing to assess regime stability

## Repository Structure
- Data
- Outputs
- Scripts
- 01_load_clean.R
- 02_feature_engineering.R
- 03_regime_modeling.R
- 04_regime_analysis.R
- 05_out_of_sample_validation.R
- master_pipeline.R


## Execution Pipeline

The analysis is organized into five main scripts, which are sequentially sourced by `master_pipeline.R`:

1. **`01_load_clean.R`** – Load raw market and VIX data, perform preprocessing.
2. **`02_feature_engineering.R`** – Compute returns, rolling statistics, drawdowns, and construct the feature matrix.
3. **`03_regime_modeling.R`** – Identify latent market regimes using Gaussian Mixture Models, confidence filtering, and temporal smoothing.
4. **`04_regime_analysis.R`** – Validate regime behavior with risk/return statistics, regime durations, and strategy simulation.
5. **`05_out_of_sample_validation.R`** – Conduct out-of-sample testing, compare train/test regimes, and compute transition probabilities.

Running `master_pipeline.R` executes the full analysis end-to-end, ensuring reproducibility.

## Dependencies

The R scripts use the following packages:

- **dplyr** – data manipulation
- **tidyr** – data wrangling
- **zoo** – rolling calculations
- **mclust** – Gaussian Mixture Models
- **data.table** – efficient operations and run-length encoding
- **moments** – skewness calculations

## Installation

```r
# Install required packages
install.packages(c("dplyr", "tidyr", "zoo", "mclust", "data.table", "moments"))
```

## How to Run
- Place all scripts, market_data.xlsx, and vix_history.csv in the same directory
- Open R and source master_pipeline.R
- This runs the full pipeline and produces outputs
