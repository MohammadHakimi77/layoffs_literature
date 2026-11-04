library(data.table)

fns <- list.files('../externals/', pattern = 'playlist[-]followers.*.csv', full.names = T)

followers <- rbindlist(lapply(fns, function(x) fread(file = x, encoding = 'UTF-8', sep='\t', quote = "", na.strings=c('NA', 'None'))))

dates = data.table(date_str=unique(followers$timestp))
dates[, date:=as.Date(date_str, format='%Y-%m-%d')]

setkey(followers, timestp)
setkey(dates,date_str)

followers[dates, date:=i.date]
followers[,timestp:=NULL]

setkey(followers, playlist_id, date)

followers <- unique(followers,by=c('playlist_id','date'))

setcolorder(followers, c('playlist_id', 'date', 'value', 'interpolated'))
setorder(followers, playlist_id, date)
setnames(followers, 'value', 'followers')
setnames(followers, 'playlist_id', 'id')
dir.create('../temp')
fwrite(followers, '../temp/followers.csv')
