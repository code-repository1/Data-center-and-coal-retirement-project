# Quick reproduction of the statistical results

This guide provides the shortest route to the principal statistical results using the released analysis-ready dataset. It does not require access to the underlying facility-level S&P Global Capital IQ Pro records.

## Required file

Place the released dataset at:

```text
Data/use/gem_coal_plants_multi_record_sa_dce_robust_forR_clean.dta
```

The dataset contains the multi-record coal-unit survival sample, constructed DCE variables, coal-unit characteristics and matched country-year controls used by the statistical models.

## Directory structure

```text
project-root/
├── Code/
│   ├── R/cox_main_repository_clean.Rmd
│   └── stata/aft_and_co2_emission_revise.do
├── Data/
│   ├── temp/
│   └── use/
│       └── gem_coal_plants_multi_record_sa_dce_robust_forR_clean.dta
└── Results/
    ├── Figures/
    └── Tables/
```

Create the empty output directories if they are not already present.

## Reproduce the Cox-model results

1. Open `Code/R/cox_main_repository_clean.Rmd` from `Code/R/`.
2. Confirm that the project-root path in the setup section points to the local repository.
3. Start a clean R session and run the Rmd from top to bottom.

Required R packages are `survival`, `haven`, `dplyr`, `tidyr`, `purrr`, `stringr`, `tibble`, `ggplot2`, `ggtext`, `grid`, `gtable`, `patchwork`, `scales`, `MatchIt` and `cobalt`.

This step reproduces the baseline Cox estimates and the associated sensitivity, survival-curve, scale, timing, heterogeneity, regional, leave-one-country-out, permutation-placebo and propensity-score-matching analyses. It generates Main Figs. 3 and 4, Main Fig. 5a, and the corresponding numbered Supplementary Figures and Tables listed in the full `README.md`.

## Reproduce the AFT estimates and lifetime-extension data

Run:

```text
Code/stata/aft_and_co2_emission_revise.do
```

After setting its project-root globals, the script reads the same analysis-ready `.dta` file and writes:

```text
Data/use/dc_life_extension_retirement_age_25_36_40_50.xlsx
```

This workbook contains the unit-level retirement schedules and lifetime extensions used by the emissions-sensitivity analysis.

## Scope

The released `.dta` file begins after construction of the proprietary data-center exposure measures. It therefore supports direct reproduction of the downstream statistical models but not reconstruction of the facility-level S&P data, Main Fig. 1, or the data-center mapping and distance calculations. The complete data-construction workflow, required input structure and figure-by-figure crosswalk are documented in `README.md`. Plotting-source data supplied in `Results/Tables/` can be used to reproduce the corresponding published visualizations without access to the proprietary facility records.
