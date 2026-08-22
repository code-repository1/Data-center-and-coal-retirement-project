** aft regression session
global raw "your_own_path/Data_center_and_fossil_energy_Replication/Data/raw"
global temp "your_own_path/Data_center_and_fossil_energy_Replication/Data/temp"
global use "your_own_path/Data_center_and_fossil_energy_Replication/Data/use"
global figures "your_own_path/Data_center_and_fossil_energy_Replication/Results/Figures"

use "$use/gem_coal_plants_multi_record_sa_dce_robust_forR_clean.dta", clear

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
    Emission_factor_kg_of_CO2_per_TJ rGDP_pc ///
    elec_price_db_uscent_kwh_raw demand_yoy_pct renew_gen_share_pct ///
    td_loss_pct_output policy_count_cum nz_has_target_active {
    
    capture confirm variable `var'
    if !_rc {
        quietly summarize `var'
        if r(sd) > 0 & r(sd) < . {
            
            if "`var'" == "Capacity_MW" {
                capture drop capacity_z
                generate capacity_z = (`var' - r(mean)) / r(sd)
                label variable capacity_z "Standardized Capacity_MW"
            }
            else if "`var'" == "Start_year" {
                capture drop start_year_z
                generate start_year_z = (`var' - r(mean)) / r(sd)
                label variable start_year_z "Standardized Start_year"
            }
            else if "`var'" == "Heat_rate_Btu_per_kWh" {
                capture drop heat_rate_z
                generate heat_rate_z = (`var' - r(mean)) / r(sd)
                label variable heat_rate_z "Standardized Heat_rate_Btu_per_kWh"
            }
            else if "`var'" == "Emission_factor_kg_of_CO2_per_TJ" {
                capture drop emission_z
                generate emission_z = (`var' - r(mean)) / r(sd)
                label variable emission_z "Standardized Emission_factor_kg_of_CO2_per_TJ"
            }
            else if "`var'" == "rGDP_pc" {
                capture drop gdp_pc_z
                generate gdp_pc_z = (`var' - r(mean)) / r(sd)
                label variable gdp_pc_z "Standardized rGDP_pc"
            }
            else if "`var'" == "elec_price_db_uscent_kwh_raw" {
                capture drop elec_price_z
                generate elec_price_z = (`var' - r(mean)) / r(sd)
                label variable elec_price_z "Standardized electricity price"
            }
            else if "`var'" == "demand_yoy_pct" {
                capture drop demand_yoy_z
                generate demand_yoy_z = (`var' - r(mean)) / r(sd)
                label variable demand_yoy_z "Standardized electricity demand YoY growth"
            }
            else if "`var'" == "renew_gen_share_pct" {
                capture drop renew_share_z
                generate renew_share_z = (`var' - r(mean)) / r(sd)
                label variable renew_share_z "Standardized renewable generation share"
            }
            else if "`var'" == "td_loss_pct_output" {
                capture drop td_loss_z
                generate td_loss_z = (`var' - r(mean)) / r(sd)
                label variable td_loss_z "Standardized T&D losses"
            }
            else if "`var'" == "policy_count_cum" {
                capture drop policy_count_z
                generate policy_count_z = (`var' - r(mean)) / r(sd)
                label variable policy_count_z "Standardized cumulative climate policy count"
            }
            else if "`var'" == "nz_has_target_active" {
                capture drop nz_target_z
                generate nz_target_z = (`var' - r(mean)) / r(sd)
                label variable nz_target_z "Standardized active national climate target"
            }
        }
    }
}

//
global control_plant_info_z ///
    capacity_z ///
    start_year_z ///
    heat_rate_z ///
    emission_z ///
    gdp_pc_z ///
    elec_price_z /// 
    demand_yoy_z ///
    renew_share_z ///
    td_loss_z ///



//aft regression session

fvset base freq country_id

streg ai_proximity_25km_before06_z ai_proximity_25km_06_15_z ///
    ai_proximity_25km_16_19_z ai_proximity_25km_20_24_z ///
    $control_plant_info_z i.country_id, ///
    distribution(weibull) time vce(cluster GEM_unit_phase_ID)
estat ic
/*
----------------------------------------------------------------------------------------------
                             |               Robust
                          _t | Coefficient  std. err.      z    P>|z|     [95% conf. interval]
-----------------------------+----------------------------------------------------------------
ai_proximity_25km_before06_z |  -.0006954   .0015637    -0.44   0.657    -.0037601    .0023694
   ai_proximity_25km_06_15_z |   -.000997   .0013379    -0.75   0.456    -.0036193    .0016253
   ai_proximity_25km_16_19_z |  -.0006642   .0011123    -0.60   0.550    -.0028443    .0015158
   ai_proximity_25km_20_24_z |   .0170132   .0044237     3.85   0.000     .0083429    .0256835

-----------------------------------------------------------------------------
       Model |          N   ll(null)  ll(model)      df        AIC        BIC
-------------+---------------------------------------------------------------
           . |    259,044  -3844.903  -1220.267      96   2632.533    3637.15
-----------------------------------------------------------------------------


*/
	
* Cluster at second-level administrative region
streg ai_proximity_25km_before06_z ai_proximity_25km_06_15_z ///
    ai_proximity_25km_16_19_z ai_proximity_25km_20_24_z ///
    $control_plant_info_z i.country_id, ///
    distribution(weibull) time vce(cluster Plant_name)
/*
----------------------------------------------------------------------------------------------
                             |               Robust
                          _t | Coefficient  std. err.      z    P>|z|     [95% conf. interval]
-----------------------------+----------------------------------------------------------------
ai_proximity_25km_before06_z |  -.0006954   .0016364    -0.42   0.671    -.0039026    .0025118
   ai_proximity_25km_06_15_z |   -.000997   .0015061    -0.66   0.508    -.0039489    .0019549
   ai_proximity_25km_16_19_z |  -.0006642    .001335    -0.50   0.619    -.0032807    .0019523
   ai_proximity_25km_20_24_z |   .0170132   .0077215     2.20   0.028     .0018794     .032147

*/

* Cluster at second-level administrative region
streg ai_proximity_25km_before06_z ai_proximity_25km_06_15_z ///
    ai_proximity_25km_16_19_z ai_proximity_25km_20_24_z ///
    $control_plant_info_z i.country_id, ///
    distribution(weibull) time vce(cluster GID_2)
/*	
----------------------------------------------------------------------------------------------
                             |               Robust
                          _t | Coefficient  std. err.      z    P>|z|     [95% conf. interval]
-----------------------------+----------------------------------------------------------------
ai_proximity_25km_before06_z |  -.0005614    .001664    -0.34   0.736    -.0038229       .0027
   ai_proximity_25km_06_15_z |   -.001351   .0017775    -0.76   0.447    -.0048348    .0021327
   ai_proximity_25km_16_19_z |   -.000516   .0014222    -0.36   0.717    -.0033035    .0022715
   ai_proximity_25km_20_24_z |   .0169345   .0081646     2.07   0.038     .0009322    .0329367

*/	
* Cluster at first-level administrative region
streg ai_proximity_25km_before06_z ai_proximity_25km_06_15_z ///
    ai_proximity_25km_16_19_z ai_proximity_25km_20_24_z ///
    $control_plant_info_z i.country_id, ///
    distribution(weibull) time vce(cluster GID_1)
/*
----------------------------------------------------------------------------------------------
                             |               Robust
                          _t | Coefficient  std. err.      z    P>|z|     [95% conf. interval]
-----------------------------+----------------------------------------------------------------
ai_proximity_25km_before06_z |  -.0005614   .0015857    -0.35   0.723    -.0036694    .0025466
   ai_proximity_25km_06_15_z |  -.0013509    .001756    -0.77   0.442    -.0047927    .0020908
   ai_proximity_25km_16_19_z |   -.000518   .0015084    -0.34   0.731    -.0034745    .0024384
   ai_proximity_25km_20_24_z |   .0169622   .0081815     2.07   0.038     .0009267    .0329977

*/	



* Lognormal AFT //
streg ai_proximity_25km_before06_z ai_proximity_25km_06_15_z ///
    ai_proximity_25km_16_19_z ai_proximity_25km_20_24_z ///
    $control_plant_info_z i.country_id, ///
    distribution(lognormal) time vce(cluster GEM_unit_phase_ID)
estat ic
/*
----------------------------------------------------------------------------------------------
                             |               Robust
                          _t | Coefficient  std. err.      z    P>|z|     [95% conf. interval]
-----------------------------+----------------------------------------------------------------
ai_proximity_25km_before06_z |   .0014216   .0038351     0.37   0.711    -.0060951    .0089383
   ai_proximity_25km_06_15_z |    -.00899   .0068122    -1.32   0.187    -.0223417    .0043617
   ai_proximity_25km_16_19_z |  -.0014813   .0047608    -0.31   0.756    -.0108123    .0078496
   ai_proximity_25km_20_24_z |   .0252344   .0058036     4.35   0.000     .0138596    .0366093

Akaike's information criterion and Bayesian information criterion

-----------------------------------------------------------------------------
       Model |          N   ll(null)  ll(model)      df        AIC        BIC
-------------+---------------------------------------------------------------
           . |    259,044  -4235.678    -1517.3      95     3224.6   4218.752
-----------------------------------------------------------------------------

*/
* Loglogistic AFT //
streg ai_proximity_25km_before06_z ai_proximity_25km_06_15_z ///
    ai_proximity_25km_16_19_z ai_proximity_25km_20_24_z ///
    $control_plant_info_z i.country_id, ///
    distribution(loglogistic) time vce(cluster GEM_unit_phase_ID)
estat ic
/*
----------------------------------------------------------------------------------------------
                             |               Robust
                          _t | Coefficient  std. err.      z    P>|z|     [95% conf. interval]
-----------------------------+----------------------------------------------------------------
ai_proximity_25km_before06_z |    .003781   .0024186     1.56   0.118    -.0009594    .0085214
   ai_proximity_25km_06_15_z |  -.0116624     .00318    -3.67   0.000     -.017895   -.0054298
   ai_proximity_25km_16_19_z |  -.0023503    .003275    -0.72   0.473    -.0087692    .0040685
   ai_proximity_25km_20_24_z |     .02469   .0053739     4.59   0.000     .0141574    .0352225


Akaike's information criterion and Bayesian information criterion
-----------------------------------------------------------------------------
       Model |          N   ll(null)  ll(model)      df        AIC        BIC
-------------+---------------------------------------------------------------
           . |    259,044  -4061.088  -1297.846      95   2785.692   3779.844
-----------------------------------------------------------------------------

*/
* Generalized gamma
streg ai_proximity_25km_before06_z ai_proximity_25km_06_15_z ///
    ai_proximity_25km_16_19_z ai_proximity_25km_20_24_z ///
    $control_plant_info_z i.country_id, ///
    distribution(ggamma) time vce(cluster GEM_unit_phase_ID)
estat ic
/*
----------------------------------------------------------------------------------------------
                             |               Robust
                          _t | Coefficient  std. err.      z    P>|z|     [95% conf. interval]
-----------------------------+----------------------------------------------------------------
ai_proximity_25km_before06_z |  -.0006473    .001499    -0.43   0.666    -.0035852    .0022906
   ai_proximity_25km_06_15_z |  -.0008196   .0012279    -0.67   0.504    -.0032262     .001587
   ai_proximity_25km_16_19_z |  -.0006833   .0010072    -0.68   0.498    -.0026572    .0012907
   ai_proximity_25km_20_24_z |   .0161577   .0044285     3.65   0.000      .007478    .0248375


Akaike's information criterion and Bayesian information criterion

-----------------------------------------------------------------------------
       Model |          N   ll(null)  ll(model)      df        AIC        BIC
-------------+---------------------------------------------------------------
           . |    259,044  -3748.871  -1217.324      96   2626.648   3631.264
-----------------------------------------------------------------------------

*/

****************************************************
* Carbon emission analysis
* Lifetime sensitivity: 25, 36, 40, 50 years
* Export each scenario to a separate Excel sheet
****************************************************

sum time1 if retire == 1, detail
local max_life = 86

sum ai_proximity_25km_20_24
local dce_sd = r(sd)

local coef = 0.0170132
local coef_ci_bottom = 0.0083429    
local coef_ci_top = 0.0256835

local outfile "$use/dc_life_extension_retirement_age_25_36_40_50.xlsx"

tempfile all_scenarios
save `all_scenarios', emptyok replace

local first_sheet = 1

foreach lifetime in 25 36 40 50 {

    preserve

    keep if year == 2024
    keep if retire == 0
    keep if ai_proximity_25km_20_24 > 0

    gen scenario_lifetime = `lifetime'

    gen sd = `dce_sd'
    gen coef = `coef'
    gen coef_ci_bottom = `coef_ci_bottom'
    gen coef_ci_top = `coef_ci_top'

    gen sd_change = ai_proximity_25km_20_24 / sd

    gen coef_change = coef * sd_change
    gen coef_change_ci_bottom = coef_ci_bottom * sd_change
    gen coef_change_ci_top = coef_ci_top * sd_change

    gen af_change = exp(coef_change)
    gen af_change_ci_bottom = exp(coef_change_ci_bottom)
    gen af_change_ci_top = exp(coef_change_ci_top)

    gen retire_average = `lifetime'

    gen life_expect = retire_average if time1 <= retire_average
    replace life_expect = time1 if time1 > retire_average

    gen life_expect_with_dc = life_expect * af_change
    gen life_expect_with_dc_bottom = life_expect * af_change_ci_bottom
    gen life_expect_with_dc_top = life_expect * af_change_ci_top

    gen life_extension = life_expect * (af_change - 1)
    gen life_extension_ci_bottom = life_expect * (af_change_ci_bottom - 1)
    gen life_extension_ci_top = life_expect * (af_change_ci_top - 1)

    drop if life_expect_with_dc > `max_life'

    gen scenario_name = ""
    replace scenario_name = "IRENA economic lifetime, 25 years" if scenario_lifetime == 25
    replace scenario_name = "Tong et al. average lifetime, 36 years" if scenario_lifetime == 36
    replace scenario_name = "Baseline assumed lifetime, 40 years" if scenario_lifetime == 40
    replace scenario_name = "IRENA technical lifetime, 50 years" if scenario_lifetime == 50

    keep GEM_unit_phase_ID year retire ai_proximity_25km_20_24 time1 ///
        sd* coef* af* retire_average scenario_lifetime scenario_name life*

    order scenario_lifetime scenario_name GEM_unit_phase_ID year retire ///
        time1 ai_proximity_25km_20_24 retire_average life_expect ///
        life_expect_with_dc life_extension

    sort GEM_unit_phase_ID

    tempfile scenario_`lifetime'
    save `scenario_`lifetime'', replace

    if `first_sheet' == 1 {
        export excel using "`outfile'", ///
            sheet("scenario_`lifetime'") firstrow(variables) replace
        local first_sheet = 0
    }
    else {
        export excel using "`outfile'", ///
            sheet("scenario_`lifetime'") firstrow(variables) sheetreplace
    }

    append using `all_scenarios'
    save `all_scenarios', replace

    restore
}

****************************************************
* Summary sheet
****************************************************
preserve

use `all_scenarios', clear

bysort scenario_lifetime scenario_name GEM_unit_phase_ID: gen unit_tag = _n == 1

collapse ///
    (sum) n_units = unit_tag ///
          total_life_extension = life_extension ///
          total_life_extension_ci_bottom = life_extension_ci_bottom ///
          total_life_extension_ci_top = life_extension_ci_top ///
    (mean) mean_life_extension = life_extension ///
           mean_life_extension_ci_bottom = life_extension_ci_bottom ///
           mean_life_extension_ci_top = life_extension_ci_top, ///
    by(scenario_lifetime scenario_name)

sort scenario_lifetime

export excel using "`outfile'", ///
    sheet("summary") firstrow(variables) sheetreplace
restore
