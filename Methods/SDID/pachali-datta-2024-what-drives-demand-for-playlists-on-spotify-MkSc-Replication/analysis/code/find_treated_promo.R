# Identify playlists treated with promotions

# Remove objects in workspace
rm(list=ls())
gc() 

# Load packages
library(tidyverse)
library(data.table)

# Load data
promo <- fread('../temp/promotions_cleaned.csv') 
promo_raw=fread('../temp/promotions.csv')

playlists <- fread('../temp/playlists.csv')

full_panel <- fread('../output/paneldata.csv')
full_panel = full_panel[!date==as.Date('2019-12-08')] # remove day in which promotion information was not properly scraped

nointerpolations_panel <- full_panel[, c('id','date', 'followers', 'metadata_stretch_id', 'metadata_stretch_length', 'qualifying_stretch_id', 'qualifying_stretch_length', 'best_qualifying_stretch'),with=F]
nointerpolations_panel <- nointerpolations_panel[metadata_stretch_length>=100&qualifying_stretch_length>=28]

setorder(full_panel, id, date)
full_panel[, lag_any_promo := c(NA, any_promo[-.N]),by=c('id')]

# identify relevant promotions

### select required window lengths before/after treatments
cutoff_pre_post_window = 15

first_required_date_in_data = as.Date('2019-10-28') + cutoff_pre_post_window 

## Collect first/last day of promotion for playlists (and number of days a playlist has been promoted)
promoted_playlists = full_panel[date<=as.Date('2020-03-26'), list(first_observed_promo_date = as.IDate(min(date[any_promo==1],na.rm=T)),
                                                                  first_switch_to_promo_date = as.IDate(min(date[any_promo==1&lag_any_promo==0],na.rm=T)),
                                                                  last_switch_from_promo_date = as.IDate(max(date[any_promo==0&lag_any_promo==1],na.rm=T))),by=c('id', 'owner_class')] 

## Create buckets of newly added, removed, and always promoted playlists
promoted_playlists[, ':=' (never_promoted = FALSE,
                           always_promoted = FALSE,
                           promoted_at_beginning=FALSE,gets_added=FALSE,gets_removed=FALSE)]

promoted_playlists[, promoted_at_beginning:=first_observed_promo_date<'2019-11-01']

uniqueN(promoted_playlists[!is.na(first_observed_promo_date)])

promoted_playlists[, gets_added:=!promoted_at_beginning&!is.na(first_observed_promo_date)]

uniqueN(promoted_playlists[gets_added==T]$id)

# diff code: this aligns with the raw data
if(0){  # how many playlists were featured in our sample?
  setkey(promo_raw, playlist_id)
  setkey(playlists, playlist_id)
  promo_raw[playlists, id:=i.id]

  promo_raw[!sectionName=='toplists'&date!=as.Date('2019-12-08')&date<=as.Date('2020-03-26')&id%in%unique(full_panel$id), sel:=T]
  uniqueN(promo_raw[sel==T]$id)
  
  # how many playlists are being ADDED (i.e., first not before 1 nov)
  promo_raw[sel==T, censored:=any(date<as.Date('2019-11-01')),by=c('id')]
  
  # censored obs
  uniqueN(promo_raw[sel&censored]$id)
  
  # non-censored obs
  uniqueN(promo_raw[sel&!censored]$id)

  # end diff code
}
sum(table(promoted_playlists[gets_added==T]$first_observed_promo_date))


promoted_playlists[, gets_added_with_minimum_pre:=gets_added&first_switch_to_promo_date>=first_required_date_in_data]
promoted_playlists[gets_added_with_minimum_pre==T, gets_added_window:=as.numeric(as.Date(first_switch_to_promo_date)-as.Date('2019-10-28'))]

uniqueN(promoted_playlists[gets_added==T]$id)
uniqueN(promoted_playlists[gets_added_with_minimum_pre==T]$id)

## Add meta data
setkey(playlists, id)
setkey(promoted_playlists, id)
promoted_playlists[playlists, name:=i.name]
promoted_playlists[playlists, owner_class:=i.owner_class]

promoted_playlists[, never_promoted:=!id%in%unique(promo_raw$id)]

# Tag 2019 and other potentially seasonal playlists
setkey(promo_raw, playlist_id)
setkey(playlists, playlist_id)
promo_raw[playlists,  id:=i.id]
sections=promo_raw[, list(sections=paste(unique(sectionName),collapse=',')),by=c('id')]
setkey(sections, id)
setkey(promoted_playlists, id)
promoted_playlists[sections, sections:=i.sections]

promoted_playlists[, is2019:=grepl('2019', sections)]
promoted_playlists[, isotherseasonal:=grepl('exercise|wellness|holiday|award', sections)]

# Explore how many events are in the data
promoted_playlists[gets_added_with_minimum_pre==T]
promoted_playlists[gets_added_with_minimum_pre==T & is2019== F]
promoted_playlists[gets_added_with_minimum_pre==T & is2019== F & isotherseasonal==F]

# Do we "see" all of these first time promotions in our data?

