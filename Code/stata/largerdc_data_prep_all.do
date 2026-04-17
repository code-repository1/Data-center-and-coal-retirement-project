
global temp "your_own_path/Data/temp"
global use "your_own_path/Data/use"
global raw"your_own_path/Data/raw"

use "$temp/larger.dta", clear

cap drop _t0 _t _d _st
stset time1, failure(retire) id(GEM_unit_phase_ID) origin(time 0) //time0(time0)
order GEM_unit_phase_ID year Start_year Retired_year time0 time1 _st _d _t _t0 plant_age retire
stdes

//control_plant_info

encode Combustion_technology, gen(Combustion_technology_temp)
drop Combustion_technology

encode Coal_type, gen(Coal_type_temp)
drop Coal_type
rename Coal_type_temp Coal_type
global control_plant_info "i.multi_owner Capacity_MW i.Combustion_technology i.Coal_type Heat_rate_Btu_per_kWh Emission_factor_kg_of_CO2_per_TJ Annual_CO2_million_tonnes_annum Start_year" 

//calculate carbon intensity

gen co2_intensity = Heat_rate_Btu_per_kWh*Emission_factor_kg_of_CO2_per_TJ/947800000

sort GEM_unit_phase_ID year

gen ISO3 = Alpha_3_code

merge m:1 ISO3 year using "$raw/GMD.dta"
drop if _merge == 2
drop _merge

sort GEM_unit_phase_ID year

local vars rGDP exports_GDP imports_GDP CPI infl pop govexp_GDP rGDP_pc

sort GEM_unit_phase_ID year

foreach var of local vars {
    by GEM_unit_phase_ID: ipolate `var' year, gen(`var'_interp) epolate
    replace `var' = `var'_interp if missing(`var')
    drop `var'_interp
}


foreach var of local vars {
    by GEM_unit_phase_ID: egen `var'_mean = mean(`var')
    replace `var' = `var'_mean if missing(`var')
    drop `var'_mean
}

foreach var of local vars {
    egen `var'_allmean = mean(`var')
    replace `var' = `var'_allmean if missing(`var')
    drop `var'_allmean
}

foreach var of local vars {
    count if missing(`var')
}


gen ai_proximity_25km_larger_all=  ai_proximity_25km_before06_hyper + ai_proximity_25km_06_15_hyper + ai_proximity_25km_16_19_hyper + ai_proximity_25km_20_24_hyper
gen ai_proximity_25km_other_all=  ai_proximity_25km_before06_other + ai_proximity_25km_06_15_other + ai_proximity_25km_16_19_other + ai_proximity_25km_20_24_other


save "$use/forR_placebo_larger_all.dta", replace






