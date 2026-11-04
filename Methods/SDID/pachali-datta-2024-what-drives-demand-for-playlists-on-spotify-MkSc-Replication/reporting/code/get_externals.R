dir.create('../externals')
cat('Downloading required files for project...', fill=T)
system('aws s3 sync s3://uvt-platformpower/analysis/2024_07_11/ ../externals --region eu-central-1 --include "*.*" --exclude "results.RData"')

cat('Done!\n')
sink('../externals/data.log')
cat('Downloaded files.\n')
cat(Sys.time())
cat('\n')
sink()


