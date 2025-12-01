** UPDATED 6.30.2021 -- RUN 0_SetDirectories first ***/
*** MAKEDATA FOR ABSENTEEISM - LINK ONTO DATA AT A LATER STEP ***
*** GET ABSENTEEISM RATES FOR TIME T+2 AND PRIOR YEAR ABSENTEEISM FOR 8TH AND 5TH ****

clear all
capture log close
set more on 

log using output/Step_4_Absences, replace text



/**********************************************************************************
****		Absences 2015-2018
**********************************************************************************

insheet using "$rawdata/absences_2014.csv", clear
duplicates report encry
duplicates report encry attend
duplicates tag encrypt, gen(dup)
gsort encrypt -school_membership_days

collapse (sum) total_* (max) tot_schls_attend = dup (first) current_school=attend , by(encrypt year)
sum total_*, detail

count if total_abs == .

save "$workingdata/absences2014", replace
*/

forvalues y = 2015/2018 {
*insheet using "$rawdata/absences_`y'.csv", clear
insheet using "$rawdata/attendance/student_daysmem_absences_cumul_`y'.csv", clear
rename schlyr year
rename abs_excused total_excused_absences
rename abs_unexcused total_unexcused_absences
rename total_abs total_absences
duplicates report encry
duplicates report encry attend
duplicates tag encrypt, gen(dup)
gsort encrypt -membership

collapse (sum) total_* (max) tot_schls_attend = dup grade_max = grade (min) grade_min = grade (first) current_school=attend , by(encrypt year)
sum total_*, detail
count if grade_max ~= grade_min
rename grade_max grade_abs
drop grade_min

count if total_abs == .
more
save "$workingdata/absences`y'", replace
}


log close




/*** DELETEME:  rewrite code for new data 
forvalues y = 2015/2018{
insheet using "$rawdata/attendance/student_daysmem_absences_cumul_`y'.csv", clear
tab schlyr
duplicates report encrypted_sid
duplicates report encrypted_sid attend_school

** get total at all schools and generate indicator for having multiple schools
duplicates tag encrypt, gen(tot_schls_attend)
duplicates report encrypted_sid membership_days

** membership days ***
collapse (sum) total_* abs_* membership (max) tot_schls_attend, by(encrypt)
count if total_abs == .
save "$workingdata/absences`y'", replace
}
*/
