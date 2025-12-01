** UPDATED 6.30.2021 -- RUN 0_SetDirectories first ***/
* MSM Step 1 PSCORES -- all assignment-related variables including sibling measures -- all schools all grade cohorts, only data used in the final paper ***

clear all
capture log close
set more off

log using output/Step_1_pscores.txt, text replace

*********************************************************************
****		Propensity Scores
*********************************************************************

*insheet using "$rawdata/p_scores_data_2015_190403_deidentified.csv", clear
*save p_scores_data,replace
** to save some time I save the dta file here instead of keep loading raw data from excel file
use "Q:\Shared drives\AANP\AANP_Code\AANP_Code\Programs\ES_1_MakeData_1\p_scores_data.dta"

*******THE 1 MILLION RUN PSCORE THAT SHOULD BE USED IS MAG_P_SCORE_NEW -- THIS STEP ROUNDS TO 11 OR 101 BINS ***
gen pscore_mil_10=round(mag_p_score_new_count,100000)/100000 
* the above code: 1000000/100000 = 10 >> 0 1 2 3 4 5 6 7 8 9 10 >> 11bins
gen pscore_mil_100=round(mag_p_score_new_count,10000)/10000 
* the above code create 101 bins
******** have different #bins for matching

********* generate instrument and conditionally seated sample >> instrument here is mag_offer
gen mag_offer=factual_assignment!=0 if !missing(factual_assignment)
** the numbers in factual_assignment are school number and project number

********* year is the spring semester of the academic year (AY)
* Year 1 assignment was conducted in 2015 for the 2015-16 AY
* so year here means 15-16AY
gen year=2016

*********** use address information to generate sibling indicators:
****** has_sibling, not_oldest, multiples (twins)
* add means address
gsort add -curr_grade encrypt
** old being list fist

by add: gen birth_ord=_n
** obtaining birth order
by add: egen num_sib=max(birth_ord)
** obtaining number of sibiling 
gen has_sib=num_sib>1

*ES DEFINES THIS AS HAS_TWINS
duplicates report add_id next_grade
** report if in this address there's more than 2 kids in the same year
** use this to identify whether there's twins in one household

duplicates tag add_id next_grade, generate(num_multiples)
** num_multiples return number of twins that certain observation have
** the following code change multiples into dummy variable that implies whether this person has twins
gen multiples=num_multiples!=0
exit


/*********************** FIX FOR NOT_OLDEST TO BE OK FOR TWINS ****************/
/*** using Siyan's code, slighlty different*/
bysort add_id (encrypted):egen min_birth_ord = min(birth_ord)
** (encrypted) is just helping sorting.  this code is aiming for gen min_birth_ord for one household>> min_birth_ord means the oldest kid
* not oldest: 1) has no twins and someone in same address born earlier 2) has twins and someone in same address born earlier than each twin
gen not_oldest_siyan = (birth_ord~=1 & multiples==0 | min_birth_ord>1 & multiples==1)

*********** Ariel: the only factor that would affect whether the second or the third... child is oldest is that whether the first kid is twins
* first I want to find out whether the first kid is twins in this household, then I want to find out 他是幾包胎
bysort add_id (birth_ord): gen first_is_twin = multiples[1]!=0
bysort add_id (birth_ord): gen first_twin_number = 1+num_multiples[1]
gen oldest_phen = ( first_is_twin!=1 & birth_ord==1 | first_is_twin==1 & birth_ord <= first_twin_number)
bysort add_id: egen we_have_multiple = mean(multiples)

list add_id birth_ord first_is_twin multiples first_twin_number if we_have_multiple!=0, sepby(add_id)

*keep add_id curr_grade encrypted first_is_twin multiples next_grade birth_ord has_sib num_sib
gen not_oldest_phen = oldest_phen!=1
list birth_ord first_twin_number first_is_twin multiples oldest_phen not_oldest_phen if we_have_multiple!=0, sepby(add_id)

*****YZ: min_birth_ord was generated as =1 for all. So not_oldest was not generated appropriately. My proposed codes:
***generates a new variable containing the number of duplicates for each observation
duplicates report add_id next_grade
duplicates tag add_id next_grade, generate(temp_multiples)
***binary/dummy variable indicating whether or not twins
*drop temp_multiples
gen oldest = 0 
replace oldest = 1 if birth_ord == 1
replace oldest = 1 if birth_ord == 2 & temp_multiples>0
*** 萬一是2-3是雙胞胎呢?
replace oldest = 1 if birth_ord == 3 & temp_multiples == 2
gen not_oldest_new = 1 - oldest
list birth_ord multiples oldest_phen oldest not_oldest_phen not_oldest_new, sepby(add_id)
** 注意74-76

** 比較結果差異
gsort add_id birth_ord
list birth_ord multiples not_oldest* if we_have_multiple!=0, sepby(add_id)
*** 注意 3903 >> triplets， 還有1541>> 23是雙胞胎，
exit


* drop unneeded variables
*drop points* min_birth_ord 

*** modify as needed ***
keep pscore_mil_* mag_p_score_new* mag_offer factual_assignment  ///
encrypt next_grade has_sib  not_oldest multiples ///
catchment curr_grade curr_school next_school next_grade  ps1_920*  ///
seat_holder first_choice       ///
 sped ag_eith add_id sped_exceptionality
** for MS/HS keep also sped ag_eith, etc.

compress
save "$workingdata/p_scores_1mill", replace

log close

