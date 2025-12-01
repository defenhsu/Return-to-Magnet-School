*** UPDATED FOR 20210903 DATA RELEASE -- FIX / CHECK SCHOOLS DATA NOT MATCHING***
** UPDATED 6.30.2021 -- RUN 0_SetDirectories first ***/
/** schools data moved to WCPSS_Schools folder ES/MS/HS_Schools.dta ****/

*** STEP 5 - MAKEDATA ES -- RUN STEP 5A GET LOCATOR FIRST ****
*** REDO STEP 11 FROM JOHN'S CODE -- MAKE ANALYSIS DATA AND COMPARISON DATA***
*** uses new data on schools -- "$workingdata/SchoolInfo_2016_Final" ***


*** MAGNET APPLICANT IS NOT THE SAME SAMPLE AS KTH GRADE COHORT: ATTRITION, NEW ENTRANTS, NON-MAGNET APPLICANTS ***
*** THIS CODE MAKES THE ANALYSIS SAMPLE (IGNORES PRE-K ATTRITION), MATCH ON SCHOOL AT EACH TIME ***

clear all
capture log close
set more off

log using output/STEP5_MAKEDATA_ES.txt, replace text


****************************************************************
****		Kth Grade Cohort AY2015-16
****************************************************************

** Kth locator is defined in step 5A -- includes on-time progress indicators, new students, attrited students ***
use "$workingdata/Locator_Kth", clear

drop if school ==  920508 

/*** ON-TIME PROGRESS / ATTRITION -- NOW DEFINED IN STEP 5A ***/
tab ontime_2nd
tab attrit_1st attrit_2nd, missing row col cell
** grade_level is student's grade ay 15-16AY
tab grade_level


****************************************************************
****		Kth Grade Cohort -- ATTENDING SCHOOL INFO KTH GRADE
****************************************************************

** SCHOOL IS CURRENT SCHOOL ATTENDING IN KTH GRADE ***
** only add basic info now, merge on other data when need it ***
*merge m:1 school using "$workingdata/SchoolInfo_2016_Final", keepusing(magnet_16* calendar_16) 
merge m:1 school using "../../WCPSS_Schools/ES_Schools", keepusing(magnet_16* calendar_16) 
tab school _merge
drop if _merge == 2
drop _merge

** keep magnet 16 designation but must rename so it is not overwritten -- PUTS IT AT THE END NOW
drop magnet_16_*

****************************************************************
****		Kth Grade Cohort -- ATTENDING SCHOOL INFO 2ND GRADE
****************************************************************

** SCHOOLS FILE HAS ONE YEAR MISALIGNMENT OF YEARS B/C OF ASSIGNMENT YEAR VS. ACADEMIC YEAR
** SCHOOL HETEROGENEITY IS CORRECT FOR 2018 TOO, SO CHANGE THAT

** only add basic info now, merge on other data when need it ***
rename school school_16
gen school = school_18 
*merge m:1 school using "$workingdata/SchoolInfo_2016_Final", keepusing(m17) 
merge m:1 school using "../../WCPSS_Schools/ES_Schools", keepusing(m17 magnet_16_*) 

tab school _merge
drop if _merge == 2
drop _merge
rename m17 magnet_18
replace magnet_18 = 0 if magnet_18 == . & school_18 < .
replace magnet_18 = . if school_18 == 920001
** traditional school v.s destination school
rename magnet_16_DEST magnet_18_DEST
rename magnet_16_TRAD magnet_18_TRAD
** langage immersion v.s non langage imersion
rename magnet_16_imm magnet_18_imm
rename magnet_16_not_imm magnet_18_not_imm


** only add basic info now, merge on other data when need it ***
replace school = school_17 
merge m:1 school using "../../WCPSS_Schools/ES_Schools", keepusing(m16) 
tab school _merge
drop if _merge == 2
drop _merge
rename m16 magnet_17
replace magnet_17 = 0 if magnet_17 == . & school_17 < .
replace magnet_17 = . if school_17 == 920001

replace school = school_16



****************************************************************
****		Kth Grade Cohort -- ABSENCES 
****************************************************************
count

*** 
** _1: attrited students
** _2: new students
** _3: on-time progress
*** use main locator file to figure this out ***
** ABSENCES EACH YEAR ***
tab grade_level, missing
gen grade_abs = grade_level
merge 1:1 encrypt grade_abs using "$workingdata/absences2016", keepusing(total_absences)
rename total_absences tot_abs_2016
rename grade_abs grade_2016

