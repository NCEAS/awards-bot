## Testing functions 

create_blank_database <- function() {
  col_names <- c("awardee",
                 "date",
                 "expDate",
                 "fundProgramName",
                 "id",
                 "piEmail",
                 "piFirstName",
                 "piLastName",
                 "piPhone",
                 "poName",
                 "startDate",
                 "title",
                 "rtTicket",
                 "piORCID",
                 "contact_initial",
                 "contact_3mo",
                 "contact_1mo",
                 "contact_1wk",
                 "adcPids")
   
  blank_db <- data.frame(matrix(ncol = length(col_names), nrow = 0))
  colnames(blank_db) <- col_names
  
  return(blank_db)
}

write_blank_database <- function(path) {
  stopifnotfile.exists(dirname(path))
  
  db <- create_blank_database()
  write.csv(db, path, row.names = FALSE)
  
  return(invisible())
}