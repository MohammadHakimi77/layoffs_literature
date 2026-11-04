****************************************************
** cleaning SEMrush data: desktop
****************************************************

****************************************************
** cleaning data regarding SEMrush traffic volumes for google.com, google.(country specific code); google.com/maps, google.(country specific code)/maps; bing.com/maps
** EU countries, European non-EU countries, other Non European countries

	 									

********************************************************************************
***************************************** EU countries *************************
********************************************************************************


global EU "Austria Belgium Bulgaria Croatia Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"


 foreach x of global EU {

//// visits 

import delimited "data/Semrush_data/EU/`x'/visits.csv", varnames(nonames) clear



assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps


gen country_spec=google_country_maps
replace country_spec="" if month!=""

gen country_spec1=country_spec[1]

drop country_spec
rename country_spec1 country_spec



drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

destring google_country_maps google_country google_com bing_com_maps google_com_maps, replace



rename google_country_maps visit_google_country_maps
rename google_country visit_google_country
rename google_com visit_google_com
rename bing_com_maps visit_bing_com_maps
rename google_com_maps visit_google_com_maps



gen visit_google=visit_google_country+visit_google_com

gen visit_google_maps=visit_google_country_maps+visit_google_com_maps


save "processed\Semrush_processed\visit_`x'_all.dta",replace


keep date month year visit_google visit_google_maps visit_bing_com_maps country_spec

order date month year visit_google visit_google_maps visit_bing_com_maps country_spec


destring visit_google visit_google_maps visit_bing_com_maps, force replace


gen country = "`x'"

save "processed\Semrush_processed\visit_`x'.dta",replace



//// visit duration

import delimited "data/Semrush_data/EU/`x'/visit_duration.csv", varnames(nonames) clear

assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

gen tot_sec_google_country_maps = real(substr(google_country_maps, 1, 2)) * 60 + real(substr(google_country_maps, 4, 2))

gen tot_sec_google_country = real(substr(google_country, 1, 2)) * 60 + real(substr(google_country, 4, 2))

gen tot_sec_google_com = real(substr(google_com, 1, 2)) * 60 + real(substr(google_com, 4, 2))

gen tot_sec_bing_com_maps = real(substr(bing_com_maps, 1, 2)) * 60 + real(substr(bing_com_maps, 4, 2))

gen tot_sec_google_com_maps = real(substr(google_com_maps, 1, 2)) * 60 + real(substr(google_com_maps, 4, 2))



merge 1:1 date using "processed\Semrush_processed\visit_`x'_all.dta"

drop _merge google_country_maps google_country google_com bing_com_maps google_com_maps 



gen visit_duration_google=((tot_sec_google_com*visit_google_com)+(tot_sec_google_country*visit_google_country))/visit_google


gen visit_duration_google_maps=((tot_sec_google_com*visit_google_com_maps)+(tot_sec_google_country*visit_google_country_maps))/visit_google_maps


rename tot_sec_bing_com_maps visit_duration_bing_com_maps

keep date month year visit_duration_google visit_duration_google_maps visit_duration_bing_com_maps

order date month year visit_duration_google visit_duration_google_maps visit_duration_bing_com_maps


destring visit_duration_google visit_duration_google_maps visit_duration_bing_com_maps, force replace


gen country = "`x'"

save "processed\Semrush_processed\visit_duration_`x'.dta",replace



//// visitors

import delimited "data/Semrush_data/EU/`x'/unique_visitor.csv", varnames(nonames) clear

assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021




destring google_country_maps google_country google_com bing_com_maps google_com_maps, replace




gen visitor_google=google_country+google_com

gen visitor_google_maps=google_country_maps+google_com_maps

rename bing_com_maps visitor_bing_maps

keep date month year visitor_google visitor_google_maps visitor_bing_maps

order date month year visitor_google visitor_google_maps visitor_bing_maps


destring visitor_google visitor_google_maps visitor_bing_maps, force replace


gen country = "`x'"

save "processed\Semrush_processed\visitor_`x'.dta",replace






//// page_visit

import delimited "data/Semrush_data/EU/`x'/page_visit.csv", varnames(nonames) clear

assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021


destring google_country_maps google_country google_com bing_com_maps google_com_maps, replace


merge 1:1 date using "processed\Semrush_processed\visit_`x'_all.dta"


gen page_visit_google = ((google_country*visit_google_country)+(google_com*visit_google_com))/visit_google
replace page_visit_google=google_country if google_com==.
replace page_visit_google=google_com if google_country==.

gen page_visit_google_maps = ((google_country_maps*visit_google_country_maps)+(google_com_maps*visit_google_com_maps))/visit_google_maps
replace page_visit_google_maps=google_country_maps if google_com_maps==.
replace page_visit_google_maps=google_com_maps if google_country_maps==.

gen page_visit_bing_com_maps = bing_com_maps



keep date month year page_visit_google page_visit_google_maps page_visit_bing_com_maps

order date month year page_visit_google page_visit_google_maps page_visit_bing_com_maps


destring page_visit_google page_visit_google_maps page_visit_bing_com_maps, force replace


gen country = "`x'"

save "processed\Semrush_processed\page_visit_`x'.dta",replace



//// mobile

import delimited "data/Semrush_data/EU/`x'/mobile.csv", varnames(nonames) clear

assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021


destring google_country_maps google_country google_com bing_com_maps google_com_maps, force replace




gen visit_mobile_google=google_country+google_com

gen visit_mobile_google_maps=google_country_maps+google_com_maps

rename bing_com_maps visit_mobile_bing_maps

keep date month year visit_mobile_google visit_mobile_google_maps visit_mobile_bing_maps

order date month year visit_mobile_google visit_mobile_google_maps visit_mobile_bing_maps


destring visit_mobile_google visit_mobile_google_maps visit_mobile_bing_maps, force replace


gen country = "`x'"

save "processed\Semrush_processed\visit_mobile_`x'.dta",replace




//// bounce

import delimited "data/Semrush_data/EU/`x'/bounce.csv", varnames(nonames) clear

assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021


replace google_country_maps ="." if google_country_maps=="n/a"

replace google_com ="." if google_com=="n/a"

replace bing_com_maps ="." if bing_com_maps=="n/a"

replace google_com_maps ="." if google_com_maps=="n/a"

replace google_country ="." if google_country=="n/a"


replace google_country_maps ="0" if google_country_maps=="< 0.01%"

replace google_com ="0" if google_com=="< 0.01%"

replace bing_com_maps ="0" if bing_com_maps=="< 0.01%"

replace google_com_maps ="0" if google_com_maps=="< 0.01%"

replace google_country ="0" if google_country=="< 0.01%"


gen google_country_maps_1 = subinstr(google_country_maps, "%", "", .)

gen google_com_1 = subinstr(google_com, "%", "", .)

gen bing_com_maps_1 = subinstr(bing_com_maps, "%", "", .)

gen google_com_maps_1 = subinstr(google_com_maps, "%", "", .)

gen google_country_1 = subinstr(google_country, "%", "", .)

drop google_country_maps google_com bing_com_maps google_com_maps google_country


rename google_country_maps_1 google_country_maps

rename google_com_1 google_com

rename bing_com_maps_1 bing_com_maps

rename google_com_maps_1 google_com_maps

rename google_country_1 google_country


destring google_country_maps google_country google_com bing_com_maps google_com_maps, replace


merge 1:1 date using "processed\Semrush_processed\visit_`x'_all.dta"


gen bounce_google = ((google_country*visit_google_country)+(google_com*visit_google_com))/visit_google
replace bounce_google=google_country if google_com==.
replace bounce_google=google_com if google_country==.

gen bounce_google_maps = ((google_country_maps*visit_google_country_maps)+(google_com_maps*visit_google_com_maps))/visit_google_maps
replace bounce_google_maps=google_country_maps if google_com_maps==.
replace bounce_google_maps=google_com_maps if google_country_maps==.

gen bounce_bing_com_maps = bing_com_maps



keep date month year bounce_google bounce_google_maps bounce_bing_com_maps

order date month year bounce_google bounce_google_maps bounce_bing_com_maps


destring bounce_google bounce_google_maps bounce_bing_com_maps, force replace


gen country = "`x'"


save "processed\Semrush_processed\bounce_`x'.dta",replace



/// channel_maps

import delimited "data/Semrush_data/EU/`x'/channel_maps.csv", varnames(1) clear 

rename v1 month
generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

rename direct direct_com_maps

rename referral referral_com_maps

rename organicsearch organicsearch_com_maps



keep date month year direct_com_maps referral_com_maps organicsearch_com_maps

order date month year direct_com_maps referral_com_maps organicsearch_com_maps


destring direct_com_maps referral_com_maps organicsearch_com_maps, force replace


gen country = "`x'"


save "processed\Semrush_processed\channel_com_maps_`x'.dta",replace



/// channel_country_maps

import delimited "data/Semrush_data/EU/`x'/channel_country_maps.csv", varnames(1) clear 

rename v1 month
generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

rename direct direct_country_maps

rename referral referral_country_maps

rename organicsearch organicsearch_country_maps



keep date month year direct_country_maps referral_country_maps organicsearch_country_maps

order date month year direct_country_maps referral_country_maps organicsearch_country_maps


destring direct_country_maps referral_country_maps organicsearch_country_maps, force replace


gen country = "`x'"


replace direct_country_maps=0 if direct_country_maps==.

replace referral_country_maps=0 if referral_country_maps==.

replace organicsearch_country_maps=0 if organicsearch_country_maps==.

save "processed\Semrush_processed\channel_country_maps_`x'.dta",replace



merge 1:1 date using "processed\Semrush_processed\channel_com_maps_`x'.dta"
drop _merge


gen direct_google_maps = direct_country_maps + direct_com_maps

gen referral_google_maps = referral_country_maps + referral_com_maps

gen organicsearch_google_maps = organicsearch_country_maps + organicsearch_com_maps

keep date month year direct_google_maps referral_google_maps organicsearch_google_maps country 


 
merge 1:1 date using "processed\Semrush_processed\bounce_`x'.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visit_mobile_`x'.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\page_visit_`x'.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visitor_`x'.dta"
drop _merge



merge 1:1 date using "processed\Semrush_processed\visit_duration_`x'.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visit_`x'.dta"
drop _merge




gen EU=1
gen Euro_NoEU=0
gen other=0

sort date country 


save "processed/Semrush_processed/all_`x'.dta",replace

 }
 



