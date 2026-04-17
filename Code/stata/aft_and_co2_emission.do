** aft regression session
global raw "your_own_path/Data/raw"
global temp "your_own_path/Data/temp"
global use "your_own_path/Data/use"
global figures "your_own_path/Results/Figures"

use "$use/gem_coal_plants_multi_record_sa_proximity_exposure_15_25_50km_forR_clean.dta", clear

cap drop _t0 _t _d _st
stset time1, failure(retire) id(GEM_unit_phase_ID) origin(time 0) 
order GEM_unit_phase_ID year Start_year Retired_year time0 time1 _st _d _t _t0 plant_age retire
stdes

encode Country_Area, gen(country_id)

* standadize vars

egen ai_proximity_25km_before06_z = std(ai_proximity_25km_before06)
egen ai_proximity_25km_06_15_z = std(ai_proximity_25km_06_15)
egen ai_proximity_25km_16_19_z = std(ai_proximity_25km_16_19)
egen ai_proximity_25km_20_24_z = std(ai_proximity_25km_20_24)

foreach var in Capacity_MW Start_year Heat_rate_Btu_per_kWh ///
    Emission_factor_kg_of_CO2_per_TJ rGDP_pc {
    
    capture confirm variable `var'
    if !_rc {
        quietly summarize `var'
        if "`var'" == "Capacity_MW" {
            generate capacity_z = (`var' - r(mean)) / r(sd)
            label variable capacity_z "Standardized Capacity_MW"
        }
        else if "`var'" == "Start_year" {
            generate start_year_z = (`var' - r(mean)) / r(sd)
            label variable start_year_z "Standardized Start_year"
        }
        else if "`var'" == "Heat_rate_Btu_per_kWh" {
            generate heat_rate_z = (`var' - r(mean)) / r(sd)
            label variable heat_rate_z "Standardized Heat_rate_Btu_per_kWh"
        }
        else if "`var'" == "Emission_factor_kg_of_CO2_per_TJ" {
            generate emission_z = (`var' - r(mean)) / r(sd)
            label variable emission_z "Standardized Emission_factor_kg_of_CO2_per_TJ"
        }
        else if "`var'" == "rGDP_pc" {
            generate gdp_pc_z = (`var' - r(mean)) / r(sd)
            label variable gdp_pc_z "Standardized rGDP_pc"
        }
    }
}

global control_plant_info_z "capacity_z start_year_z heat_rate_z emission_z gdp_pc_z"

//aft regression session

fvset base freq country_id

streg ai_proximity_25km_before06_z ai_proximity_25km_06_15_z ///
    ai_proximity_25km_16_19_z ai_proximity_25km_20_24_z ///
    $control_plant_info_z i.country_id, ///
    distribution(weibull) time vce(cluster GEM_unit_phase_ID)


** carbon emission analysis session
sum time1 if retire == 1, detail 

//extract survival units in 2024

sum ai_proximity_25km_20_24 //sd == 1.100182
gen sd = 1.100182	
	
gen coef = 0.020806	
gen coef_ci_bottom = 0.0105737	
gen coef_ci_top = 0.0310383

keep if year == 2024
keep if retire == 0		   
keep if ai_proximity_25km_20_24 > 0	

gen sd_change = ai_proximity_25km_20_24/sd

gen coef_change = coef*sd_change
gen coef_change_ci_bottom = coef_ci_bottom*sd_change
gen coef_change_ci_top = coef_ci_top*sd_change


gen af_change = exp(coef_change)
gen af_change_ci_bottom = exp(coef_change_ci_bottom)
gen af_change_ci_top = exp(coef_change_ci_top)


gen retire_average = 40  // literature： 2022 in nc

gen life_expect = retire_average if time1 <=retire_average

replace life_expect = time1 if time1 > retire_average

gen life_expect_with_dc = life_expect*(af_change)
gen life_expect_with_dc_bottom = life_expect*(af_change_ci_bottom)
gen life_expect_with_dc_top = life_expect*(af_change_ci_top)

gen life_extension = life_expect*(af_change-1)
gen life_extension_ci_bottom = life_expect*(af_change_ci_bottom-1)
gen life_extension_ci_top = life_expect*(af_change_ci_top-1)


drop if life_expect_with_dc > 86 // delete extreme estimated lifetime under dc exposure (86 is the largest lifespan of used samples)


keep GEM_unit_phase_ID year retire ai_proximity_25km_20_24 time1 sd* coef* af* retire_average life*

export excel using "$use/dc_exposure_and_coal_plant_life_extension.xls", firstrow(variables) replace
