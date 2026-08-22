# Replication code

This directory contains the code used to reproduce the analyses, figures and tables for the article "Early evidence links data center exposure to coal power retirement timelines". The workflow combines Python, R and Stata. The directory containing this README is treated as `Code/` in the project structure.

## Project structure

```text
project-root/
|- Code/
|  |- python/
|  |- R/
|  `- stata/
|- Data/
|  |- raw/
|  |- temp/
|  `- use/
`- Results/
   |- Figures/
   `- Tables/
```

Run Python notebooks from `Code/python/`, R Markdown files from `Code/R/`, and Stata scripts from `Code/stata/`. Ensure that the project-root paths defined at the beginning of each script point to the local repository.

## Analysis-ready data

The released analysis-ready dataset is:

```text
Data/use/gem_coal_plants_multi_record_sa_dce_robust_forR_clean.dta
```

It contains the multi-record coal-unit survival sample, constructed data-center exposure (DCE) variables, plant characteristics and country-year controls required for the downstream Cox and AFT analyses. It does not include the underlying facility-level S&P Global Capital IQ Pro records, which cannot be redistributed under the data license.

## Full workflow from raw inputs

Users with access to the required raw inputs should run the following core preparation steps in order:

```text
python/controls.ipynb
stata/coal_plant_multirecord.do
python/dce_calculate_robust_capacity6_eleczone.ipynb
stata/prepared_dataset.do
```

These scripts prepare country-year electricity and policy controls; create the annual coal-unit survival records; calculate the period-specific DCE measures and their robustness variants; and merge all controls into the analysis-ready dataset used below. Raw inputs are read from `Data/raw/`, intermediate files are written to `Data/temp/`, and the final analysis-ready dataset is written to `Data/use/`.

The global facility-level data-center records are from S&P Global Capital IQ Pro and must be supplied by licensed users as `Data/raw/SPGlobal_Export.xlsx`. Other raw files are referenced by filename within the scripts.

## Core analysis

Run the following file from top to bottom in a clean R session:

```text
R/cox_main.Rmd
```

This is the principal statistical analysis file. It generates Main Figs. 3-5; Extended Data Fig. 1; Supplementary Figs. 5-14; and the Cox-model-based Supplementary Tables. It writes intermediate model objects to `Data/temp/`, figures to `Results/Figures/` and table-source files to `Results/Tables/`.

Several sections depend on objects generated in earlier chunks. The Rmd should therefore be run sequentially from the beginning.

## U.S. EIA mechanism analysis

Extended Data Table 1 provides plant-year evidence on U.S. coal-fired generation. Run these files in order:

```text
python/build_eia_state_controls_2001_2024.ipynb
python/build_eia_coal_generation_mechanism_2001_2024.ipynb
stata/eia_coal_generation_mechanism_regressions.do
```

The first notebook creates state-year electricity and economic controls. The second constructs the 2001-2024 U.S. coal-plant panel from EIA Form 860 and plant-fuel generation records from EIA Form 906/920 and Form 923, merges DCE measures and writes:

```text
Data/temp/eia_coal_plant_year_generation_mechanism_2001_2024_dce_controls.dta
```

The Stata script estimates the fixed-effects regressions and writes the source table:

```text
Results/Tables/sup_table_eia_coal_generation_mechanism.rtf
```

## Emissions projections

The emissions projections require the AFT lifetime-extension output and the AR6-derived coal capacity-factor pathways. Run:

```text
stata/aft_and_co2_emission.do
python/CF_scenario.ipynb
python/emission_sensitivity.ipynb
```

These scripts generate Extended Data Fig. 2 and Extended Data Figs. 3-4, together with their plotting-source tables.

## Figure and table crosswalk

### Main figures

| Item | Code |
|---|---|
| Figs. 1-2 | `python/Figure1&2.ipynb` |
| Figs. 3-5 | `R/cox_main.Rmd` |

### Extended Data

| Item | Code |
|---|---|
| Extended Data Fig. 1 | `R/cox_main.Rmd` |
| Extended Data Fig. 2 | `python/CF_scenario.ipynb` |
| Extended Data Figs. 3-4 | `python/emission_sensitivity.ipynb` |
| Extended Data Table 1 | `python/build_eia_state_controls_2001_2024.ipynb`; `python/build_eia_coal_generation_mechanism_2001_2024.ipynb`; `stata/eia_coal_generation_mechanism_regressions.do` |

### Supplementary figures

| Item | Code |
|---|---|
| Supplementary Fig. 1 | `python/SI_figure1.ipynb` |
| Supplementary Fig. 2 | `python/Figure1&2.ipynb` |
| Supplementary Fig. 3 | `python/data_center_grid_distance_distribution.ipynb` |
| Supplementary Fig. 4 | `python/descriptive.ipynb` |
| Supplementary Figs. 5-14 | `R/cox_main.Rmd` |

### Supplementary tables

| Item | Code or source |
|---|---|
| Supplementary Table 1 | `python/descriptive.ipynb` |
| Supplementary Tables 2-3 | `R/cox_main.Rmd` |
| Supplementary Table 4 | `python/cement_and_concrete_calculate.ipynb`; `stata/placebo_cement_data_prep`;  `R/cox_cement_placebo.Rmd` |
| Supplementary Tables 5-9 | `R/cox_main.Rmd` |
| Supplementary Table 10 | `stata/aft_and_co2_emission.do` |
| Supplementary Table 11 | Author compilation from public sources |
| Supplementary Table 12 | `R/cox_main.Rmd` |
| Supplementary Table 13 | Author compilation from public sources |


## Reproducibility notes

- The released analysis-ready data support the downstream statistical analyses. Reconstructing the proprietary facility-level data-center source data requires licensed S&P Global Capital IQ Pro access and the full workflow described above.
