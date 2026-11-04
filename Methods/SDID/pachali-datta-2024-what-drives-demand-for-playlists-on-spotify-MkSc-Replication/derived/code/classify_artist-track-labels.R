library(data.table)


#############
# LOAD DATA #
#############
prototype = file.exists('prototype')

nrows = -1L

if (prototype==T) nrows = 1E6

placements_load <- rbindlist(lapply(c( '../output/placements.csv', '../output/placements-below150k.csv', '../output/placements-recommendations.csv'), 
                          function(fn) {
                            tmp = fread(fn, encoding='UTF-8', select = c('track_id','cm_artist','artist_names', 'album_names', 'album_label', 'release_dates', 'name'),
                            nrows = nrows)
                            
                            
                            unique(tmp,by=c('track_id'))}))

placements = unique(placements_load, by=c('track_id'))
placements[, oneartist:=!is.na(as.numeric(cm_artist))]


# Quick conversion of `character` date columns to Date format using data.table
# fread(..., colClasses = c(date='Date')) is slow for large data sets, especially when
# the number of unique dates is small, but the number of cross-sectional units is large.

# The intuition of this algorithm is to only convert the UNIQUE dates to dates using as.Date,
# and then merging them back to the original data.table.

library(data.table)

data.table.date <- function(dt, datecol) {
  classes=lapply(dt, class)
  oldclass = classes[which(colnames(dt)==datecol)]
  cat(paste0('Converting column `', datecol, '` (which is of type `', oldclass, '`) to date...\n'))
  cat('collecting unique dates...\n')
  uniqdates= data.table(date_str=unique(unlist(dt[, datecol, with=F])))
  uniqdates[, date:=as.Date(date_str, origin = '1970-01-01')]
  setkey(uniqdates, date_str)
  setkeyv(dt, datecol)
  cat('merging converted dates back to original data table\n')
  dt[uniqdates, date_new:=i.date]
  dt[, (datecol):=NULL]
  setnames(dt, 'date_new', datecol)
  classes=lapply(dt, class)
  newclass = classes[which(colnames(dt)==datecol)]
  
  cat(paste0('Done. `', datecol, '` now is of type `', newclass, '`.\n'))
  
}

placements[, ':=' (count1=length(strsplit(cm_artist,'[|]')[[1]])#,
            #count2=length(strsplit(artist_names,'[|]')[[1]])
            ), by = c('track_id','album_label','release_dates')]
           
#placements[!count1==count2]   # fix that count      


####################
# TRACK-LEVEL DATA #
####################
           
tracks <- placements[, list(cm_artist=as.numeric(unlist(strsplit(cm_artist,'[|]')[[1]])),
                            album_name = paste0(unique(album_names), collapse = '|'),
                            artist_names=artist_names[1],
                            album_label=album_label[1],
                            release_dates=release_dates[1],
                            name=name[1],
                            orig_artists=cm_artist[1]#,
                           # artist_name=unlist(strsplit(artist_names,'[|]')[[1]])
                          ),by=c('track_id')]


# Read labels
labels=fread('../output/labels.csv', encoding='UTF-8')

# Merge label classification
setkey(labels, album_label)
setkey(tracks, album_label)

tracks[labels, ml_curr:=grepl('warner|sony|universal', i.label)]
tracks[labels, sony_curr:=grepl('sony', i.label)]
tracks[labels, warner_curr:=grepl('warner', i.label)]
tracks[labels, universal_curr:=grepl('universal', i.label)]

####################
# ALBUM-LEVEL DATA #
####################

albums <- tracks[, list(Ntracks=.N),by=c('cm_artist','album_label','album_name', 'release_dates')]

data.table.date(albums, 'release_dates')

setkey(albums, album_label)
setkey(labels, album_label)
albums[labels, label_type:=i.label]

setorderv(albums, c('cm_artist','release_dates'), order=c(1,-1))
albums[, order_of_albums:=1:.N,by=c('cm_artist')]

nrow(albums[is.na(cm_artist)])/nrow(albums)

