****************************************************
** Diff-in-Diff for Search Volumes
****************************************************


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

xtset id obs

drop if year<2023

gen post=0
replace post=1 if obs>105


gen treated=0
replace treated=1 if EU==1 & post==1

label var treated " $ EU \times post^{DMA} $ " 

////////////////////////////////////////////////////////////////////////////////
///////////////////// DID variables ////////////////////////////////////////////



label var EU " $ EU_{i} $ " 
label var post " $ post_{t}^{DMA} $ " 


gen aus=0
replace aus=1 if country==44  // sa	
replace aus=1 if country==38  // nz	
//replace aus=1 if country==27  // india	
//replace aus=1 if country==13 // colombia	
replace aus=1 if country==12 // chile	
replace aus=1 if country==9	// brazil
replace aus=1 if country==3	// australia
	

////// remove Cyprus and Malta becasue of not all data

drop if country==16

drop if country==36 

////// remove North Macedonia becasue of not all data. Some (smaller) data restrictions for Albania, Armenia, Azerbaijan, Belarus, Georgia, Iceland, Ukraine

drop if country==35



////////////////////////////////////////////////////////////////////////////////
////////////////////////// measuring volumes when no trends ////////////////////




gen l_trends = ln(trends)

gen l_volume = ln(volume_search)


gen ratio_volume=volume_search/trends

egen volume_one_trend = max(ratio_volume), by(country query)

gen volume_search_no_zero=volume_search
replace volume_search_no_zero=volume_one_trend if volume_search==0


gen l_volume_no_zero = ln(volume_search_no_zero)

gen l_volume_no_zero1 = ln(volume_search_no_zero/2)


////////////////////////////////////////////////////////////////////////////////
////////////////////// DiD EVENT STUDIES ///////////////////////////////////////
////////////////////// FIGURE 2, B1, and B2 ////////////////////////////////////


///Search Volumes for the query maps



reghdfe l_volume i.EU##ib106.obs  if query==6, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(36, lcolor(gs10)) xline(54, lcolor(gs1)) ///
    xline(62, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.48) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 19 "May 23" 36 "Sep 23" 54 "Jan 24" 62 "Mar 24" 71 "May 24" 88 "Sep 24" 101 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (maps query)") ///
    text(0.52 54 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.65 49 "DMA Compliance Period", placement(s) size(small))

    graph export "results\figures\Figure_B2a.pdf", as(pdf) replace
	graph close 

reghdfe l_volume i.EU##ib106.obs  if query==6 & aus==0, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(36, lcolor(gs10)) xline(54, lcolor(gs1)) ///
    xline(62, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.48) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 19 "May 23" 36 "Sep 23" 54 "Jan 24" 62 "Mar 24" 71 "May 24" 88 "Sep 24" 101 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (maps query)") ///
    text(0.46 54 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.525 49 "DMA Compliance Period", placement(s) size(small))

    graph export "results\figures\Figure_B1a.pdf", as(pdf) replace
	graph close 


reghdfe l_volume i.EU##ib106.obs if query==6 & other==0, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(36, lcolor(gs10)) xline(54, lcolor(gs1)) ///
    xline(62, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.48) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 19 "May 23" 36 "Sep 23" 54 "Jan 24" 62 "Mar 24" 71 "May 24" 88 "Sep 24" 101 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (maps query)") ylabel(, angle(horizontal) labsize(small)) ///
    text(0.46 54 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.525 49 "DMA Compliance Period", placement(s) size(small))

    graph export "results\figures\Figure_2a.pdf", as(pdf) replace
	graph close 


	
	
	
	
///Search Volumes for the query google maps



reghdfe l_volume i.EU##ib106.obs  if query==4, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(36, lcolor(gs10)) xline(54, lcolor(gs1)) ///
    xline(62, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.48) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 19 "May 23" 36 "Sep 23" 54 "Jan 24" 62 "Mar 24" 71 "May 24" 88 "Sep 24" 101 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (google maps query)") ///
    text(0.49 54 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.625 49 "DMA Compliance Period", placement(s) size(small))
		
    graph export "results\figures\Figure_B2b.pdf", as(pdf) replace
	graph close 


