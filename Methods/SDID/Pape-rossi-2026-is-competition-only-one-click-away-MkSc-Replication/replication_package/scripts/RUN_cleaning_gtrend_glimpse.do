****************************************************
** cleaning Google trends and Glimpse data
****************************************************

****************************************************
** cleaning data regarding the following Google queries: maps, google maps, bing, bing maps, apple maps, mappy, openstreetmap, restaurant, shopping, supermarket. Also Yotube search queires for maps, google maps




////////////////////////////////////////////////////////////////////////////////
/////////////////////////// MAPS ///////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////		

global EU "Austria Belgium Bulgaria Croatia Cyprus Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"


/// maps in EU

 foreach x of global EU {		
		

import delimited "data/Google_trend_data/EU/`x'/maps/search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends
rename v3 volume_search

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "maps"


gen EU=1
gen Euro_NoEU=0
gen other=0


save "processed\Google_trend_processed\trend_maps_`x'.dta",replace

 }

 


global EU_1 "Belgium Bulgaria Croatia Cyprus Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"

use "processed\Google_trend_processed\trend_maps_Austria.dta", clear


qui foreach x of global EU_1 {
	
append using "processed/Google_trend_processed/trend_maps_`x'.dta", force

}


save "processed\Google_trend_processed\EU_maps.dta",replace
 
tab country

tab date_long 
 
 
 
/// maps in no_EU 
 
global no_EU "Albania Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"


 foreach x of global no_EU {		
		

import delimited "data/Google_trend_data/Euro_noEU/`x'/maps/search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}


destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "maps"


gen EU=0
gen Euro_NoEU=1
gen other=0


save "processed\Google_trend_processed\trend_maps_`x'.dta",replace

 }
 
 
global no_EU_1 " Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"

use "processed\Google_trend_processed\trend_maps_Albania.dta", clear


qui foreach x of global no_EU_1 {
	
append using "processed/Google_trend_processed/trend_maps_`x'.dta", force

}


save "processed\Google_trend_processed\no_EU_maps.dta",replace
 
tab country

tab date_long 
 
 
//// maps in other (non Euro countries) 
 
 
 

global other "Australia Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

 
 foreach x of global other {		
		

import delimited "data/Google_trend_data/other/`x'/maps/search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "maps"


gen EU=0
gen Euro_NoEU=0
gen other=1

save "processed\Google_trend_processed\trend_maps_`x'.dta",replace

 }
 


global other_1 " Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

use "processed\Google_trend_processed\trend_maps_Australia.dta", clear


qui foreach x of global other_1 {
	
append using "processed/Google_trend_processed/trend_maps_`x'.dta", force

}


save "processed\Google_trend_processed\other_maps.dta",replace
 
tab country

tab date_long  


append using "processed\Google_trend_processed\EU_maps.dta"


append using "processed\Google_trend_processed\no_EU_maps.dta"


sort country date_long

save "processed\Google_trend_processed\all_maps.dta",replace


tab country

tab date_long 




////////////////////////////////////////////////////////////////////////////////
/////////////////////////// GOOGLE MAPS ////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////		

global EU "Austria Belgium Bulgaria Croatia Cyprus Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"


/// maps in EU

 foreach x of global EU {		
		

import delimited "data/Google_trend_data/EU/`x'/google_maps/search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends
rename v3 volume_search

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "google maps"


gen EU=1
gen Euro_NoEU=0
gen other=0


save "processed\Google_trend_processed\trend_google_maps_`x'.dta",replace

 }

 


global EU_1 "Belgium Bulgaria Croatia Cyprus Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"

use "processed\Google_trend_processed\trend_google_maps_Austria.dta", clear


qui foreach x of global EU_1 {
	
append using "processed/Google_trend_processed/trend_google_maps_`x'.dta", force

}


save "processed\Google_trend_processed\EU_google_maps.dta",replace
 
tab country

tab date_long 
 
 
 
/// maps in no_EU 
 
global no_EU "Albania Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"


 foreach x of global no_EU {		
		

import delimited "data/Google_trend_data/Euro_noEU/`x'/google_maps/search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}


destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "google maps"


gen EU=0
gen Euro_NoEU=1
gen other=0


save "processed\Google_trend_processed\trend_google_maps_`x'.dta",replace

 }
 
 
global no_EU_1 " Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"

use "processed\Google_trend_processed\trend_google_maps_Albania.dta", clear


qui foreach x of global no_EU_1 {
	
append using "processed/Google_trend_processed/trend_google_maps_`x'.dta", force

}


save "processed\Google_trend_processed\no_EU_google_maps.dta",replace
 
tab country

tab date_long 
 
 
//// maps in other (non Euro countries) 
 
 
 

