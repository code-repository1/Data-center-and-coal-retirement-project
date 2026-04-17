# Replication Guide
This document provides step-by-step instructions to reproduce all data processing and analysis results in this project. 

Step 1. Data Preparation
All four scripts must be executed in the order listed before proceeding to any analysis step.
1. Run coal_plant_data_generation.ipynb (Python) Purpose: Process raw coal-fired power plant generation unit data and restructure it into a unit-year multi-record survival data format.
2. Run coal_plant_multirecord.do (Stata) Purpose: Further clean and expand the multi-record panel structure, applying unit-level filters and variable construction.
3. Run data_center_exposure_calculate.ipynb (Python) Purpose: Calculate data center exposure indicators for each observation unit at 15 km, 25 km, and 50 km proximity thresholds.
4. Run prepared_dataset.do (Stata) Purpose: Merge all processed components and finalize the analytical dataset. Output: gem_coal_plants_multi_record_sa_proximity_exposure_15_25_50km_forR_clean.dta

Step 2. Data Analysis and Visualization
5. Run Figure1&2.ipynb (Python) Purpose: Generate Figure 1 and Figure 2. 
6. Run SI_figure1.ipynb (Python) Purpose: Generate Supplementary Figure 1. 

7. Run cox_main.Rmd (R) Purpose: Conduct the main Cox proportional hazard model analyses and generate primary results. 

8. Run cement_and_concrete_calculate.ipynb (Python) → then Run placebo_cement_data_prep.do (Stata) → then Run cox_cement_placebo.Rmd (R) Purpose: Prepare cement and concrete industry data (placebo test) and estimate the placebo Cox model to produce Supplementary Table. 3. 

9. Run large_scale_dc_exposure_calculate.ipynb (Python) → then Run largerdc_data_prep.do (Stata) → then Run cox_largerdc.Rmd (R) Purpose: Recalculate exposure indicators using large-scale data center definitions and estimate the corresponding robustness model to generate Fig. 3c. 

10. Run large_scale_dc_exposure_calculate_all.ipynb (Python) → then Run largerdc_data_prep_all.do (Stata) → then Run cox_largerdc_all.Rmd (R) Purpose: Recalculate exposure indicators using all-year large-scale data center definitions (rather than the by-period defination) and estimate the corresponding robustness model to generate Supplementary Fig. 7. 

11. Run aft_and_co2_emission.do (Stata) → then Run Figure5b.ipynb(Python) Purpose: Estimate the accelerated failure time (AFT) model and compute CO₂ emission projections, then visualize the results as Fig. 5b.
    
Software
Python (Ver. 3.12.2); Stata (Ver. 19.5 SE); R (Ver. 4.4.1);