# compute label membership at the artist level (unit of analysis: artist-release)
artists = albums[, list(#ml=any(grepl('sony|warner|universal', label_type)),
                        sony=any(grepl('sony', label_type)),
                        warner=any(grepl('warner', label_type)),
                        universal=any(grepl('universal', label_type)),
                        #ml3=any(grepl('sony|warner|universal', label_type[order_of_albums<=3])),
                        sony3=any(grepl('sony', label_type[order_of_albums<=3])),
                        warner3=any(grepl('warner', label_type[order_of_albums<=3])),
                        universal3=any(grepl('universal', label_type[order_of_albums<=3])),
                        #mlsh=sum(grepl('sony|warner|universal',label_type))/.N,
                        sonysh=sum(grepl('sony',label_type))/.N,
                        warnersh=sum(grepl('warner',label_type))/.N,
                        universalsh=sum(grepl('universal',label_type))/.N),by=c('cm_artist')]

artists[, sonybyshare:=sonysh>=.5]
artists[, warnerbyshare:=warnersh>=.5]
artists[, universalbyshare:=universalsh>=.5]

artists[, ml:=sony+warner+universal>0]
artists[, ml3:=sony3+warner3+universal3>0]
artists[, mlbyshare:=sonybyshare+warnerbyshare+universalbyshare>0]

artists <- artists[!is.na(cm_artist)]

#nrow(artists[sony+warner+universal>0])/nrow(artists) # share ML artists
#nrow(artists[sony3+warner3+universal3>0])/nrow(artists) # share ML artists
#nrow(artists[sonysh>.5|warnersh>.5|universalsh>.5])/nrow(artists) # share ML artists

#artists[, anyml := sony+warner+universal>0]
#artists[, any3relml := sony3+warner3+universal3>0]
#artists[, any50percml := sonysh>=.5|warnersh>=.5|universalsh>=.5]
#artists[anyml==T&any50percml==0]
#nrow(artists[any50percml==T])/nrow(artists)
#nrow(artists[any3relml==T])/nrow(artists)
#nrow(artists[anyml==T])/nrow(artists)

# Retrieve artist names

# algorithm to extract artist names

artist_names = unique(placements[oneartist==T, c('cm_artist','artist_names'),with=F], by = c('cm_artist'))
artist_names[, cm_artist := as.numeric(cm_artist)]
artist_names <- artist_names[!is.na(cm_artist)]
# eliminate
#ambiguous[sep_id==sep_orignames&sep_id==1]

if(0)  {
artist_names[, cnt:=uniqueN(artist_names),by=c('cm_artist')]
table(artist_names$cnt)



table(unique(tracks$cm_artist)%in%artist_names$cm_artist)
notthere = unique(tracks$cm_artist)[!unique(tracks$cm_artist)%in%artist_names$cm_artist]

# gotta clean those first


#notthhere <- notthere[!is.na(notthere)]

ambiguous = tracks[cm_artist%in%notthere & !is.na(cm_artist)]
ambiguous[, sep_id := nchar(orig_artists)-nchar(gsub('[|]', '', orig_artists))]
ambiguous[, sep_orignames := nchar(artist_names)-nchar(gsub('[|]', '', artist_names))]

ambiguous = ambiguous[sep_id==sep_orignames]



table(ambiguous$sep_id)

artist_deambig = ambiguous[sep_id==sep_orignames, list(cm_artist=as.numeric(unlist(strsplit(orig_artists,'[|]')[[1]])),
                                                       artist_name=unlist(strsplit(artist_names,'[|]')[[1]])),
                                                       by = c('orig_artists', 'artist_names')]

all_artists = rbind(artist_names, artist_deambig[, c('cm_artist','artist_name'),with=F], use.names=F)

all_artists[,cnt:=uniqueN(artist_names),by=c('cm_artist')]
setorder(all_artists,cm_artist)

all_artists[cm_artist==178]
all_artists[cm_artist==247]

}

  
setkey(artists, cm_artist)
setkey(artist_names,cm_artist)
artists[artist_names, artist_name:=i.artist_names]

# gotta tell distribution firms apart from actual ML backup (--> weakness)
#tracks[grepl('distribution', album_label,ignore.case=T)]

fwrite(artists, '../output/artist-labels.csv')

sink('../output/artist-labels.txt')
cat('===================\n')
cat('DATASET DESCRIPTION\n')
cat('===================\n')
cat('\n')
cat('This data set provides a classification of artists\' label\n')
cat('membership (one of Sony, Warner, Universal, nothing (= Indie), or combinations thereof).\n')
cat('\n')
cat('The raw data provides labels at the artist-release (i.e., album) level.\n')
cat('We collapse the data at the artist levelTo obtain labels at the artist-level, we first aggregate labels\n')
cat('at the album level, and then derive three type of label membership\n')
cat('metrics.\n')

