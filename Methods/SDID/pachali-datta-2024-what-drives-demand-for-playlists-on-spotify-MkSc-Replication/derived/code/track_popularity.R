library(stringr)
library(data.table)


# Load placement data
prototype = file.exists('prototype')
 
nrows = -1L
prototype= F
if (prototype==T) nrows = 1E6

agg_type = 'placements'
source('aggregate_setup.R')

setkey(placements, id, track_id, added_at, removed_at)

playlists<-fread('../output/playlists.csv',key='id')

setkey(placements, id)
placements[playlists, followers:=i.followers]

# Compute a metric if "previous" popularity (number of playlists an artist has been on)
init_start = as.Date('2019-10-01')
init_end = as.Date('2020-04-01')

dates <- seq(from=init_start,to=init_end+7,by='7 days')

popularity <- rbindlist(lapply((1:(length(dates)-1)), function(i) {
iter_date_start = dates[i]
iter_date_end = dates[i+1]

tmp=placements[added_at<=iter_date_end & (is.na(removed_at) | removed_at > iter_date_start)]

tmp2=tmp[, list(followers=mean(followers,na.rm=T)),by=c('track_id','id')][, list(nplaylists=.N,
                                                                                 followers_mean=mean(followers,na.rm=T),
                                                                                 followers_max=max(followers,na.rm=T),
                                                                                 followers_min=min(followers,na.rm=T),
                                                                                 followers_sum=sum(followers,na.rm=T),
                                                                                 followers_median=median(followers,na.rm=T)),by=c('track_id')][, ':=' (date_begin=iter_date_start, date_end=iter_date_end)]
setcolorder(tmp2, c('track_id', 'date_begin','date_end'))
return(tmp2)
}))

# average popularity

# what about zeros?

# Create a reference data.table with all possible combinations of track_ids and dates
all_track_ids <- unique(popularity$track_id)

reference_dt <- CJ(track_id = all_track_ids, date_begin = dates[-length(dates)])

# Left join the reference data.table with the original data.table
result_dt <- popularity[reference_dt, on = c("track_id", "date_begin")]
result_dt[is.na(nplaylists), nplaylists:=0]
result_dt[is.na(followers_sum ), followers_sum :=0]


popularity2 = result_dt[, list(nplaylists_median=median(nplaylists),
                                followers_median=median(followers_sum)),by=c('track_id')]

# write files
fwrite(popularity, '../temp/track_popularity_raw.csv')
fwrite(popularity2, '../temp/track_popularity.csv')
