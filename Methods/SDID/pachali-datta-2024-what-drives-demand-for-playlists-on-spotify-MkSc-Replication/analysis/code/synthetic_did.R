# Install packages
devtools::install_github("synth-inference/synthdid@b839f2cc1685c8fddcf274b882f82e2f6eab3894")

# Load packages
library(synthdid)
library(data.table)
library(tidyverse)
library(parallel)

# Prep_data for main spec

options(echo=TRUE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)
print(args)

cutoff_pre_post_window = 15
ncpus = 10 

if (length(args)<1) {
  # run this if no arguments are given
  samplesize = 500 # set to NA for all control units; otherwise to an integer (e.g., 500, to randomly select 500 control units)
  nrepl= 2 # number of replication for computation of SEs
  estim = 'promo' # focal dataset
  dv='logfollowers' # variable
  } else {
  samplesize = as.numeric(args[1])
  nrepl = as.numeric(args[2])
  estim = as.character(args[3])
  dv = as.character(args[4])
}

# set defaults if not set via command line
if (is.na(estim)) estim='promo'
if (is.na(dv)) dv='logfollowers'

# assert code is just run for either promo (or ML), and not both (with variation in input data)
stopifnot(!grepl(',', estim))

cat(paste0('Estimating w/ samplesize = ', samplesize, ' and nrepl = ', nrepl, ' (', dv, ')...\n'))

# input files
load(paste0("../output/estpanel_sdid_minwindow_", cutoff_pre_post_window,".RData"))

# Start up cluster
cl <- makePSOCKcluster(ncpus)
void<-clusterEvalQ(cl, library(data.table))
void<-clusterEvalQ(cl, library(haven))
void<-clusterEvalQ(cl, library(synthdid))
void<-clusterEvalQ(cl, library(abind))
void<-clusterEvalQ(cl, library(tidyverse))


# ============================
# Prepare data for promotions
# ============================

estpanel_promo = rbindlist(list(treated_panel_promo[, treated_unit:=1], donors_final[never_treated_promo==T][, treated_unit:=0]),fill=T)
setnames(estpanel_promo, 'first_observed_promo_date', 'treatment_date')
estpanel_promo[, treatment_indicator := as.numeric(date >= treatment_date)]
estpanel_promo[is.na(treatment_indicator), treatment_indicator:=0] 

unique(estpanel_promo[treatment_indicator==1,treatment_date])
uniqueN(estpanel_promo[treatment_indicator==1,treatment_date])
uniqueN(estpanel_promo[treatment_indicator==1,id])

# define for no "this is" playlists
estpanel_promo[, incl_nothisis:=T]
estpanel_promo[treated_unit==1&grepl('^This is', name, ignore.case=T), incl_nothisis:=F]
uniqueN(estpanel_promo[treated_unit==1&incl_nothisis==T]$id)

# function to build placebo panels

build_placebo <- function(estpanel_orig, nevertreat_indic='never_treated_promo', seed= 1234) {
  # define panel for placebo treatments
  set.seed(seed)
  nplacebos=uniqueN(estpanel_orig[treatment_indicator==1,id])
  placebodays=estpanel_orig[treatment_indicator==1,list(N=uniqueN(id)),by=c('treatment_date')]
  
  # draw randomly treated playlists, and ensure we have sufficient data
  already_used_ids = c()
  tmp=rbindlist(lapply(split(placebodays, placebodays$treatment_date), function(.d) {
    tmp = donors_final[get(nevertreat_indic)==T&date>=.d$treatment_date-15&date<=.d$treatment_date+15, list(nconsec=uniqueN(qualifying_stretch_id)),by=c('id')][nconsec==1]
    id_treated = sample(setdiff(tmp$id, already_used_ids), .d$N)
    
    already_used_ids<<-c(already_used_ids, id_treated)
    return(rbindlist(lapply(id_treated, function(id) {
      data.table(id=id,
                 date=seq(from=as.Date(.d$treatment_date)-15,
                          to=as.Date(.d$treatment_date)+15,by='1 day'),
                 treatment_date=.d$treatment_date)
    })))}))
  stopifnot(uniqueN(tmp$id)==nplacebos)
  tmp=merge(tmp, donors_final[never_treated_promo==T], by=c('id','date'),all.x=T,all.y=F)
  
  estpanel_placebo = rbindlist(list(tmp[,treated_unit:=1], donors_final[get(nevertreat_indic)==T][!id%in%tmp$id][, treated_unit:=0]),fill=T)
  estpanel_placebo[, treatment_indicator := as.numeric(date >= treatment_date)]
  estpanel_placebo[, reltime:=as.numeric(as.Date(date)-as.Date(treatment_date))]
  estpanel_placebo[is.na(treatment_indicator), treatment_indicator:=0] 
  return(estpanel_placebo)
}

