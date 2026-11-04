****************************************************
** Diff-in-Diff for Online Traffic
****************************************************



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



////////////////////////////////////////////////////////////////////////////////
///////// google maps //////////////////////////////////////////////////////////



sum visit_google_maps, detail

gen l_visit_google_maps=ln(visit_google_maps) 


sum visit_mobile_google_maps, detail

gen l_visit_google_maps_mobile=ln(visit_mobile_google_maps) 



sum organicsearch_google_maps, detail

gen l_organicsearch_google_maps=ln(organicsearch_google_maps) 




sum direct_google_maps, detail

gen l_direct_google_maps=ln(direct_google_maps) 


tab country if organicsearch_google_maps==.

tab country if direct_google_maps==.



gen alldevices_visit = visit_google_maps + visit_mobile_google_maps



gen other_visit = visit_google_maps - direct_google_maps - referral_google_maps - organicsearch_google_maps


sum referral_google_maps, detail

gen l_referral_google_maps=ln(referral_google_maps) 


sum other_visit, detail

gen l_other_visit=ln(other_visit) 



gen l_referral__organic_google_maps=ln(referral_google_maps+organicsearch_google_maps) 




////////////////////////////////////////////////////////////////////////////////
////////////////////// DiD Table: desktop vs mobile ////////////////////////////
////////////////////// TABLE 4 /////////////////////////////////////////////////




replace l_visit_google_maps_mobile=0 if l_visit_google_maps_mobile==.


eststo clear
		eststo:	reghdfe l_visit_google_maps treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_visit_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_google_maps treated if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_visit_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_google_maps treated if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_visit_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
        eststo:	reghdfe l_visit_google_maps_mobile treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_visit_google_maps_mobile if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_google_maps_mobile treated  if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_visit_google_maps_mobile if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_google_maps_mobile treated  if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_visit_google_maps_mobile if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_4.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Month FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;		
		


////////////////////////////////////////////////////////////////////////////////
////////////////////// DiD EVENT STUDIES ///////////////////////////////////////
////////////////////// FIGURE 3, C1 ////////////////////////////////////


