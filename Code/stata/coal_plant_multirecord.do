**generate multi-record coal units survival dataset

global temp "your_own_path/Data_center_and_fossil_energy_Replication/Data/temp"
global use "your_own_path/Data_center_and_fossil_energy_Replication/Data/use"

use "$temp/coal_plants_final.dta", clear

keep if Status == "retired"| Status == "operating"
drop if Start_year == .

* gen last year for each unit
gen end_year = .
replace end_year = Retired_year if Status == "retired" & !missing(Retired_year)
replace end_year = 2024 if Status == "operating"

* check unreal data（end_year < Start_year）
drop if end_year < Start_year

* calculate records number for each unit
gen n_years = end_year - Start_year + 1

* expand multirecord data
expand n_years

* generate calendar year
bysort GEM_unit_phase_ID: gen year = Start_year + _n - 1

sort GEM_unit_phase_ID year
drop end_year n_years


//define survival dataset

* retire var
gen retire = 0
bysort GEM_unit_phase_ID (year): replace retire = 1 if _n == _N & Status == "retired"

* age var
gen plant_age = year - Start_year

* time var
gen time0 = plant_age       
gen time1 = plant_age + 1   

* set
stset time1, failure(retire) id(GEM_unit_phase_ID) origin(time 0) time0(time0)

order GEM_unit_phase_ID year Start_year Retired_year time0 time1 _st _d _t _t0 plant_age retire

stdes

save "$temp/gem_coal_plants_multi_record_sa_sinceoperating.dta", replace
