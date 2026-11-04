cat('Uploading results to S3...', fill=T)
system('aws s3 sync ../output/ s3://uvt-platformpower/analysis/2024_07_14/ --region eu-central-1 --size-only')

cat('Done!\n')
sink('../temp/upload.log')
cat('Uploaded files.\n')
cat(Sys.time())
cat('\n')
sink()


