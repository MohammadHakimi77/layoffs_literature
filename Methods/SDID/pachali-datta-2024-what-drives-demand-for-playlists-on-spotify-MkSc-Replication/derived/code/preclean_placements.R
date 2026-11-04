library(data.table)

args = commandArgs(trailingOnly=TRUE)

# test if there is at least one argument: if not, return an error
if (!length(args)==3) {
  stop("Need three arguments.", call.=FALSE)}

input_fn = args[1]
output_fn = args[2]
artist_fn= args[3]

print(args[1])
print(args[2])
print(args[3])

#input_fn = "../externals/playlist-placements.csv"
#output_fn = '../output/placements.csv'
#artist_fn =  '../output/artist-ids.csv'

placements <- fread(file = input_fn, encoding = 'UTF-8', sep='\t', quote = "", na.strings=c('NA', 'None'))

dates=data.table(date_str=unique(c(placements$added_at, placements$removed_at)))
dates[, date:=as.Date(date_str, format='%Y-%m-%d')]

setkeyv(dates, 'date_str')

for (v in c('added_at','removed_at')){
  setkeyv(placements, v)
  placements[dates, paste0(v, '_date'):=i.date]
  placements[, (v):=NULL]
  setnames(placements, paste0(v, '_date'), v)
}

first_added_ats = placements[, list(first_added=min(added_at)), by = c('playlist_id')]
dir.create('../output/')
dir.create('../temp/')

fwrite(first_added_ats, file = gsub('[.]csv', '-firstadded.csv', output_fn))

# filter for 2019 onwards only
placements <- placements[is.na(removed_at)|removed_at>=as.Date('2019-01-01')]

# remove duplicates
placements = unique(placements, by = c('playlist_id','track_id','added_at','removed_at'))


if(0){
  # problem: 
  # the raw data lists "duplicates", i.e., tracks apparently added multiple times and remoevd at different dates
  target=as.Date('2019-11-01')
  tmp=placements[id==1645067&added_at<=target&(is.na(removed_at)|removed_at>target)]
  # for example, see
  tmp[track_id==16676]
  
  tmp[, ':=' (cnt=.N, max_date=max(removed_at)),by=c('id','track_id','added_at')]
  tmp[, keep:=(is.na(removed_at)&is.na(max_date))|removed_at==max_date]
  
  tmp[track_id==16676]
  nrow(tmp[keep==T])
  
  
  target=as.Date('2020-01-01')
  tmp=placements[id==1645067&added_at<=target&(is.na(removed_at)|removed_at>target)]
  # for example, see
  nrow(tmp[keep==T])
  
  # e.g.,
  tmp[track_id==3891]
  
  #order all by added_at
  
  tmp=tmp[keep==T]
  setorder(tmp, id, track_id, added_at)
  tmp[track_id==3891]
  
  
  # case 1:
  # added_at)
  
  
  
  # keep the one with max
}

if(0){
  tmp = placements[id==1297]
  
  tmp[, ':=' (removed_at = max(removed_at), keep = 1:.N==1), by = c('id','track_id','added_at')]
  
  #tmp[keep==T, cnt:=.N,by=c('id','track_id')]
  
  tmp = tmp[keep==T]
  gc()
  
  daydiff=function(x,y) {
    #x=as.Date('2015-10-01')
    #y=as.Date('2015-12-01')
    as.numeric(y)-as.numeric(x)
  }
  
  # compute overlap
  setorder(tmp, id, track_id, added_at)
  tmp[, overlap:=daydiff(added_at, c(as.Date(NA), removed_at[-.N])), by= c('id','track_id')]
  
  setorder(tmp, id, track_id, added_at)
  
  # as soon as overlap switches to negative, increment to new group; here, tolerate gap
  spell <- function(overlap) {
    cumsum((overlap<(-2)|is.na(overlap)))
  }
  
  tmp[, spell:=spell(overlap), by = c('id','track_id')]
  
  #impute max removed_at per spell
  tmp[, ':=' (added_at = min(added_at), removed_at = max(removed_at), keep2=1:.N==1), by = c('id','track_id','spell')]
  
  tmp = tmp[keep2==T]
}


# Some tracks have the some addition dates, but varying removed_at dates.
# Rule: retain max date (can be NA)
nrow(placements)
placements[, ':=' (removed_at = max(removed_at), keep = 1:.N==1), by = c('playlist_id','track_id','added_at')]
placements = placements[keep==T]
nrow(placements)
gc()

daydiff=function(x,y) {
  as.numeric(y)-as.numeric(x)
}

spell <- function(overlap) {
  cumsum((overlap<(-2)|is.na(overlap)))
}

# compute overlap
setorder(placements, playlist_id, track_id, added_at)
placements[, overlap:=daydiff(added_at, c(as.Date(NA), removed_at[-.N])), by= c('playlist_id','track_id')]
setorder(placements, playlist_id, track_id, added_at)

# as soon as overlap switches to negative, increment to new group; here, tolerate gap
placements[, spell:=spell(overlap), by = c('playlist_id','track_id')]

#impute max removed_at per spell
placements[, ':=' (added_at = min(added_at), removed_at = max(removed_at), keep2=1:.N==1), by = c('playlist_id','track_id','spell')]

placements = placements[keep2==T][, ':=' (keep=NULL, overlap=NULL, keep2=NULL)]
gc()

#### TACKLE THIS ONE
#placements[playlist_id==827252&track_id==8689] # looks good now!
#placements[playlist_id==1297&track_id==8477668]

# verify
if(0) {
  res=rbindlist(lapply(seq(from=as.Date('2019-11-01'), to = as.Date('2020-01-01'), by = '1 day'), function(dt) {
    #print(dt='2020-01-01'
    #print(dt)
    tmp=placements[id==1015841& added_at<=dt&(removed_at>dt|is.na(removed_at))]
    data.table(dt, nrow(tmp), nrow(placements[id==1015841& added_at<=dt&(removed_at>=dt|is.na(removed_at))]))
  }))
}


cm_artists <- unlist(strsplit(unique(placements$cm_artist), '|', fixed=T))
cm_artists <- unique(cm_artists)
cm_artists <- cm_artists[!is.na(cm_artists)]

tmp = data.table(cm_artist = cm_artists)


fwrite(tmp, artist_fn)

setcolorder(placements, c('playlist_id','track_id', 'added_at','removed_at'))
setnames(placements, 'playlist_id','id')

fwrite(placements, output_fn) 
