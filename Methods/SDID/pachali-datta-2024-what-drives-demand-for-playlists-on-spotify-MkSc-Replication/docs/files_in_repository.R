# create a timestamped list of files available in this repository
setwd('../')

library(data.table)


fs <- list.files('.', all.files=T, full.names=T, recursive=T)

files = data.table(full_filepath = fs)
files[, full_filepath := gsub('^[.][/]','',full_filepath)]
files[, filename:=sapply(full_filepath, function(x) rev(unlist(strsplit(x, '/')))[[1]])]
files[, index:=1:.N]
files[, path:=gsub(filename, '', full_filepath), by = 'index']
files[, index:=NULL]



# define files that need to be excluded from the fill tree (e.g., system-internal files)
files[, exclude:=F]
files[grepl('.git[/]', full_filepath), exclude:=T]
files[grepl('[.]gitignore', full_filepath), exclude:=F]

files <- files[exclude==F][, exclude:=NULL]

# define confidential files (i.e., files that will not be shared/cannot be shared)
files[, confidential:=F]
files[grepl('^[.]confidential', filename), confidential:=T]
files[grepl('derived/externals[/]', full_filepath), confidential:=T]
files[grepl('derived/output[/]', full_filepath), confidential:=T]
files[grepl('derived/temp[/]', full_filepath), confidential:=T]

files[grepl('^docs[/]', full_filepath), confidential:=F]
files[grepl('files_in_repository[.]csv', full_filepath), confidential:=F]

# include file info
info = file.info(files$full_filepath)

files <- cbind(files, info)

# remove unnecessary content
files[, ':=' (isdir=NULL, mode=NULL)]

setcolorder(files, c('path', 'filename', 'full_filepath', 'confidential', 'ctime', 'mtime','atime'))
setnames(files, 'mtime', 'timestamp_modified')
setnames(files, 'ctime', 'timestamp_created')
setnames(files, 'atime', 'timestamp_last_accessed')

setorder(files, path, filename, timestamp_created)

fwrite(files, file = 'docs/files_in_repository.csv')
