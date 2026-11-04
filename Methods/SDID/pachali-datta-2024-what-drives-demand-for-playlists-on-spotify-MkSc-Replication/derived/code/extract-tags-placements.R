library(data.table)
library(stringr)

prototype = F

nrows = -1L

if (prototype==T) nrows = 1E6

fns <- c('../output/placements.csv') #, '../output/placements-below150k.csv', '../output/placements-recommendations.csv')

placements <- rbindlist(lapply(fns, fread, encoding='UTF-8', select = c('id','added_at', 'removed_at','track_id','track_genre'),
                       nrows = nrows))

placements <- unique(placements, by=c('id','added_at','removed_at','track_id'))


playlists <- fread(file = "../externals/all-playlists.csv", encoding = 'UTF-8', sep='\t', quote = "", na.strings=c('NA', 'None'),
                   select = c('id', 'followers', 'genre'))

playlists <- unique(playlists, key=c('playlist_id'))

playlists[followers<0, followers:=0]

# Compute follower rank
setorderv(playlists, 'followers', order=-1L, na.last=T)
playlists[, followerrank:=1:.N]

# keep data for +/- 4 weeks of observation sample
begin_inits = seq(from=as.Date('2019-08-26'), to = as.Date('2020-05-04'), by = '1 week')

time_windows = lapply(1:(length(begin_inits)-1), function(x) list(begin_init=begin_inits[x], end_init=begin_inits[x+1]-1))

placements <- placements[(is.na(removed_at)|removed_at>=min(begin_inits))&added_at<=max(begin_inits)]

placements[, track_genre:=gsub('[|]',',', track_genre)]
placements[, track_genre:=gsub('\"|[{]|[}]', '', track_genre)]
placements[, track_genre:= str_trim(gsub('[-]', ' ', track_genre))]
placements[, track_genre:= gsub(' ', '', gsub('-', '', track_genre))]
placements[, track_genre:= gsub('[&]', '', gsub('[/]', '', track_genre))]

tags_dynamic = rbindlist(lapply(time_windows, function(window) {

  begin_init = window$begin_init 
  end_init = window$end_init 

  cat(paste0('Working on time window starting ', begin_init),fill=T)
  # filter for time window
  placements_upd <- placements[(is.na(removed_at)|removed_at>=begin_init)&added_at<=end_init]

  placements_upd[, span_begin := pmax(added_at, begin_init, na.rm=T)]
  placements_upd[, span_end := pmin(removed_at, end_init, na.rm=T)]
  placements_upd[, days_on_playlist := as.numeric(difftime(span_end,span_begin, units='days'))+1]
  
  # split up tag words
  sum_days = placements_upd[, list(ntracks = .N, sum_days = sum(days_on_playlist)), by = c('id','track_genre')][, ':=' (begin_init=begin_init, end_init=end_init)]
  split_tags = sum_days[, list(tag=strsplit(track_genre, ',')[[1]]), by =c('id','track_genre','sum_days','ntracks', 'begin_init', 'end_init')]
  
  # remove NA tracks
  split_tags <- split_tags[!is.na(tag)]
  split_tags <- split_tags[!tag=='']
  
  split_tags_sum = split_tags[, list(sum_days=sum(sum_days)),by=c('id','tag','begin_init','end_init')]
  setorderv(split_tags_sum, c('id', 'sum_days'), order=c(1L,-1L))
  
  split_tags_sum[, top_n:=1:.N,by=c('id')]
  
  return(split_tags_sum) 
}))

fwrite(tags_dynamic, '../temp/tags-placements.csv')

#######################################################
### Comparison of dynamic genres with static genres ###
#######################################################


