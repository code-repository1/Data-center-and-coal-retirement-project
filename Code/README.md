# Replication code

This directory contains the code used to prepare the analytical data and reproduce the figures and tables for the manuscript and Supplementary Information. The workflow combines Stata, Python and R. Scripts should be run from the project directory described below; the directory containing this README is treated as `Code/` in the project structure.

## Quick reproduction using the released analysis data

The repository provides the analysis-ready dataset `Data/use/gem_coal_plants_multi_record_sa_dce_robust_forR_clean.dta`. This file contains the constructed DCE measures, coal-unit characteristics and matched country-year controls used in the statistical analysis, but does not contain the underlying facility-level S&P Global records. Users can therefore reproduce the principal Cox and AFT analyses without access to the proprietary data-center dataset.

For the shortest route to the main statistical results, place the released file at the path shown above and run `R/cox_main_repository_clean.Rmd` from top to bottom in a clean R session. Run `stata/aft_and_co2_emission_revise.do` first if the unit-level lifetime-extension workbook used by the emissions projections also needs to be regenerated. See `README_QUICK_START.md` for concise instructions and the scope of outputs available through this route.

## 1. Project structure

```text
project-root/
├── Code/
│   ├── stata/
│   ├── python/
│   └── R/
├── Data/
│   ├── raw/       # source data
│   ├── temp/      # intermediate files and model objects
│   └── use/       # analysis-ready data
└── Results/
    ├── Figures/
    └── Tables/
```

The code uses this structure when resolving input and output paths. Python notebooks should be opened from `Code/python/`, the R Markdown file from `Code/R/`, and Stata scripts from `Code/stata/`. The path globals at the beginning of the Stata scripts should be changed to the local `project-root` before execution.

Only the top-level scripts listed in this README are required for reproduction. Development-stage and archived files are not part of the final replication workflow.

## 2. Data availability

The main data-center records are from the S&P Global Capital IQ Pro database, accessed in March 2026, and cannot be redistributed under the data license. Licensed users can access the data through S&P Global Capital IQ Pro and should place the corresponding export in `Data/raw/SPGlobal_Export.xlsx`. The repository includes `Data/raw/SPGlobal_Export_template.xlsx`, an observation-free workbook showing the required sheet and column structure. With the exception of the six researcher-constructed capacity-scenario variables (`capacity1`-`capacity6`), its columns correspond to fields in the original S&P export. Other source files should be placed in `Data/raw/` using the filenames referenced by the scripts.

The principal external inputs are:

- coal-generation-unit records from the Global Coal Plant Tracker;
- data-center property records from S&P Global Capital IQ Pro;
- GADM administrative boundaries (`gadm_410.gpkg`);
- electricity-zone boundaries (`world.geojson`);
- global transmission-grid data used for the grid-distance analysis;
- country-year macroeconomic, electricity-system and climate-policy data;
- the IPCC AR6 Scenarios Database; and
- country and regional coal capacity-factor source data.

The released analysis-ready dataset permits direct reproduction of the downstream statistical analysis. Derived data and plotting-source files are written to `Data/temp/`, `Data/use/` and `Results/Tables/`. The scripts do not download restricted source data automatically.

## 3. Software

The workflow requires:

- **Stata**, with standard survival-analysis commands;
- **R**, with `survival`, `haven`, `dplyr`, `tidyr`, `purrr`, `stringr`, `tibble`, `ggplot2`, `ggtext`, `grid`, `gtable`, `patchwork`, `scales`, `MatchIt` and `cobalt`; and
- **Python 3**, with `pandas`, `numpy`, `matplotlib`, `scipy`, `geopandas`, `shapely`, `pyogrio`, `rasterio`, `statsmodels`, `openpyxl` and `tqdm`.

## 4. Core analytical workflow

Run the following steps in order. The control-data preparation in Step 1 can be run independently, but its output must exist before Step 4.

### Step 1. Prepare country-year controls

Run:

```text
python/controls.ipynb
```

**Inputs:** electricity prices, transmission and distribution losses, Ember yearly electricity data, climate-policy records and net-zero-target data in `Data/raw/`.

