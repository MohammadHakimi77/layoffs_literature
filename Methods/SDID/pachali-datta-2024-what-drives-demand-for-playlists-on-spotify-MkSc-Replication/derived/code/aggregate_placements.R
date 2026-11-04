library(data.table)
library(parallel)

core_count=5


####################
# LOAD COMMON DATA #
####################

prototype = file.exists('prototype')

if (file.exists('cluster')) core_count=22

nrows = -1L
prototype= F
if (prototype==T) nrows = 1E6

agg_type = 'placements'
source('aggregate_setup.R')

setkey(placements,track_id)
track_popularity <- fread('../temp/track_popularity.csv',key='track_id')
placements[track_popularity, ':=' (trackpop_nplaylists=nplaylists_median,
                                   trackpop_followers=followers_median)]

setkey(placements, id, track_id, added_at, removed_at)



##############################
# Major-label classification #
##############################

# Track-level classification
tracks <- fread('../output/track-labels.csv',nrows=10)
tracks <- fread('../output/track-labels.csv', select = grep('track|curr$', colnames(tracks),value=T))

# Loading data on collaborations
colabs <- fread('../temp/extract-collaborations.csv')

winsorize <- function(x, q=.999) {
  res=x
  res[x>=quantile(x,q)]<-quantile(x,q)
  return(res)
}

# Remove "various artists"
colabs <- colabs[!is.na(date)&!cm_artist_id%in%c(1,10)]

# Winsorize remaining observations
colabs=cbind(colabs[, 1:2,with=F], colabs[, lapply(.SD, winsorize), .SDcols=grep('cum', colnames(colabs),value=T)])

# Generate mapping between track IDs to artist IDs
all_artist_ids = suppressWarnings(placements[, list(cm_artist=as.numeric(unique(unlist(strsplit(cm_artist, '|',fixed=T))))), by =c('track_id')])

#############
# AGGREGATE #
#############

