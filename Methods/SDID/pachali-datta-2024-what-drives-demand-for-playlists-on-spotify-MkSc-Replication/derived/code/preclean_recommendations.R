library(data.table)

##########################################
# Playlist selection for recommendations #
##########################################

playlists <- fread('../output/playlists.csv')
setkey(playlists,id) 

# assume user-gen playlists (for now, make some weird assumptions for prototyping) 
playlists[, selection:=FALSE]

playlists[!grepl('not personalized', recommendation_type, ignore.case=T)&owner_class=='Spotify', selection := T]
table(playlists$recommendation_type)

playlists[grepl('artist[-]specific', recommendation_type, ignore.case=T), rec_type := 'recartist']
playlists[grepl('semi', recommendation_type, ignore.case=T), rec_type := 'recsemi']
playlists[grepl('fully', recommendation_type, ignore.case=T), rec_type := 'recfully']


rec_iteration <- unique(playlists[!is.na(rec_type)]$rec_type)

playlists <- playlists[selection==T]

fwrite(playlists[, c('id', 'playlist_id', 'recommendation_type','rec_type'),with=F], '../output/recommendation-ids.csv') 

# Dump track data for recommendations

prototype = file.exists('prototype')

nrows = -1L

if (prototype==T) nrows = 5E5

placements_load <- lapply(c( '../output/placements.csv', '../output/placements-below150k.csv', '../output/placements-recommendations.csv'), fread, 
                          encoding='UTF-8', select = c('id','track_id','track_genre', 'added_at','removed_at'),
                          nrows = nrows)

placements_raw = rbindlist(list(placements_load[[1]], placements_load[[2]][!id%in%unique(placements_load[[1]]$id)]))
placements_raw = rbindlist(list(placements_raw, placements_load[[3]][!id%in%unique(placements_raw$id)]))

# filter for playlists in our main data
placements_raw <- placements_raw[id%in%playlists$id & (is.na(removed_at)|removed_at>=as.Date('2019-01-10')) & added_at < as.Date('2020-05-01')]
placements_raw <- unique(placements_raw, by = c('id','track_id', 'added_at', 'removed_at'))

setkey(playlists, id)
setkey(placements_raw, id)
placements_raw[playlists, rec_type:=i.rec_type]

fwrite(placements_raw, '../temp/placements-recommendations-filtered.csv')



sink('../output/recommendation-ids.txt')
cat('===================\n')
cat('DATASET DESCRIPTION\n')
cat('===================\n')
cat('\n')
cat('This data lists playlist IDs that were identified to serve\n')
cat('users with personalized recommendations.\n')
cat('\n')
cat('Fully personalized rec\'s:  playlists served via the\n')
cat('                           "Made for You" section, and "Radio" playlists\n')
cat('Semi-personalized rec\'s:   playlists tagged by the PERSONALIZED\n')
cat('                           indicator by Chartmetric\n')
cat('Artist-specific rec\'s:     "This is [...]" playlists\n')

cat('\n\n')
cat('Variable operationalization\n')
cat('===========================\n')
cat('id                          Chartmetric playlist ID', fill=T)
cat('playlist_id                 Spotify Playlist ID', fill=T)
cat('playlist_id                 Spotify Playlist ID', fill=T)
cat('recommendation_type         Type of recommendation', fill=T)
cat('rec_type                    Type of recommendation (abbreviated)', fill=T)

sink()
