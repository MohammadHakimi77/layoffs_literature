# Pre-cleaning panel data #

# start with a clean workspace
rm(list=ls())

# load required packages
library(data.table)
library(tidyverse)

# setup
cutoff_marketshare = 0.95 # share of playlists (in terms of followers) included in the data preparation
lbls <- c('sony','warner','universal') # define names of major labels

# load data
dt <- fread('../temp/panel.csv', encoding='UTF-8', nrow=-1L)
promos <- fread('../temp/promotions_cleaned.csv')
playlists <- fread('../temp/playlists.csv', encoding = 'UTF-8')
categories <- fread('../temp/playlist-categories.csv')
playlist_adds <- fread('../temp/top_artists_placements.csv')
playlist_adds_meta <- fread('../temp/top_artists.csv')

# determine overall category popularity
tmp=categories[, list(sum_followers=sum(playlist_followers/1E6,na.rm=T)),by=c('category','cat_id','begin_init')][, list(sum_followers=sum(sum_followers,na.rm=T)),by=c('category','cat_id')]
setorderv(tmp, 'sum_followers',order=-1L)
tmp[, category_cumms:=cumsum(sum_followers)/sum(sum_followers)]
setkey(tmp, cat_id)
setkey(categories, cat_id)
categories[tmp, category_cumms:=i.category_cumms]

# define main data frame (those for which listeners were observed; data stops end of March 2020)
dt <- dt[date<=as.Date('2020-03-26')]
promos <- promos[date<=as.Date('2020-03-26')]

# merge dynamic categories
setkey(dt, id, date)
categories_merge = categories[, c('id','begin_init'),with=F]
setkey(categories_merge, id, begin_init)
dt=categories_merge[dt,roll=T]
setnames(dt, 'begin_init','date')

# merge superstar indicator
setkey(playlist_adds, cm_artist)
setkey(playlist_adds_meta, cm_artist)
playlist_adds[playlist_adds_meta, ':=' (sony=i.sony, warner=i.warner, universal=i.universal)]

# superstar available on a given list
dates = seq(from=min(dt$date), to=max(dt$date),by='1 day')
superstars=rbindlist(lapply(dates, function(x) playlist_adds[added_at<=x&(is.na(removed_at)|removed_at>x), list(nsuperstars=.N,
                                                                                                                nmlsuperstars=length(which(universal|warner|sony>0))
                                                                                                              ),by=c('id')][,date:=x]))
setkey(superstars, id, date)
setkey(dt, id, date)
dt[superstars, ':=' (nsuperstars=i.nsuperstars,
                     nmlsuperstars=i.nmlsuperstars)]

dt[, has_superstar:=as.numeric(nmlsuperstars>0)]
dt[, has_anysuperstar:=as.numeric(nsuperstars>0)]

dt[is.na(has_superstar), has_superstar:=0]
dt[is.na(has_anysuperstar), has_anysuperstar:=0]

# merge promotions
setkey(dt, id, date)
setkey(promos, id, date)
dt[promos, ':=' (any_browse = as.numeric(browse_GLOB+browse_nsections>0),
                 any_feature = as.numeric(featured_GLOB+featured_nsections>0),
                 any_toplist = as.numeric(toplists_GLOB+toplists_nsections>0),
                 promo_nsections = browse_nsections+browse_GLOB)]
dt[is.na(any_browse), any_browse:=0]
dt[is.na(any_feature), any_feature:=0]
dt[is.na(any_toplist), any_toplist:=0]
dt[is.na(promo_nsections), promo_nsections:=0]

# define "any promotion" indicator
dt[, any_promo := as.numeric(any_browse)]

# in some exceptional cases, track age is negative (i.e., added before official release date; in these circumstances, set track age to 0).
nrow(dt[trackage<0])/nrow(dt)
dt[trackage<0, trackage:=0]

nrow(dt[wnplaylists_trackage<0])/nrow(dt)
dt[wnplaylists_trackage<0, wnplaylists_trackage:=0]

##################
# Data selection #
##################

# Strategy: 
# The \derived stage filtered on playlists within categories in the x%-ile (and, within each category, the x%-ile of
# playlists in terms of followers). This dataset is considered the "broadest" possible panel data set we can generate,
# but it contains a few playlists that we need to exclude (e.g., 'recommendation' playlists - we have a separate measure for that).
# Therefore, we're proceeding in two steps.
# 1. Remove playlists we do not want to include at all - these are 'recommended playlists' and playlists that 
#    are barely covered in our panel data.
# 2. Create covariates.
# 3. Filter playlists that we want to model (i.e., re-filter on xx%-marketshare among the available playlists).


######################################################
# Identify stretches of consecutively available data #
######################################################

# returns vector of length x, indicating as a continuous variable the number of
# observations in a stretch of consecutively available/non-available information.
# negative numbers indicate the original variable is one that is NA.
# positive numbers indicate the original variable was measured/is available.
interp_length <- function(x) {
  stopifnot(class(x)=='logical')
  tmpx=rle(x)
  
  lengths=rep(tmpx$lengths,tmpx$lengths)*rep(ifelse(tmpx$values==F,-1,1),tmpx$lengths)
  ids=rep(seq(from=1, to=length(tmpx$lengths)),tmpx$lengths)
  return(list(lengths=lengths, ids=ids))  
  }

vars=c('id','date','followers','followers_interpolated','ntracks','cat_id')
tmp=dt[,vars,with=F]

