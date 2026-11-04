library(data.table)
library(stringr)

# Output data: 
# genre -- date -- number of releases 

dt <- fread('../temp/extract-releases-tracks.csv',nrow=-1L)
dt[, group_id:=.GRP,by=c('track_genre')]

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
# ensure alphabetical order in merging category names
setorder(track_clusters, group_id, ntracks, cluster)

track_categories = track_clusters[max_confidence>=.10, list(category=paste0(cluster, collapse=',')),by=c('group_id','ntracks')]

# merge categories back to track data
setkey(track_categories, group_id)
setkey(dt, group_id)

dt[track_categories, combined_genre:=i.category]


# Verify categories are all sorted alphabetically
cat_check = data.table(category=unique(dt$combined_genre))
cat_check=cat_check[, list(incat=unlist(strsplit(category,','))),by=c('category')]
setorder(cat_check, category, incat)
cat_check=cat_check[, list(new_category=paste0(incat, collapse=',')),by=c('category')]
stopifnot(nrow(cat_check[!category==new_category])==0)


# largest genres
#tmp=track_categories[, list(ntracks=sum(ntracks)),by=c('category')]
#setorderv(tmp,'ntracks', order=-1L)
#tmp



# Store compound genres
fwrite(dt, '../temp/extract-releases-tracks-with-classified-genres.csv')

# Aggregate releases by category/date
releases=dt[, list(releases=.N), by = c('combined_genre','release_dates')]

setnames(releases, c('category','date','released_tracks'))
setorder(releases, category,date)

fwrite(releases[!is.na(date)], '../temp/classify_track-releases.csv')
