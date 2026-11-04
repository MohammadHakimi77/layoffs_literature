# combine tags for association rule mining
library(data.table)
library(stringr)

static_tags <- fread('../output/tags-playlists.csv')
static_meta <- fread('../output/tags-playlists-meta.csv')

# extract dynamic clusters
dt <- fread('../temp/tags-placements.csv', nrows= -1L)

playlists <- fread('../output/playlists.csv')

uniqueN(static_tags$id)

# retain tags aligning with static chartmetric tags
tmp <- dt[begin_init>='2020-03-30']

placement_tags = tmp[, list(sum_days=sum(sum_days,na.rm=T)),by=c('id', 'tag')]
setorderv(placement_tags, c('id', 'sum_days'), order=c(1L,-1L))
placement_tags[, top_n:=rank(-sum_days,na.last=T, ties.method=c('average')), by = c('id')]

uniqueN(placement_tags$id)
summary(placement_tags[, list(N=.N),by=c('id')]$N)

# Major keywords in this data
genres = c('afro', 'alternative', 'anime', 'arab', 'blues', 'chill', 'christianmusic', 'classical', 'comedy', 'country', 'desi', 'edm', 'focus', 'folk', 'funk', 'videogamemusic', 'hiphop', 'indie', 'jazz', 'latin', 'metal', 'party', 'pop', 'punk', 'rb', 'regionalmexican', 'rock', 'romance', 'sleep', 'soul', 'student', 'mood','activity')

#uniqueN(static_tags_only[tag%in%genres]$id)

#uniqueN(placement_tags[tag%in%genres]$id)


# retain top 10 tags
placement_tags <- placement_tags[top_n<=10]

setkey(static_tags, tagid)
setkey(static_meta, tagid)
static_tags[static_meta, tag:=i.tag]

static_tags_only <- static_tags[, c('id','tag'),with=F]

uniqueN(static_tags_only$id)
summary(static_tags_only[, list(N=.N),by=c('id')]$N)

uniqueN(placement_tags$id)
summary(placement_tags[, list(N=.N),by=c('id')]$N)



# Combine tags
combined_tags <- rbind(static_tags_only, placement_tags[, c('id','tag'),with=F])

# remove leading and trailing spaces and hyphens
combined_tags[, tag:= gsub(' ', '', gsub('-', '', tag))]
combined_tags[, tag:= gsub('[&]', '', gsub('[/]', '', tag))]
combined_tags[, tag:= str_trim(tag)]

# remove duplicates
combined_tags <- unique(combined_tags, by=c('id', 'tag'))

setorderv(playlists, 'followers', order=-1L, na.last=T)
playlists[, followerrank:=1:.N]


setkey(combined_tags, id)
setkey(playlists, id)

combined_tags[playlists, ':=' (followers=i.followers, followerrank=i.followerrank)]

combined_tags[, tagid:=.GRP,by=c('tag')]

# Distribution of tag words
tags_summary=combined_tags[, list(N=.N),by=c('tagid','tag')]
setorderv(tags_summary, 'N', order=-1L)
tags_summary[, cumN:=cumsum(N)]
tags_summary[, percentile:=cumN/sum(N)]


uniqueN(combined_tags$id)
summary(combined_tags[, list(N=.N), by=c('id')]$N)

#$uniqueN(combined_tags[tag%in%genres]$id)
uniqueN(combined_tags$tag)

combined_tags[, tag:=NULL]

setcolorder(combined_tags, c('id','followers','followerrank'))

fwrite(combined_tags, '../output/tags-playlists-placements.csv')
fwrite(tags_summary, '../output/tags-playlists-placements-meta.csv')
