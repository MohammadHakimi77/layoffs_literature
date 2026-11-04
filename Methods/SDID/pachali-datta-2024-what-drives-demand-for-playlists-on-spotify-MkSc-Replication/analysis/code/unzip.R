# Unzips the raw data sets

files = unzip('../externals/platformpower.zip', list=T)

unzip('../externals/platformpower.zip', exdir = "../temp")

for (.f in files$Name) system(paste0('touch ../temp/', .f))

sink('../temp/unzipping.log')
cat('unzipped data')
sink()