****************************************************
** cleaning SEMrush data: mobile
****************************************************

****************************************************
** cleaning data regarding SEMrush traffic volumes for google.com/maps/dir, google.(country specific code)/maps/dir
** EU countries, European non-EU countries, other Non European countries




********************************************************************************
***************************************** EU countries *************************
********************************************************************************


global EU "Austria Belgium Bulgaria Croatia Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"


 foreach x of global EU {

//// visits 


import delimited "data/Semrush_data/EU/`x'/directions/visit.csv", varnames(nonames) clear



keep v1 v2 v4


assert v4[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_country_maps_dir
rename v4 google_com_maps_dir

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

replace google_country_maps_dir = subinstr(google_country_maps_dir, ",", "", .)
replace google_com_maps_dir = subinstr(google_com_maps_dir, ",", "", .)

destring google_country_maps_dir google_com_maps_dir, force replace


rename google_country_maps_dir  visit_google_country_maps_dir

rename google_com_maps_dir visit_google_com_maps_dir

gen visit_google_maps_dir=visit_google_country_maps_dir+visit_google_com_maps_dir


keep date month year visit_google_maps_dir visit_google_com_maps_dir visit_google_country_maps_dir

order date month year visit_google_maps_dir visit_google_com_maps_dir visit_google_country_maps_dir


destring visit_google_maps_dir visit_google_com_maps_dir visit_google_country_maps_dir, force replace



gen country = "`x'"

save "processed\Semrush_processed\visit_dir_`x'.dta",replace


//// pages 


import delimited "data/Semrush_data/EU/`x'/directions/visited_pages.csv", varnames(nonames) clear


keep v1 v2 v4


assert v4[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_country_maps_dir
rename v4 google_com_maps_dir

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

replace google_country_maps_dir = subinstr(google_country_maps_dir, ",", "", .)
replace google_com_maps_dir = subinstr(google_com_maps_dir, ",", "", .)


destring google_country_maps_dir google_com_maps_dir, force replace


rename google_country_maps_dir  pages_google_country_maps_dir

rename google_com_maps_dir pages_google_com_maps_dir

gen pages_google_maps_dir=pages_google_country_maps_dir+pages_google_com_maps_dir


keep date month year pages_google_maps_dir 

order date month year pages_google_maps_dir 


destring pages_google_maps_dir, force replace



gen country = "`x'"

save "processed\Semrush_processed\pages_dir_`x'.dta",replace



//// visit duration



import delimited "data/Semrush_data/EU/`x'/directions/visit_duration.csv", varnames(nonames) clear




keep v1 v2 v4


assert v4[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_country_maps_dir
rename v4 google_com_maps_dir

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021



gen tot_sec_google_country_maps_dir = real(substr(google_country_maps_dir, 1, 2)) * 60 + real(substr(google_country_maps_dir, 4, 2))

gen tot_sec_google_com_maps_dir = real(substr(google_com_maps_dir, 1, 2)) * 60 + real(substr(google_com_maps_dir, 4, 2))









destring tot_sec_google_country_maps_dir tot_sec_google_com_maps_dir, force replace



gen visit_duration_google_maps_dir=tot_sec_google_country_maps_dir+tot_sec_google_com_maps_dir


keep date month year visit_duration_google_maps_dir

order date month year visit_duration_google_maps_dir


destring visit_duration_google_maps_dir, force replace


gen country = "`x'"

save "processed\Semrush_processed\visit_duration_dir_`x'.dta",replace





//// bounce_rate




import delimited "data/Semrush_data/EU/`x'/directions/bounce_rate.csv", varnames(nonames) clear




keep v1 v2 v4


assert v4[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_country_maps_dir
rename v4 google_com_maps_dir

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021





replace google_country_maps_dir ="." if google_country_maps_dir=="n/a"

replace google_com_maps_dir ="." if google_com_maps_dir=="n/a"



replace google_country_maps_dir ="0" if google_country_maps_dir=="< 0.01%"

replace google_com_maps_dir ="0" if google_com_maps_dir=="< 0.01%"



replace google_country_maps_dir = subinstr(google_country_maps_dir, "%", "", .)

replace google_com_maps_dir = subinstr(google_com_maps_dir, "%", "", .)




destring google_country_maps_dir google_com_maps_dir, replace


merge 1:1 date using "processed\Semrush_processed\visit_dir_`x'.dta"


gen bounce_google_maps_dir = ((google_country_maps_dir*visit_google_country_maps_dir)+(google_com_maps_dir*visit_google_com_maps_dir))/visit_google_maps_dir
replace bounce_google_maps_dir=google_country_maps if google_com_maps==.
replace bounce_google_maps_dir=google_com_maps if google_country_maps==.


keep date month year bounce_google_maps_dir

order date month year bounce_google_maps_dir


destring bounce_google_maps_dir, force replace


gen country = "`x'"


save "processed\Semrush_processed\bounce_`x'.dta",replace



merge 1:1 date using "processed\Semrush_processed\visit_dir_`x'.dta"

drop visit_google_country_maps_dir visit_google_com_maps_dir _merge


merge 1:1 date using "processed\Semrush_processed\pages_dir_`x'.dta"
drop _merge

merge 1:1 date using "processed\Semrush_processed\visit_duration_dir_`x'.dta"
drop _merge



gen EU=1
gen Euro_NoEU=0
gen other=0

sort date country 


save "processed/Semrush_processed/all_dir_`x'.dta",replace


 }

 
 
global EU_1 "Belgium Bulgaria Croatia Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"

use "processed\Semrush_processed\all_dir_Austria.dta", clear


qui foreach x of global EU_1 {
	
append using "processed/Semrush_processed/all_dir_`x'.dta", force

}


sort date country 


order date month year visit_google_maps_dir visit_duration_google_maps_dir bounce_google_maps_dir


save "processed\Semrush_processed\dir_EU.dta",replace



********************************************************************************
**************************** European non-EU countries *************************
********************************************************************************

//// redo Albania: inconsistency in the files

global no_EU "Albania Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"



 foreach x of global no_EU {
 	
//// visits 


import delimited "data/Semrush_data/Euro_noEU/`x'/directions/visit.csv", varnames(nonames) clear



keep v1 v2 v4


assert v4[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_country_maps_dir
rename v4 google_com_maps_dir

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

replace google_country_maps_dir = subinstr(google_country_maps_dir, ",", "", .)
replace google_com_maps_dir = subinstr(google_com_maps_dir, ",", "", .)

destring google_country_maps_dir google_com_maps_dir, force replace



rename google_country_maps_dir  visit_google_country_maps_dir

rename google_com_maps_dir visit_google_com_maps_dir


gen visit_google_maps_dir=visit_google_country_maps_dir+visit_google_com_maps_dir


keep date month year visit_google_maps_dir visit_google_com_maps_dir visit_google_country_maps_dir

order date month year visit_google_maps_dir visit_google_com_maps_dir visit_google_country_maps_dir


destring visit_google_maps_dir visit_google_com_maps_dir visit_google_country_maps_dir, force replace



gen country = "`x'"

save "processed\Semrush_processed\visit_dir_`x'.dta",replace



//// pages 


import delimited "data/Semrush_data/Euro_noEU/`x'/directions/visited_pages.csv", varnames(nonames) clear


keep v1 v2 v4


assert v4[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_country_maps_dir
rename v4 google_com_maps_dir

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

replace google_country_maps_dir = subinstr(google_country_maps_dir, ",", "", .)
replace google_com_maps_dir = subinstr(google_com_maps_dir, ",", "", .)

destring google_country_maps_dir google_com_maps_dir, force replace


rename google_country_maps_dir  pages_google_country_maps_dir

rename google_com_maps_dir pages_google_com_maps_dir

gen pages_google_maps_dir=pages_google_country_maps_dir+pages_google_com_maps_dir

replace pages_google_maps_dir=pages_google_country_maps_dir if pages_google_com_maps_dir==.
replace pages_google_maps_dir=pages_google_com_maps_dir if pages_google_country_maps_dir==.


keep date month year pages_google_maps_dir 

order date month year pages_google_maps_dir 


destring pages_google_maps_dir, force replace



gen country = "`x'"

save "processed\Semrush_processed\pages_dir_`x'.dta",replace

//// visit duration



import delimited "data/Semrush_data/Euro_noEU/`x'/directions/visit_duration.csv", varnames(nonames) clear




keep v1 v2 v4


assert v4[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_country_maps_dir
rename v4 google_com_maps_dir

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021



gen tot_sec_google_country_maps_dir = real(substr(google_country_maps_dir, 1, 2)) * 60 + real(substr(google_country_maps_dir, 4, 2))

gen tot_sec_google_com_maps_dir = real(substr(google_com_maps_dir, 1, 2)) * 60 + real(substr(google_com_maps_dir, 4, 2))









destring tot_sec_google_country_maps_dir tot_sec_google_com_maps_dir, force replace



gen visit_duration_google_maps_dir=tot_sec_google_country_maps_dir+tot_sec_google_com_maps_dir


keep date month year visit_duration_google_maps_dir

order date month year visit_duration_google_maps_dir


destring visit_duration_google_maps_dir, force replace


gen country = "`x'"

save "processed\Semrush_processed\visit_duration_dir_`x'.dta",replace





//// bounce_rate




import delimited "data/Semrush_data/Euro_noEU/`x'/directions/bounce_rate.csv", varnames(nonames) clear




keep v1 v2 v4


assert v4[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_country_maps_dir
rename v4 google_com_maps_dir

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021





replace google_country_maps_dir ="." if google_country_maps_dir=="n/a"

replace google_com_maps_dir ="." if google_com_maps_dir=="n/a"



replace google_country_maps_dir ="0" if google_country_maps_dir=="< 0.01%"

replace google_com_maps_dir ="0" if google_com_maps_dir=="< 0.01%"



replace google_country_maps_dir = subinstr(google_country_maps_dir, "%", "", .)

replace google_com_maps_dir = subinstr(google_com_maps_dir, "%", "", .)




destring google_country_maps_dir google_com_maps_dir, replace


merge 1:1 date using "processed\Semrush_processed\visit_dir_`x'.dta"


gen bounce_google_maps_dir = ((google_country_maps_dir*visit_google_country_maps_dir)+(google_com_maps_dir*visit_google_com_maps_dir))/visit_google_maps_dir
replace bounce_google_maps_dir=google_country_maps if google_com_maps==.
replace bounce_google_maps_dir=google_com_maps if google_country_maps==.


keep date month year bounce_google_maps_dir

order date month year bounce_google_maps_dir


destring bounce_google_maps_dir, force replace


gen country = "`x'"


save "processed\Semrush_processed\bounce_`x'.dta",replace



merge 1:1 date using "processed\Semrush_processed\visit_dir_`x'.dta"

drop visit_google_country_maps_dir visit_google_com_maps_dir _merge


merge 1:1 date using "processed\Semrush_processed\pages_dir_`x'.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visit_duration_dir_`x'.dta"
drop _merge



gen EU=0
gen Euro_NoEU=1
gen other=0

sort date country 


save "processed/Semrush_processed/all_dir_`x'.dta",replace

}
 
 

global no_EU_1 "Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"


use "processed\Semrush_processed\all_dir_Albania.dta", clear


qui foreach x of global no_EU_1 {
	
append using "processed/Semrush_processed/all_dir_`x'.dta", force

}


sort date country 


order date month year visit_google_maps_dir visit_duration_google_maps_dir bounce_google_maps_dir


save "processed\Semrush_processed\dir_no_EU.dta",replace





********************************************************************************
**************************** non-European countries ****************************
********************************************************************************




global other "Australia Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK"



 foreach x of global other {

 	

//// visits 


import delimited "data/Semrush_data/other/`x'/directions/visit.csv", varnames(nonames) clear



keep v1 v2 v4


assert v4[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_country_maps_dir
rename v4 google_com_maps_dir

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

replace google_country_maps_dir = subinstr(google_country_maps_dir, ",", "", .)
replace google_com_maps_dir = subinstr(google_com_maps_dir, ",", "", .)

destring google_country_maps_dir google_com_maps_dir, force replace



rename google_country_maps_dir  visit_google_country_maps_dir

rename google_com_maps_dir visit_google_com_maps_dir

gen visit_google_maps_dir=visit_google_country_maps_dir+visit_google_com_maps_dir


keep date month year visit_google_maps_dir visit_google_com_maps_dir visit_google_country_maps_dir

order date month year visit_google_maps_dir visit_google_com_maps_dir visit_google_country_maps_dir


destring visit_google_maps_dir visit_google_com_maps_dir visit_google_country_maps_dir, force replace



gen country = "`x'"

save "processed\Semrush_processed\visit_dir_`x'.dta",replace


//// pages 


import delimited "data/Semrush_data/other/`x'/directions/visited_pages.csv", varnames(nonames) clear


keep v1 v2 v4


assert v4[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_country_maps_dir
rename v4 google_com_maps_dir

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

replace google_country_maps_dir = subinstr(google_country_maps_dir, ",", "", .)
replace google_com_maps_dir = subinstr(google_com_maps_dir, ",", "", .)


destring google_country_maps_dir google_com_maps_dir, force replace


rename google_country_maps_dir  pages_google_country_maps_dir

rename google_com_maps_dir pages_google_com_maps_dir

gen pages_google_maps_dir=pages_google_country_maps_dir+pages_google_com_maps_dir

replace pages_google_maps_dir=pages_google_country_maps_dir if pages_google_com_maps_dir==.
replace pages_google_maps_dir=pages_google_com_maps_dir if pages_google_country_maps_dir==.



keep date month year pages_google_maps_dir 

order date month year pages_google_maps_dir 


destring pages_google_maps_dir, force replace



gen country = "`x'"

save "processed\Semrush_processed\pages_dir_`x'.dta",replace


//// visit duration



import delimited "data/Semrush_data/other/`x'/directions/visit_duration.csv", varnames(nonames) clear




keep v1 v2 v4


assert v4[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_country_maps_dir
rename v4 google_com_maps_dir

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021



gen tot_sec_google_country_maps_dir = real(substr(google_country_maps_dir, 1, 2)) * 60 + real(substr(google_country_maps_dir, 4, 2))

gen tot_sec_google_com_maps_dir = real(substr(google_com_maps_dir, 1, 2)) * 60 + real(substr(google_com_maps_dir, 4, 2))









destring tot_sec_google_country_maps_dir tot_sec_google_com_maps_dir, force replace



gen visit_duration_google_maps_dir=tot_sec_google_country_maps_dir+tot_sec_google_com_maps_dir


keep date month year visit_duration_google_maps_dir

order date month year visit_duration_google_maps_dir


destring visit_duration_google_maps_dir, force replace


gen country = "`x'"

save "processed\Semrush_processed\visit_duration_dir_`x'.dta",replace





//// bounce_rate




import delimited "data/Semrush_data/other/`x'/directions/bounce_rate.csv", varnames(nonames) clear




keep v1 v2 v4


assert v4[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_country_maps_dir
rename v4 google_com_maps_dir

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021





replace google_country_maps_dir ="." if google_country_maps_dir=="n/a"

replace google_com_maps_dir ="." if google_com_maps_dir=="n/a"



replace google_country_maps_dir ="0" if google_country_maps_dir=="< 0.01%"

replace google_com_maps_dir ="0" if google_com_maps_dir=="< 0.01%"



replace google_country_maps_dir = subinstr(google_country_maps_dir, "%", "", .)

replace google_com_maps_dir = subinstr(google_com_maps_dir, "%", "", .)




destring google_country_maps_dir google_com_maps_dir, replace


merge 1:1 date using "processed\Semrush_processed\visit_dir_`x'.dta"


gen bounce_google_maps_dir = ((google_country_maps_dir*visit_google_country_maps_dir)+(google_com_maps_dir*visit_google_com_maps_dir))/visit_google_maps_dir
replace bounce_google_maps_dir=google_country_maps if google_com_maps==.
replace bounce_google_maps_dir=google_com_maps if google_country_maps==.


keep date month year bounce_google_maps_dir

order date month year bounce_google_maps_dir


destring bounce_google_maps_dir, force replace


gen country = "`x'"


save "processed\Semrush_processed\bounce_`x'.dta",replace



merge 1:1 date using "processed\Semrush_processed\visit_dir_`x'.dta"

drop visit_google_country_maps_dir visit_google_com_maps_dir _merge


merge 1:1 date using "processed\Semrush_processed\pages_dir_`x'.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visit_duration_dir_`x'.dta"
drop _merge



gen EU=0
gen Euro_NoEU=0
gen other=1

sort date country 


save "processed/Semrush_processed/all_dir_`x'.dta",replace

 }
 
	
	
	
	
	
 
 //// the US case
 
 //// visits 


import delimited "data/Semrush_data/other/US/directions/visit.csv", varnames(nonames) clear



keep v1 v2


assert v2[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_com_maps_dir

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

replace google_com_maps_dir = subinstr(google_com_maps_dir, ",", "", .)

destring  google_com_maps_dir, force replace



rename google_com_maps_dir visit_google_com_maps_dir

gen visit_google_maps_dir=visit_google_com_maps_dir


keep date month year visit_google_maps_dir 

order date month year visit_google_maps_dir 


destring visit_google_maps_dir, force replace



gen country = "US"

save "processed\Semrush_processed\visit_dir_US.dta",replace


//// pages 


import delimited "data/Semrush_data/other/US/directions/visited_pages.csv", varnames(nonames) clear


keep v1 v2


assert v2[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_com_maps_dir

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021


replace google_com_maps_dir = subinstr(google_com_maps_dir, ",", "", .)


destring google_com_maps_dir, force replace



rename google_com_maps_dir pages_google_maps_dir


keep date month year pages_google_maps_dir 

order date month year pages_google_maps_dir 


destring pages_google_maps_dir, force replace



gen country = "US"

save "processed\Semrush_processed\pages_dir_US.dta",replace


//// visit duration



import delimited "data/Semrush_data/other/US/directions/visit_duration.csv", varnames(nonames) clear



keep v1 v2


assert v2[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_com_maps_dir

drop in 1


generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021



gen tot_sec_google_com_maps_dir = real(substr(google_com_maps_dir, 1, 2)) * 60 + real(substr(google_com_maps_dir, 4, 2))









destring  tot_sec_google_com_maps_dir, force replace



gen visit_duration_google_maps_dir=tot_sec_google_com_maps_dir


keep date month year visit_duration_google_maps_dir

order date month year visit_duration_google_maps_dir


destring visit_duration_google_maps_dir, force replace


gen country = "US"

save "processed\Semrush_processed\visit_duration_dir_US.dta",replace





//// bounce_rate




import delimited "data/Semrush_data/other/US/directions/bounce_rate.csv", varnames(nonames) clear





keep v1 v2


assert v2[1] == "google.com/maps/dir/"
assert v1[1] == "Date"


rename v1 month
rename v2 google_com_maps_dir

drop in 1




generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021




replace google_com_maps_dir ="." if google_com_maps_dir=="n/a"


replace google_com_maps_dir ="0" if google_com_maps_dir=="< 0.01%"



replace google_com_maps_dir = subinstr(google_com_maps_dir, "%", "", .)




destring google_com_maps_dir, replace


gen bounce_google_maps_dir = google_com_maps_dir


keep date month year bounce_google_maps_dir

order date month year bounce_google_maps_dir


destring bounce_google_maps_dir, force replace


gen country = "US"


save "processed\Semrush_processed\bounce_US.dta",replace



merge 1:1 date using "processed\Semrush_processed\visit_dir_US.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\pages_dir_US.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visit_duration_dir_US.dta"
drop _merge



gen EU=0
gen Euro_NoEU=0
gen other=1

sort date country 


save "processed/Semrush_processed/all_dir_US.dta",replace

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
global other_1 "Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

use "processed\Semrush_processed\all_dir_Australia.dta", clear


qui foreach x of global other_1 {
	
append using "processed/Semrush_processed/all_dir_`x'.dta", force

}


sort date country 

save "processed\Semrush_processed\dir_other.dta",replace



append using "processed/Semrush_processed/dir_no_EU.dta", force
 
append using "processed/Semrush_processed/dir_EU.dta", force

encode country, generate(country1)

drop country

rename country1 country


tab country



save "processed\Semrush_processed\all_dir_semrush.dta",replace



use "processed\Semrush_processed\all_dir_semrush.dta",replace




