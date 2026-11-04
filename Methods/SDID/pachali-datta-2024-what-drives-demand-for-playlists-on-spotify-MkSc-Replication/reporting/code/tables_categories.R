# Generate statistics about category classification changes
library(data.table)

categories <- fread('../../analysis/temp/playlist-categories.csv')
panel <- fread('../../analysis/output/paneldata.csv')
playlists <- fread('../../analysis/temp/playlists.csv')
placements <- fread('../../analysis/temp/placements-selected-only.csv')
categories[, sel:=id%in%unique(panel$id)]
setkey(panel, id)
setkey(playlists,id)
panel[playlists, ':=' (static_followers=i.followers, name=i.name)]

categories_selected = categories[id%in%unique(panel$id)]

tmp=categories_selected[, list(nchanges=sum(changed)),by=c('id','name','playlist_followers')]

tmpx=table(tmp$nchanges)
tmpx=tmpx[order(tmpx,decreasing = T)]
tmps=cumsum(tmpx)/sum(tmpx)
tmps
round(tmpx/sum(tmpx),2)
setorderv(tmp, 'playlist_followers',order=-1L)

hist(tmp$nchanges)
tmp[nchanges==0][1:5]
tmp[nchanges==1][1:5]
