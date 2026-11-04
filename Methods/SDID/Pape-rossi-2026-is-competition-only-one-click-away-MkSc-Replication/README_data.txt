README: List of variables - "Is Competition Only One Click Away? The Digital Markets Act Impact on Google Maps"
  
Authors: Louis-Daniel Pape and Michelangelo Rossi 


List of Variables present in the datasets used for the analysis


Dataset "processed\Google_trend_processed\all_trends.dta"

* trends: value of Google Trends (value from 0 to 100) for the query listed in the variable "query" for the week listed in the variable "date_long"

* volume_search: value of earch Volumes from Glimpse for the query listed in the variable "query" for the week listed in the variable "date_long" 

* date_long: week identifier 

* EU: dummy variable taking value 1 for EU countries 

* Euro_NoEU: dummy variable taking value 1 for European countries not in the EU 

* other: dummy variable taking value 1 for all othr non European Countries 

* query: query identifier 

* country: country identifier



Dataset "processed\Google_trend_processed\all_YT.dta"


* trends: value of Google Trends (value from 0 to 100) for the Youtube Search query listed in the variable "query" for the week listed in the variable "date_long"

* date_long: week identifier 

* EU: dummy variable taking value 1 for EU countries 

* Euro_NoEU: dummy variable taking value 1 for European countries not in the EU 

* other: dummy variable taking value 1 for all othr non European Countries 

* query: query identifier 

* country: country identifier




Dataset "processed\Google_trend_processed\all_semrush.dta"


* date: month identifier 
* month: calendar month identifier 
* year: year identifier 

* direct_google_maps: direct desktop traffic for Google Maps 
* referral_google_maps: referral desktop traffic for Google Maps  
* organicsearch_google_maps: organic search desktop traffic for Google Maps 

* bounce_google: bounce rate for Google 
* bounce_google_maps: bounce rate for Google Maps 
* bounce_bing_com_maps: bounce rate for Bing Maps 

* visit_mobile_google: online desktop visits for Google
* visit_mobile_google_maps: online desktop visits for Google Maps
* visit_mobile_bing_maps: online desktop visits for Bing Maps

* page_visit_google: average visited pages for Google 
* page_visit_google_maps: average visited pages  for Google Maps 
* page_visit_bing_com_maps: average visited pages  for Bing Maps

* visitor_google: online visitors for Google
* visitor_google_maps: online visitors for Google Maps  
* visitor_bing_maps: online visitors  for Bing Maps

* visit_duration_google: average visit duration for Google 
* visit_duration_google_maps: average visit duration for Google Maps 
* visit_duration_bing_com_maps: average visit duration for Bing Maps

* visit_google: online desktop visits (total traffic) for Google 
* visit_google_maps: online desktop visits (total traffic) for Google Maps 
* visit_bing_com_maps: online desktop visits (total traffic) for Bing Maps

* country_spec: exact query for the country 

* EU: dummy variable taking value 1 for EU countries 

* Euro_NoEU: dummy variable taking value 1 for European countries not in the EU 

* other: dummy variable taking value 1 for all othr non European Countries 

* query: query identifier 

* country: country identifier





Dataset "processed\Google_trend_processed\all_dir_semrush.dta"


* date: month identifier 
* month: calendar month identifier 
* year: year identifier 


* bounce_google_maps_dir: bounce rate for Google Maps (direction button)
* visit_google_maps_dir: online desktop visits (total traffic) for Google Maps (direction button)
* pages_google_maps_dir: average visited pages  for Google Maps  (direction button)
* visit_duration_google_maps_dir: average visit duration for Google Maps (direction button)


* EU: dummy variable taking value 1 for EU countries 

* Euro_NoEU: dummy variable taking value 1 for European countries not in the EU 

* other: dummy variable taking value 1 for all othr non European Countries 

* query: query identifier 

* country: country identifier