reghdfe l_visit_google_maps i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.6 0.4) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Desktop - google.com/maps)") ///
    text(0.3 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.47 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_3a.pdf", as(pdf) replace
graph close 



reghdfe l_visit_google_maps_mobile i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  


coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.3) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Mobile - google.com/maps)") ///
    text(2.4 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(3.3 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_3b.pdf", as(pdf) replace
graph close 		



reghdfe l_visit_google_maps i.EU##ib37.obs  if aus==0 & year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.3) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Desktop - google.com/maps)") ///
    text(0.2 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.36 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C1a.pdf", as(pdf) replace
graph close 




reghdfe l_visit_google_maps i.EU##ib37.obs  if  year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.3) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Desktop - google.com/maps)") /// 
    text(0.2 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.354 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C1b.pdf", as(pdf) replace
graph close 


////////////////////////////////////////////////////////////////////////////////
//////////// Extensions: Different Channels of Google Maps Traffic /////////////
//////////// Table C1, C2 and Figure C2, C3 ////////////////////////////////////
													

////////////////////////////////////////////////////////////////////////////////
///////////// direct vs organic: google maps ////////////////////////////////////
		
		
		

eststo clear
		eststo:	reghdfe l_direct_google_maps treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_direct_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_direct_google_maps treated if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_direct_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_direct_google_maps treated if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_direct_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
        eststo:	reghdfe l_organicsearch_google_maps treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_organicsearch_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_organicsearch_google_maps treated  if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_organicsearch_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_organicsearch_google_maps treated  if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_organicsearch_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_C1.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Month FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;		
		
	
	
	

////////////////////////////////////////////////////////////////////////////////
///////////// referral vs other: google maps ////////////////////////////////////
		
		
		
eststo clear
		eststo:	reghdfe l_referral_google_maps treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_referral_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_referral_google_maps treated if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_referral_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_referral_google_maps treated if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_referral_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
        eststo:	reghdfe l_other_visit treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_other_visit if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_other_visit treated  if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_other_visit if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_other_visit treated  if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_other_visit if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_C2.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Month FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;		
		
			

			
			
reghdfe l_direct_google_maps i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  


coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.3) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Direct - google.com/maps)") ///
    text(0.2 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.37 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C2a.pdf", as(pdf) replace
graph close 


reghdfe l_organicsearch_google_maps i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.48) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Organic Search - google.com/maps)") ///
    text(1.1 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(1.65 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C2b.pdf", as(pdf) replace
graph close 		
				
		

		

reghdfe l_referral_google_maps i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  


coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.3) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Referral - google.com/maps)") ///
    text(0.36 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.59 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C3a.pdf", as(pdf) replace
graph close 				
		

		
		

reghdfe l_other_visit i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  


coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.3) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Other - google.com/maps)") ///
    text(1.29 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(1.64 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C3b.pdf", as(pdf) replace
graph close 		
	
	
	
	
	
	
	

////////////////////////////////////////////////////////////////////////////////
//////////// Robustness: Impact on the Extensive Margin ////////////////////////
//////////// Table C3, C4, C5 and C6 and Figure C4-C11 /////////////////////////	
	
	

///////////// synthetic DID


//////////// desktop vs mobile
	
eststo clear
		eststo:	sdid l_visit_google_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sdid)
		eststo:	sdid l_visit_google_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(did)
		eststo:	sdid l_visit_google_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sc)
		eststo:	sdid l_visit_google_maps_mobile country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sdid)
		eststo:	sdid l_visit_google_maps_mobile country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(did)
		eststo:	sdid l_visit_google_maps_mobile country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sc)
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(N) 
	
		#delimit ;
		esttab using "results\tables\Table_C3.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(N, fmt(%9.0fc) labels(N))
			nonotes nonumbers
			mlabels("(Synth. DiD)" "(DiD)" "(Synth. Control)" "(Synth. DiD)" "(DiD)" "(Synth. Control)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;	
	


	
	
	
sdid_event l_visit_google_maps country obs treated if  year>2022, effects(11) placebo(12) brep(100) vce(bootstrap)

preserve
mat res = e(H)[2..24,1..5]
svmat res
gen id1 = _n if !missing(res1)
replace id1 = 11 - _n if _n > 11 & !missing(res1)
sort id1
gen id2=id1+13

replace res1 = 0 in 24
replace res3 = 0 in 24
replace res4 = 0 in 24
replace id2 = 13 in 24

sort id2

twoway (rline res3 res4 id2, lcolor(black) lpattern(dash)) (rline res1 res1 id2, lcolor(black) lwidth(medthick)), legend(off) ytitle("Estimated Coefficients (Desktop - google.com/maps)") xtitle("") xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) yscale(range(-0.2 0.48) fextend) xscale(fextend) yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) xline(15, lcolor(gs10)) text(0.43 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(0.54 11.9 "DMA Compliance Period", placement(s) size(small))
 graph export "results\figures\Figure_C4a.pdf", as(pdf) replace
 
graph close 	

restore	
	


sdid_event l_visit_google_maps_mobile country obs treated if  year>2022, effects(11) placebo(12) brep(100) vce(bootstrap)


preserve
mat res = e(H)[2..24,1..5]
svmat res
gen id1 = _n if !missing(res1)
replace id1 = 11 - _n if _n > 11 & !missing(res1)
sort id1
gen id2=id1+13

replace res1 = 0 in 24
replace res3 = 0 in 24
replace res4 = 0 in 24
replace id2 = 13 in 24

sort id2


twoway (rline res3 res4 id2, lcolor(black) lpattern(dash)) (rline res1 res1 id2, lcolor(black) lwidth(medthick)), legend(off) ytitle("Estimated Coefficients (Mobile - google.com/maps)") xtitle("") xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) yscale(range(-0.2 0.48) fextend) xscale(fextend) yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) xline(15, lcolor(gs10)) text(1.25 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(1.59 11.9 "DMA Compliance Period", placement(s) size(small))
 graph export "results\figures\Figure_C4b.pdf", as(pdf) replace

graph close 	

restore	
	
		
	
	
sdid l_visit_google_maps country obs treated if  year>2022,  vce(bootstrap) reps(100) seed(123) method(sdid) graph g1on g1_opt(xtitle("") xlabel(1 "Albania" 2 "Armenia" 3 "Australia" 4 "Azerbaijan" 5 "Belarus" 6 "Bosnia" 7 "Brazil" 8 "Canada" 9 "Chile" 10 "Colombia" 11 "Costarica" 12 "Georgia" 13 "Iceland" 14 "India" 15 "Israel" 16 "Japan" 17 "Mexico" 18 "New Zealand" 19 "Norway" 20 "South Africa" 21 "South Korea" 22 "Serbia" 23 "Switzerland" 24 "Turkey" 25 "UK" 26 "US" 27 "Ukraine") ylabel(-1(0.4)0.8) scheme(plotplainblind)) g2_opt( xtitle("") ytitle("Desktop Visits - google.com/maps") xlabel(25 "Jan 23" 29 "May 23" 33 "Sep 23" 37 "Jan 24" 39 "Mar 24" 41 "May 24" 45 "Sep 24" 48 "Dec 24", labsize(vsmall) angle(horizontal)) xline(33, lcolor(gs10)) xline(37, lcolor(gs1))  xline(39, lcolor(gs10)) text(14.3 37 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
text(15.58 35.9 "DMA Compliance Period", placement(s) size(small)) ) mattitles graph_export("results\figures\Figure_C5", .pdf)

	


sdid l_visit_google_maps_mobile country obs treated if  year>2022 &  country!=2 & country!=25,  vce(bootstrap) reps(100) seed(123) method(sdid) graph g1on g1_opt(xtitle("") xlabel(1 "Albania" 2 "Australia" 3 "Azerbaijan" 4 "Belarus" 5 "Bosnia" 6 "Brazil" 7 "Canada" 8 "Chile" 9 "Colombia" 10 "Costarica" 11 "Georgia" 12 "India" 13 "Israel" 14 "Japan" 15 "Mexico" 16 "New Zealand" 17 "Norway" 18 "South Africa" 19 "South Korea" 20 "Serbia" 21 "Switzerland" 22 "Turkey" 23 "UK" 24 "US" 25 "Ukraine") ylabel(-1(0.4)1.6) scheme(plotplainblind)) g2_opt( xtitle("") ytitle("Mobile Visits - google.com/maps") xlabel(25 "Jan 23" 29 "May 23" 33 "Sep 23" 37 "Jan 24" 39 "Mar 24" 41 "May 24" 45 "Sep 24" 48 "Dec 24", labsize(vsmall) angle(horizontal)) xline(33, lcolor(gs10)) xline(37, lcolor(gs1))  xline(39, lcolor(gs10)) text(13.45 37 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(14.66 35.8 "DMA Compliance Period", placement(s) size(small)) ) mattitles graph_export("results\figures\Figure_C6", .pdf)




//////////// direct vs organic
			

eststo clear
		eststo:	sdid l_direct_google_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sdid)
		eststo:	sdid l_direct_google_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(did)
		eststo:	sdid l_direct_google_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sc)
		eststo:	sdid l_organicsearch_google_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sdid)
		eststo:	sdid l_organicsearch_google_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(did)
		eststo:	sdid l_organicsearch_google_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sc)
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(N) 
	
		#delimit ;
		esttab using "results\tables\Table_C4.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(N, fmt(%9.0fc) labels(N))
			nonotes nonumbers
			mlabels("(Synth. DiD)" "(DiD)" "(Synth. Control)" "(Synth. DiD)" "(DiD)" "(Synth. Control)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;	
			
		
		
		


sdid_event l_direct_google_maps country obs treated if  year>2022, effects(11) placebo(12) brep(100) vce(bootstrap)

preserve
mat res = e(H)[2..24,1..5]
svmat res
gen id1 = _n if !missing(res1)
replace id1 = 11 - _n if _n > 11 & !missing(res1)
sort id1
gen id2=id1+13

replace res1 = 0 in 24
replace res3 = 0 in 24
replace res4 = 0 in 24
replace id2 = 13 in 24

sort id2


twoway (rline res3 res4 id2, lcolor(black) lpattern(dash)) (rline res1 res1 id2, lcolor(black) lwidth(medthick)), legend(off) ytitle("Estimated Coefficients (Direct - google.com/maps)") xtitle("") xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) yscale(range(-0.2 0.48) fextend) xscale(fextend) yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) xline(15, lcolor(gs10)) text(0.35 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(0.53 11.9 "DMA Compliance Period", placement(s) size(small))
 graph export "results\figures\Figure_C7a.pdf", as(pdf) replace

graph close 	

restore		
		

sdid_event l_organicsearch_google_maps country obs treated if  year>2022, effects(11) placebo(12) brep(100) vce(bootstrap)

preserve
mat res = e(H)[2..24,1..5]
svmat res
gen id1 = _n if !missing(res1)
replace id1 = 11 - _n if _n > 11 & !missing(res1)
sort id1
gen id2=id1+13

replace res1 = 0 in 24
replace res3 = 0 in 24
replace res4 = 0 in 24
replace id2 = 13 in 24

sort id2


twoway (rline res3 res4 id2, lcolor(black) lpattern(dash)) (rline res1 res1 id2, lcolor(black) lwidth(medthick)), legend(off) ytitle("Estimated Coefficients (Organic Search - google.com/maps)") xtitle("") xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) yscale(range(-0.2 0.48) fextend) xscale(fextend) yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) xline(15, lcolor(gs10)) text(0.7 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(1.1 11.9 "DMA Compliance Period", placement(s) size(small))
 graph export "results\figures\Figure_C7b.pdf", as(pdf) replace

graph close 	

restore
		

	


sdid l_organicsearch_google_maps country obs treated if  year>2022 &  country!=2 & country!=25,  vce(bootstrap) reps(100) seed(123) method(sdid) graph g1on g1_opt(xtitle("") xlabel(1 "Albania" 2 "Australia" 3 "Azerbaijan" 4 "Belarus" 5 "Bosnia" 6 "Brazil" 7 "Canada" 8 "Chile" 9 "Colombia" 10 "Costarica" 11 "Georgia" 12 "India" 13 "Israel" 14 "Japan" 15 "Mexico" 16 "New Zealand" 17 "Norway" 18 "South Africa" 19 "South Korea" 20 "Serbia" 21 "Switzerland" 22 "Turkey" 23 "UK" 24 "US" 25 "Ukraine") ylabel(-1(0.4)1.6) scheme(plotplainblind)) g2_opt( xtitle("") ytitle("Organic Search - google.com/maps") xlabel(25 "Jan 23" 29 "May 23" 33 "Sep 23" 37 "Jan 24" 39 "Mar 24" 41 "May 24" 45 "Sep 24" 48 "Dec 24", labsize(vsmall) angle(horizontal)) xline(33, lcolor(gs10)) xline(37, lcolor(gs1))  xline(39, lcolor(gs10)) text(13.45 37 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(14.1 35.8 "DMA Compliance Period", placement(s) size(small)) ) mattitles graph_export("results\figures\Figure_C8", .pdf)


sdid l_direct_google_maps country obs treated if  year>2022 &  country!=2 & country!=25,  vce(bootstrap) reps(100) seed(123) method(sdid) graph g1on g1_opt(xtitle("") xlabel(1 "Albania" 2 "Australia" 3 "Azerbaijan" 4 "Belarus" 5 "Bosnia" 6 "Brazil" 7 "Canada" 8 "Chile" 9 "Colombia" 10 "Costarica" 11 "Georgia" 12 "India" 13 "Israel" 14 "Japan" 15 "Mexico" 16 "New Zealand" 17 "Norway" 18 "South Africa" 19 "South Korea" 20 "Serbia" 21 "Switzerland" 22 "Turkey" 23 "UK" 24 "US" 25 "Ukraine") ylabel(-1(0.4)1.6) scheme(plotplainblind)) g2_opt( xtitle("") ytitle("Direct - google.com/maps") xlabel(25 "Jan 23" 29 "May 23" 33 "Sep 23" 37 "Jan 24" 39 "Mar 24" 41 "May 24" 45 "Sep 24" 48 "Dec 24", labsize(vsmall) angle(horizontal)) xline(33, lcolor(gs10)) xline(37, lcolor(gs1))  xline(39, lcolor(gs10)) text(14.3 37 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(15.14 35.8 "DMA Compliance Period", placement(s) size(small)) ) mattitles graph_export("results\figures\Figure_C9", .pdf)






///////////// Direct and Organic Search Shares of Desktop Visits


gen ratio_direct=direct_google_maps/visit_google_maps

gen ratio_organic=organicsearch_google_maps/visit_google_maps

gen ratio_referral=referral_google_maps/visit_google_maps
		

gen ratio_referral_organic=(referral_google_maps+organicsearch_google_maps)/visit_google_maps
		
		
eststo clear
		eststo:	reghdfe ratio_direct treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su ratio_direct if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe ratio_direct treated if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su ratio_direct if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe ratio_direct treated if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su ratio_direct if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
        eststo:	reghdfe ratio_organic treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su ratio_organic if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe ratio_organic treated  if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su ratio_organic if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe ratio_organic treated  if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su ratio_organic if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_C5.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Month FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;		
		
				

reghdfe ratio_direct i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  


coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.18 0.1) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Ratio Direct - google.com/maps)") ///
    text(-0.1 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.117 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C10a.pdf", as(pdf) replace
graph close 			
		
		


reghdfe ratio_organic i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  


coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.05 0.15) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Ratio Organic - google.com/maps)") ///
    text(0.1 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.163 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C10b.pdf", as(pdf) replace
graph close 			
		
		

		
		
		

////////////////////// using mobile visits as control   ////////////////////////
	
preserve	

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

keep date month year EU country obs post aus other visit_google_maps visit_google visit_bing_com_maps

gen desktop=1

gen visit_google_maps_type=visit_google_maps


gen visit_google_type=visit_google


gen visit_bing_maps_type=visit_bing_com_maps


drop visit_google_maps visit_google visit_bing_com_maps
	

save "processed\Semrush_processed\all_semrush_desktop.dta",replace
	
	
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


keep date month year EU country obs post aus other visit_mobile_google visit_mobile_google_maps visit_mobile_bing_maps

gen desktop=0

gen visit_google_maps_type=visit_mobile_google_maps


gen visit_google_type=visit_mobile_google


gen visit_bing_maps_type=visit_mobile_bing_maps


drop visit_mobile_google visit_mobile_google_maps visit_mobile_bing_maps
		

append using "processed\Semrush_processed\all_semrush_desktop.dta"
		


sort country desktop obs
		
egen id=group(country desktop)		

xtset id obs
		
sum visit_google_maps_type, detail		
gen l_visit_google_maps_type=ln(visit_google_maps_type)
replace l_visit_google_maps_type=0 if l_visit_google_maps_type==.


sum visit_google_type, detail		
gen l_visit_google_type=ln(visit_google_type)
replace l_visit_google_type=0 if l_visit_google_type==.


sum visit_bing_maps_type, detail		
gen l_visit_bing_maps_type=ln(visit_bing_maps_type)
replace l_visit_bing_maps_type=0 if l_visit_bing_maps_type==.



gen treated=0
replace treated=1 if post==1 & desktop==1	

label var treated " $ desktop \times post^{DMA}  $ " 


gen treated1=0
replace treated1=1 if post==1 & EU==1	

label var treated1 " $ EU \times post^{DMA}$ " 


gen treated2=0
replace treated2=1 if EU==1 & desktop==1	


gen treated3=0
replace treated3=1 if post==1 & desktop==1 & EU==1	

label var treated3 " $ EU \times post^{DMA} \times desktop $ " 



eststo clear
		eststo: reghdfe l_visit_google_maps_type treated treated1 treated2 treated3 if  year>2022, absorb(id obs) cluster(country)
		estadd local country "\checkmark"
		estadd local desk "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_visit_google_maps_type if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo: reghdfe l_visit_google_maps_type treated treated1 treated2 treated3 if aus==0 &  year>2022, absorb(id obs) cluster(country)
		estadd local country "\checkmark"
		estadd local desk "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_visit_google_maps_type if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo: reghdfe l_visit_google_maps_type treated treated1 treated2 treated3 if other==0 &  year>2022, absorb(id obs) cluster(country)
		estadd local country "\checkmark"
		estadd local desk "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_visit_google_maps_type if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep( treated treated1 treated3) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
		#delimit ;
		esttab using "results\tables\Table_C6.tex", replace 
			booktabs 
			keep(treated treated1 treated3) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country desk date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Device FEs" "Month FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;		
		
		
	
	
	

reghdfe l_visit_google_maps_type i.desktop##ib37.obs i.EU##ib37.obs i.treated2##ib37.obs  if other==0 & year>2022, absorb(id obs) cluster(country)  

coefplot, keep(1.treated2#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.12 0.06) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Online Visits - google.com/maps)") ///
	text(-1.95 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(1.48 12 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C11.pdf", as(pdf) replace
graph close 			
			
		
restore		
		
		

		
		

////////////////////////////////////////////////////////////////////////////////
//////////// Robustness: Impact on the Intensive Margin ////////////////////////
//////////// Table C7-C10 and Figure C12-C18 ///////////////////////////////////	
			
			
//// visitor and visited pages			
			

/// visitor

	
sum visitor_google_maps, detail

gen l_visitor_google_maps=ln(visitor_google_maps) 
			

/// page visited


sum page_visit_google_maps, detail

gen l_page_visit_google_maps=ln(page_visit_google_maps) 
		
		

eststo clear
		eststo:	reghdfe l_visitor_google_maps treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_visitor_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visitor_google_maps treated if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_visitor_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visitor_google_maps treated if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_visitor_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
        eststo:	reghdfe l_page_visit_google_maps treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_page_visit_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_page_visit_google_maps treated  if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_page_visit_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_page_visit_google_maps treated  if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_page_visit_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_C7.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Month FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;		
		


reghdfe l_visitor_google_maps i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.3) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Visitors - google.com/maps)") ///
    text(0.34 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.46 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C12a.pdf", as(pdf) replace
graph close 


reghdfe l_page_visit_google_maps i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.12 0.06) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Visited Pages - google.com/maps)") ///
    text(-0.2 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.25 12 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C12b.pdf", as(pdf) replace
graph close		
		
		
		
		
		
////	Visit Duration and Bounce Rate	
	
	
/// bounce


sum bounce_google_maps, detail

gen l_bounce_google_maps=ln(bounce_google_maps) 
		
				

/// visit duration

	
sum visit_duration_google_maps, detail

gen l_visit_duration_google_maps=ln(visit_duration_google_maps) 
		
		
		
		

eststo clear
		eststo:	reghdfe l_visit_duration_google_maps treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_visit_duration_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_duration_google_maps treated if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_visit_duration_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_duration_google_maps treated if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_visit_duration_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
        eststo:	reghdfe l_bounce_google_maps treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_bounce_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_bounce_google_maps treated  if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_bounce_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_bounce_google_maps treated  if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_bounce_google_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_C8.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Month FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;		
				
		
		

reghdfe l_bounce_google_maps i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.3) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Bounce - google.com/maps)") ///
    text(0.35 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.5 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C13b.pdf", as(pdf) replace
graph close 
				
reghdfe l_bounce_google_maps i.EU##ib37.obs  if aus==0 & year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.3) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Bounce - google.com/maps)") ///
    text(0.3 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.44 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C14b.pdf", as(pdf) replace
graph close 
				

reghdfe l_bounce_google_maps i.EU##ib37.obs  if  year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.3) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Bounce - google.com/maps)") ///
    text(0.3 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.45 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C15b.pdf", as(pdf) replace
graph close 
					
		
		


reghdfe l_visit_duration_google_maps i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.12 0.06) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Duration - google.com/maps)") ///
    text(0.056 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.072 12 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C13a.pdf", as(pdf) replace
graph close 
				
reghdfe l_visit_duration_google_maps i.EU##ib37.obs  if aus==0 & year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.12 0.06) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Duration - google.com/maps)") ///
    text(0.06 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.114 12 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C14a.pdf", as(pdf) replace
graph close 
				

reghdfe l_visit_duration_google_maps i.EU##ib37.obs  if  year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.12 0.06) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Duration - google.com/maps)") ///
    text(0.05 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.072 12 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C15a.pdf", as(pdf) replace
graph close 		
		
				
//// synthetic DiD and control for duration and bounce



eststo clear
		eststo:	sdid l_visit_duration_google_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sdid)
		eststo:	sdid l_visit_duration_google_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(did)
		eststo:	sdid l_visit_duration_google_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sc)
		eststo:	sdid l_bounce_google_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sdid)
		eststo:	sdid l_bounce_google_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(did)
		eststo:	sdid l_bounce_google_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sc)
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(N) 
	
		#delimit ;
		esttab using "results\tables\Table_C9.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(N, fmt(%9.0fc) labels(N))
			nonotes nonumbers
			mlabels("(Synth. DiD)" "(DiD)" "(Synth. Control)" "(Synth. DiD)" "(DiD)" "(Synth. Control)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;	
			
		
		
		

sdid_event l_visit_duration_google_maps country obs treated if  year>2022, effects(11) placebo(12) brep(100) vce(bootstrap)

preserve
mat res = e(H)[2..24,1..5]
svmat res
gen id1 = _n if !missing(res1)
replace id1 = 11 - _n if _n > 11 & !missing(res1)
sort id1
gen id2=id1+13

replace res1 = 0 in 24
replace res3 = 0 in 24
replace res4 = 0 in 24
replace id2 = 13 in 24

sort id2


twoway (rline res3 res4 id2, lcolor(black) lpattern(dash)) (rline res1 res1 id2, lcolor(black) lwidth(medthick)), legend(off) ytitle("Estimated Coefficients (Duration - google.com/maps)") xtitle("") xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) yscale(range(-0.1 0.05) fextend) xscale(fextend) yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) xline(15, lcolor(gs10)) text(-0.05 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(0.053 11.9 "DMA Compliance Period", placement(s) size(small))
 graph export "results\figures\Figure_C16a.pdf", as(pdf) replace

graph close 	

restore		



sdid_event l_bounce_google_maps country obs treated if  year>2022, effects(11) placebo(12) brep(100) vce(bootstrap)

preserve
mat res = e(H)[2..24,1..5]
svmat res
gen id1 = _n if !missing(res1)
replace id1 = 11 - _n if _n > 11 & !missing(res1)
sort id1
gen id2=id1+13

replace res1 = 0 in 24
replace res3 = 0 in 24
replace res4 = 0 in 24
replace id2 = 13 in 24

sort id2


twoway (rline res3 res4 id2, lcolor(black) lpattern(dash)) (rline res1 res1 id2, lcolor(black) lwidth(medthick)), legend(off) ytitle("Estimated Coefficients (Bounce - google.com/maps)") xtitle("") xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) yscale(range(-0.2 0.48) fextend) xscale(fextend) yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) xline(15, lcolor(gs10)) text(0.35 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(0.52 11.9 "DMA Compliance Period", placement(s) size(small))
 graph export "results\figures\Figure_C16b.pdf", as(pdf) replace

graph close 	

restore		
		
				
////// traffic from direction link

preserve


do "scripts/RUN_DID_traffic_directions.do"


restore		
		
		

////////////////////////////////////////////////////////////////////////////////
//////////// Robustness: Impact on Alternative and Related Services ////////////
//////////// Table C11 - 14 and Figure C19-C23 /////////////////////////////////
			
				
		

////////////////////////////////////////////////////////////////////////////////
///////// bing maps //////////////////////////////////////////////////////////



sum visit_bing_com_maps, detail

tab country if visit_bing_com_maps==0

gen l_visit_bing_com_maps=ln(visit_bing_com_maps) 
replace l_visit_bing_com_maps=0 if l_visit_bing_com_maps==.

sum visit_mobile_bing_maps, detail

gen l_visit_mobile_bing_maps=ln(visit_mobile_bing_maps) 
replace l_visit_mobile_bing_maps=0 if l_visit_mobile_bing_maps==.









eststo clear
		eststo:	reghdfe l_visit_bing_com_maps treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_visit_bing_com_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_bing_com_maps treated if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_visit_bing_com_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_bing_com_maps treated if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_visit_bing_com_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
        eststo:	reghdfe l_visit_mobile_bing_maps treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_visit_mobile_bing_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_mobile_bing_maps treated  if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_visit_mobile_bing_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_mobile_bing_maps treated  if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_visit_mobile_bing_maps if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_C11.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Month FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;		
		



reghdfe l_visit_bing_com_maps i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.48) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Desktop - bing.com/maps)") ///
    text(-1.4 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(2.2 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C19a.pdf", as(pdf) replace
graph close 




reghdfe l_visit_mobile_bing_maps i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  


coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.3) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Mobile - bing.com/maps)") ///
    text(-4.3 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(4.8 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C19b.pdf", as(pdf) replace
graph close 		
		
	

///////////// synthetic DID


eststo clear
		eststo:	sdid l_visit_bing_com_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sdid)
		eststo:	sdid l_visit_bing_com_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(did)
		eststo:	sdid l_visit_bing_com_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sc)
		eststo:	sdid l_visit_mobile_bing_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sdid)
		eststo:	sdid l_visit_mobile_bing_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(did)
		eststo:	sdid l_visit_mobile_bing_maps country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sc)
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(N) 
	
		#delimit ;
		esttab using "results\tables\Table_C12.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(N, fmt(%9.0fc) labels(N))
			nonotes nonumbers
			mlabels("(Synth. DiD)" "(DiD)" "(Synth. Control)" "(Synth. DiD)" "(DiD)" "(Synth. Control)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;	
	

	

sdid_event l_visit_bing_com_maps country obs treated if  year>2022, effects(11) placebo(12) brep(100) vce(bootstrap)

preserve
mat res = e(H)[2..24,1..5]
svmat res
gen id1 = _n if !missing(res1)
replace id1 = 11 - _n if _n > 11 & !missing(res1)
sort id1
gen id2=id1+13

replace res1 = 0 in 24
replace res3 = 0 in 24
replace res4 = 0 in 24
replace id2 = 13 in 24

sort id2

twoway (rline res3 res4 id2, lcolor(black) lpattern(dash)) (rline res1 res1 id2, lcolor(black) lwidth(medthick)), legend(off) ytitle("Estimated Coefficients (Desktop - bing.com\maps)") xtitle("") xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) yscale(range(-0.2 0.2) fextend) xscale(fextend) yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) xline(15, lcolor(gs10)) text(0.8 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(1.1 11.9 "DMA Compliance Period", placement(s) size(small))
 graph export "results\figures\Figure_C20a.pdf", as(pdf) replace
 
 graph close 	

restore
		


sdid_event l_visit_mobile_bing_maps country obs treated if  year>2022, effects(11) placebo(12) brep(100) vce(bootstrap)

preserve
mat res = e(H)[2..24,1..5]
svmat res
gen id1 = _n if !missing(res1)
replace id1 = 11 - _n if _n > 11 & !missing(res1)
sort id1
gen id2=id1+13

replace res1 = 0 in 24
replace res3 = 0 in 24
replace res4 = 0 in 24
replace id2 = 13 in 24

sort id2

twoway (rline res3 res4 id2, lcolor(black) lpattern(dash)) (rline res1 res1 id2, lcolor(black) lwidth(medthick)), legend(off) ytitle("Estimated Coefficients (Mobile - bing.com\maps)") xtitle("") xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) yscale(range(-0.2 0.2) fextend) xscale(fextend) yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) xline(15, lcolor(gs10)) text(-1.8 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(4.4 11.9 "DMA Compliance Period", placement(s) size(small))
 graph export "results\figures\Figure_C20b.pdf", as(pdf) replace
 
 graph close 	

restore
		

				


	
////////////////////////////////////////////////////////////////////////////////
///////// google //////////////////////////////////////////////////////////



sum visit_google, detail

gen l_visit_google=ln(visit_google) 


sum visit_mobile_google, detail

gen l_visit_google_mobile=ln(visit_mobile_google) 
replace l_visit_google_mobile=0 if l_visit_google_mobile==.





////////////////////////////////////////////////////////////////////////////
///////////// desktop vs mobile: google ////////////////////////////////////





eststo clear
		eststo:	reghdfe l_visit_google treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_visit_google if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_google treated if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_visit_google if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_google treated if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_visit_google if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
        eststo:	reghdfe l_visit_google_mobile treated if year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_visit_google_mobile if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_google_mobile treated  if aus==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_visit_google_mobile if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_visit_google_mobile treated  if other==0 & year>2022 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_visit_google_mobile if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_C13.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Month FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;		
		


reghdfe l_visit_google i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.48) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Desktop - google.com)") ///
    text(0.4 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.53 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C22a.pdf", as(pdf) replace
graph close 




reghdfe l_visit_google_mobile i.EU##ib37.obs  if other==0 & year>2022, absorb(country obs) cluster(country)  


coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) ///
    xline(15, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.3) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (Mobile - google.com)") ///
    text(0.3 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.72 11.9 "DMA Compliance Period", placement(s) size(small))
   