** ALL STUDENTS SHOULD BE THERE UNLESS THEY HAD ZERO ABSENCES
** THOSE ATTRITED BEFORE K ARE MAG_ATTRITED
** DO NOT ADD NEW STUDENTS TO WCPSS
tab grade_2016 _merge, missing
*tab mag_attrited _merge, missing

drop if grade_2016 ~= 0 & _merge == 2
drop if _merge == 2

*** _merge == 1: zero absences or attrited from sample ***
replace tot_abs_2016 = 0 if _merge == 1 & grade_2016 == 0
drop _merge

merge 1:1 encrypt using "$workingdata/absences2017", keepusing(total_absences grade_abs)
rename total_absences tot_abs_2017
tab grade_abs grade_2017, missing

*** attrited students should be attrit_1st 
*** new students new_1st
tab grade_abs _merge, missing
drop if (grade_abs ~= 1 | grade_abs ~= 0) & _merge == 2

** NEW STUDENTS ARE IN ABSENCES BUT NOT IN OUR SAMPLE
drop if _merge == 2

** ATTRITERS ARE IN OUR SAMPLE BUT NOT ABSENCES
tab grade_abs _merge, missing
tab attrit_1st _merge, missing
tab ontime_1st _merge, missing
replace tot_abs_2017 = . if attrit_1st == 1

*** _merge == 1: zero absences or attrited from sample ***
replace tot_abs_2017 = 0 if _merge == 1 & attrit_1st == 0 & ontime_1st == 1
count if tot_abs_2017 == .
tab attrit_1st ontime_1st if tot_abs_2017 == ., missing

tab _merge, missing
tab grade_level grade_2017 if _merge == 3, missing
***RECHECK THIS***
drop grade_level grade_abs
drop _merge

count

merge 1:1 encrypt using "$workingdata/absences2018", keepusing(total_absences grade_abs)
rename total_absences tot_abs_2018
tab grade_abs grade_2018, missing

*** attrited students should be attrit_2nd 
tab grade_abs _merge, missing
drop if (grade_abs ~= 2 | grade_abs ~= 1) & _merge == 2

** NEW STUDENTS ARE IN ABSENCES BUT NOT IN OUR SAMPLE
tab grade_abs _merge, missing
drop if _merge == 2

** ATTRITERS ARE IN OUR SAMPLE BUT NOT ABSENCES
tab grade_abs _merge, missing
tab attrit_2nd _merge, missing
tab ontime_2nd _merge, missing
replace tot_abs_2018 = . if attrit_2nd == 1

*** _merge == 1: zero absences or attrited from sample ***
replace tot_abs_2018 = 0 if _merge == 1 & attrit_2nd == 0 & ontime_2nd == 1
count if tot_abs_2018 == .
tab attrit_2nd ontime_2nd if tot_abs_2018 == ., missing

tab _merge, missing
***RECHECK THIS***
drop grade_abs
drop _merge

count

* sum up absences over 3 years
gen tot_abs_ES = tot_abs_2016 + tot_abs_2017 + tot_abs_2018
gen log_abs_ES = ln(tot_abs_ES+1)
la var log_abs_ES "Ln(3yr abs+1)"

/*
gen tot_abs_gt9=tot_abs>9 if !missing(tot_abs_ES)
gen tot_abs_gt20=tot_abs>20 if !missing(tot_abs_ES)
*/

/***************************************************
/**** TEST SCORES ****/
*** MAIN OUTCOMES:
*** nkt_scores: nkt_notwb nkt_score_eoy nkt_std nkt_cat
*** trc_scores: trc_grade_lvl trc_notwb 
*** dibels_scores: dibels_std dibels_benchlvl dibels_notwb dibels_notbelow
***************************************************/

***********
*** NKT ***
***********

merge 1:1 encrypt using "$workingdata/nkt_scores"
** _1: attrited students OR missing test score info
** _2: new students
** _3: on-time progress
*** use main locator file to figure this out ***

** _2: new students
drop if _merge == 2

** _1: attrited students OR missing test score info
tab grade_2018 ontime_2nd, missing
tab grade_2018 _merge, missing
gen nkt_missing = (_merge == 1) if ontime_2nd == 1 

** _3: on-time progress
tab ontime_2nd _merge, missing
sum nkt*
tab nkt_missing


