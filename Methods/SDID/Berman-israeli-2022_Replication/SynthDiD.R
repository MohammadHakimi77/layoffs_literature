################################################################################################
###########################  The Value of Descriptive Analytics:  ############################## 
###########################    Evidence from Online Retailers     ##############################
###########################    by Ron Berman and Ayelet Israei    ##############################
###########################        Marketing Science, 2022        ##############################
################################################################################################
# This R file runs the analysis for the main results in the SynthDiD section of the  paper.    #
# The file uses a limited data file including randomly selected 5% of the retailer-channels,   #
# so results differ from those reported in the paper.                                          #
###############################################################################################
rm(list=ls())
library(data.table)
source("SynthDiD-fun.R")

data=fread("data_file_for_replication_small.csv")

set.seed(1)
lags=6
leads=5
target_leads=5

cohorts = 7:18 ### Jan 2016 to June 2017

timevar = "month_id"
idvar = "company_source"
joinvar = "month_join_id"
treatvar="m_after"
yvar="m_log_rev_usd"
# Main analysis, as in Columns (3) and (4) of Table 5 in the paper
estNplot(data=data, placebo=F, pooled=F, months=cohorts, lags=lags, leads=leads, treatvar=treatvar, timevar=timevar, idvar=idvar, yvar=yvar, joinvar=joinvar, prefix="replication_")