global other "Australia Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

 
 foreach x of global other {		
		

import delimited "data/Google_trend_data/other/`x'/google_maps/search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "google maps"


gen EU=0
gen Euro_NoEU=0
gen other=1

save "processed\Google_trend_processed\trend_google_maps_`x'.dta",replace

 }
 


global other_1 " Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

use "processed\Google_trend_processed\trend_google_maps_Australia.dta", clear


qui foreach x of global other_1 {
	
append using "processed/Google_trend_processed/trend_google_maps_`x'.dta", force

}


save "processed\Google_trend_processed\other_google_maps.dta",replace
 
tab country

tab date_long  


append using "processed\Google_trend_processed\EU_google_maps.dta"


append using "processed\Google_trend_processed\no_EU_google_maps.dta"


sort country date_long

save "processed\Google_trend_processed\all_google_maps.dta",replace


tab country

tab date_long 





////////////////////////////////////////////////////////////////////////////////
/////////////////////////// BING ///////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////		

global EU "Austria Belgium Bulgaria Croatia Cyprus Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"


/// maps in EU

 foreach x of global EU {		
		

import delimited "data/Google_trend_data/EU/`x'/bing/search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends
rename v3 volume_search

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "bing"


gen EU=1
gen Euro_NoEU=0
gen other=0


save "processed\Google_trend_processed\trend_bing_`x'.dta",replace

 }

 


global EU_1 "Belgium Bulgaria Croatia Cyprus Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"

use "processed\Google_trend_processed\trend_bing_Austria.dta", clear


qui foreach x of global EU_1 {
	
append using "processed/Google_trend_processed/trend_bing_`x'.dta", force

}


save "processed\Google_trend_processed\EU_bing.dta",replace
 
tab country

tab date_long 
 
 
 
/// maps in no_EU 
 
global no_EU "Albania Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"


 foreach x of global no_EU {		
		

import delimited "data/Google_trend_data/Euro_noEU/`x'/bing/search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}


destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "bing"


gen EU=0
gen Euro_NoEU=1
gen other=0


save "processed\Google_trend_processed\trend_bing_`x'.dta",replace

 }
 
 
global no_EU_1 " Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"

use "processed\Google_trend_processed\trend_bing_Albania.dta", clear


qui foreach x of global no_EU_1 {
	
append using "processed/Google_trend_processed/trend_bing_`x'.dta", force

}


save "processed\Google_trend_processed\no_EU_bing.dta",replace
 
tab country

tab date_long 
 
 
//// maps in other (non Euro countries) 
 
 
 

global other "Australia Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

 
 foreach x of global other {		
		

import delimited "data/Google_trend_data/other/`x'/bing/search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "bing"


gen EU=0
gen Euro_NoEU=0
gen other=1

save "processed\Google_trend_processed\trend_bing_`x'.dta",replace

 }
 


global other_1 " Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

use "processed\Google_trend_processed\trend_bing_Australia.dta", clear


qui foreach x of global other_1 {
	
append using "processed/Google_trend_processed/trend_bing_`x'.dta", force

}


save "processed\Google_trend_processed\other_bing.dta",replace
 
tab country

tab date_long  


append using "processed\Google_trend_processed\EU_bing.dta"


append using "processed\Google_trend_processed\no_EU_bing.dta"


sort country date_long

save "processed\Google_trend_processed\all_bing.dta",replace


tab country

tab date_long 




////////////////////////////////////////////////////////////////////////////////
/////////////////////////// BING MAPS //////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////		

global EU "Austria Belgium Bulgaria Croatia Cyprus Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"


/// maps in EU

 foreach x of global EU {		
		

import delimited "data/Google_trend_data/EU/`x'/bing_maps/search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends

capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

drop if date_long > 23724 //// data until 8 dec 2024

gen country = "`x'"

gen search_type = "google search" 
gen query = "bing maps"


gen EU=1
gen Euro_NoEU=0
gen other=0


save "processed\Google_trend_processed\trend_bing_maps_`x'.dta",replace

 }

 


global EU_1 "Belgium Bulgaria Croatia Cyprus Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"

use "processed\Google_trend_processed\trend_bing_maps_Austria.dta", clear


qui foreach x of global EU_1 {
	
append using "processed/Google_trend_processed/trend_bing_maps_`x'.dta", force

}


save "processed\Google_trend_processed\EU_bing_maps.dta",replace
 
tab country

tab date_long 
 
 
 
/// maps in no_EU (no data for Alabania, Armenia, Azerbaijan, Macedonia)
 