global EU_1 "Belgium Bulgaria Croatia Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"

use "processed\Semrush_processed\all_Austria.dta", clear


qui foreach x of global EU_1 {
	
append using "processed/Semrush_processed/all_`x'.dta", force

}


sort date country 

save "processed\Semrush_processed\EU.dta",replace







********************************************************************************
**************************** European non-EU countries *************************
********************************************************************************

//// redo Albania: inconsistency in the files

global no_EU "Albania Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"



 foreach x of global no_EU {

//// visits 

import delimited "data/Semrush_data/Euro_noEU/`x'/visits.csv", varnames(nonames) clear



assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

gen country_spec=google_country_maps
replace country_spec="" if month!=""

gen country_spec1=country_spec[1]

drop country_spec
rename country_spec1 country_spec

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

destring google_country_maps google_country google_com bing_com_maps google_com_maps, force replace



rename google_country_maps visit_google_country_maps
rename google_country visit_google_country
rename google_com visit_google_com
rename bing_com_maps visit_bing_com_maps
rename google_com_maps visit_google_com_maps



gen visit_google=visit_google_country+visit_google_com

gen visit_google_maps=visit_google_country_maps+visit_google_com_maps


save "processed\Semrush_processed\visit_`x'_all.dta",replace


keep date month year visit_google visit_google_maps visit_bing_com_maps country_spec

order date month year visit_google visit_google_maps visit_bing_com_maps country_spec


destring visit_google visit_google_maps visit_bing_com_maps, force replace


gen country = "`x'"

save "processed\Semrush_processed\visit_`x'.dta",replace



//// visit duration

import delimited "data/Semrush_data/Euro_noEU/`x'/visit_duration.csv", varnames(nonames) clear

assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

gen tot_sec_google_country_maps = real(substr(google_country_maps, 1, 2)) * 60 + real(substr(google_country_maps, 4, 2))

gen tot_sec_google_country = real(substr(google_country, 1, 2)) * 60 + real(substr(google_country, 4, 2))

gen tot_sec_google_com = real(substr(google_com, 1, 2)) * 60 + real(substr(google_com, 4, 2))

gen tot_sec_bing_com_maps = real(substr(bing_com_maps, 1, 2)) * 60 + real(substr(bing_com_maps, 4, 2))

gen tot_sec_google_com_maps = real(substr(google_com_maps, 1, 2)) * 60 + real(substr(google_com_maps, 4, 2))



merge 1:1 date using "processed\Semrush_processed\visit_`x'_all.dta"

drop _merge google_country_maps google_country google_com bing_com_maps google_com_maps 



gen visit_duration_google=((tot_sec_google_com*visit_google_com)+(tot_sec_google_country*visit_google_country))/visit_google


gen visit_duration_google_maps=((tot_sec_google_com*visit_google_com_maps)+(tot_sec_google_country*visit_google_country_maps))/visit_google_maps


rename tot_sec_bing_com_maps visit_duration_bing_com_maps

keep date month year visit_duration_google visit_duration_google_maps visit_duration_bing_com_maps

order date month year visit_duration_google visit_duration_google_maps visit_duration_bing_com_maps


destring visit_duration_google visit_duration_google_maps visit_duration_bing_com_maps, force replace


gen country = "`x'"

save "processed\Semrush_processed\visit_duration_`x'.dta",replace



//// visitors

import delimited "data/Semrush_data/Euro_noEU/`x'/unique_visitor.csv", varnames(nonames) clear

assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021




destring google_country_maps google_country google_com bing_com_maps google_com_maps, force replace




gen visitor_google=google_country+google_com

gen visitor_google_maps=google_country_maps+google_com_maps

rename bing_com_maps visitor_bing_maps

keep date month year visitor_google visitor_google_maps visitor_bing_maps

order date month year visitor_google visitor_google_maps visitor_bing_maps


destring visitor_google visitor_google_maps visitor_bing_maps, force replace


gen country = "`x'"

save "processed\Semrush_processed\visitor_`x'.dta",replace






//// page_visit

import delimited "data/Semrush_data/Euro_noEU/`x'/page_visit.csv", varnames(nonames) clear

assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021


destring google_country_maps google_country google_com bing_com_maps google_com_maps, force replace


merge 1:1 date using "processed\Semrush_processed\visit_`x'_all.dta"


gen page_visit_google = ((google_country*visit_google_country)+(google_com*visit_google_com))/visit_google
replace page_visit_google=google_country if google_com==.
replace page_visit_google=google_com if google_country==.

gen page_visit_google_maps = ((google_country_maps*visit_google_country_maps)+(google_com_maps*visit_google_com_maps))/visit_google_maps
replace page_visit_google_maps=google_country_maps if google_com_maps==.
replace page_visit_google_maps=google_com_maps if google_country_maps==.

gen page_visit_bing_com_maps = bing_com_maps



keep date month year page_visit_google page_visit_google_maps page_visit_bing_com_maps

order date month year page_visit_google page_visit_google_maps page_visit_bing_com_maps


destring page_visit_google page_visit_google_maps page_visit_bing_com_maps, force replace


gen country = "`x'"

save "processed\Semrush_processed\page_visit_`x'.dta",replace



//// mobile

import delimited "data/Semrush_data/Euro_noEU/`x'/mobile.csv", varnames(nonames) clear

assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021


destring google_country_maps google_country google_com bing_com_maps google_com_maps, force replace




gen visit_mobile_google=google_country+google_com

gen visit_mobile_google_maps=google_country_maps+google_com_maps

rename bing_com_maps visit_mobile_bing_maps

keep date month year visit_mobile_google visit_mobile_google_maps visit_mobile_bing_maps

order date month year visit_mobile_google visit_mobile_google_maps visit_mobile_bing_maps


destring visit_mobile_google visit_mobile_google_maps visit_mobile_bing_maps, force replace


gen country = "`x'"

save "processed\Semrush_processed\visit_mobile_`x'.dta",replace




//// bounce

import delimited "data/Semrush_data/Euro_noEU/`x'/bounce.csv", varnames(nonames) clear

assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021


replace google_country_maps ="." if google_country_maps=="n/a"

replace google_com ="." if google_com=="n/a"

replace bing_com_maps ="." if bing_com_maps=="n/a"

replace google_com_maps ="." if google_com_maps=="n/a"

replace google_country ="." if google_country=="n/a"


replace google_country_maps ="0" if google_country_maps=="< 0.01%"

replace google_com ="0" if google_com=="< 0.01%"

replace bing_com_maps ="0" if bing_com_maps=="< 0.01%"

replace google_com_maps ="0" if google_com_maps=="< 0.01%"

replace google_country ="0" if google_country=="< 0.01%"


gen google_country_maps_1 = subinstr(google_country_maps, "%", "", .)

gen google_com_1 = subinstr(google_com, "%", "", .)

gen bing_com_maps_1 = subinstr(bing_com_maps, "%", "", .)

gen google_com_maps_1 = subinstr(google_com_maps, "%", "", .)

gen google_country_1 = subinstr(google_country, "%", "", .)

drop google_country_maps google_com bing_com_maps google_com_maps google_country


rename google_country_maps_1 google_country_maps

rename google_com_1 google_com

rename bing_com_maps_1 bing_com_maps

rename google_com_maps_1 google_com_maps

rename google_country_1 google_country


destring google_country_maps google_country google_com bing_com_maps google_com_maps, force replace


merge 1:1 date using "processed\Semrush_processed\visit_`x'_all.dta"


gen bounce_google = ((google_country*visit_google_country)+(google_com*visit_google_com))/visit_google
replace bounce_google=google_country if google_com==.
replace bounce_google=google_com if google_country==.

gen bounce_google_maps = ((google_country_maps*visit_google_country_maps)+(google_com_maps*visit_google_com_maps))/visit_google_maps
replace bounce_google_maps=google_country_maps if google_com_maps==.
replace bounce_google_maps=google_com_maps if google_country_maps==.

gen bounce_bing_com_maps = bing_com_maps



keep date month year bounce_google bounce_google_maps bounce_bing_com_maps

order date month year bounce_google bounce_google_maps bounce_bing_com_maps


destring bounce_google bounce_google_maps bounce_bing_com_maps, force replace


gen country = "`x'"


save "processed\Semrush_processed\bounce_`x'.dta",replace



/// channel_maps

import delimited "data/Semrush_data/Euro_noEU/`x'/channel_maps.csv", varnames(1) clear 

rename v1 month
generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

rename direct direct_com_maps

rename referral referral_com_maps

rename organicsearch organicsearch_com_maps



keep date month year direct_com_maps referral_com_maps organicsearch_com_maps

order date month year direct_com_maps referral_com_maps organicsearch_com_maps


destring direct_com_maps referral_com_maps organicsearch_com_maps, force replace


gen country = "`x'"


save "processed\Semrush_processed\channel_com_maps_`x'.dta",replace



/// channel_country_maps

import delimited "data/Semrush_data/Euro_noEU/`x'/channel_country_maps.csv", varnames(1) clear 

rename v1 month
generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

rename direct direct_country_maps

rename referral referral_country_maps

rename organicsearch organicsearch_country_maps



keep date month year direct_country_maps referral_country_maps organicsearch_country_maps

order date month year direct_country_maps referral_country_maps organicsearch_country_maps


destring direct_country_maps referral_country_maps organicsearch_country_maps, force replace


gen country = "`x'"


replace direct_country_maps=0 if direct_country_maps==.

replace referral_country_maps=0 if referral_country_maps==.

replace organicsearch_country_maps=0 if organicsearch_country_maps==.


save "processed\Semrush_processed\channel_country_maps_`x'.dta",replace



merge 1:1 date using "processed\Semrush_processed\channel_com_maps_`x'.dta"
drop _merge



assert direct_country_maps != direct_com_maps



gen direct_google_maps = direct_country_maps + direct_com_maps

gen referral_google_maps = referral_country_maps + referral_com_maps

gen organicsearch_google_maps = organicsearch_country_maps + organicsearch_com_maps

keep date month year direct_google_maps referral_google_maps organicsearch_google_maps country 


 
merge 1:1 date using "processed\Semrush_processed\bounce_`x'.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visit_mobile_`x'.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\page_visit_`x'.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visitor_`x'.dta"
drop _merge




merge 1:1 date using "processed\Semrush_processed\visit_duration_`x'.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visit_`x'.dta"
drop _merge




gen EU=0
gen Euro_NoEU=1
gen other=0

sort date country 


save "processed/Semrush_processed/all_`x'.dta",replace

 }
 




