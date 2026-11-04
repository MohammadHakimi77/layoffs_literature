library(stringr)
options(echo=TRUE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)

if (is.na(args[1])) args[1] = 'tables_result.R'# args[1] = '[.](R|rmd)$'


# find all source code files in (sub)folders
files <- list.files(pattern=args[1], all.files=T, recursive=T, full.names = T, ignore.case=T)

for (fn in files) {
  
  code=scan(fn, what = 'character', sep = '\n', quiet = TRUE)
  code <- stringr::str_trim(code)
  # retain code that loads stuff
  code_load <- code[grepl('fread|^load|read[.]csv|read[_]|^source[(]', code, ignore.case=T)]
  code_save <- code[grepl('^fwrite|^save|^write[.]csv|^write[_]|^sink|^system|^png|^pdf|^ggsave', code, ignore.case=T)]
  
  
  cat(paste0('\n\nMake rules for: ', fn, ':\n'))
  cat('   Inputs:\n')
  for (.c in code_load) cat(paste0('      ', .c, '\n'))
  cat('   Outputs:\n')
  for (.c in code_save) cat(paste0('      ', .c, '\n'))
}
