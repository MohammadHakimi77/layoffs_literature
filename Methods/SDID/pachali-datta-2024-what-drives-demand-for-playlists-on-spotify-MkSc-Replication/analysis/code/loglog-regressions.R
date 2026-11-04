# Estimate two-way fixed effect model

# Remove objects in workspace
rm(list=ls())
gc() 

# Load packages
library(data.table)
library(fixest)
library(modelsummary)
library(ggplot2)

# Load data
filename = paste0("../output/paneldata.csv")
dt <- fread(filename)

nrow(dt)

promo_raw=fread('../temp/promotions.csv', key=c('playlist_id'))
playlists <- fread('../temp/playlists.csv')
setkey(playlists, playlist_id)
promo_raw[playlists, id:=i.id]

# lag dv
setorder(dt, id, date)
dt[,lagfollowers:= c(NA, followers[-.N]), by=c('id')]

stopifnot(all(dt[, list(N=.N),by=c('id')]$N==150))

table(dt[,list(any(any_promo)),by=c('id')]$V1)
setorder(dt, id, date)

# tag first superstar treat event per playlist
dt[, lhas_superstar:=c(NA,has_superstar[-.N]),by=c('id')]
dt[, switch:=has_superstar!=lhas_superstar & has_superstar==1]
dt[, switchcount:=cumsum(ifelse(is.na(switch),0,switch)),by=c('id')]

nrow(dt)
nrow(dt[switchcount<=1])/nrow(dt)

# define estimation data set
nointerpolations_panel <- dt[metadata_stretch_length>=100&qualifying_stretch_length>=28]
nrow(nointerpolations_panel[switchcount<=1])/nrow(nointerpolations_panel)
nrow(nointerpolations_panel)

########################
## Define main models ##
########################

# remove 2019 top playlists from estimation sample 
ids_2019 = unique(promo_raw[!is.na(id)&grepl('2019',sectionName)]$id)

# robustness check: removing other seasonal events
ids_otherseasonal = unique(promo_raw[!is.na(id)&grepl('exercise|wellness|holiday|award',sectionName)]$id)

nointerpolations_panel = nointerpolations_panel[!id%in%ids_2019]
nointerpolations_panel[, other_seasonal := id%in%ids_otherseasonal]

# define inverse hyperbolic sine transformation (as an alternative to taking log(x+1))
ihs = function(x) log(x+sqrt(x^2+1))

# rename log_ml_share: note that this already includes the weighted mean (by track popularity)
nointerpolations_panel[,log_ml_share_log1:=log(ml_curr*100+1)] 
nointerpolations_panel[,log_ml_share_ihs:=ihs((ml_curr*100))]

# compute competitor market share
nointerpolations_panel[, dv:=followers]
nointerpolations_panel[, marketshare_in_category := dv/sum(dv,na.rm=T), by = c('cat_id','date')]

set.seed(1234)
nointerpolations_panel[, rank_marketshare_in_category := frankv(marketshare_in_category, order=-1L, ties.method='random'), by = c('cat_id','date')]
nointerpolations_panel[, any_promo_compw := (sum(marketshare_in_category*any_promo)-marketshare_in_category*any_promo)/(sum(marketshare_in_category)-marketshare_in_category), by = c('cat_id','date')] 
nointerpolations_panel[, ml_curr_compw := (sum(marketshare_in_category*ml_curr*100)-marketshare_in_category*ml_curr*100)/(sum(marketshare_in_category)-marketshare_in_category), by = c('cat_id','date')] 
nointerpolations_panel[, has_superstar_compw := (sum(marketshare_in_category*has_superstar)-marketshare_in_category*has_superstar)/(sum(marketshare_in_category)-marketshare_in_category), by = c('cat_id','date')]

