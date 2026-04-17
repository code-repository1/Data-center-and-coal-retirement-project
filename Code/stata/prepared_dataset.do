** generate final data for cox in r

global temp "your_own_path/Data/temp"
global use "your_own_path/Data/use"

use "$temp/gem_coal_plants_multi_record_sa_proximity_exposure_15_25_50km_periods.dta", clear


cap drop _t0 _t _d _st
stset time1, failure(retire) id(GEM_unit_phase_ID) origin(time 0) 
order GEM_unit_phase_ID year Start_year Retired_year time0 time1 _st _d _t _t0 plant_age retire
stdes

//control_plant_info

encode Combustion_technology, gen(Combustion_technology_temp)
drop Combustion_technology

encode Coal_type, gen(Coal_type_temp)
drop Coal_type
rename Coal_type_temp Coal_type

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


summarize ai_proximity_*km_*

foreach dist in 15 25 50 {
    foreach period in before06 06_15 16_19 20_24 {
        gen ai_treat_`dist'km_`period' = ///
            (ai_proximity_`dist'km_`period' != 0 & ///
             !missing(ai_proximity_`dist'km_`period'))
        label var ai_treat_`dist'km_`period' ///
            "AI treatment: `dist'km, `period'"
    }
}

save "$use/gem_coal_plants_multi_record_sa_proximity_exposure_15_25_50km_forR_clean.dta", replace