reghdfe l_volume i.EU##ib106.obs  if query==4 & aus==0, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(36, lcolor(gs10)) xline(54, lcolor(gs1)) ///
    xline(62, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.48) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 19 "May 23" 36 "Sep 23" 54 "Jan 24" 62 "Mar 24" 71 "May 24" 88 "Sep 24" 101 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (google maps query)") ///
    text(0.46 54 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.525 49 "DMA Compliance Period", placement(s) size(small))
		
    graph export "results\figures\Figure_B1b.pdf", as(pdf) replace
	graph close 


reghdfe l_volume i.EU##ib106.obs  if query==4 & other==0, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(36, lcolor(gs10)) xline(54, lcolor(gs1)) ///
    xline(62, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.48) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 19 "May 23" 36 "Sep 23" 54 "Jan 24" 62 "Mar 24" 71 "May 24" 88 "Sep 24" 101 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (google maps query)") ///
    text(0.46 54 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(0.525 49 "DMA Compliance Period", placement(s) size(small))
		
    graph export "results\figures\Figure_2b.pdf", as(pdf) replace
	graph close 
		



////////////////////////////////////////////////////////////////////////////////
////////////////////// DiD Table: //////////////////////////////////////////////
////////////////////// TABLE 3 /////////////////////////////////////////////////

///Search Volumes for the queries maps and google maps


eststo clear
		eststo:	reghdfe l_volume treated if query==6, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume treated if aus==0 & query==6, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume treated if other==0 & query==6, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
        eststo:	reghdfe l_volume treated if query==4, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume treated  if aus==0 & query==4, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume treated  if other==0 & query==4, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_3.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Week FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;
	

	
	
	
	
	
	
////////////////////////////////////////////////////////////////////////////////
//////////// Robustness: Synthetic DiD /////////////////////////////////////////
//////////// Table B1, Figures B3a, B3b, B4, B5 ////////////////////////////////
			
		

eststo clear
		eststo:	sdid l_volume country obs treated if query==6,  vce(bootstrap) reps(100) seed(123) method(sdid)
		eststo:	sdid l_volume country obs treated if query==6,  vce(bootstrap) reps(100) seed(123) method(did)
		eststo:	sdid l_volume country obs treated if query==6,  vce(bootstrap) reps(100) seed(123) method(sc)
		eststo:	sdid l_volume country obs treated if query==4,  vce(bootstrap) reps(100) seed(123) method(sdid)
		eststo:	sdid l_volume country obs treated if query==4,  vce(bootstrap) reps(100) seed(123) method(did)
		eststo:	sdid l_volume country obs treated if query==4,  vce(bootstrap) reps(100) seed(123) method(sc)
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(N) 
	
		#delimit ;
		esttab using "results\tables\Table_B1.tex", replace 
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

		
//// Event study for query maps	

sdid_event l_volume country obs treated if query==6, effects(49) placebo(53) brep(100) vce(bootstrap) method(sdid)

preserve
mat res = e(H)[2..103,1..5]
svmat res
gen id1 = _n if !missing(res1)
replace id1 = 49 - _n if _n > 49 & !missing(res1)
sort id1
gen id2=id1+54

replace res1 = 0 in 103
replace res3 = 0 in 103
replace res4 = 0 in 103
replace id2 = 54 in 103

sort id2

twoway (rline res3 res4 id2, lcolor(black) lpattern(dash)) (rline res1 res1 id2, lcolor(black) lwidth(medthick)), legend(off) ytitle("Estimated Coefficients (maps query)") xtitle("") xlabel(1 "Jan 23" 19 "May 23" 36 "Sep 23" 54 "Jan 24" 62 "Mar 24" 71 "May 24" 88 "Sep 24" 101 "Dec 24", labsize(vsmall) angle(horizontal)) yscale(range(-0.2 0.48) fextend) xscale(fextend) yline(0, lcolor(gs1)) xline(36, lcolor(gs10)) xline(54, lcolor(gs1)) xline(62, lcolor(gs10)) text(0.43 54 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(0.51 49 "DMA Compliance  Period", placement(s) size(small))
 graph export "results\figures\Figure_B3a.pdf", as(pdf) replace
graph close 	
		
	

restore


//// Event study for query google maps	


sdid_event l_volume country obs treated if query==4, effects(49) placebo(53) brep(100) vce(bootstrap)

preserve
mat res = e(H)[2..103,1..5]
svmat res
gen id1 = _n if !missing(res1)
replace id1 = 49 - _n if _n > 49 & !missing(res1)
sort id1
gen id2=id1+54

replace res1 = 0 in 103
replace res3 = 0 in 103
replace res4 = 0 in 103
replace id2 = 54 in 103

sort id2

twoway (rline res3 res4 id2, lcolor(black) lpattern(dash)) (rline res1 res1 id2, lcolor(black) lwidth(medthick)), legend(off) ytitle("Estimated Coefficients (google maps query)") xtitle("") xlabel(1 "Jan 23" 19 "May 23" 36 "Sep 23" 54 "Jan 24" 62 "Mar 24" 71 "May 24" 88 "Sep 24" 101 "Dec 24", labsize(vsmall) angle(horizontal)) yscale(range(-0.2 0.48) fextend) xscale(fextend) yline(0, lcolor(gs1)) xline(36, lcolor(gs10)) xline(54, lcolor(gs1)) xline(62, lcolor(gs10)) text(0.43 54 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(0.51 49 "DMA Compliance  Period", placement(s) size(small))
 graph export "results\figures\Figure_B3b.pdf", as(pdf) replace
	graph close 	
		
	

restore
		



//// Weights for query maps		

sdid l_volume country obs treated if query==6,  vce(bootstrap) reps(100) seed(123) method(sdid) graph g1on g1_opt(xtitle("") xlabel(1 "Albania" 2 "Armenia" 3 "Australia" 4 "Azerbaijan" 5 "Belarus" 6 "Bosnia" 7 "Brazil" 8 "Canada" 9 "Chile" 10 "Colombia" 11 "Costarica" 12 "Georgia" 13 "Iceland" 14 "India" 15 "Israel" 16 "Japan" 17 "Mexico" 18 "New Zealand" 19 "Norway" 20 "South Africa" 21 "South Korea" 22 "Serbia" 23 "Switzerland" 24 "Turkey" 25 "UK" 26 "US" 27 "Ukraine") ylabel(0.0(0.1)0.3) scheme(plotplainblind)) g2_opt( xtitle("") ytitle("Google Search Volumes (maps query)") xlabel(53 "Jan 23" 71 "May 23" 88 "Sep 23" 106 "Jan 24" 114 "Mar 24" 123 "May 24" 140 "Sep 24" 153 "Dec 24", labsize(vsmall) angle(horizontal)) xline(88, lcolor(gs10)) xline(106, lcolor(gs1)) xline(114, lcolor(gs10)) text(13.4 106 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(13.56 101 "DMA  Compliance Period" , placement(s) size(small)) ) mattitles graph_export("results\figures\Figure_B4", .pdf)



//// Weights for query google maps		

sdid l_volume country obs treated if query==4,  vce(bootstrap) reps(100) seed(123) method(sdid) graph g1on g1_opt(xtitle("") xlabel(1 "Albania" 2 "Armenia" 3 "Australia" 4 "Azerbaijan" 5 "Belarus" 6 "Bosnia" 7 "Brazil" 8 "Canada" 9 "Chile" 10 "Colombia" 11 "Costarica" 12 "Georgia" 13 "Iceland" 14 "India" 15 "Israel" 16 "Japan" 17 "Mexico" 18 "New Zealand" 19 "Norway" 20 "South Africa" 21 "South Korea" 22 "Serbia" 23 "Switzerland" 24 "Turkey" 25 "UK" 26 "US" 27 "Ukraine") ylabel(0.0(0.1)0.3) scheme(plotplainblind)) g2_opt( xtitle("") ytitle("Google Search Volumes (google maps query)") xlabel(53 "Jan 23" 71 "May 23" 88 "Sep 23" 106 "Jan 24" 114 "Mar 24" 123 "May 24" 140 "Sep 24" 153 "Dec 24", labsize(vsmall) angle(horizontal)) xline(88, lcolor(gs10)) xline(106, lcolor(gs1)) xline(114, lcolor(gs10)) text(12.5 106 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(12.62 101 "DMA  Compliance Period" , placement(s) size(small)) ) mattitles graph_export("results\figures\Figure_B5", .pdf)

		

		
		

		
////////////////////////////////////////////////////////////////////////////////
//////////// Robustness: YT Search /////////////////////////////////////////////
//////////// Table B2, Figures B6a, B6b ////////////////////////////////////////
				

preserve

use "processed\Google_trend_processed\all_YT.dta",replace

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


drop if year<2023

gen post=0
replace post=1 if obs>105


gen treated=0
replace treated=1 if EU==1 & post==1

label var treated " $ EU \times post^{DMA} $ " 



label var EU " $ EU_{i} $ " 
label var post " $ post_{t}^{DMA} $ " 



tab trends

gen trends1=trends
replace trends1=trends+1 if trends==0

gen l_trends = ln(trends1)

	

gen aus=0
replace aus=1 if country==44  // sa	
replace aus=1 if country==38  // nz	
//replace aus=1 if country==27  // india	
//replace aus=1 if country==13 // colombia	
replace aus=1 if country==12 // chile	
replace aus=1 if country==9	// brazil
replace aus=1 if country==3	// australia
	

////// remove Cyprus and Malta becasue of not all data

drop if country==16

drop if country==36 

////// remove North Macedonia becasue of not all data. Some (smaller) data restrictions for Albania, Armenia, Azerbaijan, Belarus, Georgia, Iceland, Ukraine

drop if country==35


eststo clear
		eststo:	reghdfe l_trends treated  if query==2, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_trends if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_trends treated  if aus==0 & query==2, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_trends if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_trends treated  if other==0 & query==2, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_trends if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
        eststo:	reghdfe l_trends treated  if query==1, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_trends if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_trends treated  if aus==0 & query==1, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_trends if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_trends treated  if other==0 & query==1, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_trends if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_B2.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Week FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;
	



reghdfe l_trends i.EU##ib106.obs  if query==2 & other==0, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(36, lcolor(gs10)) xline(54, lcolor(gs1)) ///
    xline(62, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.48) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 19 "May 23" 36 "Sep 23" 54 "Jan 24" 62 "Mar 24" 71 "May 24" 88 "Sep 24" 101 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (maps query)") ///
    text(-1.6 54 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(2.2 49 "DMA Compliance Period", placement(s) size(small))
			
    graph export "results\figures\Figure_B6a.pdf", as(pdf) replace
	graph close 	
	

reghdfe l_trends i.EU##ib106.obs  if query==1 & other==0, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(36, lcolor(gs10)) xline(54, lcolor(gs1)) ///
    xline(62, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.48) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 19 "May 23" 36 "Sep 23" 54 "Jan 24" 62 "Mar 24" 71 "May 24" 88 "Sep 24" 101 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (google maps query)") ///
    text(1.75 54 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(2.2 49 "DMA Compliance Period", placement(s) size(small))
				
    graph export "results\figures\Figure_B6b.pdf", as(pdf) replace
	graph close 	


restore				
				
				
				
				
				
				
				
				

////////////////////////////////////////////////////////////////////////////////
//////////// Robustness: Google Trends /////////////////////////////////////////
//////////// Table B3 //////////////////////////////////////////////////////////
							


eststo clear
		eststo:	reghdfe l_trends treated if query==6, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_trends if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_trends treated if aus==0 & query==6, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_trends if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_trends treated if other==0 & query==6, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_trends if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
        eststo:	reghdfe l_trends treated if query==4, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_trends if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_trends treated if aus==0 & query==4, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "North Hem."
		su l_trends if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_trends treated if other==0 & query==4, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "Only Euro"
		su l_trends if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_B3.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Week FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;
	
		
				
		
		
		
		
		


////////////////////////////////////////////////////////////////////////////////
//////////// Robustness: EU Countries as Their Own Counterfactual //////////////
//////////// Table B4 //////////////////////////////////////////////////////////
									

preserve		
	

///
/// Using the past year as control
///	

/// Jan24 - Jun24: treated months
/// Jun 23 - Jun24: year considered that will be treated
/// Jun 22 - Jun23: year considered that will not be treated
/// post is from Jan to Jun 


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

gen post=0
replace post=1 if obs>105


gen treated=0
replace treated=1 if EU==1 & post==1

label var treated " $ EU \times post^{DMA} $ " 

label var EU " $ EU_{i} $ " 
label var post " $ post_{t}^{DMA} $ " 


gen aus=0
replace aus=1 if country==44  // sa	
replace aus=1 if country==38  // nz	
//replace aus=1 if country==27  // india	
//replace aus=1 if country==13 // colombia	
replace aus=1 if country==12 // chile	
replace aus=1 if country==9	// brazil
replace aus=1 if country==3	// australia
	

////// remove Cyprus and Malta becasue of not all data

drop if country==16

drop if country==36 


////// remove North Macedonia becasue of not all data. Some (smaller) data restrictions for Albania, Armenia, Azerbaijan, Belarus, Georgia, Iceland, Ukraine

drop if country==35







////////////////////////////////////////////////////////////////////////////////
////////////////////////// measuring volumes when no trends ////////////////////
////////////////////////////////////////////////////////////////////////////////


gen ratio_volume=volume_search/trends

egen volume_one_trend = max(ratio_volume), by(country query)

gen volume_search_no_zero=volume_search
replace volume_search_no_zero=volume_one_trend if volume_search==0


gen l_trends = ln(trends)

gen l_volume = ln(volume_search)


gen l_volume_no_zero = ln(volume_search_no_zero)

gen l_volume_no_zero1 = ln(volume_search_no_zero/2)



gen new_sample=0
replace new_sample=1 if (week>22 & year==2022) | year>2022 	
replace new_sample=0 if obs>127	

	
gen post_new=0
replace post_new=1 if week<23

gen last_year=0
replace last_year=1 if (week>22 & year==2023) | year>2023
	
gen treated_new=post_new*last_year	
label var treated_new " $ 2024 \times Jan-Jun $ " 

		
	

eststo clear
		eststo:	reghdfe l_volume treated_new if  query==6 & new_sample==1 & EU==1, absorb(country) cluster(country)
		estadd local country "\checkmark"
		estadd local date ""
		estadd local ctrend ""
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume treated_new obs if  query==6 & new_sample==1 & EU==1, absorb(country) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local ctrend ""
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume treated_new i.country#c.obs if  query==6 & new_sample==1 & EU==1, absorb(country) cluster(country)
		estadd local country "\checkmark"
		estadd local date ""
		estadd local ctrend "\checkmark"
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume treated_new if query==4 & new_sample==1 & EU==1, absorb(country) cluster(country)
		estadd local country "\checkmark"
		estadd local date ""
		estadd local ctrend ""
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume treated_new obs if  query==4 & new_sample==1 & EU==1, absorb(country) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local ctrend ""
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume treated_new i.country#c.obs if query==4 & new_sample==1 & EU==1, absorb(country) cluster(country)
		estadd local country "\checkmark"
		estadd local date ""
		estadd local ctrend "\checkmark"
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated_new ) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date ctrend r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_B4.tex", replace 
			booktabs 
			keep(treated_new) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date ctrend r2 N mu, fmt(%8.2f %8.2f %8.2f %8.2f %9.0fc %8.2fc) labels("Country FEs" "Linear Time Trend" "Country-Specific Time Trends" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;
	
restore		
		
		
		
		

////////////////////////////////////////////////////////////////////////////////
//////////// Extensions: Competing Mapping Services ////////////////////////////
//////////// Table B5 B6, B7, B8 and Figure B7 and B8 //////////////////////////
											
///
/// apple maps, bing maps, mappy, and openstreetmaps 
///	


eststo clear
eststo:	reghdfe l_volume_no_zero treated  if  query==1, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume_no_zero if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume_no_zero treated  if    query==3 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume_no_zero if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume_no_zero treated  if     query==5 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume_no_zero if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume_no_zero treated if   query==7 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume_no_zero if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_B5.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Week FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(\texttt{apple maps})" "(\texttt{bing maps})" "(\texttt{mappy})" "(\texttt{openstreetmap})")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;
		
		


eststo clear
eststo:	reghdfe l_volume_no_zero1 treated  if  other==0 & query==1, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume_no_zero1 if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume_no_zero1 treated  if  other==0  &   query==3 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume_no_zero1 if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume_no_zero1 treated  if  other==0  &   query==5 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume_no_zero1 if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume_no_zero1 treated if other==0  &   query==7 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume_no_zero1 if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_B6.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Week FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(\texttt{apple maps})" "(\texttt{bing maps})" "(\texttt{mappy})" "(\texttt{openstreetmap})")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;
		

					
		
eststo clear
eststo:	reghdfe l_volume treated  if  other==0 & query==1, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume treated  if  other==0  &   query==3 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume treated  if  other==0  &   query==5 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume treated if  other==0  &   query==7 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_B7.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Week FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(\texttt{apple maps})" "(\texttt{bing maps})" "(\texttt{mappy})" "(\texttt{openstreetmap})")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;

	
		
		
		
		

reghdfe l_volume_no_zero i.EU##ib106.obs  if  query==1, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(36, lcolor(gs10)) xline(54, lcolor(gs1)) ///
    xline(62, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.48) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 19 "May 23" 36 "Sep 23" 54 "Jan 24" 62 "Mar 24" 71 "May 24" 88 "Sep 24" 101 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (apple maps query)") ///
    text(1.8 54 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(2.2 49 "DMA Compliance Period", placement(s) size(small))
		

    graph export "results\figures\Figure_B7a.pdf", as(pdf) replace
	graph close 		
		
		

reghdfe l_volume_no_zero i.EU##ib106.obs  if  query==3, absorb(country obs) cluster(country)  

coefplot, keep(1.EU#*.obs) omitted baselevels vertical yline(0, lcolor(gs1)) xline(36, lcolor(gs10)) xline(54, lcolor(gs1)) ///
    xline(62, lcolor(gs10)) levels(95) recast(line) lwidth(*1.5) lcolor(black) ///
    ciopts(recast(rline) lpattern(dash) lcolor(black)) ///
    yscale(range(-0.2 0.48) fextend) xscale(fextend) ///
    xlabel(1 "Jan 23" 19 "May 23" 36 "Sep 23" 54 "Jan 24" 62 "Mar 24" 71 "May 24" 88 "Sep 24" 101 "Dec 24", labsize(vsmall) angle(horizontal)) ///
    ytitle("Estimated Coefficients (bing maps query)") ///
    text(-4.7 54 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) ///
    text(2.4 49 "DMA Compliance Period", placement(s) size(small))
		
    graph export "results\figures\Figure_B7b.pdf", as(pdf) replace
	graph close 		
		
		
		
		
		
		
	
///////// synthetic DID	for competitors


eststo clear
		eststo:	sdid l_volume_no_zero country obs treated if  l_volume_no_zero!=. & query==1 ,  vce(bootstrap) reps(100) seed(123) method(sdid)  
		eststo:	sdid l_volume_no_zero country obs treated if  l_volume_no_zero!=. & query==3 ,  vce(bootstrap) reps(100) seed(123) method(sdid) 
		eststo:	sdid l_volume_no_zero country obs treated if  l_volume_no_zero!=. & query==5 ,  vce(bootstrap) reps(100) seed(123) method(sdid)  
		eststo:	sdid l_volume_no_zero country obs treated if  l_volume_no_zero!=. & query==7 ,  vce(bootstrap) reps(100) seed(123) method(sdid)
		
	esttab, keep(treated ) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(N) 
	
		#delimit ;
		esttab using "results\tables\Table_B8.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(N, fmt(%9.0fc) labels(N))
			nonotes nonumbers
			mlabels("(\texttt{apple maps})" "(\texttt{bing maps})" "(\texttt{mappy})" "(\texttt{openstreetmap})")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;	



sdid_event l_volume_no_zero country obs treated if l_volume_no_zero!=. & query==1, effects(49) placebo(53) brep(100) vce(bootstrap)

preserve
mat res = e(H)[2..103,1..5]
svmat res
gen id1 = _n if !missing(res1)
replace id1 = 49 - _n if _n > 49 & !missing(res1)
sort id1
gen id2=id1+54

replace res1 = 0 in 103
replace res3 = 0 in 103
replace res4 = 0 in 103
replace id2 = 54 in 103

sort id2

twoway (rline res3 res4 id2, lcolor(black) lpattern(dash)) (rline res1 res1 id2, lcolor(black) lwidth(medthick)), legend(off) ytitle("Estimated Coefficients (apple maps query)") xtitle("") xlabel(1 "Jan 23" 19 "May 23" 36 "Sep 23" 54 "Jan 24" 62 "Mar 24" 71 "May 24" 88 "Sep 24" 101 "Dec 24", labsize(vsmall) angle(horizontal)) yscale(range(-0.2 0.48) fextend) xscale(fextend) yline(0, lcolor(gs1)) xline(36, lcolor(gs10)) xline(54, lcolor(gs1)) xline(62, lcolor(gs10)) text(1.6 54 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(2.11 49 "DMA Compliance  Period", placement(s) size(small))
 graph export "results\figures\Figure_B8a.pdf", as(pdf) replace
//	graph close 	
		
	

restore



sdid_event l_volume_no_zero country obs treated if l_volume_no_zero!=. & query==3, effects(49) placebo(53) brep(100) vce(bootstrap)

preserve
mat res = e(H)[2..103,1..5]
svmat res
gen id1 = _n if !missing(res1)
replace id1 = 49 - _n if _n > 49 & !missing(res1)
sort id1
gen id2=id1+54

replace res1 = 0 in 103
replace res3 = 0 in 103
replace res4 = 0 in 103
replace id2 = 54 in 103

sort id2

twoway (rline res3 res4 id2, lcolor(black) lpattern(dash)) (rline res1 res1 id2, lcolor(black) lwidth(medthick)), legend(off) ytitle("Estimated Coefficients (bing maps query)") xtitle("") xlabel(1 "Jan 23" 19 "May 23" 36 "Sep 23" 54 "Jan 24" 62 "Mar 24" 71 "May 24" 88 "Sep 24" 101 "Dec 24", labsize(vsmall) angle(horizontal)) yscale(range(-0.2 0.48) fextend) xscale(fextend) yline(0, lcolor(gs1)) xline(36, lcolor(gs10)) xline(54, lcolor(gs1)) xline(62, lcolor(gs10)) text(1.75 54 "No Clickable" "Maps", box fcolor(white) placement(s) width(17) margin(l+1 t+1 b+1) size(small)) text(2.15 49 "DMA Compliance  Period", placement(s) size(small))
 graph export "results\figures\Figure_B8b.pdf", as(pdf) replace
//	graph close 	
		
	

restore



////////////////////////////////////////////////////////////////////////////////
//////////// Extensions: Other Search Queries //////////////////////////////////
//////////// Table B9 //////////////////////////////////////////////////////////	
		


eststo clear
eststo:	reghdfe l_volume_no_zero treated  if query==8, absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume_no_zero if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume_no_zero treated  if   query==9 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume_no_zero if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
		eststo:	reghdfe l_volume_no_zero treated  if    query==10 , absorb(country obs) cluster(country)
		estadd local country "\checkmark"
		estadd local date "\checkmark"
		estadd local control "All"
		su l_volume_no_zero if e(sample)
		local mu : di %4.3f r(mean)
		cap estadd local mu `mu', replace
	esttab, keep(treated) p starlevels(* 0.10 ** 0.05 *** 0.010) stats(country date control r2 N mu) 
	
		#delimit ;
		esttab using "results\tables\Table_B9.tex", replace 
			booktabs 
			keep(treated) 
			title("") 
			label
			alignment(c) 
			starlevels( * 0.10 ** 0.05 *** 0.010) 
			cells(b(star fmt(3)) se(par)) 
			stats(country date control r2 N mu, fmt(%8.2f %8.2f %8.2f %8.3f %9.0fc %8.2fc) labels("Country FEs" "Week FEs" "Control Countries" "$ R ^2 $" N "Mean Dep. Var."))
			nonotes nonumbers
			mlabels("(\texttt{restaurant})" "(\texttt{shopping})" "(\texttt{supermarket})")
			collabels(none) prefoot( ) width(0.8\hsize) prehead( ) posthead(\midrule) postfoot(\midrule) ;
		#delimit cr;		
		
		
		
					
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		