global no_EU " Belarus Bosnia Georgia Iceland Norway Serbia Switzerland Turkey UK Ukraine"


 foreach x of global no_EU {		
		

import delimited "data/Google_trend_data/Euro_noEU/`x'/bing_maps/search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}


destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "bing maps"


gen EU=0
gen Euro_NoEU=1
gen other=0


save "processed\Google_trend_processed\trend_bing_maps_`x'.dta",replace

 }
 
 
global no_EU_1 " Bosnia Georgia Iceland Norway Serbia Switzerland Turkey UK Ukraine"

use "processed\Google_trend_processed\trend_bing_maps_Belarus.dta", clear


qui foreach x of global no_EU_1 {
	
append using "processed/Google_trend_processed/trend_bing_maps_`x'.dta", force

}


save "processed\Google_trend_processed\no_EU_bing_maps.dta",replace
 
tab country

tab date_long 
 
 
//// maps in other (non Euro countries) 
 
 
 

global other "Australia Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

 
 foreach x of global other {		
		

import delimited "data/Google_trend_data/other/`x'/bing_maps/search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "bing maps"


gen EU=0
gen Euro_NoEU=0
gen other=1

save "processed\Google_trend_processed\trend_bing_maps_`x'.dta",replace

 }
 


global other_1 " Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

use "processed\Google_trend_processed\trend_bing_maps_Australia.dta", clear


qui foreach x of global other_1 {
	
append using "processed/Google_trend_processed/trend_bing_maps_`x'.dta", force

}


save "processed\Google_trend_processed\other_bing_maps.dta",replace
 
tab country

tab date_long  


append using "processed\Google_trend_processed\EU_bing_maps.dta"


append using "processed\Google_trend_processed\no_EU_bing_maps.dta"


sort country date_long

save "processed\Google_trend_processed\all_bing_maps.dta",replace


tab country

tab date_long







////////////////////////////////////////////////////////////////////////////////
/////////////////////////// APPLE MAPS //////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////		

global EU "Austria Belgium Bulgaria Croatia Cyprus Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"


/// maps in EU

 foreach x of global EU {		
		

import delimited "data/Google_trend_data/EU/`x'/apple_maps/search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends

capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "apple maps"


gen EU=1
gen Euro_NoEU=0
gen other=0


save "processed\Google_trend_processed\trend_apple_maps_`x'.dta",replace

 }

 


global EU_1 "Belgium Bulgaria Croatia Cyprus Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"

use "processed\Google_trend_processed\trend_apple_maps_Austria.dta", clear


qui foreach x of global EU_1 {
	
append using "processed/Google_trend_processed/trend_apple_maps_`x'.dta", force

}


save "processed\Google_trend_processed\EU_apple_maps.dta",replace
 
tab country

tab date_long 
 
 
 
/// maps in no_EU (no data for Macedonia)
 
global no_EU " Albania Armenia Azerbaijan Belarus Bosnia Georgia Iceland Norway Serbia Switzerland Turkey UK Ukraine"


 foreach x of global no_EU {		
		

import delimited "data/Google_trend_data/Euro_noEU/`x'/apple_maps/search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}


destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "apple maps"


gen EU=0
gen Euro_NoEU=1
gen other=0


save "processed\Google_trend_processed\trend_apple_maps_`x'.dta",replace

 }
 
 
global no_EU_1 " Armenia Azerbaijan Bosnia Georgia Iceland Norway Serbia Switzerland Turkey UK Ukraine"

use "processed\Google_trend_processed\trend_apple_maps_Albania.dta", clear


qui foreach x of global no_EU_1 {
	
append using "processed/Google_trend_processed/trend_apple_maps_`x'.dta", force

}


save "processed\Google_trend_processed\no_EU_apple_maps.dta",replace
 
tab country

tab date_long 
 
 
//// maps in other (non Euro countries) 
 
 
 

global other "Australia Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

 
 foreach x of global other {		
		

import delimited "data/Google_trend_data/other/`x'/apple_maps/search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "apple maps"


gen EU=0
gen Euro_NoEU=0
gen other=1

save "processed\Google_trend_processed\trend_apple_maps_`x'.dta",replace

 }
 


global other_1 " Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

use "processed\Google_trend_processed\trend_apple_maps_Australia.dta", clear


qui foreach x of global other_1 {
	
append using "processed/Google_trend_processed/trend_apple_maps_`x'.dta", force

}


save "processed\Google_trend_processed\other_apple_maps.dta",replace
 
tab country

tab date_long  


append using "processed\Google_trend_processed\EU_apple_maps.dta"


append using "processed\Google_trend_processed\no_EU_apple_maps.dta"


sort country date_long

save "processed\Google_trend_processed\all_apple_maps.dta",replace


tab country