# select potential promotions
setkey(nointerpolations_panel, id) 
setkey(promoted_playlists, id)
setkey(nointerpolations_panel,id,date)
setkey(full_panel,id,date)
nointerpolations_panel[promoted_playlists, ':=' (first_observed_promo_date=i.first_observed_promo_date,
                                                 is2019=i.is2019,
                                                 isotherseasonal=i.isotherseasonal,
                                                 gets_added=i.gets_added,
                                                 gets_added_with_minimum_pre=i.gets_added_with_minimum_pre,
                                                 gets_added_window=i.gets_added_window)]

nointerpolations_panel[full_panel, any_promo:=i.any_promo] 

promo_days <- function(x) {
  x[is.na(x)]<-0
  tmpx=rle(x)
  if (length(tmpx$values)<2) return(NA)
  if (!is.na(tmpx$values[2])) {
    if (tmpx$values[2]==1) {
      return(tmpx$lengths[2]) } else {
      return(NA)
      } 
  } else {
    return(NA)
  }
}

nointerpolations_panel[, cutoff:=first_observed_promo_date+15]
tmp = nointerpolations_panel[gets_added_with_minimum_pre == T, list(.N, min_date=min(date), max_date=max(date),
                                                   event_observed = first_observed_promo_date%in%date,
                                                   last_promo_date=as.Date(max(date[any_promo==1],na.rm=T)),
                                                   nobs_first_promo_observed=as.numeric(promo_days(as.numeric(any_promo))),
                                                   nobs_within_15_days = sum(any_promo[date>=first_observed_promo_date & date < cutoff],na.rm=T)),
                             by=c('id', 'qualifying_stretch_id','qualifying_stretch_length',
                                  'first_observed_promo_date', 'is2019', 'isotherseasonal','gets_added_window')]

tmp[, observed_before := first_observed_promo_date - min_date]
tmp[, observed_after := max_date - first_observed_promo_date]


uniqueN(tmp[is2019==F]$id) #%>% filter(is2019==F)
uniqueN(tmp[is2019==F&isotherseasonal==F]$id) #%>% filter(is2019==F)
uniqueN(tmp[event_observed==T&is2019==F&isotherseasonal==F]$id) #%>% filter(is2019==F)

tmp[event_observed==T] %>% filter(is2019==F) 

test=tmp[event_observed==T & is2019==F & observed_before >= 15 & observed_after>=15]
uniqueN(test$id)


nrow(test[nobs_first_promo_observed>=0])
summary(test[nobs_first_promo_observed>=0]$nobs_first_promo_observed)
summary(test[nobs_first_promo_observed>=0]$nobs_within_15_days)
nrow(test[nobs_within_15_days>=7])

nrow(test[nobs_within_15_days>=7])# & nobs_first_promo_observed >= 14])
uniqueN(test[nobs_within_15_days>=7]$first_observed_promo_date)# & nobs_first_promo_observed >= 14])

# build sample for plot (excluding 2019, including other seasonal events)
tmp[event_observed==T] %>% filter(is2019==F) # %>% filter(is.na(nobs_promo_observed)) #%>% pull(nobs_promo_observed) %>% hist()

tmp[event_observed==T] %>% filter(is2019==F) %>% filter(observed_before>=cutoff_pre_post_window & observed_after >= cutoff_pre_post_window) %>% nrow()

tmp[event_observed==T] %>% filter(is2019==F)  %>% filter(nobs_within_15_days>=7) %>% filter(observed_before>=cutoff_pre_post_window & observed_after >= cutoff_pre_post_window) %>% nrow()


treat_playlists = tmp[event_observed==T] %>% filter(nobs_within_15_days>=floor(cutoff_pre_post_window/2)) %>% filter(observed_before>=cutoff_pre_post_window) %>% filter(is2019==F) %>% filter(observed_after>=cutoff_pre_post_window)

treat_playlists

setorderv(playlists, 'followers',order=-1L)
playlists[id%in%treat_playlists$id][grepl('This is',name)]
unique(playlists[id%in%treat_playlists$id]$owner_class)
playlists[id%in%treat_playlists$id]
playlists[id%in%treat_playlists$id&!owner_class=='Spotify']
uniqueN(treat_playlists$first_observed_promo_date)
controls=promoted_playlists[never_promoted==T][, .(id)]

# drop in promotion share
setkey(promo_raw, playlist_id)
setkey(playlists, playlist_id)
promo_raw[playlists, owner_class:=i.owner_class]

tmp=promo_raw[, list(playlist_count=uniqueN(playlist_id)),by=c('date','owner_class')]
tmp2 = tmp[!is.na(owner_class)&date<=as.Date('2020-04-01'), list(spotify_share=playlist_count[owner_class=='Spotify']/sum(playlist_count,na.rm=T)),by=c('date')]
setorder(tmp2, date)
plot(x=tmp2$date, y=tmp$spotify_share,type='l')


final_treat_list = suppressWarnings(rbindlist(list(treat_playlists[, treated:=T], controls[, treated:=F]),fill=T))


cat(paste0('Calculating with ', nrow(treat_playlists), ' treated playlists.'),fill=T)

fwrite(final_treat_list, '../temp/treated_promo.csv')
