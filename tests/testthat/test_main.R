rt_url <- 'https://support.nceas.ucsb.edu/rt'

test_that('main sends correspondences and updates the database', {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  # slack_login is NULL if the message sends 
  slack_login <- tryCatch(slackr::slackr_bot('Testing awardsBot::main function'),
                          error = function(e) return(TRUE))
  if (!is.null(slack_login)) {
    skip('Slack not configured. Skipping Test.')
  }
  
  ## Initiliaze main() inputs.  These can change if the .Renviron file that stores these system variables is updated.
  annual_report_time <- 8 
  initial_aon_offset <- 11 
  aon_recurring_interval <- 6 
  email <- 'mullen@nceas.ucsb.edu'  # set to the test email you're using.  
  
  ## Initialize database and lastrun
  db <- import_awards_db(file.path(system.file('example_db.csv', package = 'awardsBot')))
  database_path <- file.path(tempdir(), 'temp_db.csv')
  utils::write.csv(db, database_path, row.names = FALSE)
  lastrun_path <- file.path(tempdir(), 'LASTRUN')
  writeLines(as.character(Sys.Date()), lastrun_path)
  
  
  ## This iteration of main() should create two RT tickets, send initial correspondence emails, and update contact times in the database
  test_main(database_path = database_path, 
            lastrun_path = lastrun_path, 
            current_date = as.character(Sys.Date()),
            annual_report_time = annual_report_time,
            initial_aon_offset = initial_aon_offset,
            aon_recurring_interval = aon_recurring_interval,
            email = email)

  db <- import_awards_db(database_path)
  expect_type(db$rt_ticket, 'character')
  expect_equal(db$contact_initial, rep(as.character(Sys.Date()), 2))
  expect_equal(db$contact_annual_report_next,
               as.character(as.Date(db$start_date) %m+% months(annual_report_time)))
  expect_equal(db$contact_aon_next[1],
               as.character(as.Date(db$start_date[1]) %m+% months(initial_aon_offset)))
  
  ## Test that main() sends annual report reminders 
  db$contact_annual_report_next <- as.character(Sys.Date())
  utils::write.csv(db, database_path, row.names = FALSE)
  test_main(database_path = database_path, 
            lastrun_path = lastrun_path, 
            current_date = as.character(Sys.Date()),
            annual_report_time = annual_report_time,
            initial_aon_offset = initial_aon_offset,
            aon_recurring_interval = aon_recurring_interval,
            email = email)
  
  db <- import_awards_db(database_path)
  expect_equal(db$contact_annual_report_previous, rep(as.character(Sys.Date()), 2))
  
  ## Test that main sends AON reminders and moves next annual report reminder date ahead 1 year 
  db$contact_aon_next[1] <- as.character(Sys.Date())
  utils::write.csv(db, database_path, row.names = FALSE)
  test_main(database_path = database_path, 
            lastrun_path = lastrun_path, 
            current_date = as.character(Sys.Date()),
            annual_report_time = annual_report_time,
            initial_aon_offset = initial_aon_offset,
            aon_recurring_interval = aon_recurring_interval,
            email = email)
  
  db <- import_awards_db(database_path)
  expect_equal(db$contact_aon_previous[1], as.character(Sys.Date()))
  expect_equal(db$contact_annual_report_next, rep(as.character(Sys.Date() %m+% months(12)), 2))
  
  ## Test that main sends one month remaining reminders and moves next annual aon data reminder date ahead by 'aon_recurring_interval' months
  db$exp_date <- as.character(Sys.Date() %m+% months(1))
  utils::write.csv(db, database_path, row.names = FALSE)
  test_main(database_path = database_path, 
            lastrun_path = lastrun_path, 
            current_date = as.character(Sys.Date()),
            annual_report_time = annual_report_time,
            initial_aon_offset = initial_aon_offset,
            aon_recurring_interval = aon_recurring_interval,
            email = email)
  
  db <- import_awards_db(database_path)
  expect_equal(db$contact_1mo, rep(as.character(Sys.Date()), 2))
  expect_equal(db$contact_aon_next[1], as.character(Sys.Date() %m+% months(aon_recurring_interval)))
})
