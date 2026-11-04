This readme file pertains to BANNING UNSOLICITED STORE FLYERS: DOES HELPING THE ENVIRONMENT HURT RETAILING?

The replication code will generate the synthetic data required to run all the analysis performed in the main body of the paper.

The provided code is run in R and has been tested with R version 4.3.1. The following files are present in the replication package:

	00_run_code.r – Main script to initialize and run the entire pipeline.
	01_gen_data.r – Script for generating and preparing data for analysis.
	02_analysis.r – Script for analysis and generating tables


All code has been annotated.

Users aiming to replicate the full set of results can simply run 00_run_code.r
Users can select which Tables to produce by setting flags to TRUE/FALSE

Users aiming to alter the data structure and run the analysis will need to adjust these in 01_gen_data.r


Running 01_gen_data.r will create:
	dt_combined - a list of 5 cohorts with data.tables containing the data used for the analysis
	N_control / N_control_var / N_treated / N_treated_var - a list (of 5) containing the number of units for each cohort and variable
	table_10_data - the data used for the opt-in analysis as reported on in Table 10
	variables - a dataframe containing information on the variables used in the analysis (as reported on in Table 2)
	various setup parameters pertaining to the ratios (see Tables 5 and 9)

Running 02_analysis.r will run the analysis as reported on in the main paper.
	Importantly, this analysis may has been parallelized in order to not take too long. Jackknifing takes considerable time.
