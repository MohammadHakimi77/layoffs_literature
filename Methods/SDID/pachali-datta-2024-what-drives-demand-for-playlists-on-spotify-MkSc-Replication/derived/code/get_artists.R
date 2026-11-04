library(data.table)

artist_names <- fread(file = "../externals/playlist-placements.csv", encoding = 'UTF-8', sep='\t', quote = "", 
                      na.strings=c('NA', 'None'),  select = c('artist_names', 'playlist_id','track_id'))

tmp = artist_names[, list(artist_name_uncollapsed=unlist(strsplit(artist_names, '|', fixed=T))), by = c('playlist_id','track_id')]


cm_artists = tmp[, list(N_tracks = uniqueN(track_id), N_playlists = uniqueN(playlist_id)),by=c('artist_name_uncollapsed')]

setnames(cm_artists, 'artist_name_uncollapsed','artist_name')

cm_artists <- cm_artists[!(is.na(artist_name)|artist_name=='')]

dir.create('../output')
fwrite(cm_artists, '../output/artists.csv')