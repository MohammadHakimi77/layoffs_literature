# Preclean promotion data

library(data.table)

raw <- fread('../temp/promotions.csv', nrows=-1L)
playlists <- fread('../temp/playlists.csv')
raw[, V1:=1]

setkey(playlists, playlist_id)
setkey(raw, playlist_id)
raw[playlists, id:=i.id]

# Number of sections
tmp = dcast(raw, date+sectionName+id~continent, value.var='V1', fill = 0, fun.aggregate=sum)

setnames(tmp, 'sectionName', 'sectionname')
setnames(tmp, 'glob', 'GLOB')
setnames(tmp, 'af', 'africa')
setnames(tmp, 'as', 'asia')
setnames(tmp, 'eu', 'europe')
setnames(tmp, 'na', 'northamerica')
setnames(tmp, 'oc', 'oceania')
setnames(tmp, 'sa', 'southamerica')

tmp[,n_countries_promoted:=africa+asia+europe+northamerica+oceania+southamerica]

tmp[, sectiontype:='browse']
tmp[sectionname%in%c('toplists','featured'), sectiontype:=sectionname]

tmpx = melt(tmp, id.vars=c('id','date','sectionname','sectiontype'))
tmpx[variable=='n_countries_promoted', variable:='nsections']
promo_nsections = dcast(tmpx[variable%in%c('nsections','GLOB')], id+date~sectiontype+variable, fun.aggregate = sum)

promo_nsections <- promo_nsections[!is.na(id)]

dir.create('../output/')
fwrite(promo_nsections, '../temp/promotions_cleaned.csv')