tab date_long


////////////////////////////////////////////////////////////////////////////////
/////////////////////////// MAPPY ///////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////		

global EU "Austria Belgium Bulgaria Croatia Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"


/// maps in EU (no data for Cyprus, Malta)

 foreach x of global EU {		
		

import delimited "data/Google_trend_data/EU/`x'/mappy/mappy.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends

capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "mappy"


gen EU=1
gen Euro_NoEU=0
gen other=0


save "processed\Google_trend_processed\trend_mappy_`x'.dta",replace

 }

 


global EU_1 "Belgium Bulgaria Croatia Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"

use "processed\Google_trend_processed\trend_mappy_Austria.dta", clear


qui foreach x of global EU_1 {
	
append using "processed/Google_trend_processed/trend_mappy_`x'.dta", force

}


save "processed\Google_trend_processed\EU_mappy.dta",replace
 
tab country

tab date_long 
 
 
 
/// maps in no_EU (no data for Albania, Azerbaijan, Bosnia, Georgia, Iceland, Ukraine)
 
global no_EU " Armenia Belarus Macedonia Norway Serbia Switzerland Turkey UK"


 foreach x of global no_EU {		
		

import delimited "data/Google_trend_data/Euro_noEU/`x'/mappy/mappy.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}


destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "mappy"


gen EU=0
gen Euro_NoEU=1
gen other=0


save "processed\Google_trend_processed\trend_mappy_`x'.dta",replace

 }
 
 
global no_EU_1 " Belarus Macedonia Norway Serbia Switzerland Turkey UK"

use "processed\Google_trend_processed\trend_mappy_Armenia.dta", clear


qui foreach x of global no_EU_1 {
	
append using "processed/Google_trend_processed/trend_mappy_`x'.dta", force

}


save "processed\Google_trend_processed\no_EU_mappy.dta",replace
 
tab country

tab date_long 
 
 
//// maps in other (non Euro countries) 
 
 
 

global other "Australia Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

 
 foreach x of global other {		
		

import delimited "data/Google_trend_data/other/`x'/mappy/mappy.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "mappy"


gen EU=0
gen Euro_NoEU=0
gen other=1

save "processed\Google_trend_processed\trend_mappy_`x'.dta",replace

 }
 


global other_1 " Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

use "processed\Google_trend_processed\trend_mappy_Australia.dta", clear


qui foreach x of global other_1 {
	
append using "processed/Google_trend_processed/trend_mappy_`x'.dta", force

}


save "processed\Google_trend_processed\other_mappy.dta",replace
 
tab country

tab date_long  


append using "processed\Google_trend_processed\EU_mappy.dta"


append using "processed\Google_trend_processed\no_EU_mappy.dta"


sort country date_long

save "processed\Google_trend_processed\all_mappy.dta",replace


tab country

tab date_long 





////////////////////////////////////////////////////////////////////////////////
/////////////////////////// OPENSTREETMAP //////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////		

global EU "Austria Belgium Bulgaria Croatia Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"


/// maps in EU (no data for Cyprus, Malta)

 foreach x of global EU {		
		

import delimited "data/Google_trend_data/EU/`x'/openstreetmap/openstreetmap.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends
rename v3 volume_search

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

drop if date_long > 23724 //// data until 8 dec 2024

gen country = "`x'"

gen search_type = "google search" 
gen query = "openstreetmap"


gen EU=1
gen Euro_NoEU=0
gen other=0


save "processed\Google_trend_processed\trend_openstreetmap_`x'.dta",replace

 }

 


global EU_1 "Belgium Bulgaria Croatia Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"

use "processed\Google_trend_processed\trend_openstreetmap_Austria.dta", clear


qui foreach x of global EU_1 {
	
append using "processed/Google_trend_processed/trend_openstreetmap_`x'.dta", force

}


save "processed\Google_trend_processed\EU_openstreetmap.dta",replace
 
tab country

tab date_long 
 
 
 
/// maps in no_EU 
 
global no_EU "Albania Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"


 foreach x of global no_EU {		
		

import delimited "data/Google_trend_data/Euro_noEU/`x'/openstreetmap/openstreetmap.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}


destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

drop if date_long > 23724 //// data until 8 dec 2024

gen country = "`x'"

gen search_type = "google search" 
gen query = "openstreetmap"


gen EU=0
gen Euro_NoEU=1
gen other=0


save "processed\Google_trend_processed\trend_openstreetmap_`x'.dta",replace

 }
 
 
global no_EU_1 " Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"

use "processed\Google_trend_processed\trend_openstreetmap_Albania.dta", clear


qui foreach x of global no_EU_1 {
	
append using "processed/Google_trend_processed/trend_openstreetmap_`x'.dta", force

}


