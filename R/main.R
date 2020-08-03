## TODO add a slack message that details every email sent per day?
main <- function(database_path = Sys.getenv('DATABASE_PATH'),
                 lastrun_path = Sys.getenv('LASTRUN_PATH'),
                 current_date = as.character(Sys.Date()),
                 annual_report_time = Sys.getenv('ANNUAL_REPORT_TIME'),
                 initial_aon_offset = Sys.getenv('INITIAL_AON_OFFSET'),
                 aon_recurring_interval = Sys.getenv('AON_RECURRING_INTERVAL')) {
  
  annual_report_time <-  as.numeric(annual_report_time)
  initial_aon_offset <-  as.numeric(initial_aon_offset)
  aon_recurring_interval <-  as.numeric(aon_recurring_interval)
  
  
  ## Import awards database 
  db <- import_awards_db(database_path)
  
  ## Update awards database 
  lastrun <- get_lastrun(lastrun_path)
  db <- update_awards(db, lastrun, current_date)
  db <- update_contact_dates(db, annual_report_time, initial_aon_offset, aon_recurring_interval) 
  
  ## Send correspondences 
  db <- send_correspondences(db)
  
  ## Save lastrun and database 
  save_lastrun(current_date, lastrun_path)
  utils::write.csv(db, file = database_path, row.names = FALSE)
  
  return(invisible())
}

# Wrapper for main, with additional email testing argument. 
test_main <- function(database_path = Sys.getenv('DATABASE_PATH'),
                      lastrun_path = Sys.getenv('LASTRUN_PATH'),
                      current_date = as.character(Sys.Date()),
                      annual_report_time = Sys.getenv('ANNUAL_REPORT_TIME'),
                      initial_aon_offset = Sys.getenv('INITIAL_AON_OFFSET'),
                      aon_recurring_interval = Sys.getenv('AON_RECURRING_INTERVAL'),
                      email) {
  
  annual_report_time <-  as.numeric(annual_report_time)
  initial_aon_offset <-  as.numeric(initial_aon_offset)
  aon_recurring_interval <-  as.numeric(aon_recurring_interval)
  
  # Change email to testing email 
  db <- import_awards_db(database_path)
  db$pi_email <- email
  utils::write.csv(db, database_path, row.names = FALSE)
  
  main(database_path = database_path, lastrun_path = lastrun_path, current_date = current_date,
       annual_report_time = annual_report_time, initial_aon_offset = initial_aon_offset,
       aon_recurring_interval = aon_recurring_interval)
  
}

## Run a separate cron bot that notifies with correspondences 
## include some logic to only run this when Sys.Date() changes, the rest can run every 15 minutes.  