if(0) {
library(data.table)
library(readr)
tags_dynamic <- data.table(read_csv("../temp/dynamic_genres_tracks.csv"))

# extract dynamic tag words
  
  # separate out playlist genres/tags
  split_tags = tags_dynamic[begin_init>=as.Date('2019-07-01') & top_n<=10, list(id=id, tag=tag, tagrank=top_n, group=.GRP),by=c('begin_init')]
  
  setkey(split_tags, id)
  setkey(playlists, id)
  
  split_tags[playlists, ':=' (followerrank=i.followerrank, followers=i.followers)]
  setcolorder(split_tags, c('id', 'group', 'begin_init', 'tag'))
  split_tags[, tagid := .GRP,by=c('tag')]
  split_tags[, tagimportance:=(max(tagrank)-tagrank)+1, by = c('group','begin_init','id')]
  
  # Distribution of tag words
  tags_summary=split_tags[, list(N=.N),by=c('group','begin_init','tagid','tag')]
  tags_summary[, cumN:=cumsum(N)]
  tags_summary[, percentile:=cumN/sum(N)]
  setorderv(tags_summary, c('group','N'), order=c(1L, -1L))

  void <- lapply(split(split_tags, split_tags$group), function(x) fwrite(x[, tag:=NULL], paste0('../output/tags-placements-group-', unique(x$group), '.csv')))
  void <- lapply(split(tags_summary, tags_summary$group), function(x) fwrite(x, paste0('../output/tags-placements-meta-group-', unique(x$group), '.csv')))
  
# extract static genres for comparison
split_tags_pl = playlists[, list(tag=strsplit(genre, ',')[[1]]), by =c('id', 'followerrank','followers')]
split_tags_pl[, tagrank:=1:.N,by=c('id')]
split_tags_pl = split_tags_pl[!is.na(tag)]
split_tags_pl[, tagid := .GRP,by=c('tag')]
split_tags_pl[, tagimportance:=(max(tagrank)-tagrank)+1, by = 'id']
setkey(split_tags_pl, id)
setkey(playlists, id)
split_tags_pl[playlists, ':=' (followerrank=i.followerrank, followers=i.followers)]
setcolorder(split_tags_pl, c('id','followers','followerrank'))


#### Comparison between number of playlists with genres
  
  setkey(playlists, id)
  
  top_genres_static = split_tags_pl[tagrank<=10, list(top_genres=paste(tag, collapse = ', ')),by=c('id')]
  top_genres_dynamic = split_tags[tagrank<=10, list(top_genres=paste(tag, collapse = ', ')),by=c('id')]
  
  setkey(top_genres_static, id)
  setkey(top_genres_dynamic, id)
  
  
  playlists[top_genres_static, genre_static:=i.top_genres]
  playlists[top_genres_dynamic, genre_dynamic:=i.top_genres]
  
  void <- with(playlists, table(static_genre_available = !is.na(genre_static), dynamic_genre_available = !is.na(genre_dynamic), ))
  void
  # static genre available
  rowSums(void)
  # dynamic genre available 
  colSums(void)
  
  # dynamic extraction just adds 2249 keywords....
  
#### Comparison between genres early vs. late
split_tags[, group_count:=uniqueN(group),by=c('id')]
same_tags = split_tags[tagrank<=10 & group_count==2][, list(count = .N),by=c('id','followerrank','followers','tag')][, mean_count := as.numeric(mean(count==2)),by=c('id')]
tmp=same_tags[, list(mean=mean(count==2)),by=c('id', 'followerrank','followers')]

hist(tmp$mean) # --> most are the same
summary(tmp$mean) # --> 93% are the same.

tmpplot = rbindlist(lapply(seq(from=0, to=1, by=.01), function(x) data.table(similarity = x, N=nrow(tmp[mean>=x]))))
plot(tmpplot$similarity, tmpplot$N, xlab = 'Similarity is at least...')


# among top
hist(tmp[followerrank<=30000]$mean) # --> most are the same
summary(tmp[followerrank<=30000]$mean) # --> 90% are the same.

# among very top
hist(tmp[followerrank<=10000]$mean) # --> most are the same
summary(tmp[followerrank<=10000]$mean) # --> 90% are the same.

# among very top
hist(tmp[followerrank<=1000]$mean) # --> most are the same
summary(tmp[followerrank<=1000]$mean) # --> 90% are the same.

}
