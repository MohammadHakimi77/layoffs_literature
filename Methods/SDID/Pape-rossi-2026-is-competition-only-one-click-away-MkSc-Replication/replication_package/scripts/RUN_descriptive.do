****************************************************
** Descriptive Statistics of the Google trends and SEMrush data
****************************************************


////////////////////////////////////////////////////////////////////////////////
////////// Data on search volumes: Google trends and Glimpse////////////////////
////////////////////////////////////////////////////////////////////////////////

use "processed\Google_trend_processed\all_trends.dta",replace


egen id=group(country query)


gen week=week(date_long) 
gen month=month(date_long) 
gen year=year(date_long)

gen obs=date
replace obs=obs-22640
replace obs=obs/7

tab obs

sort id obs

duplicates list id obs

xtset id obs

gen sample=0
replace sample=1 if year>2022 

gen post=0
replace post=1 if obs>105

label var EU " $ EU_{i} $ " 
label var post " $ post_{t}^{DMA} $ " 


label define post_label 0 "Before DMA" 1 "After DMA"


label values post post_label


tab query 

drop if query==2
drop if query>7

label define query_label 1 "\texttt{apple maps}" 3 "\texttt{bing maps}" 4 "\texttt{google maps}" 5 "\texttt{mappy}" 6 "\texttt{maps}" 7 "\texttt{openstreetmap}"

label values query query_label



gen aus=0
replace aus=1 if country==44  // sa	
replace aus=1 if country==38  // nz	
//replace aus=1 if country==27  // india	
//replace aus=1 if country==13 // colombia	
replace aus=1 if country==12 // chile	
replace aus=1 if country==9	// brazil
replace aus=1 if country==3	// australia
	
tab country if EU==1

////// remove Cyprus and Malta becasue of not all data

drop if country==16

drop if country==36 


tab country if EU==0

////// remove North Macedonia becasue of not all data. Some (smaller) data restrictions for Albania, Armenia, Azerbaijan, Belarus, Georgia, Iceland, Ukraine

drop if country==35

tab country if EU==1



gen n=1
egen tot_obs_country=count(n), by(country)	

tab tot_obs_country

drop if tot_obs_country<771	

drop tot_obs_country n 
//// remove additional countries for the tables

tab country if EU==0


collapse (mean) volume_search if sample==1, by(EU post query)

egen sum_volume=total(volume_search), by(post EU)

gen share_volume=volume_search/sum_volume

replace share_volume=share_volume*100

drop sum_volume
reshape wide share_volume volume_search, i(query post) j(EU)

sort post query

gen volume_search_NONEU=floor(volume_search0)

gen volume_search_EU=floor(volume_search1)

gen share_volume_NONEU=floor(share_volume0*100)/100

gen share_volume_EU=floor(share_volume1*100)/100

drop volume_search0 share_volume0 volume_search1 share_volume1

order query post volume_search_EU share_volume_EU volume_search_NONEU share_volume_NONEU

////////////////////////////////////////////////////////////////////////////////
//////////////////////// Table 1
////////////////////////////////////////////////////////////////////////////////

preserve

keep if post==0

drop post

texsave * using "results\tables\Table_1_beforeDMA.tex", nofix replace valuelabels dataonly

restore 

preserve

keep if post==1

drop post

texsave * using "results\tables\Table_1_afterDMA.tex", nofix replace valuelabels dataonly

restore 

////////////////////////////////////////////////////////////////////////////////




use "processed\Google_trend_processed\all_trends.dta",replace


egen id=group(country query)

gen year=year(date_long)

gen obs=date
replace obs=obs-22640
replace obs=obs/7

tab obs

sort id obs

xtset id obs

drop if year<2023

////// remove Cyprus and Malta because of not all data

drop if country==16

drop if country==36 


////// remove North Macedonia becasue of not all data. Some (smaller) data restrictions for Albania, Armenia, Azerbaijan, Belarus, Georgia, Iceland, Ukraine

drop if country==35



////////////////////////////////////////////////////////////////////////////////
////////////////////// FIGURES A2, A3, and B9 //////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



preserve	
	
gen country_tab=.
replace country_tab=1 if country==21
replace country_tab=2 if country==23
replace country_tab=3 if country==30
replace country_tab=4 if country==49
replace country_tab=5 if EU==1 & country_tab==.

replace country_tab=6 if country==54	
replace country_tab=7 if country==53	
replace country_tab=8 if country==40
replace country_tab=9 if country==51
replace country_tab=10 if country_tab==.	