global no_EU_1 "Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"

use "processed\Semrush_processed\all_Albania.dta", clear


qui foreach x of global no_EU_1 {
	
append using "processed/Semrush_processed/all_`x'.dta", force

}


sort date country 

save "processed\Semrush_processed\no_EU.dta",replace




********************************************************************************
**************************** non-European countries ****************************
********************************************************************************




global other "Australia Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK"



 foreach x of global other {

//// visits 

import delimited "data/Semrush_data/other/`x'/visits.csv", varnames(nonames) clear



assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps


gen country_spec=google_country_maps
replace country_spec="" if month!=""

gen country_spec1=country_spec[1]

drop country_spec
rename country_spec1 country_spec 

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

destring google_country_maps google_country google_com bing_com_maps google_com_maps, force replace



rename google_country_maps visit_google_country_maps
rename google_country visit_google_country
rename google_com visit_google_com
rename bing_com_maps visit_bing_com_maps
rename google_com_maps visit_google_com_maps



gen visit_google=visit_google_country+visit_google_com

gen visit_google_maps=visit_google_country_maps+visit_google_com_maps


save "processed\Semrush_processed\visit_`x'_all.dta",replace


keep date month year visit_google visit_google_maps visit_bing_com_maps country_spec

order date month year visit_google visit_google_maps visit_bing_com_maps country_spec


destring visit_google visit_google_maps visit_bing_com_maps, force replace


gen country = "`x'"

save "processed\Semrush_processed\visit_`x'.dta",replace



//// visit duration

import delimited "data/Semrush_data/other/`x'/visit_duration.csv", varnames(nonames) clear

assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

gen tot_sec_google_country_maps = real(substr(google_country_maps, 1, 2)) * 60 + real(substr(google_country_maps, 4, 2))

gen tot_sec_google_country = real(substr(google_country, 1, 2)) * 60 + real(substr(google_country, 4, 2))

gen tot_sec_google_com = real(substr(google_com, 1, 2)) * 60 + real(substr(google_com, 4, 2))

gen tot_sec_bing_com_maps = real(substr(bing_com_maps, 1, 2)) * 60 + real(substr(bing_com_maps, 4, 2))

gen tot_sec_google_com_maps = real(substr(google_com_maps, 1, 2)) * 60 + real(substr(google_com_maps, 4, 2))



merge 1:1 date using "processed\Semrush_processed\visit_`x'_all.dta"

drop _merge google_country_maps google_country google_com bing_com_maps google_com_maps 



gen visit_duration_google=((tot_sec_google_com*visit_google_com)+(tot_sec_google_country*visit_google_country))/visit_google


gen visit_duration_google_maps=((tot_sec_google_com*visit_google_com_maps)+(tot_sec_google_country*visit_google_country_maps))/visit_google_maps


rename tot_sec_bing_com_maps visit_duration_bing_com_maps

keep date month year visit_duration_google visit_duration_google_maps visit_duration_bing_com_maps

order date month year visit_duration_google visit_duration_google_maps visit_duration_bing_com_maps


destring visit_duration_google visit_duration_google_maps visit_duration_bing_com_maps, force replace


gen country = "`x'"

save "processed\Semrush_processed\visit_duration_`x'.dta",replace



//// visitors

import delimited "data/Semrush_data/other/`x'/unique_visitor.csv", varnames(nonames) clear

assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021




destring google_country_maps google_country google_com bing_com_maps google_com_maps, force  replace




gen visitor_google=google_country+google_com

gen visitor_google_maps=google_country_maps+google_com_maps

rename bing_com_maps visitor_bing_maps

keep date month year visitor_google visitor_google_maps visitor_bing_maps

order date month year visitor_google visitor_google_maps visitor_bing_maps


destring visitor_google visitor_google_maps visitor_bing_maps, force replace


gen country = "`x'"

save "processed\Semrush_processed\visitor_`x'.dta",replace






//// page_visit

import delimited "data/Semrush_data/other/`x'/page_visit.csv", varnames(nonames) clear

assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021


destring google_country_maps google_country google_com bing_com_maps google_com_maps, force replace


merge 1:1 date using "processed\Semrush_processed\visit_`x'_all.dta"


gen page_visit_google = ((google_country*visit_google_country)+(google_com*visit_google_com))/visit_google
replace page_visit_google=google_country if google_com==.
replace page_visit_google=google_com if google_country==.

gen page_visit_google_maps = ((google_country_maps*visit_google_country_maps)+(google_com_maps*visit_google_com_maps))/visit_google_maps
replace page_visit_google_maps=google_country_maps if google_com_maps==.
replace page_visit_google_maps=google_com_maps if google_country_maps==.

gen page_visit_bing_com_maps = bing_com_maps



keep date month year page_visit_google page_visit_google_maps page_visit_bing_com_maps

order date month year page_visit_google page_visit_google_maps page_visit_bing_com_maps


destring page_visit_google page_visit_google_maps page_visit_bing_com_maps, force replace


gen country = "`x'"

save "processed\Semrush_processed\page_visit_`x'.dta",replace



//// mobile

import delimited "data/Semrush_data/other/`x'/mobile.csv", varnames(nonames) clear

assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021


destring google_country_maps google_country google_com bing_com_maps google_com_maps, force replace




gen visit_mobile_google=google_country+google_com

gen visit_mobile_google_maps=google_country_maps+google_com_maps

rename bing_com_maps visit_mobile_bing_maps

keep date month year visit_mobile_google visit_mobile_google_maps visit_mobile_bing_maps

order date month year visit_mobile_google visit_mobile_google_maps visit_mobile_bing_maps


destring visit_mobile_google visit_mobile_google_maps visit_mobile_bing_maps, force replace


gen country = "`x'"

save "processed\Semrush_processed\visit_mobile_`x'.dta",replace




//// bounce

import delimited "data/Semrush_data/other/`x'/bounce.csv", varnames(nonames) clear

assert v4[1] == "google.com"
assert v5[1] == "bing.com/maps/"
assert v6[1] == "google.com/maps/"

gen last_six = substr(v2, -6, .)
assert last_six[1] == "/maps/"

drop last_six

rename v1 month
rename v2 google_country_maps
rename v3 google_country
rename v4 google_com
rename v5 bing_com_maps
rename v6 google_com_maps

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021


replace google_country_maps ="." if google_country_maps=="n/a"

replace google_com ="." if google_com=="n/a"

replace bing_com_maps ="." if bing_com_maps=="n/a"

replace google_com_maps ="." if google_com_maps=="n/a"

replace google_country ="." if google_country=="n/a"


replace google_country_maps ="0" if google_country_maps=="< 0.01%"

replace google_com ="0" if google_com=="< 0.01%"

replace bing_com_maps ="0" if bing_com_maps=="< 0.01%"

replace google_com_maps ="0" if google_com_maps=="< 0.01%"

replace google_country ="0" if google_country=="< 0.01%"


gen google_country_maps_1 = subinstr(google_country_maps, "%", "", .)

gen google_com_1 = subinstr(google_com, "%", "", .)

gen bing_com_maps_1 = subinstr(bing_com_maps, "%", "", .)

gen google_com_maps_1 = subinstr(google_com_maps, "%", "", .)

gen google_country_1 = subinstr(google_country, "%", "", .)

drop google_country_maps google_com bing_com_maps google_com_maps google_country


rename google_country_maps_1 google_country_maps

rename google_com_1 google_com

rename bing_com_maps_1 bing_com_maps

rename google_com_maps_1 google_com_maps

rename google_country_1 google_country


destring google_country_maps google_country google_com bing_com_maps google_com_maps, force replace


merge 1:1 date using "processed\Semrush_processed\visit_`x'_all.dta"


gen bounce_google = ((google_country*visit_google_country)+(google_com*visit_google_com))/visit_google
replace bounce_google=google_country if google_com==.
replace bounce_google=google_com if google_country==.

gen bounce_google_maps = ((google_country_maps*visit_google_country_maps)+(google_com_maps*visit_google_com_maps))/visit_google_maps
replace bounce_google_maps=google_country_maps if google_com_maps==.
replace bounce_google_maps=google_com_maps if google_country_maps==.

gen bounce_bing_com_maps = bing_com_maps



keep date month year bounce_google bounce_google_maps bounce_bing_com_maps

order date month year bounce_google bounce_google_maps bounce_bing_com_maps


destring bounce_google bounce_google_maps bounce_bing_com_maps, force replace


gen country = "`x'"


save "processed\Semrush_processed\bounce_`x'.dta",replace



/// channel_maps

import delimited "data/Semrush_data/other/`x'/channel_maps.csv", varnames(1) clear 

rename v1 month
generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

rename direct direct_com_maps

rename referral referral_com_maps

rename organicsearch organicsearch_com_maps



keep date month year direct_com_maps referral_com_maps organicsearch_com_maps

order date month year direct_com_maps referral_com_maps organicsearch_com_maps


destring direct_com_maps referral_com_maps organicsearch_com_maps, force replace


gen country = "`x'"


save "processed\Semrush_processed\channel_com_maps_`x'.dta",replace



/// channel_country_maps

import delimited "data/Semrush_data/other/`x'/channel_country_maps.csv", varnames(1) clear 

rename v1 month
generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

rename direct direct_country_maps

rename referral referral_country_maps

rename organicsearch organicsearch_country_maps



keep date month year direct_country_maps referral_country_maps organicsearch_country_maps

order date month year direct_country_maps referral_country_maps organicsearch_country_maps


destring direct_country_maps referral_country_maps organicsearch_country_maps, force replace

replace direct_country_maps=0 if direct_country_maps==.

replace referral_country_maps=0 if referral_country_maps==.

replace organicsearch_country_maps=0 if organicsearch_country_maps==.


gen country = "`x'"


save "processed\Semrush_processed\channel_country_maps_`x'.dta",replace



merge 1:1 date using "processed\Semrush_processed\channel_com_maps_`x'.dta"
drop _merge



assert direct_country_maps != direct_com_maps


gen direct_google_maps = direct_country_maps + direct_com_maps

gen referral_google_maps = referral_country_maps + referral_com_maps

gen organicsearch_google_maps = organicsearch_country_maps + organicsearch_com_maps

keep date month year direct_google_maps referral_google_maps organicsearch_google_maps country 


 
merge 1:1 date using "processed\Semrush_processed\bounce_`x'.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visit_mobile_`x'.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\page_visit_`x'.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visitor_`x'.dta"
drop _merge




merge 1:1 date using "processed\Semrush_processed\visit_duration_`x'.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visit_`x'.dta"
drop _merge




gen EU=0
gen Euro_NoEU=0
gen other=1

sort date country 


save "processed/Semrush_processed/all_`x'.dta",replace

 }
 
 
 
 
 //// the US case
 
 
 
