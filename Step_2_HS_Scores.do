clear all
capture log close
set more off

log using output/Step_2_HS_Scores, text replace

** First set the directories **

cd "Q:\Shared drives\AANP\AANP_Code\AANP_Code\Programs\HS_1_MakeData"
global rawdata "Q:\Shared drives\AANP\WCPSS_ConfidentialData\WCPSS_20210903"
global workingdata "Q:\Shared drives\AANP\WCPSS_ConfidentialData\WorkingData"

********************************************************
****		All Test Scores and grade info
********************************************************
*insheet using "$rawdata/curtest_2007-2018.csv", clear
/*use data/curtest_panel_2006-2020,clear
drop if encrypt==.
*destring score, replace

tab test_id
keep if inlist(test_id,"ACCO","ACEN","ACMA","ACRD","ACSC","RD08","MA08","MTH1")

*tostring testdate, replace
gen date=date(testdate,"DMY")
format date %td
gen test_day=day(date)
gen test_month=month(date)
gen test_year=year(date)

** KEEP FIRST ACT ATTEMPT. INDICATOR FOR MULTIPLE ATTEMPTS
duplicates report encrypt test_id date 
bysort encrypt test_id date:keep if _n == 1

** KEEP FIRST ACT ATTEMPT. INDICATOR FOR MULTIPLE ATTEMPTS ** method 2
sort encrypt test_id test_year 
duplicates drop encrypt test_id test_year, force
save data/ACT_dupclear,replace */

use data/ACT_dupclear,clear
drop collect schlyr ach accom_list test_day test_month
duplicates drop encrypt, force

preserve

use data/ACT_dupclear,clear
drop if score ==.
sort encrypt test_id test_year 
duplicates tag encrypt test_id, generate(dup)
keep score dup encrypt test_year test_id
reshape wide score dup, i(encrypt test_year) j(test_id) string
sort encrypt test_year 

rename scoreACCO ACCO
rename scoreACEN ACEN
rename scoreACMA ACMA
rename scoreACRD ACRD
rename scoreACSC ACSC
rename scoreMA08 MA08
rename scoreRD08 RD08

/*gen ACCO = score if test_id == "ACCO"
gen ACEN = score if test_id == "ACEN"
gen ACMA = score if test_id == "ACMA"
gen ACRD = score if test_id == "ACRD"
gen ACSC = score if test_id == "ACSC"
gen MA08 = score if test_id == "MA08"
gen RD08 = score if test_id == "RD08" */

la var ACCO "ACT Combined Score"
la var ACEN "ACT English Score"
la var ACMA "ACT Math Score"
la var ACRD "ACT Reading Score"
la var ACSC "ACT Science Score"
la var MA08 "8th grade Math score"
la var RD08 "8th grade Reading score"

save data/all_actscores,replace

restore

merge 1:m encrypt using data/all_actscores
keep if _merge==3
save data/all_actscores,replace


*putdocx begin
*putdocx paragraph
***************************************************
****		Normalize Scores
***************************************************
bysort testdate: egen ACCO_mean=mean(ACCO) //"ACT Combined Score"
bysort testdate: egen ACCO_sd=sd(ACCO)
gen ACCO_z=(ACCO-ACCO_mean)/ACCO_sd
la var ACCO_z "standardized ACT Combined Score"

*hist ACCO_z, by(testdate) width(0.18)
*graph export graph.png, replace
*putdocx image graph.png 

bysort testdate: egen ACMA_mean=mean(ACMA) //"ACT Math Score"
bysort testdate: egen ACMA_sd=sd(ACMA)
gen ACMA_z=(ACMA-ACMA_mean)/ACMA_sd
la var ACMA_z "standardized ACT Math Score"

*hist ACMA_z, by(testdate) width(0.18)
*graph export graph.png, replace
*putdocx image graph.png 

bysort testdate: egen ACRD_mean=mean(ACRD) //"ACT Reading Score"
bysort testdate: egen ACRD_sd=sd(ACRD)
gen ACRD_z=(ACRD-ACRD_mean)/ACRD_sd
la var ACRD_z "standardized ACT Reading Score"

