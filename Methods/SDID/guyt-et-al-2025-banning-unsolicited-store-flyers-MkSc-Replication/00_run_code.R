library(MASS)
library(data.table)
library(fixest)
library(synthdid)
library(parallel)
library(foreach)
rm(list=ls())
gc()

set.seed(1)


### select here which tables to recreate
table_2 <- TRUE # descriptive statistics
table_6 <- TRUE # correlation (requires SynthDID estimates)
table_7 <- TRUE # SynthDID estimates
table_8 <- TRUE # Robustness Checks (requires SynthDID estimates)
table_9 <- TRUE # Subgroup Analysis
table_10 <- TRUE # Who opts in


source("01_gen_data.R") # this will call the file to generate the data
source("02_analysis.R") # this will call the file to analyze the data