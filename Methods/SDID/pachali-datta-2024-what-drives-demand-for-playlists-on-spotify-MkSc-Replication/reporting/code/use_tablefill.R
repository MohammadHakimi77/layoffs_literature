saveTable <- function (outfile, tag, outmatrix, append = T) {
  cat(tag,
      sep    = "\n",
      file   = outfile,
      append = append)
  
  write.table(outmatrix,
              file      = outfile,
              sep       = "\t",
              append    = TRUE,
              quote     = FALSE,
              col.names = FALSE,
              row.names = FALSE,
              na = "")
}