//// visits 

import delimited "data/Semrush_data/other/US/visits.csv", varnames(nonames) clear



rename v1 month
rename v2 google_maps
rename v3 google_com
rename v4 bing_com_maps


gen country_spec=""

drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

destring google_com bing_com_maps google_maps, force replace




rename google_com visit_google
rename bing_com_maps visit_bing_com_maps
rename google_maps visit_google_maps




keep date month year visit_google visit_google_maps visit_bing_com_maps

order date month year visit_google visit_google_maps visit_bing_com_maps


destring visit_google visit_google_maps visit_bing_com_maps, force replace


gen country = "US"

save "processed\Semrush_processed\visit_US.dta",replace



//// visit duration

import delimited "data/Semrush_data/other/US/visit_duration.csv", varnames(nonames) clear

rename v1 month
rename v2 google_maps
rename v3 google_com
rename v4 bing_com_maps


drop in 1




generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

gen visit_duration_google = real(substr(google_com, 1, 2)) * 60 + real(substr(google_com, 4, 2))

gen visit_duration_bing_com_maps = real(substr(bing_com_maps, 1, 2)) * 60 + real(substr(bing_com_maps, 4, 2))

gen visit_duration_google_maps = real(substr(google_maps, 1, 2)) * 60 + real(substr(google_maps, 4, 2))