# collect playlists in rest category
categories <- fread('../temp/playlist-categories.csv')
category_ranks = categories[begin_init=='2020-03-30'][, list(followers=sum(playlist_followers,na.rm=T)),by=c('cat_id','category')]
setorderv(category_ranks, 'followers',order=-1L)
category_ranks[, ':=' (rank=1:.N,cumfollowers=cumsum(followers/1E6)/sum(followers/1E6))]
category_ranks[, niche:=cumfollowers>=.95]
category_ranks[, cat_id_with_rest:=cat_id]
stopifnot(!999999%in%category_ranks$cat_id)
category_ranks[niche==T, cat_id_with_rest := 999999]
setkey(category_ranks, cat_id)
setkey(nointerpolations_panel, cat_id)
nointerpolations_panel[category_ranks, cat_id_with_rest:=i.cat_id_with_rest]

uniqueN(nointerpolations_panel[!is.na(cat_id)&cat_id_with_rest!=999999]$cat_id_with_rest) # number of categories in estimation
unique(nointerpolations_panel[!is.na(cat_id)&cat_id_with_rest!=999999]$cat_id_with_rest)

# create top x competitor variables by category
for (i in 1:15) {
  print(i)
  # create variables that measure the xth competitor for playlist i in a category j.
  # the issue here is that we can't just take the xth's competitor easily, because we may
  # treat playlist i as its own competitor.
  # a solution is to match to the kth competitor, where k=x+1 if own rank <= i.
  catvar='cat_id_with_rest'
  nointerpolations_panel[, paste0('rankmatch_comp', i) := i, by = c(catvar,'date')]
  nointerpolations_panel[rank_marketshare_in_category<=i, paste0('rankmatch_comp', i) := i+1, by = c(catvar,'date')]
  nointerpolations_panel[, searchmatch := get(paste0('rankmatch_comp', i))]
  nointerpolations_panel[, matchvar := match(searchmatch, rank_marketshare_in_category), by = c(catvar,'date')] 
  
  nointerpolations_panel[, paste0('any_promo_comp', i) := any_promo[matchvar], by = c(catvar,'date')] 
  nointerpolations_panel[, paste0('ml_curr_comp', i) := ml_curr[matchvar]*100, by = c(catvar,'date')] 
  nointerpolations_panel[, paste0('has_superstar_comp', i) := has_superstar[matchvar], by = c(catvar,'date')] 
  
  nointerpolations_panel[, matchvar:=NULL]
  nointerpolations_panel[, searchmatch:=NULL]
  
}


### add playlist-month fixed effects
nointerpolations_panel[, month:=month(date)]
for (.month in month.name) {
  nointerpolations_panel[, (.month):=0]
  nointerpolations_panel[month.name[month]==.month, (.month):=1]
}

nointerpolations_panel[, id_month:=.GRP,by=c('id','month')]

### define recommendation intensity
rec_definition = c('recfully') # which recommendations are to be considered: one of c('recfully','recsemi','recartist')
nointerpolations_panel[, rec_intensity:=0]

for (.v in rec_definition) nointerpolations_panel[, rec_intensity:=rec_intensity+(get(paste0(.v,'_nadded'))/get(paste0(.v, '_nplaylists')))]
nointerpolations_panel[, rec_intensity:=rec_intensity/length(rec_definition)]

# by category
nointerpolations_panel[, rec_intensity_cat:=0]

for (.v in rec_definition) nointerpolations_panel[, rec_intensity_cat:=rec_intensity_cat+(get(paste0(.v,'_nadded_cat'))/get(paste0(.v, '_nplaylists_cat')))]
nointerpolations_panel[, rec_intensity_cat:=rec_intensity_cat/length(rec_definition)]
nointerpolations_panel[is.na(rec_intensity_cat), rec_intensity_cat:=0]

### OLS model without instruments
model_vars_exog = c("log(1 + rec_intensity_cat)","log_ml_share_log1", "log(playlist_duration_h+1)",
                   "log(wnplaylists_trackage_year+1)","wnplaylists_ac_danceability","wnplaylists_ac_energy","wnplaylists_ac_speechiness","wnplaylists_ac_acousticness","wnplaylists_ac_instrumentalness",
                   "wnplaylists_ac_liveness","wnplaylists_ac_valence","wnplaylists_ac_tempo","wnplaylists_ac_loudness",paste0("any_promo_comp", 1:15), paste0("has_superstar_comp", 1:15))

