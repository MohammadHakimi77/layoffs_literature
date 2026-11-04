# Load packages
library(data.table)
library(tidyverse)
library(arules)

# ---------------------------- #
#       DATA PREPARATION       #
# ---------------------------- #

# derived from Everynoise World Browser (http://everynoise.com/worldbrowser.cgi)
genres = c('afro', 'alternative', 'anime', 'arab', 'blues', 'chill', 'christianmusic', 'classical', 'comedy', 'country', 'desi', 'edm', 'focus', 'folk', 'funk', 'videogamemusic', 'hiphop', 'indie', 'jazz', 'latin', 'metal', 'party', 'pop', 'punk', 'rb', 'regionalmexican', 'rock', 'romance', 'sleep', 'soul', 'student', 'mood','activity')

playlists <- fread('../output/playlists.csv') # N about 1,215,300
tags_playlists = fread('../output/tags-playlists-placements.csv', key='tagid', nrows=-1L) 
tags_playlists_meta = fread('../output/tags-playlists-placements-meta.csv', key='tagid')

tags_playlists[tags_playlists_meta, 'tag':=i.tag]

lapply(genres, function(x) tags_playlists[tag==x])

# number of playlists in data
length(unique(tags_playlists$id))

# For association rule mining, retain playlists that have at least one keyword 
tags_filtered=tags_playlists[id%in%tags_playlists[tag%in%genres]$id] %>% unique(by=c('id','tag'))

uniqueN(tags_filtered$id) # playlists input to the association rule mining

# converting to matrix "transaction" data necessary for arules and remove first (ID) column
tags_filtered[, incidence:=1]
mat=as.matrix(dcast.data.table(tags_filtered, id~tag,value.var='incidence',fill=0))[,-1]
tran = transactions(mat)

# computing rules
rules <- apriori(tran, parameter = list(supp = 0.0, conf = 0.50, maxlen=2)) %>% sort(by='confidence', decreasing=T)

# extract rules to data table
extracted_rules = data.table(as(rules, "data.frame"))
extracted_rules[, lhs:=str_trim(sapply(rules, function(x) strsplit(x,'=>')[[1]][1]))]
extracted_rules[, rhs:=str_trim(sapply(rules, function(x) strsplit(x,'=>')[[1]][2]))]

extracted_rules[, lhs:=gsub('[{]|[}]','', lhs)]
extracted_rules[, rhs:=gsub('[{]|[}]','', rhs)]

extracted_rules[, list(n_tagwords=.N),by=c('rhs')] %>% arrange(desc(n_tagwords))

new_rules = extracted_rules[, list(tag=lhs, cluster=rhs, confidence=confidence, lift=lift)]

setorder(new_rules, cluster,tag)

# retain only rules with a main genre as a consequence (right hand side, rhs)
new_rules = new_rules[cluster%in%genres]

for (x in genres) {
  cat(paste0('rules for ', x,'\n'))
  print(new_rules[cluster==x])
}


# kick out any main genres from lhs
new_rules <- new_rules[!tag%in%genres]
# add existing genres lhs --> rhs
new_rules = rbind(new_rules, data.table(tag=genres, cluster=genres, confidence=1, lift=1))

# identify the same tag words leading to different clusters --> retain max confidence only
setorderv(new_rules, c('tag','confidence','lift'), order=c(1L,-1L,-1L))
# keep max confidence, resolve conflicts by highest lift
new_rules[, keep:=1:.N==1,by=c('tag')]

#new_rules[keep==F]
#nrow(new_rules)

#new_rules <- new_rules[keep==T][, keep:=NULL]
setorder(new_rules, cluster,tag)
fwrite(new_rules, "../temp/rules.csv")