keep date month year visit_duration_google visit_duration_google_maps visit_duration_bing_com_maps

order date month year visit_duration_google visit_duration_google_maps visit_duration_bing_com_maps


destring visit_duration_google visit_duration_google_maps visit_duration_bing_com_maps, force replace


gen country = "US"

save "processed\Semrush_processed\visit_duration_US.dta",replace



//// visitors

import delimited "data/Semrush_data/other/US/unique_visitor.csv", varnames(nonames) clear

rename v1 month
rename v2 google_maps
rename v3 google_com
rename v4 bing_com_maps


drop in 1





generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021




destring google_com bing_com_maps google_maps, force  replace




gen visitor_google=google_com

gen visitor_google_maps=google_maps

rename bing_com_maps visitor_bing_maps

keep date month year visitor_google visitor_google_maps visitor_bing_maps

order date month year visitor_google visitor_google_maps visitor_bing_maps


destring visitor_google visitor_google_maps visitor_bing_maps, force replace


gen country = "US"

save "processed\Semrush_processed\visitor_US.dta",replace





//// page_visit

import delimited "data/Semrush_data/other/US/page_visit.csv", varnames(nonames) clear

rename v1 month
rename v2 google_maps
rename v3 google_com
rename v4 bing_com_maps


drop in 1



generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021



gen page_visit_google = google_com

gen page_visit_google_maps = google_maps

gen page_visit_bing_com_maps = bing_com_maps



keep date month year page_visit_google page_visit_google_maps page_visit_bing_com_maps

order date month year page_visit_google page_visit_google_maps page_visit_bing_com_maps


destring page_visit_google page_visit_google_maps page_visit_bing_com_maps, force replace


gen country = "US"

save "processed\Semrush_processed\page_visit_US.dta",replace



//// mobile

import delimited "data/Semrush_data/other/US/mobile.csv", varnames(nonames) clear


rename v1 month
rename v2 google_com 
rename v3 bing_com_maps
rename v4 google_maps


drop in 1





generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021


destring google_com bing_com_maps google_maps, force replace




gen visit_mobile_google=google_com

gen visit_mobile_google_maps=google_maps

rename bing_com_maps visit_mobile_bing_maps

keep date month year visit_mobile_google visit_mobile_google_maps visit_mobile_bing_maps

order date month year visit_mobile_google visit_mobile_google_maps visit_mobile_bing_maps


destring visit_mobile_google visit_mobile_google_maps visit_mobile_bing_maps, force replace


gen country = "US"

save "processed\Semrush_processed\visit_mobile_US.dta",replace




//// bounce

