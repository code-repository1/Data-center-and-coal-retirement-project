/*
EIA plant-level coal-generation mechanism regressions, 2001-2024

Input
-----
Data/temp/eia_coal_plant_year_generation_mechanism_2001_2024_dce_controls.dta

This dataset is built from EIA-860 operable coal capacity and EIA-906/920
(2001-2007) or EIA-923 (2008-2024) plant-fuel net generation. The main
mechanism outcome is standardized plant-level coal-fired net generation.
*/

clear all
set more off
eststo clear

cd "your_own_path/Data_center_and_fossil_energy_Replication"

global project "."
global temp "$project/Data/temp"
global tables "$project/Results/Tables"

use "$temp/eia_coal_plant_year_generation_mechanism_2001_2024_dce_controls.dta", clear

keep if plant_cf_regression_sample == 1
keep if inrange(year, 2001, 2024)

destring plant_code, replace force
egen plant_fe = group(plant_code)
egen state_year_fe = group(state year)
xtset plant_fe year

foreach v of varlist dce_* exp_* dceagg_* expagg_* {
    replace `v' = 0 if missing(`v')
}

* ============================================================
* Mechanism check: coal-fired net generation
* ============================================================

xtset plant_fe year

global state_controls ///
    st_ln_real_gdp ///
    st_retail_price_cents_kwh ///
    st_total_sales_mwh ///
	st_total_gen_mwh ///
    st_total_cap_mw ///
    st_ren_gen_share ///
    st_ren_cap_share
	
foreach var of global state_controls {
    capture drop pm

    bysort plant_fe: egen pm = mean(`var')
    replace `var' = pm if missing(`var')

    quietly summarize `var'
    replace `var' = r(mean) if missing(`var')

    drop pm
}

egen z_coal_net_generation_mwh = std(coal_net_generation_mwh)

egen state_fe = group(state)
egen ba_fe = group(balancing_authority)

* ------------------------------------------------------------
* Model 1: plant and year fixed effects
* ------------------------------------------------------------
reghdfe z_coal_net_generation_mwh ///
    dce_all_25km_before06 ///
    dce_all_25km_06_15 ///
    dce_all_25km_16_19 ///
    dce_all_25km_20_24, ///
    absorb(plant_fe year) ///
    vce(cluster plant_fe)

eststo m1_twfe
estadd local plant_fe "Yes"
estadd local year_fe "Yes"
estadd local state_controls "No"

* ------------------------------------------------------------
* Model 2: plant and year fixed effects + state controls
* ------------------------------------------------------------
reghdfe z_coal_net_generation_mwh ///
    dce_all_25km_before06 ///
    dce_all_25km_06_15 ///
    dce_all_25km_16_19 ///
    dce_all_25km_20_24 ///
    $state_controls, ///
    absorb(plant_fe year) ///
    vce(cluster plant_fe)

eststo m2_controls
estadd local plant_fe "Yes"
estadd local year_fe "Yes"
estadd local state_controls "Yes"

* ------------------------------------------------------------
* Output table
* ------------------------------------------------------------
esttab m1_twfe m2_controls ///
    using "$tables/sup_table_eia_coal_generation_mechanism.rtf", ///
    replace ///
    b(3) se(3) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    label ///
keep( ///
    dce_all_25km_20_24 ///
    dce_all_25km_16_19 ///
    dce_all_25km_06_15 ///
    dce_all_25km_before06 ///
) ///
order( ///
    dce_all_25km_20_24 ///
    dce_all_25km_16_19 ///
    dce_all_25km_06_15 ///
    dce_all_25km_before06 ///
) ///
coeflabels( ///
    dce_all_25km_20_24 "DCE, 2020-2024" ///
    dce_all_25km_16_19 "DCE, 2016-2019" ///
    dce_all_25km_06_15 "DCE, 2006-2015" ///
    dce_all_25km_before06 "DCE, pre-2006" ///
) ///
    mtitles( ///
        "TWFE" ///
        "TWFE + controls" ///
    ) ///
    stats( ///
        plant_fe year_fe state_controls N r2_a, ///
        labels( ///
            "Plant fixed effects" ///
            "Year fixed effects" ///
            "State controls" ///
            "Observations" ///
            "Adjusted R-squared" ///
        ) ///
        fmt(%9s %9s %9s %9.0fc %9.3f) ///
    ) ///
    title("Extended Data Table X. Data-center exposure and coal-fired generation for U.S. coal plants") ///
    addnotes( ///
        "Notes: This table reports plant-year panel regressions using U.S. EIA data for coal-fired power plants from 2001 to 2024. The dependent variable is standardized plant-level coal-fired net generation. DCE measures inverse-distance-weighted exposure to data centers within 25 km, separated by data-center commissioning period. The plant-year panel is constructed using plant information from EIA Form 860 and plant-level annual coal-fired net generation from EIA Form 923, supplemented by earlier EIA Form 906/920 records. State controls include state-level real GDP from the U.S. Bureau of Economic Analysis (https://www.bea.gov/data/gdp/gdp-state), retail electricity prices, total electricity sales, total electricity generation, total installed capacity, renewable generation share and renewable capacity share from EIA historical state data (https://www.eia.gov/electricity/data/state/). Model (1) includes plant and year fixed effects. Model (2) further adds state-level controls. Standard errors, reported in parentheses, are clustered at the plant level. * p < 0.05, ** p < 0.01, *** p < 0.001." ///
    )
