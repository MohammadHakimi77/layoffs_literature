library(data.table)

nrows=-1L

placements <- fread('../output/placements-aggregated.csv', nrows = nrows)

dyncategories <- fread('../output/playlist-categories.csv')
categories <- dyncategories[, list(.N),by=c('category', 'cat_id')]

playlists <- fread('../output/playlists.csv', drop = c('retrieval_unix','location','genre','position'))
setorderv(playlists, 'followers', order = -1L, na.last=T)
playlists[, follower_rank:=1:.N]
setnames(playlists, 'followers', 'followers_static')

recommendations <- fread('../output/recommendations.csv')
recommendations_by_category <- fread('../output/recommendations-by-category.csv')

followers_listeners <- fread('../output/followers-listeners.csv')

# set dates
# convert dates to R dates
dates=data.table(date_str=unique(c(unique(placements$date), unique(followers_listeners$date))))

dates[, date:=as.Date(date_str, format='%Y-%m-%d')]

setkeyv(dates, 'date_str')

for (v in c('date')){
  setkeyv(placements, v)
  placements[dates, paste0(v, '_date'):=i.date]
  placements[, (v):=NULL]
  setnames(placements, paste0(v, '_date'), v)
}

placements <- placements[date>=as.Date('2019-10-29') & date <= as.Date('2020-04-30')]

gc()


#########
# MERGE #
#########

setkey(followers_listeners, id, date)
setkey(placements, id, date)
placements[followers_listeners, ':=' (followers=i.followers, followers_interpolated=i.interpolated_followers,
                                      listeners = i.listeners, listeners_interpolated = i.interpolated_listeners)]

# Playlists
setkey(placements, id)
setkey(playlists, id)

placements[playlists, ':=' (playlist_id=i.playlist_id, playlist_name = i.name, 
                            playlist_followers_static = i.followers_static,
                            playlist_follower_rank = i.follower_rank)]

# Rec's (non-category specific)
rec_tmp = dcast(melt(recommendations, id.vars=c('date','rec_type')), date~rec_type+variable)

setkey(placements, date)
setkey(rec_tmp, date)

merge_variables = setdiff(colnames(rec_tmp),c('date'))
for (.var in merge_variables) eval(parse(text=paste0("placements[rec_tmp, `", .var, "`:=`i.", .var, "`]")))

# merge category-secific variables
setkey(categories, cat_id)
setkey(placements, cat_id)
placements[categories, category:=i.category]

# Rec's (non-category specific)
rec_tmp2 = dcast(melt(recommendations_by_category, id.vars=c('date','rec_type', 'combined_genre')), date+combined_genre~rec_type+variable)

setkey(placements, date, category)
setkey(rec_tmp2, date, combined_genre)

merge_variables = setdiff(colnames(rec_tmp2),c('date', 'combined_genre'))
for (.var in merge_variables) eval(parse(text=paste0("placements[rec_tmp2, `", .var, "_cat`:=`i.", .var, "`]")))
for (.var in merge_variables) eval(parse(text=paste0("placements[is.na(`", .var, "_cat`), `", .var, "_cat`:=0]")))

# variable order
setcolorder(placements, unique(c('id', 'playlist_id', 'date', 'cat_id', 'category', 'followers', 'listeners', 'playlist_name', grep('playlist[_]follower', colnames(placements),value=T),
                          grep('^promo', colnames(placements),value=T))))

for (.v in grep('[_]$',colnames(placements),value=T)) setnames(placements, .v, gsub('[_]$', '', .v))
     

fwrite(placements, '../output/panel.csv')


#merged <- merge(all_pls, followers, by = c('id', 'date'), all.x=T, all.y=F)


sink('../output/panel.txt')
cat('===========================\n')
cat('VARIABLE OPERATIONALIZATION\n')
cat('===========================\n')

cat(paste0('\nData set generated on: ', as.character(Sys.time()), '\n--------------------------------------------\n'))
cat('\n')
cat('WARNING: Description below not up-to-date.\n')

cat('\n\n')
cat('id                             Chartmetric Playlist ID', fill=T)
cat('playlist_id                    Corresponding Spotify playlist ID - can be used to look up data on Spotify', fill=T)
cat('date                           Date (YYYY-MM-DD)', fill=T)
cat('followers                      Number of followers (daily; interpolated if missing)', fill=T)
cat('listeners                      Number of listeners (daily; based on rolling windows of 28 days; estimated by Chartmetric; interpolated if missing)', fill = T)
cat('\n')
cat('playlist_name                  Name of the playlist', fill = T)
cat('playlist_followers_static      Number of followers at data retrieval (static; April 2020)', fill = T)
cat('playlist_followers_rank        Popularity rank (1=most popular, N = least popular) of playlist at data retrieval (based on playlist_followers_static)', fill = T)
cat('\n')
cat('promo_featured                 Indicator variable, equaling 1 if playlist was promoted on Spotify\'s feature section', fill = T)
cat('promo_toplists                 Indicator variable, equaling 1 if playlist was promoted on Spotify\'s toplists section', fill = T)
cat('promo_nsections                Count variable, capturing the number of sections the playlist was promoted on Spotify\'s \"genres & mood\" section', fill = T)
cat('\n')

