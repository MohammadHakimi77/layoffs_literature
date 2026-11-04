############################################
# INTERPOLATION OF FOLLOWERS AND LISTENERS #
############################################

library(data.table)

#############
# LOAD DATA #
#############

prototype = file.exists('prototype')

nrows = -1L
if(prototype==T) nrows = 5E6

listeners <- fread('../externals/cm-export_playlist.csv', nrows=nrows)
setnames(listeners, 'timestamp','date')

followers <- fread('../temp/followers.csv', nrows=nrows)

# set dates
# convert dates to R dates
dates=data.table(date_str=unique(c(unique(listeners$date), unique(followers$date))))
dates[, date:=as.Date(date_str, format='%Y-%m-%d')]
setorder(dates,date)
dates[, date_num:=1:.N]

setkeyv(dates, 'date_str')

for (ds in c('followers','listeners')) {
  cat(ds,fill=T)
  eval(parse(text=paste0('setkey(',ds,',date)')))
  eval(parse(text=paste0(ds,'[dates, date_str:=i.date]')))
  eval(parse(text=paste0(ds,'[dates, date_num:=i.date_num]')))
  eval(parse(text=paste0(ds,'[, date:= NULL]')))
  eval(parse(text=paste0('setnames(',ds,', \'date_str\', \'date\')')))
  
}


# Make empty time series
start_series = as.Date('2019-10-01')
end_series = as.Date('2020-04-18')
dates_series=seq(from=start_series, to=end_series, by = '1 day')
dates_series_num = seq(from=dates[date==start_series]$date_num, to=dates[date==end_series]$date_num)

interp <- function(dt) {
  dt[, new_num:=id*10000+date_num]
  setorder(dt, new_num)
  tmp = dt[!is.na(value), list(first=min(date_num), last=max(date_num)),by=c('id')]
  tmp[, first_cap := pmax(first, min(dates_series_num))]
  tmp[, last_cap := pmin(last, max(dates_series_num))]
  
  interp = tmp[first_cap<=last_cap, list(num=id*10000+as.double(seq(from=first_cap,to=last_cap))),by=c('id')]$num
  cat('starting to interpolate\n')
  res=approx(dt$new_num, dt$value, xout=interp)
  cat('ending to interpolate\n')
  
  dres = data.table(new_num=res$x, value=res$y)
  dres[, id:=floor(new_num/10000)]
  dres[, date_num:=new_num-id*10000]
  dres[, date:=dates_series[match(date_num, dates_series_num)]]
  dres[, interpolated:=!new_num%in%dt$new_num]
  dres[, ':=' (date_num=NULL, new_num=NULL)]
  
  setcolorder(dres, c('id','date','value', 'interpolated'))
  dres
}

flwr = copy(followers)
flwr = flwr[interpolated==F]
setnames(flwr, 'followers','value')

res = interp(flwr)
setnames(res, 'value','followers')
setnames(res, 'interpolated','interpolated_followers')

lstr = unique(listeners, by = c('playlist_id','date'))
setnames(lstr, 'monthly_listeners_avg','value')
setnames(lstr, 'playlist_id','id')

res2 = interp(lstr)

setnames(res2, 'value','listeners')
setnames(res2, 'interpolated','interpolated_listeners')

ds_merged = merge(res, res2, by = c('id','date'), all.x=T,all.y=T)

fwrite(ds_merged, '../output/followers-listeners.csv')
