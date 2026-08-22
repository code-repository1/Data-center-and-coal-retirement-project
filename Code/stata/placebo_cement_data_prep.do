
global temp "your_own_path/Data_center_and_fossil_energy_Replication/Data/temp"
global use "your_own_path/Data_center_and_fossil_energy_Replication/Data/use"
global raw "your_own_path/Data_center_and_fossil_energy_Replication/Data/raw"

use "$temp/gem_coal_sa_prox_exp_with_placebo.dta", clear


cap drop _t0 _t _d _st
stset time1, failure(retire) id(GEM_unit_phase_ID) origin(time 0)
order GEM_unit_phase_ID year Start_year Retired_year time0 time1 _st _d _t _t0 plant_age retire
stdes

// control_plant_info

capture confirm numeric variable Combustion_technology
if _rc {
    encode Combustion_technology, gen(Combustion_technology_temp)
    drop Combustion_technology
    rename Combustion_technology_temp Combustion_technology
}

capture confirm numeric variable Coal_type
if _rc {
    encode Coal_type, gen(Coal_type_temp)
    drop Coal_type
    rename Coal_type_temp Coal_type
}

// calculate carbon intensity

capture drop co2_intensity
gen co2_intensity = Heat_rate_Btu_per_kWh * Emission_factor_kg_of_CO2_per_TJ / 947800000

sort GEM_unit_phase_ID year

capture drop ISO3
gen ISO3 = Alpha_3_code

merge m:1 ISO3 year using "$raw/GMD.dta"
drop if _merge == 2
drop _merge

sort GEM_unit_phase_ID year


//match further control variables for robustness ：

/*elec_price_db_uscent_kwh_raw
demand_yoy_pct
renew_gen_share_pct
td_loss_pct_output
policy_count_cum
nz_has_target_active
*/

// match country-year electricity-system and policy controls
merge m:1 Alpha_3_code year using ///
    "$use/country_year_electricity_policy_controls.dta", ///
    keepusing( ///
        elec_price_db_uscent_kwh_raw ///
        demand_yoy_pct ///
        renew_gen_share_pct ///
        td_loss_pct_output ///
        policy_count_cum ///
        nz_has_target_active ///
    )

drop if _merge == 2
drop _merge

sort GEM_unit_phase_ID year

****************************************************
* Preserve non-imputed controls for robustness checks
****************************************************

local preserve_controls ///
    rGDP_pc ///
    elec_price_db_uscent_kwh_raw ///
    demand_yoy_pct ///
    renew_gen_share_pct ///
    td_loss_pct_output ///
    policy_count_cum ///
    nz_has_target_active

foreach var of local preserve_controls {
    cap drop `var'_ni
    gen `var'_ni = `var'
}
****************************************************
* Impute country-year controls used in regressions
* Step 1: within-unit linear interpolation/extrapolation
* Step 2: within-unit mean fill
* Step 3: full-sample mean fill
****************************************************

sort GEM_unit_phase_ID year

local impute_controls ///
    rGDP_pc ///
    elec_price_db_uscent_kwh_raw ///
    demand_yoy_pct ///
    renew_gen_share_pct ///
    td_loss_pct_output

* 1. within-unit linear interpolation / extrapolation
foreach var of local impute_controls {
    cap drop __ip
    by GEM_unit_phase_ID: ipolate `var' year, gen(__ip) epolate
    replace `var' = __ip if missing(`var')
    drop __ip
}
****************************************************
* Preserve controls after linear interpolation/extrapolation only
****************************************************

foreach var of local impute_controls {
    cap drop `var'_li
    gen `var'_li = `var'
}

* Policy controls are not interpolated
cap drop policy_count_cum_li
gen policy_count_cum_li = policy_count_cum

cap drop nz_has_target_active_li
gen nz_has_target_active_li = nz_has_target_active

* 2. within-unit mean fill
foreach var of local impute_controls {
    cap drop __mean
    by GEM_unit_phase_ID: egen __mean = mean(`var')
    replace `var' = __mean if missing(`var')
    drop __mean
}

* 3. full-sample mean fill
foreach var of local impute_controls {
    cap drop __allmean
    egen __allmean = mean(`var')
    replace `var' = __allmean if missing(`var')
    drop __allmean
}

* Policy controls: no interpolation; missing means no recorded policy/active target
replace policy_count_cum = 0 if missing(policy_count_cum)
replace nz_has_target_active = 0 if missing(nz_has_target_active)

replace policy_count_cum_ni = policy_count_cum
replace nz_has_target_active_ni = nz_has_target_active

* Check remaining missing
foreach var of local impute_controls {
    count if missing(`var')
    display "`var' remaining missing: " r(N)
}
count if missing(policy_count_cum)
display "policy_count_cum remaining missing: " r(N)
count if missing(nz_has_target_active)
display "nz_has_target_active remaining missing: " r(N)

replace policy_count_cum = 0 if missing(policy_count_cum)
replace nz_has_target_active = 0 if missing(nz_has_target_active)

save "$use/forR_placebo_cement.dta", replace




