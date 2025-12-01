** UPDATED 6.30.2021 -- RUN 0_SetDirectories first ***/
** 20210903 DATA RELEASE HAS GRADE INDICATOR, SO NO LONGER NEED TO RUN STEP 2A FIRST! ***
** UPDATED TO MATCH WITH OTHER SCORE FORMATTING CODE -- NEED TO INCLUDE NORMALIZATION ***
** MSM STEP 2 ES SCORES, REWRITTEN FROM SIYAN'S CODE, ELEMENTARY ONLY ***

*** MAIN OUTCOMES:
*** nkt_scores: nkt_notwb nkt_score_eoy nkt_std nkt_cat
*** trc_scores: trc_grade_lvl trc_notwb 
*** dibels_scores: dibels_std dibels_benchlvl dibels_notwb dibels_notbelow
********************* this file is for transfering data into implimentable format 

clear all
capture log close
set more off

log using output/Step_2_ES_Scores, text replace

/*********************************************************************
****		Find everyone in 2nd grade in 2018 for normalization purposes
*** NEED TO FIND 2ND GRADERS BECAUSE CURTEST INCLUDES LOTS OF VALUES ***
*** RUN STEP_2A GETS ALL 2ND GRADERS
*********************************************************************/


*************************************************************
**  TRC       ***********************************************
*************************************************************

*********************************************************************
****		Reading Levels in 2018 eoy >> end of the year
*********************************************************************

*insheet using "$rawdata/trc/trc_2018.csv",clear
*save trc_2018, replace

** 

use "Q:\Shared drives\AANP\AANP_Code\AANP_Code\Programs\ES_1_MakeData_1\trc_2018.dta"

* 09032021 release includes different variables, includes grade!
keep if grade == "2"
keep if benchmarkperiod == "EOY"
rename primaryschoolid school

* 09032021 release includes special education, demographics, and DATE!  update to include?
*keep encrypted trc_*lvl_eoy year
keep encrypted trc_*lvl year *date 
drop if encrypted==.

* NO NEED TO MERGE NEW VERSION B/C ALREADY HAS ONLY SECOND GRADERS
*merge 1:1 encrypted using "$workingdata/locator_2nd"
*tab school _merge
*keep if _merge == 3
*drop _merge year

*********************************************************************
****		Recoding reading levels to numbers (only for those in 2nd grade)
*********************************************************************

tab trc_prof
tab trc_book_lvl
tab trc_book_perf

** RENAME TO MATCH EARLIER VERSION OF CODE
rename trc_book_lvl trc_book_lvl_eoy
rename trc_prof trc_prof_lvl_eoy