egen id_1=group(country_tab query)	
egen sum_volume=total(volume_search), by(id_1 obs)	

keep if year>2022


quietly  twoway (line sum_volume obs if country==21 & query==6 & year>2022, lwidth(medthick) lpattern(solid) ) ///
    (line sum_volume obs if country==23 & query==6 & year>2022, lwidth(medthick) lpattern(dash) ) ///
    (line sum_volume obs if country==30 & query==6 & year>2022, lwidth(medthick) lpattern(longdash) ) ///
    (line sum_volume obs if country==49 & query==6 & year>2022, lwidth(medthick) lpattern(shortdash) ) ///
    (line sum_volume obs if country==50 & query==6 & year>2022, lwidth(vthick) lpattern(dot) lcolor(black)), ///
legend(order(1 "France" 2 "Germany" 3 "Italy" 4 "Spain" 5 "Other EU") position(bottom) cols(5)) ytitle("Search Volumes (maps query) - log scale") xtitle("") yscale(log fextend) ylabel(2000000 4000000 6000000 8000000 10000000, format(%9.0f)) xscale(range(53 127)) xlabel(53 "Jan 23" 71 "May 23" 88 "Sep 23" 106 "Jan 24" 114 "Mar 24" 123 "May 24" 140 "Sep 24" 153 "Dec 24", labsize(vsmall) angle(horizontal)) xline(88, lcolor(gs10)) xline(106, lcolor(gs1)) xline(114, lcolor(gs10)) text(9000000 106 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(13000000 101 "DMA Compliance  Period" , placement(s) size(small)) 
graph export "results\figures\Figure_A2a.pdf", as(pdf) replace
		


quietly twoway (line sum_volume obs if country==40 & query==6 & year>2022, lwidth(medthick) lpattern(solid)) ///
    (line sum_volume obs if country==51 & query==6 & year>2022, lwidth(medthick) lpattern(dash)) ///
    (line sum_volume obs if country==53 & query==6 & year>2022, lwidth(medthick) lpattern(longdash)) ///
    (line sum_volume obs if country==54 & query==6 & year>2022, lwidth(medthick) lpattern(shortdash)) ///
    (line sum_volume obs if country==55 & query==6 & year>2022, lwidth(medthick) lwidth(vthick) lpattern(dot) lcolor(black)), ///
	legend(order(1 "Norway" 2 "Switzerland" 3 "UK" 4 "US" 5 "Other Non-EU") position(bottom) cols(5)) ytitle("Search Volumes (maps query) - log scale") xtitle("") yscale(log fextend) ylabel(100000 500000 1000000 5000000 10000000 15000000, format(%9.0f)) xscale(range(53 127)) xlabel(53 "Jan 23" 71 "May 23" 88 "Sep 23" 106 "Jan 24" 114 "Mar 24" 123 "May 24" 140 "Sep 24" 153 "Dec 24", labsize(vsmall) angle(horizontal)) xline(88, lcolor(gs10)) xline(106, lcolor(gs1)) xline(114, lcolor(gs10)) text(155000 106 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(35000000 101 "DMA Compliance  Period" , placement(s) size(small)) 
graph export "results\figures\Figure_A2b.pdf", as(pdf) replace
			

quietly twoway (line sum_volume obs if country==21 & query==4 & year>2022, lwidth(medthick) lpattern(solid)) ///
    (line sum_volume obs if country==23 & query==4 & year>2022, lwidth(medthick) lpattern(dash)) ///
    (line sum_volume obs if country==30 & query==4 & year>2022, lwidth(medthick) lpattern(longdash)) ///
    (line sum_volume obs if country==49 & query==4 & year>2022, lwidth(medthick) lpattern(shortdash)) ///
    (line sum_volume obs if country==50 & query==4 & year>2022, lwidth(medthick) lwidth(vthick) lpattern(dot)), /// 
	legend(order(1 "France" 2 "Germany" 3 "Italy" 4 "Spain" 5 "Other EU") position(bottom) cols(5)) ytitle("Search Volumes (google maps query) - log scale") xtitle("") yscale(log fextend) ylabel(1000000 2000000 4000000 6000000 8000000, format(%9.0f)) xscale(range(53 127)) xlabel(53 "Jan 23" 71 "May 23" 88 "Sep 23" 106 "Jan 24" 114 "Mar 24" 123 "May 24" 140 "Sep 24" 153 "Dec 24", labsize(vsmall) angle(horizontal)) xline(88, lcolor(gs10)) xline(106, lcolor(gs1)) xline(114, lcolor(gs10)) text(2500000 106 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(9500000 101 "DMA Compliance  Period" , placement(s) size(small)) 
graph export "results\figures\Figure_A3a.pdf", as(pdf) replace
		

	
quietly twoway (line sum_volume obs if country==40 & query==4 & year>2022, lwidth(medthick) lpattern(solid)) ///
    (line sum_volume obs if country==51 & query==4 & year>2022, lwidth(medthick) lpattern(dash)) ///
    (line sum_volume obs if country==53 & query==4 & year>2022, lwidth(medthick) lpattern(longdash)) ///
    (line sum_volume obs if country==54 & query==4 & year>2022, lwidth(medthick) lpattern(shortdash)) ///
    (line sum_volume obs if country==55 & query==4 & year>2022, lwidth(medthick) lwidth(vthick) lpattern(dot)), ///
	legend(order(1 "Norway" 2 "Switzerland" 3 "UK" 4 "US" 5 "Other Non-EU") position(bottom) cols(5)) ytitle("Search Volumes (google maps query) - log scale") xtitle("") yscale(log fextend) ylabel(400000 1000000 2000000 4000000 6000000 8000000, format(%9.0f)) xscale(range(53 127)) xlabel(53 "Jan 23" 71 "May 23" 88 "Sep 23" 106 "Jan 24" 114 "Mar 24" 123 "May 24" 140 "Sep 24" 153 "Dec 24", labsize(vsmall) angle(horizontal)) xline(88, lcolor(gs10)) xline(106, lcolor(gs1)) xline(114, lcolor(gs10)) text(1000000 106 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(12500000 101 "DMA Compliance  Period" , placement(s) size(small)) 
graph export "results\figures\Figure_A3b.pdf", as(pdf) replace
			
			
			

quietly twoway (line sum_volume obs if country==21 & query==4 & year>2022, lwidth(medthick) lpattern(solid)) (line sum_volume obs if country==21 & query==5 & year>2022, lwidth(medthick) lpattern(dash)) (line sum_volume obs if country==21 & query==6 & year>2022, lwidth(medthick) lpattern(longdash)), ///
 legend(order(1 "Google Maps" 2 "Mappy" 3 "Maps") position(bottom) cols(3)) ytitle("Search Volumes (France) - log scale") ylabel(1000000 2000000 4000000 6000000, format(%9.0f)) xtitle("") yscale(log fextend) xlabel(53 "Jan 23" 71 "May 23" 88 "Sep 23" 106 "Jan 24" 114 "Mar 24" 123 "May 24" 140 "Sep 24" 153 "Dec 24", labsize(vsmall) angle(horizontal)) xline(88, lcolor(gs10)) xline(106, lcolor(gs1)) xline(114, lcolor(gs10)) text(2000000 106 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(7000000 101 "DMA  Compliance Period" , placement(s) size(small))  
graph export "results\figures\Figure_B9.pdf", as(pdf) replace
			
			
restore
























////////////////////////////////////////////////////////////////////////////////
/////////////////////////// Data on traffic: SEMrush ///////////////////////////
////////////////////////////////////////////////////////////////////////////////



use "processed\Semrush_processed\all_semrush.dta",replace



sort country date

by country : gen obs=_n

tab obs

sort country obs

duplicates list country obs

xtset country obs


gen post=0
replace post=1 if obs>36

tab date if post==1

keep if year>2022

drop if obs==49
drop if obs==50

sort country obs

xtset country obs

label var EU " $ EU_{i} $ " 

label define post_label 0 "Before DMA" 1 "After DMA"


label values post post_label

gen no_all_info=0
replace no_all_info=1 if direct_google_maps==. | referral_google_maps==. | organicsearch_google_maps==.

tab country if no_all_info==1



gen alldevices_visit = visit_google_maps + visit_mobile_google_maps



gen other_visit = visit_google_maps - direct_google_maps - referral_google_maps - organicsearch_google_maps

sum other_visit, detail
tab country if other_visit<0

tab country if direct_google_maps>visit_google_maps


tab country if organicsearch_google_maps>visit_google_maps




////////////////////////////////////////////////////////////////////////////////
//////////////////////// FIGURES A4 and A5 /////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



preserve	
	
gen country_tab=.
replace country_tab=1 if country==20
replace country_tab=2 if country==22
replace country_tab=3 if country==29
replace country_tab=4 if country==48
replace country_tab=5 if EU==1 & country_tab==.

replace country_tab=6 if country==53	
replace country_tab=7 if country==52	
replace country_tab=8 if country==39
replace country_tab=9 if country==50
replace country_tab=10 if country_tab==.	

egen id_1=group(country_tab)	
egen sum_google_maps=total(visit_google_maps), by(id_1 obs)	
egen sum_google=total(visit_google), by(id_1 obs)	
egen sum_google_maps_organic=total(organicsearch_google_maps), by(id_1 obs)	


keep if year>2022


quietly twoway (line sum_google_maps obs if country==20, lwidth(medthick) lpattern(solid) ) ///
    (line sum_google_maps obs if country==22, lwidth(medthick) lpattern(dash) ) ///
    (line sum_google_maps obs if country==29, lwidth(medthick) lpattern(longdash) ) ///
    (line sum_google_maps obs if country==48, lwidth(medthick) lpattern(shortdash) ) ///
    (line sum_google_maps obs if country==49, lwidth(vthick) lpattern(dot) lcolor(black)), ///
legend(order(1 "France" 2 "Germany" 3 "Italy" 4 "Spain" 5 "Other EU") position(bottom) cols(5)) ytitle(" Visits Desktop (www.google.com\maps) - log scale") xtitle("") yscale(log fextend) ylabel(5000000 15000000 50000000, format(%9.0f)) xlabel(25 "Jan 23" 29 "May 23" 33 "Sep 23" 37 "Jan 24" 39 "Mar 24" 41 "May 24" 45 "Sep 24" 48 "Dec 24", labsize(vsmall) angle(horizontal)) xline(33, lcolor(gs10)) xline(37, lcolor(gs1))  xline(39, lcolor(gs10)) text(6900000 37 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(130000000 36 "DMA Compliance Period" , placement(s) size(small)) 
graph export "results\figures\Figure_A4a.pdf", as(pdf) replace
		
	
	
quietly twoway (line sum_google_maps obs if country==53, lwidth(medthick) lpattern(solid) ) ///
    (line sum_google_maps obs if country==52, lwidth(medthick) lpattern(dash) ) ///
    (line sum_google_maps obs if country==39, lwidth(medthick) lpattern(longdash) ) ///
    (line sum_google_maps obs if country==50, lwidth(medthick) lpattern(shortdash) ) ///
    (line sum_google_maps obs if country==54, lwidth(vthick) lpattern(dot) lcolor(black)), ///
legend(order(1 "Norway" 2 "Switzerland" 3 "UK" 4 "US" 5 "Other Non-EU") position(bottom) cols(5)) ytitle(" Visits Desktop (www.google.com\maps) - log scale") xtitle("") yscale(log fextend) ylabel(500000 1500000 5000000 15000000 50000000 150000000, format(%9.0f)) xlabel(25 "Jan 23" 29 "May 23" 33 "Sep 23" 37 "Jan 24" 39 "Mar 24" 41 "May 24" 45 "Sep 24" 48 "Dec 24", labsize(vsmall) angle(horizontal)) xline(33, lcolor(gs10)) xline(37, lcolor(gs1))  xline(39, lcolor(gs10)) text(15000000 37 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(320600000 36 "DMA Compliance Period" , placement(s) size(small)) 
graph export "results\figures\Figure_A4b.pdf", as(pdf) replace
					
	
	
quietly twoway (line sum_google_maps_organic obs if country==20, lwidth(medthick) lpattern(solid) ) ///
    (line sum_google_maps_organic obs if country==22, lwidth(medthick) lpattern(dash) ) ///
    (line sum_google_maps_organic obs if country==29, lwidth(medthick) lpattern(longdash) ) ///
    (line sum_google_maps_organic obs if country==48, lwidth(medthick) lpattern(shortdash) ) ///
    (line sum_google_maps_organic obs if country==49, lwidth(vthick) lpattern(dot) lcolor(black)), ///
	legend(order(1 "France" 2 "Germany" 3 "Italy" 4 "Spain" 5 "Other EU") position(bottom) cols(5)) ytitle(" Organic Search (www.google.com\maps) - log scale") xtitle("") yscale(log fextend) ylabel(1000000 5000000 10000000 20000000 30000000, format(%9.0f)) xlabel(25 "Jan 23" 29 "May 23" 33 "Sep 23" 37 "Jan 24" 39 "Mar 24" 41 "May 24" 45 "Sep 24" 48 "Dec 24", labsize(vsmall) angle(horizontal)) xline(33, lcolor(gs10)) xline(37, lcolor(gs1))  xline(39, lcolor(gs10)) text(21500000 37 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(36000000 36 "DMA Compliance Period" , placement(s) size(small)) 
graph export "results\figures\Figure_A5a.pdf", as(pdf) replace
	
	
quietly twoway (line sum_google_maps_organic obs if country==53, lwidth(medthick) lpattern(solid) ) ///
    (line sum_google_maps_organic obs if country==52, lwidth(medthick) lpattern(dash) ) ///
    (line sum_google_maps_organic obs if country==39, lwidth(medthick) lpattern(longdash) ) ///
    (line sum_google_maps_organic obs if country==50, lwidth(medthick) lpattern(shortdash) ) ///
    (line sum_google_maps_organic obs if country==54, lwidth(vthick) lpattern(dot) lcolor(black)), ///
legend(order(1 "Norway" 2 "Switzerland" 3 "UK" 4 "US" 5 "Other Non-EU") position(bottom) cols(5)) ytitle(" Organic Search (www.google.com\maps) - log scale") xtitle("") yscale(log fextend) ylabel(100000 500000 1500000 5000000 15000000 50000000, format(%9.0f)) xlabel(25 "Jan 23" 29 "May 23" 33 "Sep 23" 37 "Jan 24" 39 "Mar 24" 41 "May 24" 45 "Sep 24", labsize(vsmall) angle(horizontal)) xline(33, lcolor(gs10)) xline(37, lcolor(gs1))  xline(39, lcolor(gs10)) text(15000000 37 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(77000000 36 "DMA Compliance Period" , placement(s) size(small)) 
graph export "results\figures\Figure_A5b.pdf", as(pdf) replace
	
restore	


////////////////////////////////////////////////////////////////////////////////




collapse (mean) alldevices_visit visit_google_maps visit_mobile_google_maps direct_google_maps referral_google_maps organicsearch_google_maps other_visit, by(EU post)




rename alldevices_visit visit1
rename visit_google_maps visit2
rename visit_mobile_google_maps visit3
rename direct_google_maps visit4
rename referral_google_maps visit5
rename organicsearch_google_maps visit6
rename other_visit visit7

reshape long visit, i(EU post) j(type_traffic)

egen total_visit=max(visit), by(EU post)

gen visit1 = visit
replace visit1 =. if type_traffic==1 | type_traffic==3

egen total_visit1=max(visit1), by(EU post)




gen share_visit=visit/total_visit


gen share_visit1=visit1/total_visit1
replace share_visit=share_visit1 if type_traffic>3

drop share_visit1 total_visit1 visit1

replace share_visit=share_visit*100

drop total_visit




////////////////////////////////////////////////////////////////////////////////
///////////////////////// Table 2
////////////////////////////////////////////////////////////////////////////////


preserve

drop if post==1

reshape wide share_visit visit, i(type_traffic) j(EU)

drop post


label define traffic_label 1 "All Devices" 2 "Desktop" 3 "Mobile" 4 "Direct Desktop Traffic" 5 "Referral Desktop Traffic" 6 "Organic Desktop Search" 7 "Other Desktop Sources" 

label values type_traffic traffic_label

replace visit0=visit0/1000
replace visit1=visit1/1000

gen volume_search_NONEU=floor(visit0)

gen volume_search_EU=floor(visit1)

gen share_volume_NONEU=floor(share_visit0*100)/100

gen share_volume_EU=floor(share_visit1*100)/100

drop visit0 visit1 share_visit1 share_visit0


order type_traffic volume_search_EU share_volume_EU volume_search_NONEU share_volume_NONEU

keep if type_traffic==1
texsave * using "results\tables\Table_2_beforeDMA_1.tex", nofix replace valuelabels dataonly


restore

preserve

drop if post==1

reshape wide share_visit visit, i(type_traffic) j(EU)

drop post


label define traffic_label 1 "All Devices" 2 "Desktop" 3 "Mobile" 4 "Direct Desktop Traffic" 5 "Referral Desktop Traffic" 6 "Organic Desktop Search" 7 "Other Desktop Sources" 

label values type_traffic traffic_label

replace visit0=visit0/1000
replace visit1=visit1/1000

gen volume_search_NONEU=floor(visit0)

gen volume_search_EU=floor(visit1)

gen share_volume_NONEU=floor(share_visit0*100)/100

gen share_volume_EU=floor(share_visit1*100)/100

drop visit0 visit1 share_visit1 share_visit0


order type_traffic volume_search_EU share_volume_EU volume_search_NONEU share_volume_NONEU


keep if type_traffic==2 | type_traffic==3
texsave * using "results\tables\Table_2_beforeDMA_2.tex", nofix replace valuelabels dataonly


restore


preserve

drop if post==1

reshape wide share_visit visit, i(type_traffic) j(EU)

drop post


label define traffic_label 1 "All Devices" 2 "Desktop" 3 "Mobile" 4 "Direct Desktop Traffic" 5 "Referral Desktop Traffic" 6 "Organic Desktop Search" 7 "Other Desktop Sources" 

label values type_traffic traffic_label

replace visit0=visit0/1000
replace visit1=visit1/1000

gen volume_search_NONEU=floor(visit0)

gen volume_search_EU=floor(visit1)

gen share_volume_NONEU=floor(share_visit0*100)/100

gen share_volume_EU=floor(share_visit1*100)/100

drop visit0 visit1 share_visit1 share_visit0


order type_traffic volume_search_EU share_volume_EU volume_search_NONEU share_volume_NONEU


keep if type_traffic>3
texsave * using "results\tables\Table_2_beforeDMA_3.tex", nofix replace valuelabels dataonly


restore







preserve

drop if post==0

reshape wide share_visit visit, i(type_traffic) j(EU)

drop post


label define traffic_label 1 "All Devices" 2 "Desktop" 3 "Mobile" 4 "Direct Desktop Traffic" 5 "Referral Desktop Traffic" 6 "Organic Desktop Search" 7 "Other Desktop Sources" 

label values type_traffic traffic_label

replace visit0=visit0/1000
replace visit1=visit1/1000

gen volume_search_NONEU=floor(visit0)

gen volume_search_EU=floor(visit1)

gen share_volume_NONEU=floor(share_visit0*100)/100

gen share_volume_EU=floor(share_visit1*100)/100

drop visit0 visit1 share_visit1 share_visit0


order type_traffic volume_search_EU share_volume_EU volume_search_NONEU share_volume_NONEU

keep if type_traffic==1
texsave * using "results\tables\Table_2_afterDMA_1.tex", nofix replace valuelabels dataonly


restore





preserve

drop if post==0

reshape wide share_visit visit, i(type_traffic) j(EU)

drop post


label define traffic_label 1 "All Devices" 2 "Desktop" 3 "Mobile" 4 "Direct Desktop Traffic" 5 "Referral Desktop Traffic" 6 "Organic Desktop Search" 7 "Other Desktop Sources" 

label values type_traffic traffic_label

replace visit0=visit0/1000
replace visit1=visit1/1000

gen volume_search_NONEU=floor(visit0)

gen volume_search_EU=floor(visit1)

gen share_volume_NONEU=floor(share_visit0*100)/100

gen share_volume_EU=floor(share_visit1*100)/100

drop visit0 visit1 share_visit1 share_visit0


order type_traffic volume_search_EU share_volume_EU volume_search_NONEU share_volume_NONEU

keep if type_traffic==2 | type_traffic==3
texsave * using "results\tables\Table_2_afterDMA_2.tex", nofix replace valuelabels dataonly


restore




preserve


drop if post==0

reshape wide share_visit visit, i(type_traffic) j(EU)

drop post


label define traffic_label 1 "All Devices" 2 "Desktop" 3 "Mobile" 4 "Direct Desktop Traffic" 5 "Referral Desktop Traffic" 6 "Organic Desktop Search" 7 "Other Desktop Sources" 

label values type_traffic traffic_label

replace visit0=visit0/1000
replace visit1=visit1/1000

gen volume_search_NONEU=floor(visit0)

gen volume_search_EU=floor(visit1)

gen share_volume_NONEU=floor(share_visit0*100)/100

gen share_volume_EU=floor(share_visit1*100)/100

drop visit0 visit1 share_visit1 share_visit0


order type_traffic volume_search_EU share_volume_EU volume_search_NONEU share_volume_NONEU


keep if type_traffic>3
texsave * using "results\tables\Table_2_afterDMA_3.tex", nofix replace valuelabels dataonly


restore

////////////////////////////////////////////////////////////////////////////////










