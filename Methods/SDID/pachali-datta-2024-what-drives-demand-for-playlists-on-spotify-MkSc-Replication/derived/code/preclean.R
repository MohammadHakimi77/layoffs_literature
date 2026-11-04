library(data.table)

pls <- fread('../temp/parsed_playlists.csv', encoding = 'UTF-8', sep = '\t', quote='', fill=T, na.strings=c('None', 'NA'),
             colClasses=c(added_at='date', track_releasedates= 'date'))

setorder(pls, track_id, pl_id, added_at)

pls[, track_id:=as.numeric(track_id)]
pls <- pls[!pl_id=='']

to_date<-function(x) {
  dates<-data.table(tmp=unique(x))
  dates[, date:=as.Date(tmp)]
  return(dates$date[match(x,dates$tmp)])
  
}

pls[, added_at:=as.Date(to_date(added_at))]
pls[, track_releasedates:=as.Date(to_date(track_releasedates))]


# keep only tracks released in 2017
pls <- pls[track_releasedates>='2017-01-01']

# remove tracks that were listed on a playlist earlier than 2017
pls[, earliest_added_at:=min(added_at),by=c('track_id')]
pls <- pls[earliest_added_at>='2017-01-01']


# clean uniques
pls <- unique(pls,by=c('track_id','pl_id', 'added_at'))


tracks <- unique(pls, by=c('track_id'))[, c('track_id','track_name','track_durationms','track_popularity')]
tracks[, track_duration_sec:=track_durationms/1000]
tracks[, track_durationms:=NULL]
tracks <- tracks[!is.na(track_id)]

playlists <- unique(pls, by = c('pl_id'))[, c('pl_id', 'pl_name', 'pl_ownerid', 'pl_ownername', 'pl_followers', 'pl_official')]


listings <- pls[!is.na(track_id), c('track_id', 'pl_id', 'added_at')]
setorder(listings, track_id, added_at)


playlists[, pl_type:='other']
playlists[grepl('topsify|digster|filtr', pl_ownername, ignore.case=T), pl_type:='majorlabel']
playlists[pl_official==T, pl_type:='spotify']
playlists[, pl_official:=NULL]


nrow(tracks)
nrow(playlists)
nrow(listings)


# convert dates to numerics
#pls[,date_num:=as.integer(date)]


dir.create('../output')
fwrite(tracks, '../output/tracks.csv')
fwrite(playlists, '../output/playlists.csv')
fwrite(listings, '../output/listings.csv')