cat('The following variables measure the share of major-label (ml), Sony (sony), Warner (warner), and Universal (universal)\n')
cat('content on a playlist. The metrics distinguish between various ways to associate a given track on a playlist with a label:\n')
cat('\n')
cat('_curr:        track label classified on the basis of the label of the track\n')
cat('_any:         track label classified on the basis of *any* of the contributing artists\' label membership\n')
cat('              (artist label = any of the artists\' tracks is by the focal label)\n')
cat('3_any:        track label classified on the basis of *any* of the contributing artists\' label membership\n')
cat('              (artist label = any of the three most recent track or album releases of an artist is by the focal label)\n')
cat('byshare_any:  track label classified on the basis of *any* of the contributing artists\' label membership\n')
cat('              (artist label = at least 50% of an artist\'s tracks are by the focal label)\n')
cat('\n')
cat('_half:        track label classified if at least half of the contributing artists are from focal label\n')
cat('              (artist label = any of the artists\' tracks is by the focal label)\n')
cat('3_half:       track label classified if at least half of the contributing artists are from focal label\n')
cat('              (artist label = any of the three most recent track or album releases of an artist is by the focal label)\n')
cat('byshare_half: track label classified if at least half of the contributing artists are from focal label\n')
cat('              (artist label = at least 50% of an artist\'s tracks are by the focal label)\n')

for (.v in grep('(^ml|^sony|^universal|^warner)', colnames(placements),value=T)) cat(.v,fill=T)


cat('\n')
cat('ntracks                        Number of tracks available on playlist', fill=T)
cat('nadded                         Number of tracks added to playlist at date', fill=T)
cat('nremoved                       Number of tracks removed from the playlist at date (still considered available that day)', fill=T)
cat('\n')
cat('ntracksotherpl                 Average number of other playlists that tracks on focal playlist are listed on (track popularity proxy)', fill=T)
cat('spotify_popularity             Average Spotify popularity score of tracks on playlist at date', fill=T)
cat('\n')
cat('trackage                       Average number of days since release of tracks on playlist', fill=T)
cat('tracklength_sec                Average duration (in sec) of tracks on plalyist at date', fill=T)
cat('\n')
cat('ac_danceability                Average of acoustic attribute [...] of tracks on playlist', fill=T)
cat('ac_energy                      Average of acoustic attribute [...] of tracks on playlist', fill=T)
cat('ac_speechiness                 Average of acoustic attribute [...] of tracks on playlist', fill=T)
cat('ac_acousticness                Average of acoustic attribute [...] of tracks on playlist', fill=T)
cat('ac_valence                     Average of acoustic attribute [...] of tracks on playlist', fill=T)
cat('ac_tempo                       Average of acoustic attribute [...] of tracks on playlist', fill=T)
cat('ac_loudness                    Average of acoustic attribute [...] of tracks on playlist', fill=T)
cat('\n')

cat('The following variables summarize the social media performance (followers) of artists associated\n')
cat('with tracks on a playlist.\n')
cat('_curr:                  artists *currently* listed on focal playlist\n')
cat('_all:                   artists that were or will ever be listed on focal playlist\n')
cat('_ml:                    artists that were or will ever be listed on focal playlist, and that are associated with a major label (at least one track by label)\n')
cat('_sony/universal/warner: artists that were or will ever be listed on focal playlist, and that are associated with focal label (at least one track by label)\n')
cat('_ml3:                   artists that were or will ever be listed on focal playlist, and that are associated with a major label (at least one of most recent 3 releases by label)\n')
cat('_sony3/...:             artists that were or will ever be listed on focal playlist, and that are associated with focal label (at least one of most recent 3 releases by label)\n')
cat('_mlbyshare:             artists that were or will ever be listed on focal playlist, and that are associated with a major label (at least half of artists\' tracks releases by label)\n')
cat('_sonybyshare/...:       artists that were or will ever be listed on focal playlist, and that are associated with focal label (at least half of artists\' tracks releases by label)\n')
cat('\n')
cat('The variables further report on six statistics: _N (number of artists over which aggregation is done),\n')
cat('_sum (sum of followers), _am/_gm (arithmetic or geometric mean of followers), _dsum (sum of differences\n')
cat('of followers), and _dam (arithmetic mean of differences of followers; gm not available).\n')
cat('\n')
for (.v in grep('^fan.*[_]curr[_].*$', colnames(placements),value=T)) cat(.v,fill=T)
cat('\n')


cat('The following variables characterize the extent to which Spotify recommends content via\n')
cat('three types of (semi)-personalized playlists:\n')
cat('recfully:   fully personalized playlists (those listed in the "Made for You" section; e.g., Discover Weekly)\n')
cat('recsemi:    semi-personalized playlists (editorial playlists that adapt content to user; like "Songs to Sing in the Shower")\n')
cat('recartist:  artist-based playlists ("This is...", "...Radio" playlists\n')
cat('\n')

cat('The variables further report on several statistics:\n')
cat('_nplaylists:            Number of playlists identified in a category on day\n')
cat('_nadded:                Number of tracks added to recommendation lists on a day\n')
cat('                        (suffix indicates label type of content; no suffix = all tracks added/recommended)\n')
cat('_ntracks:               Number of tracks available on recommendation lists on a day\n')
cat('                        (suffix indicates label type of content; no suffix = all tracks available)\n')
cat('_flwrs_am/gm:           Arithmetic (geometric) mean of followers of all nplaylists in this recommendation category\n')
cat('_flwrs_sum:             Sum of followers of all nplaylists in this recommendation category\n')
cat('\n')
for (.v in grep('^rec', colnames(placements),value=T)) cat(.v,fill=T)
cat('\n')

sink()


#cor(data.frame(placements$fans_mlartists_deezer,placements$fans_mlartists_instagram, placements$user_globalmlshare, placements$user_clustermlshare, placements$mlshare), use = 'pairwise')
 