**Outputs:**

```text
Data/use/country_year_electricity_policy_controls.dta
```

The `.dta` file is merged into the survival dataset in Step 4.

### Step 2. Construct the multi-record survival dataset

Run:

```text
stata/coal_plant_multirecord.do
```

**Input:** `Data/temp/coal_plants_final.dta`, the prepared Stata-format version of the Global Coal Plant Tracker unit-level dataset.

**Output:** `Data/temp/gem_coal_plants_multi_record_sa_sinceoperating.dta`.

The script retains operating and retired coal units, expands each unit into annual records from commissioning through retirement or 2024, and constructs the event indicator and start-stop survival-time variables (`time0`, `time1` and `retire`).

### Step 3. Calculate data center exposure

Run all cells in:

```text
python/dce_calculate_robust_capacity6_eleczone.ipynb
```

**Main inputs:**

```text
Data/temp/gem_coal_plants_multi_record_sa_sinceoperating.dta
Data/raw/SPGlobal_Export.xlsx
Data/raw/gadm_410.gpkg
Data/raw/world.geojson
```

Because the licensed observations cannot be redistributed, `Data/raw/SPGlobal_Export_template.xlsx` is provided to document the workbook structure required by this notebook. All template columns other than `capacity1`-`capacity6` correspond to fields exported directly from S&P Global Capital IQ Pro; the six capacity variables implement the researcher-defined capacity scenarios described in Supplementary Fig. 10.

**Main output:**

```text
Data/temp/gem_coal_plants_multi_record_sa_dce_robust3.dta
```

The notebook constructs period-specific DCE measures for the 15, 25, 50, 100 and 200 km buffers; GID-1 and GID-2 areas; and electricity zones. It also creates larger- versus other-data-center measures, six capacity-weighted variants, alternative minimum-distance caps, winsorized measures and supporting consistency diagnostics. Its principal metadata outputs are:

```text
Data/temp/dce_robust3_variable_dictionary.csv
Data/temp/dce_robust3_summary_statistics.csv
Data/temp/dce_robust3_larger_other_consistency.csv
Data/temp/dce_robust3_capacity_larger_other_consistency.csv
```

The final cells produce additional distance-cap diagnostics. These are quality-control outputs and are not required to estimate the main models.

### Step 4. Merge controls and create the analysis-ready dataset

Run:

```text
stata/prepared_dataset.do
```

**Main inputs:**

```text
Data/temp/gem_coal_plants_multi_record_sa_dce_robust3.dta
Data/raw/GMD.dta
Data/use/country_year_electricity_policy_controls.dta
```

**Output:**

```text
Data/use/gem_coal_plants_multi_record_sa_dce_robust_forR_clean.dta
```

The script merges GDP and country-year electricity and policy controls, constructs coal characteristics, retains raw and linearly interpolated control variants for sensitivity tests, and creates the completed controls used in the baseline models.

### Step 5. Estimate AFT models and lifetime extensions

Run:

```text
stata/aft_and_co2_emission_revise.do
```

**Input:** `Data/use/gem_coal_plants_multi_record_sa_dce_robust_forR_clean.dta`.

**Main output:**

```text
Data/use/dc_life_extension_retirement_age_25_36_40_50.xlsx
```

The script estimates the Weibull accelerated failure time model, alternative survival-time distributions and clustering specifications. It then calculates unit-level retirement schedules and lifetime extensions under the 25-, 36-, 40- and 50-year lifetime assumptions. The workbook is an input to the emissions calculations in Step 8. The AFT estimates are also used in `R/cox_main_repository_clean.Rmd` for Main Fig. 5a, Supplementary Fig. 15 and Supplementary Table 11.

### Step 6. Estimate Cox models and generate statistical results

Render or run all chunks in:

```text
R/cox_main_repository_clean.Rmd
```

**Input:** `Data/use/gem_coal_plants_multi_record_sa_dce_robust_forR_clean.dta`.

