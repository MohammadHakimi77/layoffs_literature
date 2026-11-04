# extract dynamic clusters
library(data.table)

dt <- fread('../temp/tags-placements.csv', nrows=-1L)

rules <- fread('../temp/rules.csv')[keep==T]
nrow(rules)
summary(rules)

setkey(dt, tag)
setkey(rules,tag)
nrow(rules)
dt[rules, ':=' (cluster=i.cluster, confidence=i.confidence)]

dt <- dt[!is.na(cluster)]

dt[, weights:=sum_days/sum(sum_days,na.rm=T),by=c('id','begin_init')]

setorder(dt, id, begin_init,top_n)
categories = dt[, list(wconfidence=sum(weights)),by=c('id','begin_init','end_init', 'cluster')]

# convert to wide data to "fill" missing labels
wide_categories = dcast(categories, id+begin_init+end_init~cluster,fill=0, value.var='wconfidence')
setorder(wide_categories, id, begin_init, end_init)

# melt again
long_categories = melt(wide_categories, id.vars=c('id','begin_init','end_init'))

# tag all genres that are always not available (9999) and remove them
long_categories[, always_zero := all(value==0),by=c('id','variable')]
long_categories <- long_categories[always_zero==F][, always_zero:=NULL]

# clean up workspace
gc()

# drop pre-observation period
# keep key observation period +/- 4 weeks
long_categories <- long_categories[begin_init>=as.Date('2019-09-02') & begin_init <= as.Date('2020-04-27')]


# compute consecutive stretches
long_categories[, has_value:=as.numeric(value>=.10)]
long_categories[, consec:=cumsum(1-has_value),by=c('id', 'variable')]
long_categories[, mixed_consec:=all(c(0,1)%in%has_value),by=c('id','variable','consec')]
long_categories[mixed_consec==TRUE & value<.10, consec:=consec-.5]
long_categories[, stretch_id:=.GRP,by=c('id','variable','consec')]
long_categories[, stretch_length:=.N,by=c('id','variable','stretch_id')]
long_categories[, max_avail_stretch_length:=max(c(stretch_length*has_value)),by=c('id','variable')]
#long_categories[, obs_in_key_period:=sum(has_value) max_avail_stretch_length:=max(c(stretch_length*has_value)),by=c('id','variable')]
long_categories[, is_available := has_value==1]

long_categories[, value_na:=has_value]
long_categories[has_value==0, value_na:=NA]

#tmp=dcast(long_categories[id==1336858], id+begin_init~variable, value.var='value')
#View(tmp)
#dt[id==1776039&begin_init%in%c('2019-12-02', '2019-12-09')]

# retain only minimum stretch lengths
#long_categories <- long_categories[max_avail_stretch_length>=4]


# Obtain dynamic categories, ensure they are ordered alphabetically 
setorder(long_categories, id, begin_init, end_init, variable)
long_categories[, gsubbed_categories := gsub('[^[A-Za-z]]|[ ]|[&]|[/]', '', variable)]

#&stretch_length>=2
agg_categories = long_categories[max_avail_stretch_length>=4, list(category=paste0(gsubbed_categories[which(value>=.10)],collapse='-')),by=c('id','begin_init','end_init')]

# Tag change of category
setorder(agg_categories, id, begin_init)
agg_categories[, lag_category:=c(NA, category[-.N]),by=c('id')]
agg_categories[, changed:=as.numeric(!category==lag_category)]
agg_categories[, ':=' (lag_category=NULL)]
agg_categories <- agg_categories[!is.na(changed) & begin_init >= as.Date('2019-09-30')&begin_init<=as.Date('2020-03-30')]

# Merge playlist attributes
playlists<-fread('../output/playlists.csv')
setkey(playlists, id)
setkey(agg_categories, id)
agg_categories[playlists, ':=' (playlist_followers=i.followers, name=i.name)]
agg_categories[, category:=gsub('[-]',',', category)]
agg_categories[, cat_id:=.GRP,by=c('category')]
fwrite(agg_categories, '../output/playlist-categories.csv')

