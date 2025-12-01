*** locator does match with NKT but cannot get propensity score matched.  try one more time....***
** NEW LOCATOR MATCH WITH NEW PROPENSITY SCORE?***
*** NEW PROPENSITY SCORE IS: "$workingdata/p_scores_1mill"
*** NEW LOCATOR IS: "$workingdata/locator_grade2"" 
use "$workingdata/locator_grade2", clear
merge 1:1 encrypted using "$workingdata/p_scores_1mill"
*** old propensity score ***
insheet using "$rawdata2/p_scores_data_2015_190403_deidentified.csv", clear

merge 1:1 using "$workingdata/locator_grade2"
merge 1:1 encrypted using "$workingdata/locator_grade2"
*** try merging 2016 kindergarten locator file ***
insheet using "$rawdata/locator.csv", clear

keep if schlyr==2016

tab grade_level
keep if grade_level==0

merge 1:1 encrypted using "$workingdata/p_scores_1mill"
do "/Users/melindamorrill/Dropbox/AANP_Code/Programs/0_SetDirectories.do"
do "/var/folders/h2/06yjpdvj0hl50d5p2t25x4nw0000gn/T//SD06417.000000"
do "/Users/melindamorrill/Dropbox/AANP_Code/Programs/ES_1_MakeData/Step_1_pscores.do"
do "/Users/melindamorrill/Dropbox/AANP_Code/Programs/ES_1_MakeData/Step_2_ES_Scores.do"
merge 1:1 encrypted using "$workingdata/p_scores_1mill"
drop _merge
merge 1:1 encrypted using "$workingdata/p_scores_1mill"
do "/var/folders/h2/06yjpdvj0hl50d5p2t25x4nw0000gn/T//SD06417.000000"
count
help tempfile
tempfile mytemp
save mytemp
ls
rm mytemp
rm mytemp.dta
save "$workingdata\temp"
insheet using "$rawdata/locator.csv", clear

keep if schlyr == 2016
keep if grade == 0
merge 1:1 encrypted using "$workingdata/temp"
sum *grade*
keep if grade_level == 0
count
merge 1:1 encrypted using "$workingdata\temp"
bysort _merge: sum encrypted
 use "$workingdata\temp", clear
coun t
count
insheet using "$rawdata/locator.csv", clear
keep schlyr grade_level encrypted school
merge m:1 encrypted using "$workingdata\temp"
tab schlyr
keep if schlyr == 2016
takeep grade* *school* encrypted 
count
keep *grade* *school* encrypted
duplicates report encrypted
save "$workingdata/locator_small"
merge 1:1 encrypted using "$workingdata/temp"
insheet using "$rawdata/p_scores_data_2015_190403_deidentified.csv", clear

sum encrypted *school* *grade* next*
tab next_grade
keep encrypted *school* *grade* next*
merge 1:1 encrypted using "$workingdata/locator_small"
sum if _merge == 1
tab next_grade if _merge == 1
tab nextgrade if _merge == 2
gen diff = next_grade - nextgrade
do "/Users/melindamorrill/Dropbox/AANP_Code/Programs/ES_1_MakeData/Step_1_pscores.do"
do "/var/folders/h2/06yjpdvj0hl50d5p2t25x4nw0000gn/T//SD06417.000000"
do "/Users/melindamorrill/Dropbox/AANP_Code/Programs/ES_1_MakeData/Step_5A_Locator_Kth.do"
do "/Users/melindamorrill/Dropbox/Teaching/EC431/Fall 2021/Midterms/Analyze_midterm1.do"
log close
rm analyze_midterm1.txt
ls
cd "/Users/melindamorrill/Dropbox"
cd teaching
cd EC431
cd Fall2021
ls
d "Fall 2021"
cd "Fall 2021"
ls
do "/Users/melindamorrill/Dropbox/Teaching/EC431/Fall 2021/Midterms/Analyze_midterm1.do"
log close
rm analyze_midterm1
rm analyze_midterm1.txt
cd midterms
do analyze_midterm1
list
insheet using EC431_Midterm1_Grades.csv, clear names

list
tab total
count
drop if total == .
do "/var/folders/h2/06yjpdvj0hl50d5p2t25x4nw0000gn/T//SD06417.000000"
do "/var/folders/h2/06yjpdvj0hl50d5p2t25x4nw0000gn/T//SD06417.000000"
do "/Users/melindamorrill/Dropbox/Teaching/EC431/Fall 2021/Midterms/Analyze_midterm1.do"
do "/Users/melindamorrill/Dropbox/Teaching/EC431/Fall 2021/Midterms/Analyze_midterm1.do"
do "/Users/melindamorrill/Dropbox/Teaching/EC431/Fall 2021/Midterms/Analyze_midterm1.do"
do "/Users/melindamorrill/Dropbox/Teaching/EC431/Fall 2021/Midterms/Analyze_midterm1.do"
do "/Users/melindamorrill/Dropbox/Teaching/EC431/Fall 2021/Midterms/Analyze_midterm1.do"
use "/Volumes/GoogleDrive/Shared drives/MSAP_RAAL/RawData/employees_ratrained_20210910.dta"
exit