estpanel_promo_placebo = build_placebo(estpanel_promo, 'never_treated_promo', seed= 1234)


# ================================================
# Prepare data for major label/superstar additions
# ================================================

estpanel_ml = rbindlist(list(treated_panel_ml[, treated_unit:=1], donors_final[never_treated_ml==T][, treated_unit:=0]),fill=T)
estpanel_ml[, treatment_indicator := as.numeric(date >= treatment_date)]
estpanel_ml[is.na(treatment_indicator), treatment_indicator:=0] 
estpanel_ml[treatment_indicator==1, list(obs=.N),by='id']
estpanel_ml[, mlartistpanel:=(treated_unit==1&(sony+warner+universal>0))|treated_unit==0]

unique(estpanel_ml[treatment_indicator==1,treatment_date])
uniqueN(estpanel_ml[treatment_indicator==1,treatment_date])
uniqueN(estpanel_ml[treatment_indicator==1,id])

unique(estpanel_ml[treatment_indicator==1&mlartistpanel==T,treatment_date])
uniqueN(estpanel_ml[treatment_indicator==1&mlartistpanel==T,treatment_date])
uniqueN(estpanel_ml[treatment_indicator==1&mlartistpanel==T,id])

# placebo panel
estpanel_ml_placebo = build_placebo(estpanel_ml, 'never_treated_ml', seed = 9876)