save "processed\Google_trend_processed\no_EU_openstreetmap.dta",replace
 
tab country

tab date_long 
 
 
//// maps in other (non Euro countries) 
 
 
 

global other "Australia Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

 
 foreach x of global other {		
		

import delimited "data/Google_trend_data/other/`x'/openstreetmap/openstreetmap.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "openstreetmap"


gen EU=0
gen Euro_NoEU=0
gen other=1

save "processed\Google_trend_processed\trend_openstreetmap_`x'.dta",replace

 }
 


global other_1 " Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

use "processed\Google_trend_processed\trend_openstreetmap_Australia.dta", clear


qui foreach x of global other_1 {
	
append using "processed/Google_trend_processed/trend_openstreetmap_`x'.dta", force

}


save "processed\Google_trend_processed\other_openstreetmap.dta",replace
 
tab country

tab date_long  


append using "processed\Google_trend_processed\EU_openstreetmap.dta"


append using "processed\Google_trend_processed\no_EU_openstreetmap.dta"


sort country date_long

save "processed\Google_trend_processed\all_openstreetmap.dta",replace


tab country

tab date_long 



////////////////////////////////////////////////////////////////////////////////
/////////////////////////// RESTAURANT /////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////		

global EU "Austria Belgium Bulgaria Croatia Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"


/// maps in EU (no data for Cyprus, Malta)

 foreach x of global EU {		
		

import delimited "data/Google_trend_data/EU/`x'/restaurant/restaurant.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends
rename v3 volume_search

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "restaurant"


gen EU=1
gen Euro_NoEU=0
gen other=0


save "processed\Google_trend_processed\trend_restaurant_`x'.dta",replace

 }

 


global EU_1 "Belgium Bulgaria Croatia Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"

use "processed\Google_trend_processed\trend_restaurant_Austria.dta", clear


qui foreach x of global EU_1 {
	
append using "processed/Google_trend_processed/trend_restaurant_`x'.dta", force

}


save "processed\Google_trend_processed\EU_restaurant.dta",replace
 
tab country

tab date_long 
 
 
 
/// maps in no_EU (no data for Macedonia)
 
global no_EU "Albania Armenia Azerbaijan Belarus Bosnia Georgia Iceland Norway Serbia Switzerland Turkey UK Ukraine"


 foreach x of global no_EU {		
		

import delimited "data/Google_trend_data/Euro_noEU/`x'/restaurant/restaurant.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}


destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

drop if date_long > 23724 //// data until 8 dec 2024

gen country = "`x'"

gen search_type = "google search" 
gen query = "restaurant"


gen EU=0
gen Euro_NoEU=1
gen other=0


save "processed\Google_trend_processed\trend_restaurant_`x'.dta",replace

 }
 
 
global no_EU_1 " Armenia Azerbaijan Belarus Bosnia Georgia Iceland Norway Serbia Switzerland Turkey UK Ukraine"

use "processed\Google_trend_processed\trend_restaurant_Albania.dta", clear


qui foreach x of global no_EU_1 {
	
append using "processed/Google_trend_processed/trend_restaurant_`x'.dta", force

}


save "processed\Google_trend_processed\no_EU_restaurant.dta",replace
 
tab country

tab date_long 
 
 
//// maps in other (non Euro countries) 
 
 
 

global other "Australia Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

 
 foreach x of global other {		
		

import delimited "data/Google_trend_data/other/`x'/restaurant/restaurant.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "restaurant"


gen EU=0
gen Euro_NoEU=0
gen other=1

save "processed\Google_trend_processed\trend_restaurant_`x'.dta",replace

 }
 


global other_1 " Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

use "processed\Google_trend_processed\trend_restaurant_Australia.dta", clear


qui foreach x of global other_1 {
	
append using "processed/Google_trend_processed/trend_restaurant_`x'.dta", force

}


save "processed\Google_trend_processed\other_restaurant.dta",replace
 
tab country

tab date_long  


append using "processed\Google_trend_processed\EU_restaurant.dta"


append using "processed\Google_trend_processed\no_EU_restaurant.dta"


sort country date_long

save "processed\Google_trend_processed\all_restaurant.dta",replace


tab country

tab date_long 


////////////////////////////////////////////////////////////////////////////////
/////////////////////////// SHOPPING ///////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////		

global EU "Austria Belgium Bulgaria Croatia Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"


/// maps in EU (no data for Cyprus, Malta)

 foreach x of global EU {		
		

import delimited "data/Google_trend_data/EU/`x'/shopping/shopping.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends
rename v3 volume_search

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "shopping"


gen EU=1
gen Euro_NoEU=0
gen other=0


save "processed\Google_trend_processed\trend_shopping_`x'.dta",replace

 }

 


