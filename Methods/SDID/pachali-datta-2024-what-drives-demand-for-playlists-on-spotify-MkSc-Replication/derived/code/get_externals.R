# Download raw data files for building data set

dir.create('../externals')
cat('Downloading required files for project...', fill=T)
system('aws s3 sync s3://uvt-platformpower/raw-parsed/2021_10_31 ../externals')
system('aws s3 sync s3://uvt-platformpower/raw/chartmetric/2020_07_08/ ../externals')
system('aws s3 sync s3://uvt-data-music-streaming/everynoise/releases/2021_03_29 ../externals --exclude "*.*" --include "everynoise-new-releases.csv"')
system('aws s3 sync s3://uvt-data-music-streaming/everynoise/releases/2023_01_03 ../externals')
system('aws s3 sync s3://uvt-data-music-streaming/everynoise/releases/2023_01_04 ../externals --exclude "*.*" --include "promotions.csv"')
system('aws s3 sync s3://uvt-platformpower/raw/kaggle-charts/2023-07-06 ../externals/kaggle')

# set timestamp of data.log to latest downloaded file from AWS
files = list.files('../externals/', pattern = 'everynoise|promotions|new[-]releases|chartmetric[.]zip|cm[-]export', full.names = T)

ts=format(as.POSIXct(max(sapply(files, function(x) file.info(x)$mtime)), origin="1970-01-01")+60, '%Y%m%d%H%M')

cat('Done!\n')
sink('../externals/data.log')
cat('Downloaded files.\n')
cat('Latest timestamp: \n')
print(ts)
cat('\n')
sink()
