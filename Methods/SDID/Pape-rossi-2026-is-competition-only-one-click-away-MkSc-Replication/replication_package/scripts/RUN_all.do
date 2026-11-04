****************************************************
* Replication Package - Is Competition Only One Click Away? The Digital Markets Act Impact on Google Maps
* Author:  Louis-Daniel Pape and Michelangelo Rossi
* Date: November 2025
****************************************************
 
version 17.0
clear all

set more off, permanently
set maxvar 30000 

set seed 123


cd "$\MKSC-2025-0159_replication_package\replication_package"


do "scripts\install_commands.do"


set scheme plotplainblind, permanently


do "scripts/RUN_cleaning.do"


do "scripts/RUN_descriptive.do"


do "scripts/RUN_DID_search_volumes.do"


do "scripts/RUN_DID_traffic.do"


