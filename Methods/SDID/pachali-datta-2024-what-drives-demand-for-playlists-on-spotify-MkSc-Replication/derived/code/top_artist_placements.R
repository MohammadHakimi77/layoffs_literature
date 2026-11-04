# goal: create an indicator variable for the *addition* of "superstar" artists
# on a playlist (i.e., varying by artist, playlist and date).
# this can then be used in a similar quasi experimental design like done in 
# https://github.com/hannesdatta/platformpower/blob/master/analysis/code/compare_promoted.R


library(stringr)
library(data.table)

# 1. Determine top artists
billboard <- fread('../externals/kaggle/billboardHot100_1999-2019.csv', select = c('Artists', 'Name', 'Weekly.rank','Peak.position', 'Weeks.on.chart', 'Week'))
spotify <- fread('../externals/kaggle/spotifyWeeklyTop200Streams.csv')

billboard_artists = billboard[Weekly.rank<=10&Week>=as.Date('2019-01-01')&Week<=as.Date('2019-07-06')][, list(max_weeks=max(Weeks.on.chart,na.rm=T)),by=c('Artists')][, billboard_top10:=T]
billboard_artists[Artists=='Lil Nas,', Artists:='Lil Nas X']
billboard_artists[Artists=='Lil Nas', Artists:='Lil Nas X']
billboard_artists_old = billboard[Weekly.rank<=10&Week>=as.Date('1999-01-01')&Week<=as.Date('2003-12-31')][, list(max_weeks=max(Weeks.on.chart,na.rm=T)),by=c('Artists')][, billboard_top10:=T]
billboard_artists_old[Artists=='Lil Nas', Artists:='Lil Nas X']
setorderv(spotify, c('Week', 'Streams'), order=c(1L,-1L))
spotify[, Weekly.rank:=1:.N,by=c('Week')]

spot_artists = spotify[Weekly.rank<=10&Week>=as.Date('2019-01-01')&Week<=as.Date('2019-07-06')][, list(.N),by=c('Artist')][, spotify_top10:=T]


tmp = merge(billboard_artists[, list(artist=unique(tolower(str_trim(unlist(strsplit(Artists, ','))))), billboard=T)],
            spot_artists[, list(artist=unique(tolower(str_trim(unlist(strsplit(Artist, ','))))), spotify_top10=T)],
            by=c('artist'), all.x=T, all.y=T)
tmp = merge(tmp,
            billboard_artists_old[, list(artist=unique(tolower(str_trim(unlist(strsplit(Artists, ','))))), billboard_old=T)],
            by=c('artist'), all.x=T, all.y=T)

tmp[artist=='celine dion', artist:='céline dion']
tmp[artist=='beyonce', artist:='beyoncé']
tmp[artist=="cam\'ron", artist:='cam’ron']
tmp[artist=="deborah cox with r.l.", artist:='deborah cox']
tmp[artist=="jagged edge with nelly", artist:='jagged edge']
tmp[grepl('n sync', artist), artist:='*nsync']
tmp[artist=="98 degrees", artist:='98º']
tmp[artist=="p. diddy", artist:='pdiddy']
tmp[artist=='pharrell', artist:='pharrell williams']
tmp[artist=='the black eyed peas', artist:='black eyed peas']
tmp[grepl('missy.*elliott', artist), artist:='missy elliott']




tmp[, top_id:=1:.N]

# search for matches?
artists <- fread('../output/artist-labels.csv')

artists[, lartistname:=tolower(artist_name)]


top_artists=merge(tmp, artists, by.x=c('artist'), by.y=c('lartistname'), all.x=T, all.y=F)
setorder(top_artists, top_id, cm_artist)

fwrite(top_artists, '../output/top_artists.csv')

# 2. Load placement data

# Load placement data
prototype = file.exists('prototype')

if (file.exists('cluster')) core_count=12

nrows = -1L
prototype= F
if (prototype==T) nrows = 1E6

agg_type = 'placements'
source('aggregate_setup.R')

setkey(placements, id, track_id, added_at, removed_at)

if(0){
  
# Compute a metric if "previous" popularity (number of playlists an artist has been on)
init_start = as.Date('2019-01-01')
init_end = as.Date('2019-10-01')

placements[, days_on_list:=as.numeric(pmin(removed_at,init_end,na.rm=T)-pmax(added_at, init_start,na.rm=T))]

by_combined_artist = placements[added_at>=init_start &(is.na(removed_at)|removed_at>=init_end),
  list(cm_artist_ids=as.numeric(unlist(strsplit(cm_artist, '[|]'))), sumdays = sum(days_on_list,na.rm=T)), by = c('id','cm_artist')][, N:=.N,by=c('id','cm_artist')]

by_single_artist = by_combined_artist[, list(sumdays=sum(sumdays),
                                             unique_playlists=uniqueN(id)),by=c('cm_artist_ids')]

setorderv(by_single_artist, 'sumdays', order=-1L)
setorderv(by_single_artist, 'unique_playlists', order=-1L)

# check negatives here...

# better metric for superstar?

# follower reach
superstars = merge(by_single_artist[1:200], all_artists,by.x=c('cm_artist_ids'),by.y=c('cm_artist'), all.x=T, all.y=F)

}

# 3. For artists identified above, identify when songs were added or removed

# Analysis period
analysis_start = as.Date('2019-11-01')
analysis_end = as.Date('2020-04-01')

#selected_placements = placements[cm_artist%in%top_artists$cm_artist & added_at >= analysis_start & (is.na(removed_at)|removed_at>analysis_end)]

selected_placements = placements[cm_artist%in%top_artists$cm_artist & added_at >= analysis_start & added_at <= analysis_end]# & (is.na(removed_at)|removed_at>analysis_end)]

selected_placements[, days_on_list:=as.numeric(pmin(removed_at,analysis_end,na.rm=T)-pmax(added_at, analysis_start,na.rm=T))]

# events
fwrite(selected_placements, '../output/top_artists_placements.csv')