*hist ACRD_z, by(testdate)
*graph export graph.png, replace
*putdocx image graph.png 

bysort testdate: egen ACEN_mean=mean(ACEN) //"ACT English Score"
bysort testdate: egen ACEN_sd=sd(ACEN)
gen ACEN_z=(ACEN-ACEN_mean)/ACEN_sd
la var ACEN_z "standardized ACT English Score"

*hist ACEN_z, by(testdate)
*graph export graph.png, replace
*putdocx image graph.png 

bysort testdate: egen ACSC_mean=mean(ACSC) //"ACT Science Score"
bysort testdate: egen ACSC_sd=sd(ACSC)
gen ACSC_z=(ACSC-ACSC_mean)/ACSC_sd
la var ACSC_z "standardized ACT Science Score"

*hist ACSC_z, by(testdate)
*graph export graph.png, replace
*putdocx image graph.png 

bysort testdate: egen MA08_mean=mean(MA08) //"ACT English Score"
bysort testdate: egen MA08_sd=sd(MA08)
gen MA08_z=(MA08-MA08_mean)/MA08_sd
la var MA08_z "standardized 8th grade math score"

*hist MA08_z, by(testdate)
*graph export graph.png, replace
*putdocx image graph.png 

bysort testdate: egen RD08_mean=mean(RD08) //"ACT Science Score"
bysort testdate: egen RD08_sd=sd(RD08)
gen RD08_z=(RD08-RD08_mean)/RD08_sd
la var RD08_z "standardized 8th grade reading score"

*hist RD08_z, by(testdate)
*graph export graph.png, replace
*putdocx image graph.png 

*putdocx save "ACT and score hist.docx", replace

drop test_id score pctl dupACCO dupACEN dupACMA dupACRD dupACSC dupMA08 dupMTH1 dupRD08 _merge 
save data/all_actscores,replace


*********************************************************************
****		Find everyone in 11nd grade in 2018 
*** NEED TO FIND 2ND GRADERS BECAUSE CURTEST INCLUDES LOTS OF VALUES ***

************************  ACT(11th grade)  **************************     
****	keep score in 2018 march >> since there's more sample size here
*********************************************************************

use data/all_actscores,clear
preserve
keep if grade == 11 
keep if test_year == 2018 
keep if testdate == "01mar2018"
drop if ACEN==.|ACMA==.|ACRD==.|ACSC==.|ACCO==. 
keep encryp schlcode ACCO* ACEN* ACMA* ACRD* ACSC* date
duplicates drop encryp, force

save data/11grader_actscores,replace

** now I'm trying to get 8th grade outcome
*** but I'm not sure whether should I keep only scores from May 
restore
keep if grade == 8 
keep if test_year == 2015 
drop if MA08==.|RD08==.
keep encrypt MA08 RD08 
duplicates drop encryp, force
save data/8grader_outcome,replace

** there is no match :(
merge 1:1 encrypt using data/11grader_actscores


exit

***************************************************
*  saving NKT codes for comparing 
* NKT   ******************************************
***************************************************

keep if period == 3
keep if grade == 2

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


*********************************************************
*                    ACT scores files(just in case)
*************************************************************
**2012 Scores from class of file
*insheet using "$rawdata/act_class_of_2013.csv", clear

********preparing act file
insheet using "$rawdata/act/act_jrs_2018.csv", clear
bysort encrypt testdate:keep if _n == 1
duplicates e encrypt testdat
duplicates e encrypt
duplicates tag encrypt,gen(dup)
list if dup ==1
drop if ssmath ==. & encrypt ==  60515860 
duplicates drop encrypt,force
save act_jrs_2018,replace

insheet using "$rawdata/act/act_jrs_2019.csv", clear
duplicates e encrypt testdat
duplicates e encrypt

save act_jrs_2019,replace

insheet using "$rawdata/act/act_jrs_2017.csv", clear
duplicates e encrypt testdat
duplicates e encrypt

save act_jrs_2017,replace


use act_jrs_2018,clear
append using act_jrs_2019
append using act_jrs_2017

save act_jrs,replace