drop _merge
count

***********
*** TRC ***
***********

merge 1:1 encrypt using "$workingdata/trc_scores"
** _1: attrited students OR missing test score info
** _2: new students
** _3: on-time progress
*** use main locator file to figure this out ***
tab grade_2018 _merge, missing

** _2: new students
drop if _merge == 2

** _1: attrited students OR missing test score info
tab grade_2018 ontime_2nd, missing
tab grade_2018 _merge, missing
gen trc_missing = (_merge == 1) if ontime_2nd == 1 

** _3: on-time progress
tab ontime_2nd _merge, missing
sum trc_*
tab trc_missing

drop _merge

count

***********
*** DIBELS ***
***********

merge 1:1 encrypt using "$workingdata/dibels_scores"
** _1: attrited students OR missing test score info
** _2: new students
** _3: on-time progress
*** use main locator file to figure this out ***
tab grade_2018 _merge, missing

** _2: new students
drop if _merge == 2

** _1: attrited students OR missing test score info
tab grade_2018 ontime_2nd, missing
tab grade_2018 _merge, missing
gen dibels_missing = (_merge == 1) if ontime_2nd == 1 

** _3: on-time progress
tab ontime_2nd _merge, missing
sum dibels_*
tab dibels_missing

drop _merge
count

bysort nkt_missing: tab dibels_missing trc_missing, missing

tab ontime_2nd
* 9,987 students in the same on-time to 2nd
* Valid all three: 9,774
* Missing all three: 146
* Missing NKT Only: 24
* Missing NKT and DIBELS: 2
* Missing NKT and TRC: 2
* Missing TRC and DIBELS: 35
* Missing TRC only: 0
* Missing DIBELS only: 4
di 9774+146+24+2+2+35+4



****************************************************************
****		Kth Grade Applicants 2015 Match AND BASE SCHOOL INFO
** PUTTING THIS LAST SO GETTING THE MAG ATTRITERS AFTER ALL THE OTHER INFO IS MERGED ON
****************************************************************
preserve

use "$workingdata/p_scores_1mill", clear
* keep 15-16AY magnet school applicant >> our target sample
keep if next_grade==0
keep if next_school ~= .
gen school = next_school

*merge m:1 school using "$workingdata/SchoolInfo_2016_Final", keepusing(calendar_16 magnet_16)
merge m:1 school using "../../WCPSS_Schools/ES_Schools", keepusing(magnet_16* calendar_16) 
keep if _merge!=2
drop _merge
rename magnet_16 base_magnet
rename calendar_16 base_calendar 


tempfile temp
save `temp'

restore

merge 1:1 encrypt using `temp'
* _merge = 1 ==> not a magnet applicant
* _merge = 2 ==> attrited from sample post-application
tab _merge mag_offer, missing col
gen mag_applicant = _merge > 1
gen mag_attrited = _merge == 2

sum mag_p_score_new_count, detail
*********** only have off of complier for sample
gen aanp_sample_mil= (mag_p_score_new_count > 0) if mag_applicant == 1
** those who got reserved seat doesn't count
replace aanp_sample_mil = 0 if mag_p_score_new_count == 1000000
replace aanp_sample_mil = 0 if base_magnet == 1

sum mag_p_score_new_count if aanp_sample_mil == 1, detail

drop _merge

*** CATCHMENT INFO ***
*merge m:1 catchment_code using "$workingdata/CatchmentInfo2015"
merge m:1 catchment_code using "../../WCPSS_Schools/CatchmentInfo2015"
tab mag_applicant _merge, missing
drop if _merge == 2
drop _merge

tab haspoints_c mag_applicant, missing



********************************************************
****		On-time/Attrition Measures
********************************************************

** FOR REGRESSIONS, NEED CONTINUOUS ENROLLMENT
*** use ontime_2nd for that
** attrit_2nd
** retained*

** DEFINE SWITCHING SCHOOLS
gen switch_schools=(school != school_17 | school != school_18 | school_17 != school_18) if attrit_2nd == 0

count
tab mag_attrited, missing
tab aanp_sample, missing

*keep if ontime_2nd == 1

*** CHECK DEFINITIONS
tab magnet_16 magnet_18 if ontime_2nd == 1, missing
tab switch_schools if magnet_16 ~= magnet_18 & ontime_2nd == 1, missing

save "$workingdata/MagAtt_ES", replace
log close

