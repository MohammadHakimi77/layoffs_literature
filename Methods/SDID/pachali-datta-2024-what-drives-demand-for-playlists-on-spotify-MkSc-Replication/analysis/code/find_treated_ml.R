# Identify playlists treated with ML content

# Remove objects in workspace and clean memory
rm(list=ls())
gc()

# Load packages
library(tidyverse)
library(data.table)

prototype = F
nrows=-1L
if (prototype==T) nrows=1E6

# Load data
playlists <- fread('../temp/playlists.csv')

full_panel <- fread('../output/paneldata.csv', nrows=nrows)
nointerpolations_panel <- full_panel[, c('id','date', 'followers', 'metadata_stretch_id', 'metadata_stretch_length', 'qualifying_stretch_id', 'qualifying_stretch_length', 'best_qualifying_stretch'),with=F]
nointerpolations_panel <- nointerpolations_panel[metadata_stretch_length>=100&qualifying_stretch_length>=28]

playlist_adds <- fread('../temp/top_artists_placements.csv')
playlist_adds_meta <- fread('../temp/top_artists.csv')

# Add owner class to panel
setkey(full_panel, id)
setkey(playlists, id)
full_panel[playlists, owner_class:=i.owner_class]

cutoff_pre_post_window = 15

addition_panel = merge(playlist_adds, playlist_adds_meta, by = c('cm_artist'))
addition_panel = addition_panel[days_on_list>=cutoff_pre_post_window]

first_required_date_in_data = as.Date('2019-10-28') + cutoff_pre_post_window
last_required_date_in_data = as.Date('2020-03-26') - cutoff_pre_post_window

barplot(table(addition_panel$added_at))
nrow(addition_panel[added_at >= first_required_date_in_data])

# per playlist, select isolated events
tmp=addition_panel[, list(.N),by=c('id')]

setkey(nointerpolations_panel, id, date)
setkey(addition_panel, id, added_at)

nointerpolations_panel[addition_panel, ':=' (treat_id = top_id, treatment_date=i.added_at, treatment_days_on_list=i.days_on_list)]

setorder(nointerpolations_panel, id, date)

nointerpolations_panel[, col:=cumsum(!is.na(treat_id)),by=c('id','qualifying_stretch_id','qualifying_stretch_length')]

treat_stretches = nointerpolations_panel[, list(observed_after=.N, treatment_date=treatment_date[1], treatment_id=treat_id[1],
                                                treatment_days_on_list=treatment_days_on_list[1],
                                                stretch_min_date=min(date), stretch_max_date=max(date)),by=c('id','qualifying_stretch_id','qualifying_stretch_length', 'col')]
setorder(treat_stretches, id, qualifying_stretch_id)

treat_stretches[, observed_before:=c(NA, observed_after[-.N]-ifelse(is.na(treatment_date[-.N]),0,1)),by=c('id','qualifying_stretch_id')]

treat_stretches[, min_date:=treatment_date - observed_before]
treat_stretches[, max_date:=stretch_max_date]


controls = treat_stretches[, list(never_treated=all(is.na(treatment_date))),by=c('id')]
controls = controls[never_treated==T]

# remove events after the max window
treat_stretches <- treat_stretches[treatment_date<=last_required_date_in_data]

setorder(treat_stretches, id, treatment_date)
treat_stretches[, treat_order:=1:.N,by=c('id')]
treat_playlists = treat_stretches[observed_after>=cutoff_pre_post_window&observed_before>=ifelse(treat_order>1, cutoff_pre_post_window*2, cutoff_pre_post_window)][, treated:=T]
setorder(treat_playlists, id, treatment_date, treat_order)

treat_playlists[, order:=1:.N,by=c('id')]

summary(treat_playlists$order)
treat_playlists = treat_playlists[order==1]

final_treat_list = rbindlist(list(treat_playlists, controls[!id%in%unique(addition_panel$id)][, treated:=F]),fill=T)

setkey(final_treat_list, treatment_id)
setkey(playlist_adds_meta, top_id)

final_treat_list[playlist_adds_meta, ':=' (universal=i.universal, sony=i.sony, warner=i.warner, artist_name=i.artist_name)]

fwrite(final_treat_list, '../temp/treated_ml.csv')