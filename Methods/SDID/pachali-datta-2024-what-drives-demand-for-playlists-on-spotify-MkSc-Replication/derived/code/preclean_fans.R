library(data.table)

files <- c("../externals/fans-instagram.csv", "../externals/fans-deezer.csv", "../externals/fans-deezer-missings.csv")

prototype = F

nrows=-1L
if (prototype==T) nrows=1E5

process_fans <- function(fn) {
  dt <- fread(file = fn, encoding = 'UTF-8', sep='\t', quote = "", na.strings=c('NA', 'None'), drop = 'link', nrows=nrows)
  
  dates = data.table(date_str=unique(dt$timestp))
  dates[, date:=as.Date(date_str, format='%Y-%m-%d')]
  
  setkey(dt, timestp)
  setkey(dates,date_str)
  
  dt[dates, date:=i.date]
  dt[,timestp:=NULL]

  setcolorder(dt, c('cm_artistid', 'date', 'value', 'flags'))
  setorder(dt, cm_artistid, date)
  
  fn_extract = rev(strsplit(fn, '/')[[1]])[1]
  fn_extract = gsub('[.]csv','',fn_extract)
  fn_extract = gsub('[-]missings','',fn_extract)
  
  setnames(dt, 'value', fn_extract)
  dt[, flags := NULL]
  return(dt)
  
}

fans <- lapply(files, process_fans)

fans_deezer = rbindlist(fans[2:3])
setkey(fans_deezer, cm_artistid, date)
fans_deezer <- unique(fans_deezer, by = c('cm_artistid','date'))


fans_merged = merge(fans[[1]], fans_deezer, by = c('cm_artistid','date'), all.x=T, all.y=T)
### think about data format
 
fwrite(fans_merged, '../output/fans.csv')
