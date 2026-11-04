library(data.table)

tracks <- fread('../output/track-labels.csv')
placements <- fread('../output/placements.csv')
sample <- fread('../output/panel.csv', select= c('id','date')) # current playlist sample
top_artists <- fread('../output/top_artists_placements.csv')


uniqueN(sample$id)
top_artist_ids = unique(top_artists$track_id)
placements <- placements[id%in%unique(sample$id)]

place_filtered = placements[(is.na(removed_at)|removed_at>as.Date('2019-11-01')) & added_at <= as.Date('2020-04-01')]


setkey(place_filtered, track_id)
setkey(tracks, track_id)
place_filtered[tracks, ':=' (sony=i.sony_curr, universal=i.universal_curr, warner=i.warner_curr)]


nrow(place_filtered)
place_filtered[, spell:=NULL]
place_filtered[, album_names:=NULL]
place_filtered[, track_genre:=NULL]
place_filtered[, spotify_album_id:=NULL]
place_filtered[, sony:=as.numeric(sony)]
place_filtered[, universal:=as.numeric(universal)]
place_filtered[, warner:=as.numeric(warner)]

fwrite(place_filtered, '../output/placements-selected-only.csv')
