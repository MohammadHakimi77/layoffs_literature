	 	
use "processed\Semrush_processed\all_semrush.dta",replace


merge 1:1 country date using "processed\Semrush_processed\all_dir_semrush.dta"

drop _merge
 
 
 
sort country date

by country : gen obs=_n

tab obs

sort country obs

duplicates list country obs

xtset country obs

gen post=0
replace post=1 if obs>36

tab date if post==1


drop if obs==49 | obs==50 



sort country obs

xtset country obs



gen aus=0
replace aus=1 if country==43  // sa	
replace aus=1 if country==37  // nz	
replace aus=1 if country==12 // chile	
replace aus=1 if country==9	// brazil
replace aus=1 if country==3	// australia
	

////// remove Malta becasue of not all data


drop if country==35 


tab country if EU==0 & aus==0

////// remove North Macedonia because of not all data. Some (smaller) data restrictions for Albania, Armenia, Azerbaijan, Belarus, Georgia, Iceland, Ukraine

drop if country==34










////////////////////////////////////////////////////////////////////////////////
///////////////////// DiD //////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

label var EU " $ EU_{i} $ " 
label var post " $ post_{t}^{DMA} $ " 


gen treated=0
replace treated=1 if EU==1 & post==1
label var treated " $ EU \times post^{DMA} $ " 





gen l_visit_google_maps_dir=ln(visit_google_maps_dir) 

replace l_visit_google_maps_dir=0 if l_visit_google_maps_dir==.


gen l_visit_duration_google_maps_dir=ln(visit_duration_google_maps_dir) 

replace l_visit_duration_google_maps_dir=0 if l_visit_duration_google_maps_dir==.


gen l_bounce_google_maps_dir=ln(bounce_google_maps_dir) 

replace l_bounce_google_maps_dir=0 if l_bounce_google_maps_dir==.





eststo clear
		eststo:	reghdfe l_visit_google_maps_dir treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_visit_google_maps_dir if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_google_maps_dir treated if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_visit_google_maps_dir if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_google_maps_dir treated if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_visit_google_maps_dir if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
        eststo:	reghdfe l_visit_duration_google_maps_dir treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_visit_duration_google_maps_dir if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_duration_google_maps_dir treated  if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_visit_duration_google_maps_dir if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_duration_google_maps_dir treated  if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_visit_duration_google_maps_dir if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		 eststo:	reghdfe l_bounce_google_maps_dir treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_bounce_google_maps_dir if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_bounce_google_maps_dir treated  if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_bounce_google_maps_dir if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_bounce_google_maps_dir treated  if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_bounce_google_maps_dir if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_C10.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2f) labels("Country FEs" "Month FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)" "(7)" "(8)" "(9)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;		
						
		





reghdfe l_visit_google_maps_dir i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.6 0.4) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients" "(Desktop - google.com/maps/dir)") ///
    text(-0.45 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.46 11.9 "DMA Compliance Period", placement(s) size(small))
   	

graph export "results\figures\Figure_C17.pdf", as(pdf) replace
graph close 	
	
	
	
	
	
	

reghdfe l_visit_duration_google_maps_dir i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.6 0.4) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients" "(Duration - google.com/maps/dir)") ///
    text(-0.44 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.46 11.9 "DMA Compliance Period", placement(s) size(small))
   	

graph export "results\figures\Figure_C18a.pdf", as(pdf) replace
graph close 	
	
	
	
	
	
	

reghdfe l_bounce_google_maps_dir i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.6 0.4) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients" "(Bounce - google.com/maps/dir)") ///
    text(0.92 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(1.1 11.9 "DMA Compliance Period", placement(s) size(small))
   	

graph export "results\figures\Figure_C18b.pdf", as(pdf) replace
graph close 	
		

		
		


	
		
		
		
	
		
		