# add, for each playlist-date observation an information of the length of the current consecutively available stretch length (in days), and assign an ID to it
setorder(tmp, id,date)
tmp[, c('metadata_stretch_length', 'metadata_stretch_id'):=interp_length(!is.na(cat_id) & !is.na(ntracks)),by=c('id')]

# within each stretch, compute consec. available followers
tmp[, c('stretch_length_followers', 'followers_stretch_id'):=interp_length(followers_interpolated==F),by=c('id','metadata_stretch_id')]

# flag stretches with less or equal than 2 missing observations for followers and complete meta data - "we interpolate up to two consecutively missing observations"
tmp[, qualifying_stretch:=stretch_length_followers>=c(-2) & metadata_stretch_length>0,by=c('id', 'metadata_stretch_id', 'followers_stretch_id')]

# compute length of stretches that potentially qualify for inclusion
tmp[, c('qualifying_stretch_length', 'qualifying_stretch_id'):=interp_length(qualifying_stretch), by= c('id')]

# flag "best" stretch (maximum length)
tmp[, best_metadata_stretch := metadata_stretch_length==max(metadata_stretch_length),by='id']
tmp[, best_qualifying_stretch:=qualifying_stretch_length==max(qualifying_stretch_length),by=c('id', 'metadata_stretch_length')]
tmp[best_qualifying_stretch==T&best_metadata_stretch==F, best_qualifying_stretch:=F]

# make overview of stretches
stretches=tmp[, list(N=.N, best_qualifying_stretch=all(best_qualifying_stretch==T)), by = c('id','metadata_stretch_id','metadata_stretch_length','qualifying_stretch_length','qualifying_stretch_id')]

setkey(tmp, id, date)
setkey(dt, id, date)

dt[tmp, ':=' (metadata_stretch_length =i.metadata_stretch_length,
              metadata_stretch_id = i.metadata_stretch_id,
              qualifying_stretch_length=i.qualifying_stretch_length, 
              qualifying_stretch_id=i.qualifying_stretch_id, 
              best_qualifying_stretch=i.best_qualifying_stretch)]

####################
# Select playlists #
####################

# compile derived data set used for playlist selection
obs = stretches[, list(nobs_best_qualifying_stretch = sum(N[best_qualifying_stretch==T]),
                       metadata_stretch_length = max(metadata_stretch_length[best_qualifying_stretch==T])
                       ),by=c('id')] # --> all playlists

obs[nobs_best_qualifying_stretch>=28&metadata_stretch_length>=100]

# merge market shares
setkey(obs, id)
setkey(playlists, id)
obs[playlists, recommendation_type:=i.recommendation_type]

obs[grepl('fully', recommendation_type, ignore.case=T), exclude_recommended:=T]

obs[playlists, follower_percentile:=i.follower_percentile]
obs[playlists, followers:=i.followers]

obs[follower_percentile<=cutoff_marketshare]
obs[follower_percentile<=cutoff_marketshare&is.na(exclude_recommended)]
obs[follower_percentile<=cutoff_marketshare&is.na(exclude_recommended)&metadata_stretch_length>=100]
obs[follower_percentile<=cutoff_marketshare&is.na(exclude_recommended)&metadata_stretch_length>=100&nobs_best_qualifying_stretch>=28]

sum(obs[follower_percentile<=cutoff_marketshare&is.na(exclude_recommended)&metadata_stretch_length>=100&nobs_best_qualifying_stretch>=28]$followers,na.rm=T)/sum(obs$followers,na.rm=T)
obs[follower_percentile<=cutoff_marketshare&is.na(exclude_recommended)&metadata_stretch_length>=100&nobs_best_qualifying_stretch>=28, selected:=T]

fwrite(obs, '../temp/selected-playlists.csv')

###################
# Create measures #
###################

dt_backup <- copy(dt)

# exclude from data prep those unselected categories as well as 
dt <- dt[id%in%obs[selected==T]$id]

# number of playlists in sample
uniqueN(dt$id)

# number of categories in sample
uniqueN(dt$cat_id)

#####################
# Create covariates #
#####################

dt[, playduration := tracklength_sec]

# Add owner class
setkey(dt, id)
setkey(playlists, id)
dt[playlists, owner_class:=i.owner_class]

# rescale some variables
for (.v in grep('trackage$', colnames(dt),value=T)) {
  dt[, paste0(.v, '_year'):= get(.v) / 365]
  setnames(dt, .v, paste0(.v, '_days'))
}

# re-code the spotify duration variable and listening duration
dt[, tracklength_min:=tracklength_sec/60]
dt[, playlist_duration_h:=(tracklength_min*ntracks)/60]

#######################
# DESCRIBE FINAL DATA #
#######################

new_dt <- copy(dt)
uniqueN(new_dt$id)

# investigate which playlists are contained in the panel data
setkey(playlists, id)
setkey(new_dt, id)
playlists[, selected:=id%in%unique(new_dt$id)]

# this data features the following selected playlists
table(playlists$selected)

category_names = categories[, list(.N),by=c('cat_id','category')]

setkey(category_names, cat_id)
setkey(new_dt, cat_id)

new_dt[category_names, categories:=i.category]

# calculate combined follower share of selected playlists (static)
sum(playlists[selected==T]$followers, na.rm=T)/sum(playlists$followers, na.rm=T)

# drop unnecessary columns
remove <- grep('[_](half|any|NNA)$', colnames(dt), value=T)
length(remove)
for (r in remove) new_dt[, paste0(r):=NULL]

category_names 

########################
# Save precleaned file #
########################

filename = paste0("../output/paneldata.csv")
dir.create('../output')
fwrite(new_dt, filename)