********** EOY means the end of the calendar year
gen trc_book_lvl_eoy_ = trc_book_lvl_eoy 
replace trc_book_lvl_eoy_ = "" if trc_book_lvl_eoy_ == "PC"
*** gen score from 1 to 21 >> TRC benchmark goals for 2nd grader would be M to N
** need to earn at least 13
gen trc_score_num = .
local i = 1
foreach x in RB B C D E F G H I J K L M N O P Q R S T U {
 replace trc_score_num = `i' if trc_book_lvl_eoy_ =="`x'"
 local i = `i'+1
 }
drop trc_book_lvl_eoy_

sum trc_score_num, d
gen trc_score_mean = r(mean)
gen trc_score_sd = r(sd)
gen trc_std = (trc_score_num - trc_score_mean)/trc_score_sd
drop trc_score_mean trc_score_sd


** grade level equivalents ***
** if less than 3 >> below
capture drop trc_grade_lvl
gen trc_grade_lvl = .
replace trc_grade_lvl = 0 if inlist(trc_book_lvl_eoy, "RB", "PC") == 1
replace trc_grade_lvl = 0 if inlist(trc_book_lvl_eoy, "B", "C", "D") == 1
replace trc_grade_lvl = 1 if inlist(trc_book_lvl_eoy, "E", "F", "G", "H", "I", "J") == 1
replace trc_grade_lvl = 2 if inlist(trc_book_lvl_eoy, "K", "L", "M") == 1
replace trc_grade_lvl = 3 if inlist(trc_book_lvl_eoy, "N", "O", "P") == 1
replace trc_grade_lvl = 4 if inlist(trc_book_lvl_eoy, "Q", "R", "S") == 1
replace trc_grade_lvl = 5 if inlist(trc_book_lvl_eoy, "T", "U", "V") == 1
replace trc_grade_lvl = 6 if inlist(trc_book_lvl_eoy, "W", "X", "Y") == 1
replace trc_grade_lvl = 7.5 if inlist(trc_book_lvl_eoy, "Z") == 1


tab trc_grade_lvl trc_book_lvl_eoy, missing

gen trc_notwb = 1 - strpos(trc_prof_lvl_eoy ,"Far") if trc_prof_lvl_eoy ~=""
** fixed 1.2.2021 MSM 
gen trc_notbelow = 1 - ((strpos(trc_prof_lvl_eoy ,"Far")>0) | (trc_prof_lvl_eoy =="Below Proficient")) if trc_prof_lvl_eoy ~=""
tab trc_not*, missing

tab trc_grade_lvl trc_notwb, missing


* benchmark levels:
** gen level frm 1 to 4
** 1 is well below, 2 is below
gen trc_benchlvl = 1*(strpos(trc_prof_lvl_eoy ,"Far")>0) + 2*(trc_prof_lvl_eoy =="Below Proficient") ///
+ 3*(trc_prof_lvl_eoy =="Proficient") + 4*( strpos(trc_prof_lvl_eoy ,"Above")>0) if trc_prof_lvl_eoy ~=""

tab trc_benchlvl trc_grade_lvl, missing

keep encrypted_sid trc_book_lvl_eoy trc_grade_lvl trc_score_num trc_notwb trc_benchlvl trc_notbelow trc_std trc_prof_lvl_eoy
save "$workingdata/trc_scores",replace



*************************************************************
**  DIBELS    ***********************************************
*************************************************************


*********************************************************************
****		DIBELS in 2018 eoy
*********************************************************************

/*I am trying out:
- standardized DIBELS score, Standardized zero mean and sd 1
- DIBELS 4-point categories (1-4, ordinal groups, interpret it as relative to a one unit change in benchmark level)
- DIBELS not well below (0/1)
- DIBELS at or above benchmark
***/

*insheet using "$rawdata/dibels/dibels_2018.csv",clear
*save dibels_2018,replace
use "Q:\Shared drives\AANP\AANP_Code\AANP_Code\Programs\ES_1_MakeData_1\dibels_2018.dta"


keep if grade == "2"
drop year
drop if encrypted==.


** UPDATE THIS AFTER REPLICATION ***
*** use test score from middle of the year
***********************************why the title say end of the year??
keep if benchmark == "MOY"
rename comp_level comp_level_moy
rename comp_score comp_score_moy

duplicates report encrypted
count

* NO NEED TO MERGE NEW VERSION B/C ALREADY HAS ONLY SECOND GRADERS
*merge 1:1 encrypted using "$workingdata/locator_2nd"
*keep if _merge == 3
*drop _merge 

bysort comp_level_moy: sum comp_score_moy 

sum comp_score_moy,d
gen comp_score_moy_mean = r(mean)
gen comp_score_moy_sd = r(sd)

gen dibels_std = (comp_score_moy - comp_score_moy_mean)/comp_score_moy_sd

******* categories students into 4 levels >> 1 2 3 4 >> 4 perform the best
gen dibels_benchlvl = 1*(comp_level_moy == "Well Below Benchmark") + ///
2*(comp_level_moy == "Below Benchmark") + 3*(comp_level_moy == "Benchmark") + 4*(comp_level_moy == "Above Benchmark") if comp_level_moy ~= ""

gen dibels_notwb = (comp_level_moy ~= "Well Below Benchmark") if comp_level_moy ~= ""
gen dibels_notbelow = (dibels_benchlvl >= 3) if comp_level_moy ~= "" & dibels_benchlvl <= 4 & dibels_benchlvl >= 1

*** CHECK DATE_COMPLETED IN BALANCE TEST
keep encrypted_sid comp_score_moy comp_level_moy dibels_std dibels_benchlvl dibels_notwb dibels_notbelow  /***add***/ ///
syncdate clientdate administrationtype
save "$workingdata/dibels_scores",replace

***************************************************
*  NKT   ******************************************
***************************************************

*insheet using "$rawdata/nkt_2018_eoy.csv",clear
*insheet using "$rawdata/nkt/nkt_2018.csv",clear
*save nkt_2018,replace
use "Q:\Shared drives\AANP\AANP_Code\AANP_Code\Programs\ES_1_MakeData_1\nkt_2018.dta"


*format encrypted %12.0f
*tostring encrypted, gen(sid_string) usedisplayformat force

** added for eoy ***
************************************************************************************************ I think maybe the answer lies in here
keep if period == 3
keep if grade == 2

*drop year
drop if encrypted==.
rename student_score nkt_score_eoy
duplicates report encrypted

*keep sid_string nkt_score school_id 
*** CHECK DATE_COMPLETED IN BALANCE TEST
keep encrypted nkt_score school_id date_completed
rename school_id school
*gen sid_short = substr(sid_string, 1, 7)

* NO NEED TO MERGE NEW VERSION B/C ALREADY HAS ONLY SECOND GRADERS
*merge 1:1 sid_short school using "$workingdata/locator_2nd"
*merge 1:1 encrypted using "$workingdata/locator_grade2"
*tab school _merge
*keep if _merge == 3
*drop _merge 


* nkt category >> 1 2 3 4 5 6 >> 6 perform the best
egen nkt_cat = cut(nkt_score_eoy),at(0,7,9,15,21,26,29,30) icodes
replace nkt_cat = 6 if nkt_score_eoy==30
tab nkt_score_eoy nkt_cat

* standardize nkt_score
sum nkt_score_eoy, d
gen nkt_score_mean = r(mean)
* standard
gen nkt_score_sd = r(sd)
* standared deviation
gen nkt_std = (nkt_score_eoy - nkt_score_mean)/nkt_score_sd

*nkt well below benchmark
gen nkt_notwb = (nkt_score_eoy >= 15) & nkt_score_eoy <= 30 
*** why need to add nkt_score_eoy <= 30 
*** useful info about NKT benchmark https://riversmath.weebly.com/uploads/7/4/0/5/74051485/nkt_testing_windows_18-19.docx.pdf

*** CHECK DATE_COMPLETED IN BALANCE TEST
keep encrypted nkt_notwb nkt_score_eoy nkt_std nkt_cat date_completed
save "$workingdata/nkt_scores", replace

capture log close