# Function to aggregate playlist-date-song-addition-removal data to the playlist-(category)-date level.
calcLine <- function(iter_date) {
  
  cat(paste0('Merging initial data for date: ', iter_date, '...\n'))
  # Filter data for only tracks that are currently listed on the playlist at `iterdate`
  tmp=node_placement[added_at<=iter_date&(removed_at>iter_date|is.na(removed_at))][, date:=iter_date]
  
  # Get count of tracks that were REMOVED on the particular day
  tmp_removed=node_placement[removed_at==iter_date][, date:=iter_date][, list(nremoved=.N),by=c('id', 'date')]
  
  setkey(tmp, track_id)
  setkey(tracks,track_id)
  tmp[tracks, ':='(ml_curr=i.ml_curr, sony_curr=i.sony_curr, warner_curr=i.warner_curr,universal_curr=i.universal_curr)]
  
  # build list of major label share variables
  aggvars = NULL
  for (.v in c('%_curr')) {
    aggvars=c(aggvars,sapply(c('ml','sony','universal','warner'), function(.lbl) gsub('[%]', .lbl, .v)))
  }
  aggvars = aggvars[aggvars%in%colnames(tracks)]
  
  # Merge artist IDs (by track) to playlist-date-track data
  stopifnot(key(tmp)=='track_id')
  setkey(all_artist_ids, track_id)
  
  extracted_artist_ids=all_artist_ids[tmp[, c('id','track_id','date')]][!is.na(cm_artist)]
  setcolorder(extracted_artist_ids, c('id','track_id','date'))

  # merge cumulative number of colaborations
  setkey(extracted_artist_ids, cm_artist, date)
  setkey(colabs, cm_artist_id, date)
  colabs_joined=colabs[extracted_artist_ids, roll=T][!is.na(cm_artist_id)]
  tmp_colabs = colabs_joined[, lapply(.SD, mean, na.rm=T), by = c('id', 'date'), .SDcols=grep('cumn|cumu',colnames(colabs_joined),value=T)]
  for (.v in grep('cum', colnames(tmp_colabs),value=T)) setnames(tmp_colabs, .v, paste0('rel', .v))  
  
  # prepare fan data
    # merge label affiliations
    setkey(extracted_artist_ids, 'track_id')
    stopifnot(key(tracks)=='track_id')
    tmp_fans <- tracks[extracted_artist_ids][!is.na(cm_artist)]
    
  # merge fan data
    setkey(tmp_fans, date, cm_artist)
    setkey(node_fans, date, cm_artistid)
    tmp_fans[node_fans, ':=' (curr=T, `fans-instagram`=`i.fans-instagram`, `fans-deezer`=`i.fans-deezer`)]
    
 # impute missing data - mean of #followers of artists at the same label 
  for (.v in c('fans-instagram', 'fans-deezer')) {
    tmp_fans[, tmpvar:=get(.v)]
    tmp_fans[, paste0(.v, '-imp') :=  ifelse(is.na(tmpvar), mean(tmpvar,na.rm=T),
                                           tmpvar), by = c('date', 'ml_curr','sony_curr','warner_curr','universal_curr')]
    tmp_fans[, tmpvar:=NULL]
  }
  
  merge.all <- function(x,y, ...) {merge(x,y, all.x=T,all.y=T,...)}
  
  fans_agg_tmp = lapply(c('fans-instagram', 'fans-instagram-imp', 'fans-deezer', 'fans-deezer-imp'), function(.var) { 
    cat(paste0('Calculating fans for ', .var, '...\n'))
    tmp_fans[, var:=get(.var)]
    tmp_fans[, isnavar:=is.na(var)]
    
    tmp_x1 = lapply(c('curr', aggvars[1]), function(.agg) {
      tmp_fans[, aggvar:=get(.agg)]
      
      tmp_x2 <- lapply(c(T, F), function(.filter) {
        cat('.')
        tmp_x=tmp_fans[aggvar==.filter]
        sum_notna=sum(tmp_x$isnavar==F)
        
        # retain only unique artists
        if (sum_notna>0) tmp_x[, selected:=1:.N%in%match(cm_artist, cm_artist), by = c('id','date')] else tmp_x[, selected:=T]
        
        ret = tmp_x[selected==T, list(N = .N,
                                       NNA = length(which(isnavar)),
                                       sum = as.numeric(sum(var,na.rm=T))),by=c('id', 'date')][, am:=sum/(N-NNA)]
        
        setnames(ret, c('id','date', paste0(.var, '_', ifelse(.filter==F, 'not', ''),.agg, '_', colnames(ret)[-c(1:2)])))
        setkey(ret, id, date)
        if (.agg=='curr' & .filter==F) return(data.table())
        return(ret)
    })
      
      tmp_x2_merged=Reduce(merge.all, tmp_x2[unlist(lapply(tmp_x2, nrow))>0])
      setkey(tmp_x2_merged, id, date)
      
      return(tmp_x2_merged)
    })
  cat('\n')
  tmp_x1_merged=Reduce(merge.all, tmp_x1)
  setkey(tmp_x1_merged, id, date)
  return(tmp_x1_merged)
  
  })
  
  fans_agg = Reduce(merge.all, fans_agg_tmp)
  
  # if total number of observed artists on a list is zero, set sum/am/gm to zero 
  for (.v in grep('[_]N$', colnames(fans_agg),value=T)) {
    for (.v2 in c('_NNA', '_sum', '_am', '_N')) fans_agg[is.na(get(.v)), paste0(gsub('_N$', .v2, .v)):=0]
  }
  
  # if all artist data is MISSING, set to zero those metrics that were not imputed
  .iters=grep('[-]imp', grep('[_]N$', colnames(fans_agg),value=T), invert=T, value=T)
  
  for (.v in .iters) {
    for (.v2 in c('_sum', '_am', '_gm')) fans_agg[get(.v)==get(paste0(.v, 'NA')), paste0(gsub('_N$', .v2, .v)):=0]
  }
  
  # end fans

  cat('Releases...\n')
  # Playlist-level covariates, aggregated from the placement data
  tmp[, trackage:=as.numeric(date-release_dates)]
  
  # Time-since-release
  tmp[, trackage1:=trackage<1]
  tmp[, trackage7:=trackage<7]
  tmp[, trackage28:=trackage<28] # 4 weeks
  
  # merge (dynamic) categories
  tmp_categories = dyncategories[iter_date>=begin_init & iter_date <= end_init]
  setkey(tmp_categories, id)
  setkey(tmp, id)
  tmp[tmp_categories, ':=' (cat_id=i.cat_id, withincat_msrank=i.withincat_msrank)]
  
  # Extract only newly released tracks
  tmprel = tmp[trackage28==T][, grep('date|id$|cat_id|withincat_msrank|track_id|trackage[0-9].*', colnames(tmp),value=T), with = F] # all "new" tracks (to some degree at least)
  
  # We need to extend this with a list of "ghost" tracks for each playlist -- we leave them out later, but 
  # require it to compute the releases for playlists WITHOUT released tracks, but where tracks in a category
  # have been newly released.
  ghost_tracks = unique(tmp[, c('id', 'cat_id', 'date'),with=F], by=  c('id'))[, track_id:=-1]
  
  tmprel = rbindlist(list(ghost_tracks, tmprel),fill=T)
  
  nunique=function(x) length(unique(x))
  
  agg_releases1=tmprel[, list(relfocal_1 = nunique(track_id[which(trackage1==T)]),
                                     relfocal_7 = nunique(track_id[which(trackage7==T)]),
                                     relfocal_28 = nunique(track_id[which(trackage28==T)])),by=c("id", "cat_id", "date")]
  agg_releases2=tmprel[, list(relfocalcat_1 = nunique(track_id[which(trackage1==T)]),
                              relfocalcat_7 = nunique(track_id[which(trackage7==T)]),
                              relfocalcat_28 = nunique(track_id[which(trackage28==T)])),by=c("cat_id", "date")]
  
  # We need to compare all released tracks on a playlist with all other tracks released in a category on that particular day
  tmprel_crossed=merge(tmprel, tmprel[track_id>0 & withincat_msrank <= 10], allow.cartesian = T, by = c('cat_id', 'date'))
  
  #system.time({for (i in 1:10) length(unique(tmprel_crossed$track_id.x))})
  #system.time({for (i in 1:10) uniqueN(tmprel_crossed$track_id.x)})
  #system.time({for (i in 1:10) nunique(tmprel_crossed$track_id.x)})
  #system.time({for (i in 1:1000) length(unique(x))})
  
  agg_releases3=tmprel_crossed[, list(relfocaltop10_1 = nunique(c(track_id.x[which(trackage1.x==T)], track_id.y[which(trackage1.y==T)])),
              relfocaltop10_7 = nunique(c(track_id.x[which(trackage7.x==T)], track_id.y[which(trackage7.y==T)])),
              relfocaltop10_28 = nunique(c(track_id.x[which(trackage28.x==T)], track_id.y[which(trackage28.y==T)]))),by=c("id.x", "date")]
  setnames(agg_releases3, 'id.x','id')
  
  agg_releases= merge(agg_releases1, agg_releases2, by = c('cat_id','date'),all.x=T)
  
  setkey(agg_releases, id, date)
  setkey(agg_releases3, id, date)
  
  agg_releases = agg_releases3[agg_releases]
  agg_releases[is.na(agg_releases)]<-0
  agg_releases[, cat_id:=NULL]
  
  rm(agg_releases1, agg_releases2, agg_releases3, tmprel_crossed, tmprel, ghost_tracks)
  
  # Continue w/ operationalizing variables
  cat('Content popularity...\n')
  tmp[, ntracks:=.N,by=c('id','date')]
  tmp[, paste0('ntracks_', aggvars) := lapply(.SD, function(x) length(which(x))), by = c('id', 'date'), .SDcols=aggvars]
  
  set.seed(1234)
  tmp[, ntracksotherpl:=.N-1, by =c('track_id','date')] 
  
  tmp[, rank_ntracksotherpl := rank(-ntracksotherpl, ties.method='random'), by = c('id', 'date')]
  
  # ntracksotherpl for tracks that were added no less than 7, 14, ... days ago.
  tmp[, addedage:=as.numeric(date-added_at)]
  days= c(7,14,28,28*3)
  for (.d in days) tmp[, paste0('addedage_', .d):=addedage<=.d]
  tmp[, paste0('ntracksotherpl', days):=lapply(.SD, sum), by = c('track_id', 'date'), .SDcols=paste0('addedage_', days)]
  for (.d in days) tmp[, paste0('ntracksotherpl', .d):=get(paste0('ntracksotherpl', .d)) - as.numeric(addedage<=.d)]
 
  tmp[, ntracksotherpl_top10 := ifelse(rank_ntracksotherpl<=10, ntracksotherpl, NA)]
  tmp[, ntracksotherpl_top20 := ifelse(rank_ntracksotherpl<=20, ntracksotherpl, NA)]
  
  tmp[, universal_top10share := ifelse(rank_ntracksotherpl<=10, universal_curr, NA)]
  tmp[, universal_top20share := ifelse(rank_ntracksotherpl<=20, universal_curr, NA)]
  
  tmp[, warner_top10share := ifelse(rank_ntracksotherpl<=10, warner_curr, NA)]
  tmp[, warner_top20share := ifelse(rank_ntracksotherpl<=20, warner_curr, NA)]

  tmp[, sony_top10share := ifelse(rank_ntracksotherpl<=10, sony_curr, NA)]
  tmp[, sony_top20share := ifelse(rank_ntracksotherpl<=20, sony_curr, NA)]
  
  tmp[, ml_top10share := ifelse(rank_ntracksotherpl<=10,ml_curr,NA)]
  tmp[, ml_top20share := ifelse(rank_ntracksotherpl<=20,ml_curr,NA)]
  
  tmp[, curr:=T]
  
  cat('Number of tracks on label...\n')
  
  # ntracks (on label)
  ntracks_on_label = tmp[, lapply(.SD, function(x) mean(ntracksotherpl[x==T], na.rm=T)), by = c('date','id'), .SDcols = c('curr', aggvars)]
  ntracks_on_label = ntracks_on_label[, lapply(.SD, function(x) ifelse(is.na(x), 0, x)), by = c('date','id')]
  setnames(ntracks_on_label, c('id','date', paste0('ntracksotherpl_', c('curr', aggvars))))
  
  # ntracks (not on label)
  ntracks_noton_label = tmp[, lapply(.SD, function(x) mean(ntracksotherpl[x==F], na.rm=T)), by = c('date', 'id'), .SDcols = aggvars]
  ntracks_noton_label = ntracks_noton_label[, lapply(.SD, function(x) ifelse(is.na(x), 0, x)), by = c('date', 'id')]
  setnames(ntracks_noton_label, c('id','date', paste0('ntracksotherpl_not', aggvars)))
  tmp[, curr:=NULL]
  
  tmp[, ':=' (nadded = length(which(date==added_at))), by = c('id', 'date')]
  
  setkey(tmp, id, date)
  setkey(tmp_removed, id, date)
  tmp[tmp_removed, nremoved:=i.nremoved]
  tmp[is.na(nremoved), nremoved:=0]
  
  cat('Aggregation...\n')
  
  acc_attrib = c('danceability', 'energy','speechiness','acousticness',
  'instrumentalness','liveness','valence',
  'tempo','loudness')
  
  # check if all acoustic attributes are 0 --> set to NA
  tmp[, sumfaccattr:=rowSums(.SD), .SDcols=acc_attrib]
  for (.v in acc_attrib) tmp[sumfaccattr==0, (.v):=NA]
  
  tmp[, tracklength_sec:=spotify_duration_ms/1000]
  
  agg=tmp[, lapply(.SD,mean,na.rm=T), by=c('id','cat_id','date'), .SDcols=c(aggvars,
                                                                   'ntracks', 
                                                                   'nadded', 
                                                                   'nremoved',
                                                                   'ntracksotherpl', 
                                                                   grep('ntracksotherpl[0-9]', colnames(tmp), value=T), # no
                                                                   'ntracksotherpl_top10',
                                                                   'ntracksotherpl_top20',
                                                                   'ml_top10share',
                                                                   'ml_top20share',
                                                                   'universal_top10share',
                                                                   'universal_top20share',
                                                                   'sony_top10share',
                                                                   'sony_top20share',
                                                                   'warner_top10share',
                                                                   'warner_top20share',
                                                                   'trackage', # YES
                                                                   'tracklength_sec', # YES
                                                                   acc_attrib)]
  for (.v in acc_attrib) setnames(agg, .v, paste0('ac_', .v))
  
  
  # weighted covariates
  wagg = lapply(c('nplaylists','followers'), function(.w) {
    if (.w=='nplaylists') tmp[, logw:=log(trackpop_nplaylists+1)]
    if (.w=='followers') tmp[, logw:=log(trackpop_followers+1)]
    
    tmp[, sum_weights:=sum(logw),by=c('id','date')]
    tmp[, logw_used:=logw]
    tmp[sum_weights==0, logw_used:=1]
    
    wtmp <- tmp[, lapply(.SD, function(x) weighted.mean(x, w = logw_used, na.rm = TRUE)),
                by = c('id', 'cat_id', 'date'),
                .SDcols = c(aggvars, 'trackage', 'tracklength_sec', acc_attrib)]
    for (.v in acc_attrib) setnames(wtmp, .v, paste0('ac_', .v))
  for (.v in setdiff(colnames(wtmp), c('id','cat_id','date'))) setnames(wtmp, .v, paste0('w', .w, '_', .v))
    return(wtmp)
  })
  
  wagg_combined = Reduce(function(x,y) merge(x,y,by=c('id','cat_id','date')), wagg)
  
  
  cat('Merging...\n')
  
  agg <- merge(agg, wagg_combined, by = c('id','cat_id', 'date'),all.x=T)
  
  agg <- merge(agg, fans_agg, by = c('id','date'),all.x=T)
  
  agg <- merge(agg, ntracks_on_label, by = c('id','date'), all.x=T)
  
  agg <- merge(agg, ntracks_noton_label, by = c('id','date'), all.x=T)
  
  agg <- merge(agg, tmp_colabs, by = c('id','date'), all.x=T)
  
  agg <- merge(agg, agg_releases, by = c('id','date'), all.x=T)
  
  setorder(agg, id,date)
  rm(tmp, fans_agg, tmp_fans, tmp_colabs, colabs_joined, ntracks_on_label, ntracks_noton_label, agg_releases, wagg, wagg_combined)
  return(agg)
}


