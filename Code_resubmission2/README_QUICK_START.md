# Quick start

This guide gives the shortest route to the principal statistical outputs using the analysis-ready dataset.

## Required file

Place the released analysis-ready dataset at:

```text
Data/use/gem_coal_plants_multi_record_sa_dce_robust_forR_clean.dta
```

Create the following directories if needed:

```text
Data/temp/
Results/Figures/
Results/Tables/
```

## Reproduce the main Cox-model results

1. Open `Code/R/cox_main.Rmd` from `Code/R/`.
2. Confirm that the project-root detection in the setup section resolves to the local repository.
3. Start a clean R session and run the Rmd from top to bottom.

This reproduces Main Figs. 3-5, Extended Data Fig. 1, Supplementary Figs. 5-14, and the Cox-model-based Supplementary Tables. Required R packages are loaded or listed in the Rmd.

## Reproduce the U.S. generation mechanism table

Extended Data Table 1 is a separate, newly added analysis. Run the following in order:

```text
Code/python/build_eia_state_controls_2001_2024.ipynb
Code/python/build_eia_coal_generation_mechanism_2001_2024.ipynb
Code/stata/eia_coal_generation_mechanism_regressions.do
```

The first two scripts prepare state-year controls and the EIA 2001-2024 coal-plant panel. The Stata script estimates the plant and year fixed-effects models and writes `Results/Tables/sup_table_eia_coal_generation_mechanism.rtf`.

## Reproduce the emissions figures

For Extended Data Figs. 2-4, run:

```text
Code/stata/aft_and_co2_emission.do
Code/python/CF_scenario.ipynb
Code/python/emission_sensitivity.ipynb
```

## Scope

Main Figs. 1-2 and Supplementary Figs. 1-4 require the corresponding Python notebooks and, where applicable, the proprietary source data. `README.md` provides the full raw-data workflow and figure-by-figure crosswalk.
