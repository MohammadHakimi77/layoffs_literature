library(data.table)

tracks <- unique(rbindlist(lapply(c('../externals/playlist-placements.csv',
                   '../externals/playlist-placements-below150k.csv',
                   '../externals/playlist-placements-recommendations.csv'), function(fn) {
  cat(paste0('Reading ', fn, '...'), fill=T)
  unique(fread(fn, nrows=-1L,
            encoding = 'UTF-8', sep='\t', quote = "", 
            na.strings=c('NA', 'None'),
            select = c('track_id','track_genre','release_dates','cm_artist','album_label', 'key','mode','danceability','energy',
                       'speechiness','acousticness','instrumentalness','liveness','valence','tempo','loudness', 'spotify_duration_ms')), by = c('track_id'))
})),by=c('track_id'))

print(nrow(tracks))

tracks[, collaboration := grepl('[|]', cm_artist)]
fwrite(tracks, '../temp/extract-releases-tracks.csv')

artist_releases = tracks[, list(artist_id = unlist(strsplit(cm_artist,'[|]'))), by = c('track_id', 'release_dates','album_label','collaboration')][!is.na(artist_id)]
setorder(artist_releases, artist_id, release_dates, album_label)
artist_releases[, uniq_label := match(album_label, album_label)==1:.N, by = c('artist_id')]

artist_collab_count = artist_releases[, list(ntracks=.N, 
                                             ntracks_collab = sum(collaboration),
                                             uniq_labels=any(uniq_label)
                                             ),by=c('artist_id','release_dates')]

setorder(artist_collab_count, artist_id, release_dates)
artist_collab_count[, ':=' (cumntracks = cumsum(ntracks),
                            cumntracks_collab = cumsum(ntracks_collab),
                            cumuniq_labels = cumsum(uniq_labels)),by=c('artist_id')]

artist_collab_count <- artist_collab_count[!artist_id=='None']
artist_collab_count[, artist_id:=as.numeric(artist_id)]
setnames(artist_collab_count, 'artist_id','cm_artist_id')
setnames(artist_collab_count, 'release_dates','date')

fwrite(artist_collab_count, '../temp/extract-collaborations.csv')

