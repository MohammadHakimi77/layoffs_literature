# Obtain raw data files from AWS S3

# In the case of replicating this project using files with a populated \externals directory,
# this file does not need to be run.

dir.create('../externals')
cat('Downloading required files for project...', fill=T)
system('aws s3 sync s3://uvt-platformpower/derived/2024_07_13 ../externals --region eu-central-1 --exclude "*.*" --include "platformpower.zip" --size-only')

# set timestamp of data.log to latest downloaded file from AWS
unlink('../externals/data.log')
files = list.files('../externals/', full.names = T)

cat('Done!\n')
sink('../externals/data.log')
cat('Downloaded files.\n')
cat('Latest timestamp: \n')
print(ts)
cat('\n')
sink()

for (.f in files) system(paste0('touch ../externals/', .f))



