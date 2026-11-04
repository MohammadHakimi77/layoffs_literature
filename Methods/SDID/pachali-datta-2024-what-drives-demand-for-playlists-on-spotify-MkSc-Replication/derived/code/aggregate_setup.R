cat('Loading placements...\n')
if (agg_type == 'placements') {
  placements <- fread('../output/placements.csv', encoding='UTF-8', drop = c('name','spotify_album_id','artist_names','album_names', 'track_genre', 'key','mode'), 
                      nrows = nrows)
  
}

if (agg_type == 'fans') {
  placements <- fread('../output/placements.csv', encoding='UTF-8', select= c('id','track_id','cm_artist',
                                                                              'added_at','removed_at'),
                      nrows = nrows)
}


sharecutoff=.95

######################
# Playlist selection #
######################
cat('Loading playlists...\n')
playlists <- fread('../output/playlists.csv')

placements = placements[id%in%playlists[follower_percentile <= sharecutoff]$id]

# categories
dyncategories <- fread('../output/playlist-categories.csv')

dyncategories[, withincat_ms:=ifelse(is.na(playlist_followers),0,playlist_followers)/sum(playlist_followers,na.rm=T),by=c('category', 'begin_init')]
setorderv(dyncategories, c('category','withincat_ms'), order=c(1L,-1L))
dyncategories[, withincat_cumms:=cumsum(withincat_ms),by=c('category', 'begin_init')]
dyncategories[, withincat_msrank:=rank(withincat_cumms),by=c('category', 'begin_init')]


gc()

#################
# Convert dates #
#################
cat('Converting dates...\n')
# convert dates to R dates
dates=data.table(date_str=unique(c(placements$added_at, 
                                   placements$removed_at, 
                                   placements$release_dates)))
dates[, date:=as.Date(date_str, format='%Y-%m-%d')]

setkeyv(dates, 'date_str')

for (v in c('added_at','removed_at', 'release_dates')){
  if (!v %in% colnames(placements)) next
  setkeyv(placements, v)
  placements[dates, paste0(v, '_date'):=i.date]
  placements[, (v):=NULL]
  setnames(placements, paste0(v, '_date'), v)
}

####################################
# Load artist label classification #
####################################

cat('Obtain label classification...\n')

# Obtain artist-level label classification
artistlabels <- fread('../output/artist-labels.csv')

# define observation period
start_series = as.Date('2019-10-01')
end_series = as.Date('2020-04-05')
dates_series=seq(from=start_series, to=end_series, by = '1 day')

# collect artist IDs and labels by playlist in observation period
all_artists_by_pl <- placements[!grepl('none', cm_artist, ignore.case=T)&!cm_artist=='' & added_at<=end_series & (is.na(removed_at)|removed_at>=start_series), list(N=.N), by=c('id','cm_artist')]
all_artists_by_pl <- all_artists_by_pl[, list(cm_artist=as.numeric(unique(unlist(strsplit(cm_artist, '|',fixed=T))))), by =c('id')]

all_artists_by_pl <- merge(all_artists_by_pl, artistlabels,by.x=c('cm_artist'), by.y=c('cm_artist'),all.x=T, all.y=F)



all_artists <- unique(all_artists_by_pl, by = c('cm_artist'))[, id:=NULL]

setkey(all_artists, cm_artist)
setkey(all_artists_by_pl, id,cm_artist)


#################
# Load fan data #
#################

# Load interpolated fans
fans_raw <-fread('../temp/fans_interpolated.csv', nrows = nrows)

# convert dates to R dates
dates=data.table(date_str=unique(fans_raw$date))
dates[, date:=as.Date(date_str, format='%Y-%m-%d')]
setkeyv(dates, 'date_str')

v='date'
setkeyv(fans_raw, v)
fans_raw[dates, paste0(v, '_date'):=i.date]
fans_raw[, (v):=NULL]
setnames(fans_raw, paste0(v, '_date'), v)
setkey(fans_raw, cm_artistid,date)

fans <- fans_raw[date>=start_series & date<=end_series & cm_artistid %in% unique(all_artists_by_pl$cm_artist)]

setorder(fans, cm_artistid,date)
fans[, 'dfans-instagram':=`fans-instagram`-c(NA,`fans-instagram`[-.N]),by=c('cm_artistid')]
fans[, 'dfans-deezer':=`fans-deezer`-c(NA,`fans-deezer`[-.N]),by=c('cm_artistid')]
setkey(fans, cm_artistid,date)

rm(fans_raw)