This is the principal analysis file. It estimates the baseline and sensitivity Cox models, marginal survival curves, scale and timing analyses, heterogeneity models, regional and leave-one-country-out analyses, AFT comparison plots, placebo permutations and propensity-score-matched models. It writes model objects to `Data/temp/`, table-source files to `Results/Tables/` and figures to `Results/Figures/`.

Because several sections depend on objects created in earlier chunks, the Rmd should be executed from top to bottom in a clean R session.

### Step 7. Construct capacity-factor pathways

Run:

```text
python/CF_scenario.ipynb
```

**Inputs:**

```text
Data/raw/AR6_Scenarios_Database_World_v1.1.csv
Data/raw/AR6_Scenarios_Database_metadata_indicators_v1.1.xlsx
```

**Outputs:**

```text
Results/Tables/CF_trend.csv
Results/Figures/CF_trends_nature_style.svg
```

The notebook derives coal capacity-factor pathways from the IPCC AR6 scenario database for scenarios limiting warming to 2 °C, limiting warming to 3 °C and exceeding 3 °C. Values after 2100 are held at their 2100 levels in the emissions projections.

### Step 8. Calculate projected emissions and sensitivity ranges

After Steps 5 and 7, run:

```text
python/emission_sensitivity.ipynb
```

**Main inputs:**

```text
Data/use/dc_life_extension_retirement_age_25_36_40_50.xlsx
Data/raw/Global-Coal-Plant-Tracker-January-2025-cf.xlsx
Data/raw/Capacity_factor.xlsx
Results/Tables/CF_trend.csv
```

**Main outputs:**

```text
Results/Tables/emissions_life<lifetime>_<scenario>.csv
Results/Tables/summary_all_scenarios.csv
Results/Figures/Scenario_single_life40_Limit_to_3C.svg
Results/Figures/Scenarios_12_compact.svg
Results/Figures/Scenarios_summary_nature_style.svg
```

The notebook calculates annual baseline and additional emissions for every combination of four lifetime assumptions and three capacity-factor pathways, then produces the baseline projection and the two emissions-sensitivity figures.

## 5. Descriptive and spatial figures

These notebooks are independent of the Cox-model sequence once their stated inputs are available.

### Main Figs. 1 and 2 and Supplementary Figs. 1 and 2

Run:

```text
python/Figure1&2_revise.ipynb
```

The notebook reads the S&P data-center export and Global Energy Monitor coal, gas, solar and wind datasets. It produces the country map, annual commissioning and facility-type panels for Main Fig. 1 and Supplementary Fig. 1; the limited-sample property-size analysis for Supplementary Fig. 2; and the distance and accessible-capacity panels for Main Fig. 2.

Principal figure components are:

```text
Results/Figures/fig1a_datacenter_heatmap.pdf
Results/Figures/fig1b_datacenter_yearly_stacked_era_clean.pdf
Results/Figures/fig1b_datacenter_type_donuts.pdf
Results/Figures/fig1b_datacenter_property_size_bubble_limited_sample_log_trend_sig.pdf
Results/Figures/fig2a.pdf
Results/Figures/fig2b.pdf
```

The final manuscript figures combine these panel files without changing the underlying plotted values.

### Supplementary Fig. 3: data centers and grid infrastructure

Run:

```text
python/data_center_grid_distance_distribution.ipynb
```

**Inputs:** `Data/raw/SPGlobal_Export.xlsx` and the global grid-line dataset stored under `Data/raw/grid/`.

**Outputs:**

```text
Data/temp/data_center_nearest_grid_distance.csv
Results/Figures/global_data_centers_and_recorded_grid_lines.svg
Results/Figures/data_center_distance_to_grid_distribution.svg
```

The two SVG files provide the map and distribution panels assembled as Supplementary Fig. 3. The cached distance file avoids repeating the global nearest-line calculation.

### Supplementary Tables 1 and 2 and Supplementary Fig. 4

Run after Step 4:

```text
python/descriptive.ipynb
```

**Input:** `Data/use/gem_coal_plants_multi_record_sa_dce_robust_forR_clean.dta`.

**Outputs:**

