library(data.table)
library(devtools)
devtools::install_github("hannesdatta/musicMetadata")
library(musicMetadata)

tracks1 = fread('../externals/playlist-placements.csv', select=c('track_id','album_label'), encoding = 'UTF-8', quote = '')
tracks2 = fread('../externals/playlist-placements-below150k.csv', select=c('track_id','album_label'), encoding = 'UTF-8', quote = '')
tracks3 = fread('../externals/playlist-placements-recommendations.csv', select=c('track_id','album_label'), encoding = 'UTF-8', quote = '')

tracks <- rbind(tracks1, tracks2, tracks3)

tracks = unique(tracks,by=c('track_id'))

labels = tracks[, list(N_tracks = .N),keyby=c('album_label')]

setorderv(labels, 'N_tracks', order=-1L)

classification <- classify_labels(labels$album_label, concatenate = T)

labels[, label:=classification]

labels <- labels[!album_label=='']
dir.create('../output')
fwrite(labels, file='../output/labels.csv')
