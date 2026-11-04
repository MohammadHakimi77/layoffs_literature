cat('Uploading results to S3...', fill=T)
system('aws s3 sync . s3://uvt-platformpower/replication_package_public/2024_07_14/ --region eu-central-1 --size-only')
