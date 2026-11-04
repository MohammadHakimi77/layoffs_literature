# Build balanced data set for synthetic DiD analysis

# Remove objects in workspace
rm(list=ls())
gc() 

# Load packages
library(tidyverse)
library(data.table)

# Load panel data
full_panel <- fread('../output/paneldata.csv')
nointerpolations_panel <- full_panel[, c('id','date', 'followers', 'metadata_stretch_id', 'metadata_stretch_length', 'qualifying_stretch_id', 'qualifying_stretch_length', 'best_qualifying_stretch'),with=F]
nointerpolations_panel <- nointerpolations_panel[metadata_stretch_length>=100&qualifying_stretch_length>=28]

# Load playlist characteristics
playlists <- fread('../temp/playlists.csv')

# Load treatment events
treat_ml <- fread('../temp/treated_ml.csv')
treat_promo <- fread('../temp/treated_promo.csv')

# assemble list of controls
vars = c('followers', 'ntracks', 'nadded', 'ntracksotherpl', 'ml_curr', 'trackage_year','tracklength_sec',
         grep('^ac[_]', colnames(full_panel),value=T))

cutoff_pre_post_window =15

### build panel data set

### treatment pool for promos
treated_panel_promo = treat_promo[treated==T, list(date=seq(from=as.Date(first_observed_promo_date)-cutoff_pre_post_window,to=first_observed_promo_date+cutoff_pre_post_window,
                                                by=c('1 day')),
                                         reltime=seq(from=-cutoff_pre_post_window, to=cutoff_pre_post_window)),by=c('id', 'first_observed_promo_date', 'is2019', 'isotherseasonal', 'gets_added_window')]

treated_panel_ml = treat_ml[treated==T, list(date=seq(from=as.Date(treatment_date)-cutoff_pre_post_window,to=treatment_date+cutoff_pre_post_window,
                                                  by=c('1 day')),
                                             reltime=seq(from=-cutoff_pre_post_window, to=cutoff_pre_post_window)),by=c('id', 'treatment_date', 'treatment_id')]


setkey(nointerpolations_panel, id, date)
setkey(treated_panel_ml, id, date)
setkey(treated_panel_promo, id, date)

# add covariates
treated_panel_promo = merge(treated_panel_promo, full_panel[, c('id','date', vars[vars%in%colnames(full_panel)]),with=F],by=c('id','date'), all.x=T)
treated_panel_ml = merge(treated_panel_ml, full_panel[, c('id','date', vars[vars%in%colnames(full_panel)]),with=F],by=c('id','date'), all.x=T)

# Build corresponding donor panel
setorder(nointerpolations_panel, id, date)
donor_pool = nointerpolations_panel[qualifying_stretch_length>=(cutoff_pre_post_window*2+1)] ### weakest requirement on donor pool
uniqueN(donor_pool$id)

# add never treated indicators
setkey(donor_pool, id)
setkey(treat_promo, id)
setkey(treat_ml, id)
donor_pool[treat_promo[treated==F], never_treated_promo:=T]
donor_pool[treat_ml[treated==F], never_treated_ml:=T]

uniqueN(donor_pool[never_treated_promo==T]$id)
uniqueN(donor_pool[never_treated_ml==T]$id)


donors_final = donor_pool[never_treated_promo==T|never_treated_ml==T]

# add covariates
donors_final = merge(donors_final, full_panel[, c('id','date', vars[vars%in%colnames(full_panel)&!vars%in%colnames(donors_final)]),with=F],by=c('id','date'), all.x=T)
donors_final[, nobs:=.N,by=c('id', 'qualifying_stretch_id')]

donors_final[,logfollowers := log(1+followers)]
treated_panel_promo[,logfollowers := log(1+followers)]
treated_panel_ml[,logfollowers := log(1+followers)]

ihs = function(x) log(x+sqrt(x^2+1))

donors_final[,logfollowers_ihs := ihs(followers)]
treated_panel_promo[,logfollowers_ihs := ihs(followers)]
treated_panel_ml[,logfollowers_ihs := ihs(followers)]

donors_final[, logntracksotherpl:=log(1+ntracksotherpl)]
treated_panel_promo[, logntracksotherpl:=log(1+ntracksotherpl)]
treated_panel_ml[, logntracksotherpl:=log(1+ntracksotherpl)]

setkey(playlists,id)
setkey(donors_final,id)
setkey(treated_panel_promo,id)
setkey(treated_panel_ml,id)

donors_final[playlists,':=' (name=i.name,listeners_to_followers_ratio = i.listeners_to_followers_ratio,follower_percentile=i.follower_percentile)]
treated_panel_promo[playlists,':=' (name=i.name,listeners_to_followers_ratio = i.listeners_to_followers_ratio,follower_percentile=i.follower_percentile)]
treated_panel_ml[playlists,':=' (name=i.name,listeners_to_followers_ratio = i.listeners_to_followers_ratio,follower_percentile=i.follower_percentile)]


# merge categories
setkey(full_panel, id, date)
setkey(donors_final, id, date)
setkey(treated_panel_promo, id, date)
setkey(treated_panel_ml, id, date)

donors_final[full_panel, ':=' (cat_id=i.cat_id)]
treated_panel_promo[full_panel, ':=' (cat_id=i.cat_id)]
treated_panel_ml[full_panel, ':=' (cat_id=i.cat_id)]
donors_final[, date:=as.Date(date)]

# merge labels
ml_status = unique(treat_ml, by=c('treatment_id'))
setkey(ml_status, treatment_id)
setkey(treated_panel_ml, treatment_id)
treated_panel_ml[ml_status, ':=' (sony=i.sony, warner=i.warner, universal=i.universal, artist_name=i.artist_name)]

filename = paste0("../output/estpanel_sdid_minwindow_", cutoff_pre_post_window,".RData")

save(donors_final,treated_panel_promo, treated_panel_ml, file = filename)
