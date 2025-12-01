*** STEP 5A - THE LONG STEP OF OPENING THE LOCATOR FILE AND GETTING KTH GRADE COHORT -- RUN BEFORE STEP 5 MAKEDATA ES ****
*** DEFINES THE SAMPLE AND THE ON-TIME MEASURES ***

clear all
capture log close
set more off

*log using output/STEP5A_MAKEDATA_ES, replace text


****************************************************************
****		9th Grade Cohort AY2015-16
****************************************************************


*insheet using "$rawdata/locator.csv", clear
*save locator,replace
** just saving time so I transfer locator csv into dta
use "Q:\Shared drives\AANP\AANP_Code\AANP_Code\Programs\ES_1_MakeData_1\locator.dta",clear

*** UPDATES FOR 20210903 VERSION
rename schlyr year

** keep if applying year is 15-16AY
keep if year==2016
** keep kindergarten students in 15-16AY >> base sample >> need to find kids who keep enroll in Magnet school
keep if grade_level==9 // finding 9th grade in 15-16AY
** I think active means they enrolled in Magnet school in 15-16AY
keep if active==1
** check if there's duplicates sample
duplicates report encrypt


tab race_new
/*** CATEGORIES (PER MATT LENARD):
tab race_new

Use this one, not the other race variables. 
1 – AmInd/AKnative
2 – Asian
3 – Hispanic
4 – Black
5 – White
6 - Multiracial 
**/

gen race_white = race_new == 5
gen race_black = race_new == 4
gen race_hisp = race_new == 3
gen race_other = race_new < 3 | race_new > 5

gen race_asian = race_new == 2
gen race_nonasian_other = race_new < 2 | race_new > 5

** Valid school code and convert to the standard format for merging ***
tostring cur_school_code, gen(temp)
*** 920XXX would be the standard format for school code
** 920 stand for school from wake county
gen school = "920" + temp
drop cur_school_code temp
destring school, replace
replace school = 920001 if school==9201

** remove special schools *** >> not sure whether should be remove special school for high schooler
*drop if school == 920001 | school == 920292

* NOT ALL VARIABLES IN 20210903 VERSION
keep encrypted_sid race_*  ///
male homelanguagecode spec_ed_ever school grade_level ///
/*dob* *fe_indicator*/

*** KTH GRADE INFO, ALL STUDENTS HAVE ***

preserve

***************************************
*** ANNUAL INFO FOR ONTIME PROGRESS ***
***************************************
use "Q:\Shared drives\AANP\AANP_Code\AANP_Code\Programs\ES_1_MakeData_1\locator.dta",clear

**** FIRST GRADE ****
*insheet using "$rawdata/locator.csv", clear
*** UPDATES FOR 20210903 VERSION
rename schlyr year
** keep if applying year is 16-17AY
keep if year==2017
keep if active==1
** keep the kids who attend kindergarten in 15-16AY, now is first grade at 16-17AY
keep if grade_level == 10 | grade_level == 11 | grade_level == 9

** Valid school code and convert to the standard format for merging ***
tostring cur_school_code, gen(temp)
gen school = "920" + temp
drop cur_school_code temp
destring school, replace
replace school = 920001 if school==9201
rename school school_17
* keep nonmisssing data
keep if school_17 ~= .

** remove special schools *** >> not sure if we should do it for high schooler
*drop if school_17 == 920001 | school_17 == 920292

rename grade_level grade_2017
keep encrypted_sid school_17 grade_2017

tempfile temp
save `temp'

restore

merge 1:1 encrypted using `temp'
* drop if this students join the school at 17-18AY not from the very start
drop if _merge == 2 
gen ontime_1st = grade_2017 == 10 
** retain>> didn't attend 1st grade on time
gen retained_2017 = grade_2017 == 9 
** skip one grade
gen ahead_2017 = grade_2017 == 11 
* this is student attrited if can't find her/his info on the later file
gen attrit_1st = _merge == 1 
drop _merge

** want to know if there are weird case where the kid skip one grade? 
** yes, please refer to ahead_*

preserve
***** SECOND GRADE *****
use "Q:\Shared drives\AANP\AANP_Code\AANP_Code\Programs\ES_1_MakeData_1\locator.dta",clear
*insheet using "$rawdata/locator.csv", clear
*** UPDATES FOR 20210903 VERSION
rename schlyr year

keep if year==2018
keep if active==1
** keep the kids who attend kindergarten in 15-16AY, now is sec grade at 17-18AY
keep if grade_level == 11 | grade_level == 10 | grade_level == 12
** Valid school code and convert to the standard format for merging ***
tostring cur_school_code, gen(temp)
gen school = "920" + temp
drop cur_school_code temp
destring school, replace
replace school = 920001 if school==9201
rename school school_18
keep if school_18 ~= .
rename grade_level grade_2018

** remove special schools ***
*drop if school_18 == 920001 | school_18 == 920292

keep encrypted_sid school_18 grade_2018

tempfile temp
save `temp'

restore

merge 1:1 encrypted using `temp'
drop if _merge == 2 
gen ontime_2nd = (grade_2018 == 11)
*** wouldn't it accidentally inculde people who retained from 16-17 second grader?? 
*** No >> because we merge with the file contain only 15-16 applicant
gen retained_2018 = grade_2018 == 10 
gen ahead_2018 = grade_2018 == 12 
* this is student attrited if can't find her/his info on the later file
gen attrit_2nd = _merge == 1
drop _merge

save "Locator_9th", replace


*** explore data ****
** this is just to find out whether there's conflict
tab ontime_2nd ontime_1st, missing
tab attrit_1st attrit_2nd, missing
bysort retained_2018: tab  ontime_2nd attrit_2nd, missing
tab ahead_2018 if retained_2018 == 0 & ontime_2nd == 0 & attrit_2nd == 0, missing
bysort attrit_2nd: tab grade_2018 ontime_2nd, missing

log close