global EU_1 "Belgium Bulgaria Croatia Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"

use "processed\Google_trend_processed\trend_shopping_Austria.dta", clear


qui foreach x of global EU_1 {
	
append using "processed/Google_trend_processed/trend_shopping_`x'.dta", force

}


save "processed\Google_trend_processed\EU_shopping.dta",replace
 
tab country

tab date_long 
 
 
 
/// maps in no_EU (no data for Macedonia)
 
global no_EU "Albania Armenia Azerbaijan Belarus Bosnia Georgia Iceland Norway Serbia Switzerland Turkey UK Ukraine"


 foreach x of global no_EU {		
		

import delimited "data/Google_trend_data/Euro_noEU/`x'/shopping/shopping.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}


destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

drop if date_long > 23724 //// data until 8 dec 2024

gen country = "`x'"

gen search_type = "google search" 
gen query = "shopping"


gen EU=0
gen Euro_NoEU=1
gen other=0


save "processed\Google_trend_processed\trend_shopping_`x'.dta",replace

 }
 
 
global no_EU_1 " Armenia Azerbaijan Belarus Bosnia Georgia Iceland Norway Serbia Switzerland Turkey UK Ukraine"

use "processed\Google_trend_processed\trend_shopping_Albania.dta", clear


qui foreach x of global no_EU_1 {
	
append using "processed/Google_trend_processed/trend_shopping_`x'.dta", force

}


save "processed\Google_trend_processed\no_EU_shopping.dta",replace
 
tab country

tab date_long 
 
 
//// maps in other (non Euro countries) 
 
 
 

global other "Australia Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

 
 foreach x of global other {		
		

import delimited "data/Google_trend_data/other/`x'/shopping/shopping.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "shopping"


gen EU=0
gen Euro_NoEU=0
gen other=1

save "processed\Google_trend_processed\trend_shopping_`x'.dta",replace

 }
 


global other_1 " Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

use "processed\Google_trend_processed\trend_shopping_Australia.dta", clear


qui foreach x of global other_1 {
	
append using "processed/Google_trend_processed/trend_shopping_`x'.dta", force

}


save "processed\Google_trend_processed\other_shopping.dta",replace
 
tab country

tab date_long  


append using "processed\Google_trend_processed\EU_shopping.dta"


append using "processed\Google_trend_processed\no_EU_shopping.dta"


sort country date_long

save "processed\Google_trend_processed\all_shopping.dta",replace


tab country

tab date_long 




////////////////////////////////////////////////////////////////////////////////
/////////////////////////// SUPERMARKET ////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////		

global EU "Austria Belgium Bulgaria Croatia Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"


/// maps in EU (no data for Cyprus, Malta)

 foreach x of global EU {		
		

import delimited "data/Google_trend_data/EU/`x'/supermarket/supermarket.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends
rename v3 volume_search

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "supermarket"


gen EU=1
gen Euro_NoEU=0
gen other=0


save "processed\Google_trend_processed\trend_supermarket_`x'.dta",replace

 }

 


global EU_1 "Belgium Bulgaria Croatia Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"

use "processed\Google_trend_processed\trend_supermarket_Austria.dta", clear


qui foreach x of global EU_1 {
	
append using "processed/Google_trend_processed/trend_supermarket_`x'.dta", force

}


save "processed\Google_trend_processed\EU_supermarket.dta",replace
 
tab country

tab date_long 
 
 
 
/// maps in no_EU (no data for Macedonia)
 
global no_EU "Albania Armenia Azerbaijan Belarus Bosnia Georgia Iceland Norway Serbia Switzerland Turkey UK Ukraine"


 foreach x of global no_EU {		
		

import delimited "data/Google_trend_data/Euro_noEU/`x'/supermarket/supermarket.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}


destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

drop if date_long > 23724 //// data until 8 dec 2024

gen country = "`x'"

gen search_type = "google search" 
gen query = "supermarket"


gen EU=0
gen Euro_NoEU=1
gen other=0


save "processed\Google_trend_processed\trend_supermarket_`x'.dta",replace

 }
 
 
global no_EU_1 " Armenia Azerbaijan Belarus Bosnia Georgia Iceland Norway Serbia Switzerland Turkey UK Ukraine"

use "processed\Google_trend_processed\trend_supermarket_Albania.dta", clear


qui foreach x of global no_EU_1 {
	
append using "processed/Google_trend_processed/trend_supermarket_`x'.dta", force

}


save "processed\Google_trend_processed\no_EU_supermarket.dta",replace
 
tab country

