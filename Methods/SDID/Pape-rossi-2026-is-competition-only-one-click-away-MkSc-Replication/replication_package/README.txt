README: Data and Code Structure for "Is Competition Only One Click Away? The Digital Markets Act Impact on Google Maps"

Manuscript ID:  MKSC-2025-0159  

Authors: Louis-Daniel Pape and Michelangelo Rossi 

This README document delineates the organizational structure of data and code within the replication package accompanying our research paper. 
The package facilitates replication of all results, including tables and figures, as presented in the main text and online appendix.

Directory Structure

The replication package is organized into the following directories:


Data (Folder)

This folder contains the starting datasets (from Google Trends, Glimpse and SEMrush) used to build the analysis.


Processed (Folder)

This folder contains the intermediate datasets generated throughout the workflow.

The Stata code in RUN_cleaning.do (and related do-files it calls) takes the raw input data from the data folder and produces cleaned datasets stored here.

Finally, the Stata do-files RUN_Descriptive.do, RUN_DID_search_volumes.do, RUN_DID_traffic.do and  use the datasets in processed as input to produce all the tables and figures in the paper.


Results (Folder)

Contains all tables and figures from the main text and appendix, organized into tables and figures subfolders.


Scripts (Folder)

Contains Stata scripts:

- Stata scripts:
The master file, RUN_all.do, executes all Stata routines (after installing packages via install_commands.do). Running this file alone will replicate all tables and figures from the paper.




Replication Notes

To ensure full reproducibility, we provide all starting datasets in the data folder.

Running the Stata codes from scratch allows users to recreate all the final results.

The current directory is set up as: cd "$\MKSC-2025-0159_replication_package\replication_package"

The folder "MKSC-2025-0159_replication_package/replication_package/data/Semrush_data" contains four SEMrush snapshots that visually indicate the webpage controls used to trace and extract the relevant information for Austria.



Computation time:

Running all Stata code (RUN_all.do) takes about 15 minutes.


The README file labeled "README_dataset" catalogs all variables present in the main datasets used for the analysis and offers concise explanations for each.



Software Requirement

* Stata: SE 17
