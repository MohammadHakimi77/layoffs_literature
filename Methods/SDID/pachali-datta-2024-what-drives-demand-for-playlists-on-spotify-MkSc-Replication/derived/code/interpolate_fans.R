####################################
# INTERPOLATION OF ARTIST FAN DATA #
####################################

library(data.table)

#############
# LOAD DATA #
#############

prototype = F

nrows = -1L
if (prototype==T) nrows = 25E6

# Load fans
fans <-fread('../output/fans.csv', nrows = nrows)

# convert dates to R dates
dates=data.table(date_str=unique(fans$date))
dates[, date:=as.Date(date_str, format='%Y-%m-%d')]
setorder(dates,date)
dates[, date_num:=1:.N]

setkeyv(dates, 'date_str')
setkey(fans, date)

fans[dates, ':=' (date_date=i.date, date_num=i.date_num)]
fans[, date:=NULL]
setnames(fans, 'date_date','date')
setkey(fans, cm_artistid,date)

# Make empty time series
start_series = as.Date('2019-10-01')
end_series = as.Date('2020-04-18')
dates_series=seq(from=start_series, to=end_series, by = '1 day')
dates_series_num = seq(from=dates[date==start_series]$date_num, to=dates[date==end_series]$date_num)

# do we have all dates?
#fans <- fans[date>=start_series-28 & date<=end_series+28]

#fans[, all_na:=all(is.na(get('fans-instagram'))), by = c('cm_artistid')]

fans[, new_num:=cm_artistid*10000+date_num]

interpolated = lapply(c('fans-instagram','fans-deezer'), function(var) {
  cat(var, fill=T)
  tmp = fans[!is.na(get(var)), list(first=min(date_num), last=max(date_num)),by=c('cm_artistid')]
  tmp[, first_cap := pmax(first, min(dates_series_num))]
  tmp[, last_cap := pmin(last, max(dates_series_num))]
  
  interp = tmp[first_cap<=last_cap, list(num=cm_artistid*10000+as.double(seq(from=first_cap,to=last_cap))),by=c('cm_artistid')]$num
  cat('starting to interpolate\n')
  res=approx(fans$new_num, fans[,get(var)], xout=interp)
  cat('ending to interpolate\n')
  
  dt = data.table(new_num=res$x, y=res$y)
  setnames(dt, 'y',var)
  dt[, cm_artistid:=floor(new_num/10000)]
  dt[, date_num:=new_num-cm_artistid*10000]
  dt[, date:=dates_series[match(date_num, dates_series_num)]]
  dt[, ':=' (date_num=NULL, new_num=NULL)]
  setcolorder(dt, c('cm_artistid','date',var))
  dt
})

fans_merged = merge(interpolated[[1]], interpolated[[2]], by = c('cm_artistid','date'), all.x=T, all.y=T)

# Retain only complete time series
for (var in c('fans-instagram', 'fans-deezer')) {
  fans_select=fans_merged[date%in%as.Date(c('2019-10-01','2020-04-18')), list(N=.N, sum=sum(get(var))), by = c('cm_artistid')]
  fans_select[, select:=N>1&!is.na(sum)]
  
  fans_merged[!cm_artistid%in%fans_select[select==T]$cm_artistid, (var):=NA]
}

fans_merged <- fans_merged[!is.na(`fans-instagram`)|!is.na(`fans-deezer`)]


fwrite(fans_merged, '../temp/fans_interpolated.csv')

if(0) {
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

data.table.date(fans_merged, 'date')

if(0) {
tmp=fans_merged[, list(select=any(!is.na(`fans-deezer`[date==as.Date('2020-01-01')]))&
                       any(is.na(`fans-deezer`[date==as.Date('2020-04-10')]))), by = c('cm_artistid')]
fwrite(tmp[select==T][, select:=NULL], file = '../temp/missing-deezer-cmartistids.csv')
}

}
#deezer/insta followers for all artists that ever appeared on that parti ular list; across 2019-2020 [playlist-specific]
#deezer/insta followers for all artists that across whole data [overall 2019-2020]