graph export "results\figures\Figure_C22b.pdf", as(pdf) replace
graph close 		
		
	

///////////// synthetic DID

	

eststo clear
		eststo:	sdid l_visit_google country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sdid)
		eststo:	sdid l_visit_google country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(did)
		eststo:	sdid l_visit_google country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sc)
		eststo:	sdid l_visit_google_mobile country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sdid)
		eststo:	sdid l_visit_google_mobile country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(did)
		eststo:	sdid l_visit_google_mobile country obs treated if year>2022,  vce(bootstrap) reps(300) seed(123) method(sc)
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(N) 
	
		#delimit ;
		esttab using "results\tables\Table_C14.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(N, fmt(%9.0fc) labels(N))
			nonotes nonumbers
			mlabels("(Synth. DiD)" "(DiD)" "(Synth. Control)" "(Synth. DiD)" "(DiD)" "(Synth. Control)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;	
	

	

sdid_event l_visit_google country obs treated if  year>2022, effects(11) placebo(12) brep(100) vce(bootstrap)

preserve
mat res = e(H)[2..24,1..5]
svmat res
gen id1 = _n if !missing(res1)
replace id1 = 11 - _n if _n > 11 & !missing(res1)
sort id1
gen id2=id1+13

replace res1 = 0 in 24
replace res3 = 0 in 24
replace res4 = 0 in 24
replace id2 = 13 in 24

sort id2

twoway (rline res3 res4 id2, lcolor(black) lpattern(dash)) (rline res1 res1 id2, lcolor(black) lwidth(medthick)), legend(off) ytitle("Estimated Coefficients (Desktop - google.com)") xtitle("") xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) yscale(range(-0.2 0.2) fextend) xscale(fextend) yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) xline(15, lcolor(gs10)) text(0.21 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(0.24 11.9 "DMA Compliance Period", placement(s) size(small))
 graph export "results\figures\Figure_C23a.pdf", as(pdf) replace
 
graph close 	

restore
		

		
		

sdid_event l_visit_google_mobile country obs treated if  year>2022, effects(11) placebo(12) brep(100) vce(bootstrap)

preserve
mat res = e(H)[2..24,1..5]
svmat res
gen id1 = _n if !missing(res1)
replace id1 = 11 - _n if _n > 11 & !missing(res1)
sort id1
gen id2=id1+13

replace res1 = 0 in 24
replace res3 = 0 in 24
replace res4 = 0 in 24
replace id2 = 13 in 24

sort id2

twoway (rline res3 res4 id2, lcolor(black) lpattern(dash)) (rline res1 res1 id2, lcolor(black) lwidth(medthick)), legend(off) ytitle("Estimated Coefficients (Mobile - google.com)") xtitle("") xlabel(1 "Jan 23" 5 "May 23" 9 "Sep 23" 13 "Jan 24" 15 "Mar 24" 17 "May 24" 21 "Sep 24" 24 "Dec 24", labsize(vsmall) angle(horizontal)) yscale(range(-0.2 0.2) fextend) xscale(fextend) yline(0, lcolor(gs1)) xline(9, lcolor(gs10)) xline(13, lcolor(gs1)) xline(15, lcolor(gs10)) text(0.24 13 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(0.36 11.9 "DMA Compliance Period", placement(s) size(small))
 graph export "results\figures\Figure_C23b.pdf", as(pdf) replace
 
graph close 	

restore
		
		
				
				
				
			
	
	
	
	
	
	
	
	
	