cat('\n\n')
cat('Variable operationalization\n')
cat('===========================\n')
cat('cm_artist                   Chartmetric Artist ID', fill=T)
cat('sony/warner/universal       TRUE if any of an artists\'s releases is by Sony, Warner, or Universal', fill=T)
cat('sony3/warner3/universal3    TRUE if any of an artists\'s most recent 3 releases is by Sony, Warner, or Universal', fill=T)
cat('sonysh/warnersh/universalsh Share of releases by Song, Warner, or Universal, among all of an artist\'s releases', fill=T)
cat('artist_name                 Clear-text artist name; only listed for those that could be unambigously identified (the raw data lists artist names and IDs jointly)', fill=T)

sink()



tmp = merge(tracks, artists, all.x=T, by = c('cm_artist'))

setcolorder(tmp, c('track_id','cm_artist'))
setorder(tmp, track_id, cm_artist)

fkts = list(any=function(x) any(x==T),
            half=function(x) (sum(x)/length(x)>=.5))

trackclass=lapply(seq(along=fkts), function(i) {
  fkt=fkts[[i]]
  
  res = tmp[, lapply(.SD, fkt), by = c('track_id'), .SDcols=grep('(^(sony|warner|universal|ml)(.{0,1}$|.{1,2}curr$|3$|share$))|byshare', colnames(tmp),value=T)]
  setnames(res, c('track_id', paste0(colnames(res)[-1], '_', names(fkts)[i])))
  setkey(res, track_id)
  res
})

track_final = merge(trackclass[[1]], trackclass[[2]])   

for (.lbl in c('ml','sony','warner','universal')) {
  setnames(track_final, paste0(.lbl,'_curr_any'), paste0(.lbl, '_curr'))
  track_final[, (paste0(.lbl,'_curr_half')):=NULL]
}


fwrite(track_final, '../output/track-labels.csv')

sink('../output/track-labels.txt')
cat('===================\n')
cat('DATASET DESCRIPTION\n')
cat('===================\n')
cat('\n')
cat('This data set provides a classification of the label that is associated with a\n')
cat('particular track.\n\n')
cat('We propose several metrics for major-label content (ML), and content from the three\n')
cat('major music labels Sony, Warner, and Universal. Labels are identified by their suffix,\n')
cat('and metrics are identified by their suffix:\n')
cat('1) "_curr" identifies a track\'s releasing label as the *actual* label under which the track was released\n')
cat('2) "_any" identifies a track\'s releasing label as the focal label, if *any* of the contributing artists\n')
cat('   has been classified as belonging to the focal label (in this instance: if ANY of an artists\' release was\n')
cat('   from the focal label)\n')
cat('3) "3_any" identifies a track\'s releasing label as the focal label, if *any* of the contributing artists\n')
cat('   has been classified as belonging to the focal label (in this instance: if one of the most recent three\n')
cat('   releases was on the focal label)\n')
cat('4) "byshare_any" identifies a track\'s releasing label as the focal label, if *any* of the contributing artists\n')
cat('   has been classified as belonging to the focal label (in this instance: if at least 50% of an artists\' tracks\n')
cat('   was released on the focal label)\n')
cat('5) "_half" identifies a track\'s releasing label as the focal label, if at least half of the contributing artists\n')
cat('   has been classified as belonging to the focal label (in this instance: if ANY of an artists\' release was\n')
cat('   from the focal label)\n')
cat('6) "3_half" identifies a track\'s releasing label as the focal label, if at least half of the contributing artists\n')
cat('   has been classified as belonging to the focal label (in this instance: if one of the most recent three\n')
cat('   releases was on the focal label)\n')
cat('7) "byshare_half" identifies a track\'s releasing label as the focal label, if at least half of the contributing artists\n')
cat('   has been classified as belonging to the focal label (in this instance: if at least 50% of an artists\' tracks\n')
cat('   was released on the focal label)\n')

cat('\n\n')
cat('Variable operationalization\n')
cat('===========================\n')
cat('cm_artist                   Chartmetric Artist ID', fill=T)
for (v in colnames(track_final)[-1]) cat(v, fill=T)

sink()