import delimited "data/Semrush_data/other/US/bounce.csv", varnames(nonames) clear


rename v1 month
rename v2 google_maps
rename v3 google_com
rename v4 bing_com_maps


drop in 1




generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021



replace google_com ="." if google_com=="n/a"

replace bing_com_maps ="." if bing_com_maps=="n/a"

replace google_maps ="." if google_maps=="n/a"


replace google_com ="0" if google_com=="< 0.01%"

replace bing_com_maps ="0" if bing_com_maps=="< 0.01%"

replace google_maps ="0" if google_maps=="< 0.01%"


gen google_com_1 = subinstr(google_com, "%", "", .)

gen bing_com_maps_1 = subinstr(bing_com_maps, "%", "", .)

gen google_maps_1 = subinstr(google_maps, "%", "", .)

drop  google_com bing_com_maps google_maps 




rename google_com_1 google_com

rename bing_com_maps_1 bing_com_maps

rename google_maps_1 google_maps


destring  google_com bing_com_maps google_maps, force replace



gen bounce_google = google_com

gen bounce_google_maps = google_maps

gen bounce_bing_com_maps = bing_com_maps



keep date month year bounce_google bounce_google_maps bounce_bing_com_maps

order date month year bounce_google bounce_google_maps bounce_bing_com_maps