```text
Results/Tables/descriptive_dce_summary_statistics.csv
Results/Tables/descriptive_unit_and_raw_control_summary_statistics.csv
Results/Tables/descriptive_dce_functional_form_nonzero_summary.csv
Results/Figures/descriptive_dce_functional_form_nonzero_density.svg
```

The first two CSV files underlie Supplementary Tables 1 and 2. The SVG is Supplementary Fig. 4. Summary tables retain the full data distribution; only the displayed density range is restricted to the pooled 99th percentile for readability.

`python/dce_distribution_diagnostics.ipynb` provides additional DCE and nearest-data-center diagnostics used for internal validation but not required for the final numbered figures or tables.

## 6. Figure and table crosswalk

### Main manuscript

| Item | Code | Principal output |
|---|---|---|
| Fig. 1 | `python/Figure1&2_revise.ipynb` | `fig1a_datacenter_heatmap.pdf`; annual/type panel files |
| Fig. 2 | `python/Figure1&2_revise.ipynb` | `fig2a.pdf`; `fig2b.pdf` |
| Fig. 3a | `R/cox_main_repository_clean.Rmd` | `fig3a.pdf` / `fig3a.tif` |
| Fig. 3b | `R/cox_main_repository_clean.Rmd` | `fig3b.pdf`; `main_fig3b_survival_data.csv` |
| Fig. 3c | `R/cox_main_repository_clean.Rmd` | `main_fig3c_scale_period.pdf` / `.tif` |
| Fig. 4a-c | `R/cox_main_repository_clean.Rmd` | `fig4a.pdf`; `fig4b.pdf`; `fig4c.pdf` |
| Fig. 5a | `stata/aft_and_co2_emission_revise.do`; `R/cox_main_repository_clean.Rmd` | `fig5a.pdf` |
| Fig. 5b | `stata/aft_and_co2_emission_revise.do`; `python/CF_scenario.ipynb`; `python/emission_sensitivity.ipynb` | `Scenario_single_life40_Limit_to_3C.svg` |

### Supplementary figures

| Item | Code | Principal output |
|---|---|---|
| Fig. 1 | `python/Figure1&2_revise.ipynb` | Fig. 1 component files |
| Fig. 2 | `python/Figure1&2_revise.ipynb` | `fig1b_datacenter_property_size_bubble_limited_sample_log_trend_sig.pdf` |
| Fig. 3 | `python/data_center_grid_distance_distribution.ipynb` | grid map and distance-distribution SVGs |
| Fig. 4 | `python/descriptive.ipynb` | `descriptive_dce_functional_form_nonzero_density.svg` |
| Fig. 5 | `R/cox_main_repository_clean.Rmd` | `sup_fig05_robustness_forest.pdf` / `.tif` |
| Fig. 6 | `R/cox_main_repository_clean.Rmd` | `sup_fig06_survivor2020.pdf` |
| Fig. 7 | `R/cox_main_repository_clean.Rmd` | `sup_fig07_random_dce_placebo.pdf` |
| Fig. 8 | `R/cox_main_repository_clean.Rmd` | `sup_fig08_psm_balance.pdf`; `sup_fig08_psm_forest.pdf` |
| Fig. 9 | `R/cox_main_repository_clean.Rmd` | `sup_fig09_pooled_period.pdf` / `.tif` |
| Fig. 10 | `R/cox_main_repository_clean.Rmd` | `sup_fig10_capacity_sensitivity.pdf` / `.tif` |
| Fig. 11 | `R/cox_main_repository_clean.Rmd` | `sup_fig11a_cutoff_sensitivity.pdf`; `sup_fig11b_timing_comparison.pdf` |
| Fig. 12 | `R/cox_main_repository_clean.Rmd` | `sup_fig12_larger_definition.pdf` / `.tif` |
| Fig. 13 | `R/cox_main_repository_clean.Rmd` | `sup_fig13_region_25km.pdf` / `.tif` |
| Fig. 14 | `R/cox_main_repository_clean.Rmd` | `sup_fig14_loco_25km.pdf` |
| Fig. 15 | `stata/aft_and_co2_emission_revise.do`; `R/cox_main_repository_clean.Rmd` | `sup_fig15_aft_distribution.pdf` / `.tif` |
| Fig. 16 | `python/CF_scenario.ipynb` | `CF_trends_nature_style.svg` |
| Fig. 17 | `python/emission_sensitivity.ipynb` | `Scenarios_12_compact.svg` |
| Fig. 18 | `python/emission_sensitivity.ipynb` | `Scenarios_summary_nature_style.svg` |