tab date_long 
 
 
//// maps in other (non Euro countries) 
 
 
 

global other "Australia Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

 
 foreach x of global other {		
		

import delimited "data/Google_trend_data/other/`x'/supermarket/supermarket.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


capture confirm variable v3
if _rc == 0 {
    rename v3 volume_search
} 
else {
    generate volume_search = .
}

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

gen country = "`x'"

gen search_type = "google search" 
gen query = "supermarket"


gen EU=0
gen Euro_NoEU=0
gen other=1

save "processed\Google_trend_processed\trend_supermarket_`x'.dta",replace

 }
 


global other_1 " Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

use "processed\Google_trend_processed\trend_supermarket_Australia.dta", clear


qui foreach x of global other_1 {
	
append using "processed/Google_trend_processed/trend_supermarket_`x'.dta", force

}


save "processed\Google_trend_processed\other_supermarket.dta",replace
 
tab country

tab date_long  


append using "processed\Google_trend_processed\EU_supermarket.dta"


append using "processed\Google_trend_processed\no_EU_supermarket.dta"


sort country date_long

save "processed\Google_trend_processed\all_supermarket.dta",replace


tab country

tab date_long 



////////////////////////////////////////////////////////////////////////////////
//////////////////////// append all ////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

append using "processed\Google_trend_processed\all_shopping.dta"

append using "processed\Google_trend_processed\all_restaurant.dta"

append using "processed\Google_trend_processed\all_openstreetmap.dta"

append using "processed\Google_trend_processed\all_mappy.dta"

append using "processed\Google_trend_processed\all_apple_maps.dta"

append using "processed\Google_trend_processed\all_bing.dta"

append using "processed\Google_trend_processed\all_bing_maps.dta"

append using "processed\Google_trend_processed\all_maps.dta"

append using "processed\Google_trend_processed\all_google_maps.dta"


sort query country date_long

encode query, gen(query_long)

encode country, gen (country_long)

tab country_long
ta query_long

drop query country

rename query_long query

rename country_long country 


sort query country date_long



drop search_type

save "processed\Google_trend_processed\all_trends.dta",replace




////////////////////////////////////////////////////////////////////////////////
//////////////// YOUTUBE SEARCH: MAPS //////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////		

global EU "Austria Belgium Bulgaria Croatia Cyprus Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"


/// maps in EU

 foreach x of global EU {		
		

import delimited "data/Google_trend_data/EU/`x'/maps/search_YT.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

drop if date_long > 23724 //// data until 8 dec 2024

gen country = "`x'"

gen search_type = "YT search" 
gen query = "maps"


gen EU=1
gen Euro_NoEU=0
gen other=0


save "processed\Google_trend_processed\trend_YTmaps_`x'.dta",replace

 }

 


global EU_1 "Belgium Bulgaria Croatia Cyprus Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"

use "processed\Google_trend_processed\trend_YTmaps_Austria.dta", clear


qui foreach x of global EU_1 {
	
append using "processed/Google_trend_processed/trend_YTmaps_`x'.dta", force

}


save "processed\Google_trend_processed\EU_YTmaps.dta",replace
 
tab country

tab date_long 
 
 
 
/// maps in no_EU 
 
global no_EU "Albania Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"


 foreach x of global no_EU {		
		

import delimited "data/Google_trend_data/Euro_noEU/`x'/maps/search_YT.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends




destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

drop if date_long > 23724 //// data until 8 dec 2024

gen country = "`x'"

gen search_type = "YT search" 
gen query = "maps"


gen EU=0
gen Euro_NoEU=1
gen other=0


save "processed\Google_trend_processed\trend_YTmaps_`x'.dta",replace

 }
 
 
global no_EU_1 " Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"

use "processed\Google_trend_processed\trend_YTmaps_Albania.dta", clear


qui foreach x of global no_EU_1 {
	
append using "processed/Google_trend_processed/trend_YTmaps_`x'.dta", force

}


save "processed\Google_trend_processed\no_EU_YTmaps.dta",replace
 
tab country

tab date_long 
 
 
//// maps in other (non Euro countries) 
 
 
 

global other "Australia Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

 
 foreach x of global other {		
		

import delimited "data/Google_trend_data/other/`x'/maps/search_YT.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

drop if date_long > 23724 //// data until 8 dec 2024

gen country = "`x'"

gen search_type = "YT search" 
gen query = "maps"


gen EU=0
gen Euro_NoEU=0
gen other=1

save "processed\Google_trend_processed\trend_YTmaps_`x'.dta",replace

 }
 


global other_1 " Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

use "processed\Google_trend_processed\trend_YTmaps_Australia.dta", clear


