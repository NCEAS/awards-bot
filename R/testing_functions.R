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
                 "contact_annual_report_previous",
                 "contact_annual_report_next",
                 "contact_aon",
                 "contact_3mo",
                 "contact_1mo",
                 "contact_1wk",
                 "adcPids")
   
  blank_db <- data.frame(matrix(ncol = length(col_names), nrow = 1))
  colnames(blank_db) <- col_names
  
  return(blank_db)
}

write_blank_database <- function(path) {
  stopifnot(file.exists(dirname(path)))
  
  db <- create_blank_database()
  write.csv(db, path, row.names = FALSE)
  
  return(invisible())
}

create_dummy_database <- function() {
  db <- create_blank_database()
  
  db$piEmail <- "mullen@nceas.ucsb.edu"
  db$piFirstName <- "Dominic"
  db$piLastName <- "Mullen"
  db$title <- "**Test** AwardBot Title"
  db$fundProgramName <- "ARCTIC NATURAL SCIENCES"
  db$id <- "1234567"  # NSF award number 
  
  return(db)
}
