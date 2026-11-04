library(data.table)

positions <- fread('../externals/playlist-positions.csv')


dates <- data.table(date_str=unique(positions$date))
dates[, date:=as.Date(date_str)]
setkey(dates,date_str)
setkey(positions, date)
positions[dates, date_num:=i.date]

positions <- positions[date_num>=as.Date('2019-08-01')&date_num<=as.Date('2020-04-15')]

fwrite(positions[, -c('date_num'), with=F], '../temp/positions.csv')

if(0){

placements <- fread('../output/placements.csv', select = 'id')
ids = unique(placements$id)


test = data.table(id=848051, track_id=7891358, date = as.Date('2018-08-01'))
setkey(test, id, track_id,date)
setkey(dt, playlist_id, track_id, date_num)

# max roll = `x` days before
dt[test, roll=14]

}