### Supplementary tables

| Item | Code | Principal source output |
|---|---|---|
| Table 1 | `python/descriptive.ipynb` | `descriptive_dce_summary_statistics.csv` |
| Table 2 | `python/descriptive.ipynb` | `descriptive_unit_and_raw_control_summary_statistics.csv` |
| Table 3 | `R/cox_main_repository_clean.Rmd` | `sup_table03_baseline_cox_source.csv` |
| Table 4 | `R/cox_main_repository_clean.Rmd` | `sup_table04_time_dependent_cox_source.csv` |
| Table 5 | `python/cement_and_concrete_calculate.ipynb`; `stata/placebo_cement_data_prep.do`; `R/cox_cement_placebo.Rmd` | `sup_table05_cement_placebo_source.csv` |
| Table 6 | `R/cox_main_repository_clean.Rmd` | `sup_table06_survival_probabilities_source.csv` |
| Table 7 | `R/cox_main_repository_clean.Rmd` | `main_fig3c_scale_period_results.csv` |
| Table 8 | `R/cox_main_repository_clean.Rmd` | `sup_table08_co2_heat_interactions_source.csv` |
| Table 9 | `R/cox_main_repository_clean.Rmd` | `sup_table09_coal_type_interactions_source.csv` |
| Table 10 | `R/cox_main_repository_clean.Rmd` | `sup_table10_hete_cluster.csv` |
| Table 11 | `stata/aft_and_co2_emission_revise.do`; `R/cox_main_repository_clean.Rmd` | `sup_table11_aft_lifetime_source.csv` |
| Table 12 | `R/cox_main_repository_clean.Rmd` | `sup_table12_schoenfeld_source.csv` |
| Table 13 | `python/emission_sensitivity.ipynb` and `Data/raw/Capacity_factor.xlsx` | country/region capacity-factor inputs reported in the SI |

Supplementary Table 5 uses a dedicated three-step placebo workflow:

1. Run `python/cement_and_concrete_calculate.ipynb` to calculate coal-unit exposure to cement and concrete facilities and create `Data/temp/gem_coal_sa_prox_exp_with_placebo.dta`.
2. Run `stata/placebo_cement_data_prep.do` to merge controls and create `Data/use/forR_placebo_cement.dta`.
3. Run `R/cox_cement_placebo.Rmd` to estimate the placebo Cox model and write `Results/Tables/sup_table05_cement_placebo_source.csv`.

Supplementary Table 10 is generated within the `interaction cluster sensitivity` section of `R/cox_main_repository_clean.Rmd`. This section re-estimates the CO2-intensity and heat-rate interaction models with standard errors clustered by generation unit, plant, GID-2, GID-1 and GID-0, and writes `Results/Tables/sup_table10_hete_cluster.csv`. No separate figure is required for this analysis.

## 7. Output assembly and reproducibility notes

- Several manuscript figures are assembled from separately exported vector panels. Assembly changes layout only; numerical values are taken directly from the listed source outputs.
- Existing output files may be overwritten when scripts are rerun.
- Intermediate `.rds`, `.dta` and `.csv` files are retained to separate estimation from plotting and to facilitate verification of reported values.
- The capacity-sensitivity models use the six capacity variables already present in the S&P `Sheet1` data; no additional capacity merge is required.
- The electricity-zone DCE variables are generated from `Data/raw/world.geojson`; the administrative-boundary variables use `Data/raw/gadm_410.gpkg`.
- A clean end-to-end run should begin with empty `Data/temp/`, `Data/use/`, `Results/Figures/` and `Results/Tables/` directories while preserving all required files in `Data/raw/`.
