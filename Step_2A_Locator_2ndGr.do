** UPDATED 6.30.2021 -- RUN 0_SetDirectories first ***/
** 20210903 DATA RELEASE HAS GRADE INDICATOR, SO NO LONGER NEED TO RUN STEP 2A FIRST! ***
*** NEW LOCATOR FILE HAS DIFFERENT VARIABLE NAMES ***
*** MSM 2020.02.09 STEP 0 LOCATOR FILE -- USE THIS JUST TO GET THE MAIN LOCATOR FILE FOR 2018 TO FIND THE 2ND, 8TH, AND 11TH GRADERS FOR NORMALIZING TEST SCORES ***

clear all
capture log close
set more off


log using output/Step_2A_Locator, text replace

*** NEED TO FIND 2ND GRADERS BECAUSE CURTEST INCLUDES LOTS OF VALUES ? ***

*********************************************************************
****		Find everyone in 2nd grade in 2018 for normalization purposes
*********************************************************************

*insheet using "$rawdata/locator_2000-2018.csv", clear
insheet using "$rawdata/locator.csv", clear

*format encrypted %12.0f
*tostring encrypted, gen(sid_string) usedisplayformat force

keep if schlyr==2018
rename schlyr year
keep if active==1
keep if grade_level==2

** Valid school code and convert to the standard format for merging ***
tostring cur_school_code, gen(temp)
gen school = "920" + temp
drop cur_school_code temp
destring school, replace
replace school = 920001 if school==9201

keep if school ~= .
drop if school == 920001
drop if school == 920292

drop if encrypted == . 
*keep sid_string school encryp
*gen sid_short = substr(sid_string, 1, 7)
*list sid* in 1/3

keep encrypted school year 

save "$workingdata/locator_2nd", replace