# Test main aggregation function (prototyping)
if (0) {
  iter_date=as.Date('2019-10-29')
  node_placement = placements[added_at<=iter_date&(removed_at>=iter_date|is.na(removed_at))]
  node_fans = fans[date>=iter_date&date<=iter_date]
  
  system.time({test<-calcLine(iter_date)})
}


######################
# INITIALIZE CLUSTER #
######################

cl <- makePSOCKcluster(core_count)

void<-clusterEvalQ(cl, library(data.table))

node_alloc = rep(1:core_count, length.out=length(dates_series))
node_alloc = node_alloc[order(node_alloc)]

split_dates <- split(dates_series, node_alloc)

calcFull <- function(dates) { rbindlist(lapply(dates, calcLine))}

# create derivates, send to cluster
for (node in seq(along=split_dates)) {
  print(node)
  print('filtering')
  node_dates = split_dates[[node]]
  node_placement <<- placements[added_at<=max(node_dates)&(removed_at>min(node_dates)|is.na(removed_at))]
  node_fans <<- fans[date>=min(node_dates)&date<=max(node_dates)]
  
  #tracks <<- tracks
  
  print('writing')
  clusterExport(cl[node], c('node_placement', 'tracks', 'node_fans', 'colabs', 'all_artist_ids','dyncategories'))
  rm(node_placement)
  gc()
}


clusterExport(cl, c('calcLine', 'calcFull'))

###################################
# EXECUTE AGGREGATION IN PARALLEL #
###################################

#split_dates[[1]] <- split_dates[[1]][1:2]
#split_dates[[2]] <- split_dates[[2]][1:2]

all_pls <- rbindlist(clusterApply(cl, split_dates, calcFull))


#########
# MERGE #
#########

empty_df = rbindlist(lapply(unique(all_pls$id), function(x) return(data.table(id = x, date = dates_series))))

merged <- merge(empty_df, all_pls, by = c('id','date'), all.x=T, all.y=F)

fwrite(merged, '../output/placements-aggregated.csv')