qui foreach x of global other_1 {
	
append using "processed/Google_trend_processed/trend_YTmaps_`x'.dta", force

}


save "processed\Google_trend_processed\other_YTmaps.dta",replace
 
tab country

tab date_long  


append using "processed\Google_trend_processed\EU_YTmaps.dta"


append using "processed\Google_trend_processed\no_EU_YTmaps.dta"


sort country date_long

save "processed\Google_trend_processed\all_YTmaps.dta",replace


tab country

tab date_long 




////////////////////////////////////////////////////////////////////////////////
/////////////////////////// GOOGLE MAPS ////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////		

global EU "Austria Belgium Bulgaria Croatia Cyprus Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"


/// maps in EU

 foreach x of global EU {		
		

import delimited "data/Google_trend_data/EU/`x'/google_maps/YT_search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends

destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

drop if date_long > 23724 //// data until 8 dec 2024

gen country = "`x'"

gen search_type = "YT search" 
gen query = "google maps"


gen EU=1
gen Euro_NoEU=0
gen other=0


save "processed\Google_trend_processed\trend_YTgoogle_maps_`x'.dta",replace

 }

 


global EU_1 "Belgium Bulgaria Croatia Cyprus Czechia Denmark Estonia Finland France Germany Greece Hungary Ireland Italy Latvia Lithuania Luxembourg Malta Netherlands Poland Portugal Romania Slovakia Slovenia Spain Sweden"

use "processed\Google_trend_processed\trend_YTgoogle_maps_Austria.dta", clear


qui foreach x of global EU_1 {
	
append using "processed/Google_trend_processed/trend_YTgoogle_maps_`x'.dta", force

}


save "processed\Google_trend_processed\EU_YTgoogle_maps.dta",replace
 
tab country

tab date_long 
 
 
 
/// maps in no_EU 
 
global no_EU "Albania Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"


 foreach x of global no_EU {		
		

import delimited "data/Google_trend_data/Euro_noEU/`x'/google_maps/YT_search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends



destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

drop if date_long > 23724 //// data until 8 dec 2024

gen country = "`x'"

gen search_type = "YT search" 
gen query = "google maps"


gen EU=0
gen Euro_NoEU=1
gen other=0


save "processed\Google_trend_processed\trend_YTgoogle_maps_`x'.dta",replace

 }
 
 
global no_EU_1 " Armenia Azerbaijan Belarus Bosnia Georgia Iceland Macedonia Norway Serbia Switzerland Turkey UK Ukraine"

use "processed\Google_trend_processed\trend_YTgoogle_maps_Albania.dta", clear


qui foreach x of global no_EU_1 {
	
append using "processed/Google_trend_processed/trend_YTgoogle_maps_`x'.dta", force

}


save "processed\Google_trend_processed\no_EU_YTgoogle_maps.dta",replace
 
tab country

tab date_long 
 
 
//// maps in other (non Euro countries) 
 
 
 

global other "Australia Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

 
 foreach x of global other {		
		

import delimited "data/Google_trend_data/other/`x'/google_maps/YT_search.csv",  clear 

drop in 1/6		

rename v1 date
rename v2 trends


destring, replace

generate date_long = date(date, "YMD")
format date_long %td

drop date 


drop if date_long < 22647 //// data from 2022

drop if date_long > 23724 //// data until 8 dec 2024

gen country = "`x'"

gen search_type = "YT search" 
gen query = "google maps"


gen EU=0
gen Euro_NoEU=0
gen other=1

save "processed\Google_trend_processed\trend_YTgoogle_maps_`x'.dta",replace

 }
 


global other_1 " Brazil Canada Chile Colombia Costarica India Israel Japan Mexico NZ SA SK US"

use "processed\Google_trend_processed\trend_YTgoogle_maps_Australia.dta", clear


qui foreach x of global other_1 {
	
append using "processed/Google_trend_processed/trend_YTgoogle_maps_`x'.dta", force

}


save "processed\Google_trend_processed\other_YTgoogle_maps.dta",replace
 
tab country

tab date_long  


append using "processed\Google_trend_processed\EU_YTgoogle_maps.dta"


append using "processed\Google_trend_processed\no_EU_YTgoogle_maps.dta"


sort country date_long

save "processed\Google_trend_processed\all_YTgoogle_maps.dta",replace


tab country

tab date_long 


append using "processed\Google_trend_processed\all_YTmaps.dta"



sort query country date_long

encode query, gen(query_long)

encode country, gen (country_long)

tab country_long
ta query_long

drop query country

rename query_long query

rename country_long country 


sort query country date_long


drop search_type

save "processed\Google_trend_processed\all_YT.dta",replace