vars_endog = c("any_promo","has_superstar")

form_base_ols = paste("log(followers+1)", paste(c(vars_endog,model_vars_exog),collapse = "+"), sep = "~") #
form_fes_ols = as.formula(form_base_ols)

form_fes_ols_ihs = ihs(followers) ~ any_promo + has_superstar + ihs(rec_intensity_cat) + 
  log_ml_share_ihs + ihs(playlist_duration_h) + ihs(wnplaylists_trackage_year) + wnplaylists_ac_danceability + 
  wnplaylists_ac_energy + wnplaylists_ac_speechiness + wnplaylists_ac_acousticness + 
  wnplaylists_ac_instrumentalness + wnplaylists_ac_liveness + 
  wnplaylists_ac_valence + wnplaylists_ac_tempo + wnplaylists_ac_loudness + 
  any_promo_comp1 + any_promo_comp2 + any_promo_comp3 + any_promo_comp4 + 
  any_promo_comp5 + any_promo_comp6 + any_promo_comp7 + any_promo_comp8 + 
  any_promo_comp9 + any_promo_comp10 + any_promo_comp11 + any_promo_comp12 + 
  any_promo_comp13 + any_promo_comp14 + any_promo_comp15 + 
  has_superstar_comp1 + has_superstar_comp2 + has_superstar_comp3 + 
  has_superstar_comp4 + has_superstar_comp5 + has_superstar_comp6 + 
  has_superstar_comp7 + has_superstar_comp8 + has_superstar_comp9 + 
  has_superstar_comp10 + has_superstar_comp11 + has_superstar_comp12 + 
  has_superstar_comp13 + has_superstar_comp14 + has_superstar_comp15



### models: Note that the missings come from the missings in the IVs
models <- list(
  "OLS" = feols(form_fes_ols, data = nointerpolations_panel, panel.id = ~id + date, fixef = c('id','date'),vcov="twoway"),
  "Playlist-month fixed effects" = feols(form_fes_ols, data = nointerpolations_panel, panel.id = ~id + date, fixef = c('id_month','date'),vcov="twoway"),
  "Playlist-month fixed effects (ihs)" = feols(form_fes_ols_ihs, data = nointerpolations_panel, panel.id = ~id + date, fixef = c('id_month','date'),vcov="twoway"),
  "First-time treatment only" = feols(form_fes_ols, data = nointerpolations_panel[switchcount<=1], panel.id = ~id + date, fixef = c('id_month','date'),vcov="twoway"),
  "Playlist-month fixed effects - excl. other seasonal" = feols(form_fes_ols, data = nointerpolations_panel[other_seasonal==F], panel.id = ~id + date, fixef = c('id_month','date'),vcov="twoway")
)

loglogmodels <- models


#################################################################################################################################################
### what variation is left in feature activity and major label addition if using playlist-month fixed effects
#################################################################################################################################################

form_fes = paste("any_promo", paste(model_vars_exog,collapse = "+"), sep = "~")
form_fes_ml = paste("has_superstar", paste(model_vars_exog,collapse = "+"), sep = "~")
form_fs = as.formula(form_fes)
form_fs_ml = as.formula(form_fes_ml)

variation_promo_month = feols(form_fs, data = nointerpolations_panel, panel.id = ~id + date, fixef = c('id_month','date'))
variation_ml_month = feols(form_fs_ml, data = nointerpolations_panel, panel.id = ~id + date, fixef = c('id_month','date'))

etable(variation_promo_month, variation_ml_month)

nointerpolations_panel[variation_promo_month$obs_selection$obsRemoved, resid_promo:=variation_promo_month$residuals]
nointerpolations_panel[variation_ml_month$obs_selection$obsRemoved, resid_ml:=variation_ml_month$residuals]

saved_resid = nointerpolations_panel[, c('id','date','followers','any_promo','has_superstar','resid_promo','resid_ml')]

save(loglogmodels, variation_promo_month, variation_ml_month, saved_resid, file = '../output/loglogmodels.RData')
