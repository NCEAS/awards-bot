## TODO add a slack message that details every email sent per day?
main <- function(database_path = Sys.getenv("DATABASE_PATH"),
                 lastrun_path = Sys.getenv("LASTRUN_PATH"),
                 to_date = as.character(Sys.Date()),
                 annual_report_time = Sys.getenv("ANNUAL_REPORT_TIME"),
                 initial_aon_offset = Sys.getenv("INITIAL_AON_OFFSET"),
                 aon_recurring_interval = Sys.getenv("AON_RECURRING_INTERVAL")) {
  ## Import awards database 
  db <- import_awards_db(database_path)
  
  ## Update awards database 
  lastrun <- get_lastrun(lastrun_path)
  db <- update_awards(db, lastrun, to_date)
  db <- update_contact_dates(db, annual_report_time, initial_aon_offset, aon_recurring_interval) 
  
  ## Send correspondences 
  db <- send_correspondences(db)
  
  ## Save lastrun and database 
  save_lastrun(to_date, lastrun_path)
  utils::write.csv(db, file = database_path, row.names = FALSE)
  
  return(invisible())
}

## Same as main, although for testing swap out all email address for 'mullen@nceas.ucsb.edu'
test_main <- function(database_path = Sys.getenv("DATABASE_PATH"),
                      lastrun_path = Sys.getenv("LASTRUN_PATH"),
                      to_date = as.character(Sys.Date()),
                      annual_report_time = Sys.getenv("ANNUAL_REPORT_TIME"),
                      initial_aon_offset = Sys.getenv("INITIAL_AON_OFFSET"),
                      aon_recurring_interval = Sys.getenv("AON_RECURRING_INTERVAL"),
                      email) {
  ## Import awards database 
  db <- import_awards_db(database_path)
  
  ## Update awards database 
  lastrun <- get_lastrun(lastrun_path)
  db <- update_awards(db, lastrun, to_date)
  db <- update_contact_dates(db, annual_report_time, initial_aon_offset, aon_recurring_interval) 
  db$piEmail <- email
  
  ## Send correspondences 
  db <- send_correspondences(db)
  
  ## Save lastrun and database 
  save_lastrun(to_date, lastrun_path)
  utils::write.csv(db, file = database_path, row.names = FALSE)
  
  return(invisible())
}

## Run a separate cron bot that notifies with correspondences 
## include some logic to only run this when Sys.Date() changes, the rest can run every 15 minutes.  