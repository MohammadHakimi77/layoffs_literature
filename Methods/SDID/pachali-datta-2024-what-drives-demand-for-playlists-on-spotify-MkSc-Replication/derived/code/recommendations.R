library(data.table)
library(stringr)


dt <- fread('../temp/placements-recommendations-filtered.csv')
dt[, group_id:=.GRP,by=c('track_genre')]

# make empty time series
start_series = as.Date('2019-10-01')
end_series = as.Date('2020-04-20')

dates_series=seq(from=start_series, to=end_series, by = '1 day')

######################
# TAG CLASSIFICATION #
######################

uniq_tags = dt[, list(ntracks=uniqueN(track_id), track_genre=track_genre[1]),by=c('group_id')]

all_tags = uniq_tags[, list(tag=unlist(strsplit(track_genre, ',|[|]')), ntracks=ntracks[1]),by=c('group_id')]

# remove leading and trailing spaces and hyphens
all_tags[, tag:= gsub(' ', '', gsub('-', '', tag))]
all_tags[, tag:= gsub('[&]', '', gsub('[/]', '', tag))]
all_tags[, tag:= str_trim(tag)]
all_tags <- all_tags[!tag=='']
all_tags <- unique(all_tags, by=c('group_id', 'tag'))

# Load association rules
rules <- fread('../temp/rules.csv')[keep==T]

setkey(all_tags, tag)
setkey(rules,tag)

all_tags[rules, ':=' (cluster=i.cluster, confidence=i.confidence)]
all_tags <- all_tags[!is.na(cluster)]

track_clusters = all_tags[, list(max_confidence=max(confidence)),by=c('group_id','ntracks','cluster')]

# ensure alphabetical order in category names
setorder(track_clusters, group_id, ntracks, cluster)
track_categories = track_clusters[max_confidence>=.10, list(category=paste0(cluster, collapse=',')),by=c('group_id','ntracks')]

# merge categories back to track data
setkey(track_categories, group_id)
setkey(dt, group_id)

dt[track_categories, combined_genre:=i.category]



# Across all categories
added_ats = dt[added_at>=start_series&added_at<=end_series, list(nadded=.N), by = c('added_at', 'rec_type')]
setorder(added_ats, added_at, rec_type)

nplaylists = rbindlist(lapply(seq(from=start_series,to=end_series,by='1 day'), function(.d) {
  dt[added_at<=.d & (is.na(removed_at)|removed_at>.d)][, list(ntracks=.N, nplaylists=uniqueN(id)),by=c('rec_type')][, date:=.d]
}))
setkey(nplaylists, date, rec_type)
setkey(added_ats, added_at, rec_type)
nplaylists[added_ats, nadded:=i.nadded]
nplaylists[is.na(nadded), nadded:=0]


# By category

added_ats_cats = dt[added_at>=start_series&added_at<=end_series, list(nadded=.N), by = c('added_at', 'rec_type', 'combined_genre')]
setorder(added_ats_cats, added_at, rec_type, combined_genre)
added_ats_cats <- added_ats_cats[!is.na(combined_genre)]

nplaylists_cats = rbindlist(lapply(seq(from=start_series,to=end_series,by='1 day'), function(.d) {
  dt[added_at<=.d & (is.na(removed_at)|removed_at>.d)][, list(ntracks=.N, nplaylists=uniqueN(id)),by=c('rec_type', 'combined_genre')][, date:=.d]
}))

nplaylists_cats <- nplaylists_cats[!is.na(combined_genre)]

setkey(nplaylists_cats, date, rec_type, combined_genre)
setkey(added_ats_cats, added_at, rec_type, combined_genre)
nplaylists_cats[added_ats_cats, nadded:=i.nadded]
nplaylists_cats[is.na(nadded), nadded:=0]

fwrite(nplaylists, '../output/recommendations.csv')
fwrite(nplaylists_cats, '../output/recommendations-by-category.csv')