destring bounce_google bounce_google_maps bounce_bing_com_maps, force replace


gen country = "US"


save "processed\Semrush_processed\bounce_US.dta",replace



/// channel_maps

import delimited "data/Semrush_data/other/US/channel_maps.csv", varnames(1) clear 

rename v1 month
generate date = date(month, "MY")
format date %td

drop month

gen month=month(date) 
gen year=year(date)

drop if year<2021

rename direct direct_google_maps

rename referral referral_google_maps

rename organicsearch organicsearch_google_maps

gen country = "US"


keep date month year direct_google_maps referral_google_maps organicsearch_google_maps country 


 
merge 1:1 date using "processed\Semrush_processed\bounce_US.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visit_mobile_US.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\page_visit_US.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visitor_US.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visit_duration_US.dta"
drop _merge


merge 1:1 date using "processed\Semrush_processed\visit_US.dta"
drop _merge




gen EU=0
gen Euro_NoEU=0
gen other=1

sort date country 


save "processed/Semrush_processed/all_US.dta",replace

 
 
 
 
 
 
 

global other_1 "Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

use "processed\Semrush_processed\all_Australia.dta", clear


qui foreach x of global other_1 {
	
append using "processed/Semrush_processed/all_`x'.dta", force

}


sort date country 

save "processed\Semrush_processed\other.dta",replace

append using "processed/Semrush_processed/no_EU.dta", force
 
append using "processed/Semrush_processed/EU.dta", force



encode country, generate(country1)

drop country

rename country1 country


tab country

tab country_spec


save "processed\Semrush_processed\all_semrush.dta",replace