estimate_fkt <- function(estpanel) {
  last_period = max(estpanel$date)
  first_period = min(estpanel$date)
  
  estpanel[, list(.N),by=c('treatment_date')]
  
  treated_periods <- sort(unique(estpanel[treated_unit==1,treatment_date]))
  
  cat('Exporting data set to cluster...',fill=T)
  estpanel <<- estpanel
  clusterExport(cl, c('estpanel'))
  
  
  estimate_synthdid <- function(i, stats_only = F) {
    subbed <- estpanel[treatment_date == treated_periods[i]&treated_unit==1 | treated_unit==0]
  
    panel = subbed
  
    if (!is.data.frame(panel)) {
      stop("Unsupported input type `panel.`")
    }
    if (length(unique(panel$anypromo)) == 1) {
      stop("There is no variation in treatment status.")
    }
    if (!all(panel$anypromo %in% c(0, 1))) {
      stop("The treatment status should be in 0 or 1.")
    }
    
    ### create balanced panel by selecting appropriate donor units
    treated_panel = panel[treated_unit==1]
    uniqueN(treated_panel$id)
    # donor panel: pls from different categories than treated pls
    donor_panel = panel[treated_unit==0&!cat_id%in%unique(treated_panel$cat_id)] 
    uniqueN(donor_panel$id)
    # merge rel-time to donor panel by date
    setkey(treated_panel,date)
    setkey(donor_panel,date)
    donor_panel[treated_panel,reltime:=i.reltime]
    donor_panel = donor_panel[!is.na(reltime)]
    setorder(donor_panel,id,date)
    # select donors observable throughout
    summary=donor_panel[, list(nobs=.N),by=c('id')]
    useful_donors = unique(summary[nobs==uniqueN(treated_panel$reltime),id])
    
    #if (length(useful_donors)<=0) stop('Not enough donors')
    
    if (!is.na(samplesize)) {
      if (!samplesize==99999) {
        # set seed for user selection
        set.seed(1234)
        useful_donors=sample(useful_donors, min(length(useful_donors), samplesize))
      } else {
        useful_donors = useful_donors # use all donors instead
      }
    }
    
    donor_panel = donor_panel[id%in%useful_donors]
    
    # balanced? 
    nrow(donor_panel)==uniqueN(donor_panel$id)*uniqueN(treated_panel$reltime)
    panel_balanced = rbind(donor_panel,treated_panel)
      
    val <- as.vector(table(panel_balanced$id, panel_balanced$date))
    if (!all(val == 1)) {
      stop("Input `panel` must be a balanced panel: it must have an observation for every unit at every time.")
    }
    
    # return only statistics about sample size
    if (stats_only) {
      return(list(stats=data.frame(period=treated_periods[i],
                        nrows=nrow(panel_balanced),
               ndonor=uniqueN(donor_panel$id),
               ntreated=uniqueN(treated_panel$id)),
             ids=panel_balanced[, list(N=.N),by=c('treated_unit','id','date')][, period:=treated_periods[i]]))
    }
    
    setorder(panel_balanced,treated_unit,id,date)
    num.dates = uniqueN(panel_balanced[, date])
    num.units = uniqueN(panel_balanced[, id])
    Y = matrix(pull(panel_balanced, dv), num.units, num.dates, byrow = TRUE,
                dimnames = list(unique(panel_balanced[, id]), unique(panel_balanced[,date])))
    W = matrix(panel_balanced[, treatment_indicator], num.units, num.dates, byrow = TRUE,
                dimnames = list(unique(panel_balanced[, id]), unique(panel_balanced[,date])))
    w = apply(W, 1, any)
    # number of untreated periods in batch
    T0 = unname(which(apply(W, 2, any))[1] - 1) # -1 because we want the last period not-treated
    N0 = sum(!w)
    if (!(all(W[!w, ] == 0) && all(W[, 1:T0] == 0) && all(W[w,(T0 + 1):ncol(Y)] == 1))) {
      stop("The package cannot use this data. Treatment adoption is not simultaneous.")
    }
    
    tau_hat <- synthdid_estimate(Y, N0, T0)
      
    tau_se <- drop(sqrt(vcov(tau_hat, method = "placebo", replications = nrepl)))
  
    res = list(treatment_period=treated_periods[i],
               tau_hat = as.numeric(tau_hat),
               tau_hat_list = tau_hat,
               standard_error = tau_se,
               lower_95_CI = as.numeric(tau_hat) - (1.96 * as.numeric(tau_se)),
               upper_95_CI = as.numeric(tau_hat) + (1.96 * as.numeric(tau_se)),
               post_treat_days = nrow(panel_balanced[treatment_indicator==1, ]),
               current_treat = uniqueN(panel_balanced[treatment_indicator>0]$id),
               nreplications=nrepl,
               ndonors=uniqueN(donor_panel$id))
    
    print(paste0("completed batch ",i," out of ",length(treated_periods)))
    return(res)
  }
  
  cat('Computing sample size...',fill=T)
  samplesize_list=lapply(1:length(treated_periods), estimate_synthdid, stats_only=T)
  samplesize_overview=rbindlist(lapply(samplesize_list, function(x) x$stats))
  
  cat('Starting estimations...',fill=T)
  nrepl<<-nrepl
  estimate_synthdid<<-estimate_synthdid
  treated_periods<<-treated_periods
  samplesize<<-samplesize
  dv<<-dv
  
  clusterExport(cl,c('nrepl', 'estimate_synthdid', 'treated_periods', 'samplesize', 'dv'))
  
  results <- clusterApplyLB(cl, (1:length(treated_periods))[which(samplesize_overview$ndonor>0)], function(i) try(estimate_synthdid(i), silent=T))
  
  return(list(estimates=results, treated_periods=treated_periods, samplesize=samplesize_list))
}

print(estim)

if (grepl('^promo$',estim)) synthdid_promo = estimate_fkt(estpanel=estpanel_promo)
if (grepl('^promoremoveotherseasonal',estim)) synthdid_promoremoveotherseasonal = estimate_fkt(estpanel=estpanel_promo[(isotherseasonal==F&treated_unit==1) | treated_unit==0])
if (grepl('^ml$',estim)) synthdid_ml = estimate_fkt(estpanel=estpanel_ml[mlartistpanel==T])

# Function scans global environment for occurrence of regular expression (`regex`), 
# and saves all objects in `filename`.
save_by_regex <- function(regex, filename) {
  lscall = ls(envir=.GlobalEnv)
  stuff_to_save = grep(regex, lscall, value=T)
  if (length(stuff_to_save)>0) {
    cat('saving...\n')
    cat(paste0('(', paste0(stuff_to_save, collapse=', '), ')\n'))
    save(list=stuff_to_save , file = filename)
    cat('...done.\n') } else {
      cat('No objects to save. Verify regular expression.\n')
    }
}

path = paste0('../output/synthdid_results_matched_', samplesize, '_', nrepl, '_', estim, '_', dv, '.RData')

save_by_regex('^synthdid', path)
