context('NSF awards database functions')

test_that('update_awards updates an existing database with NSF API information', {
  db <- create_blank_database()
  db <- update_awards(db, from_date = as.Date('2018-06-28'), to_date = as.Date('2018-07-05'))

  expect_equal(db$pi_first_name[2], 'Bruce')
  expect_equal(db$id[3], '1822021')
})

test_that('update_awards does not overwrite existing rows', {
  db <- create_blank_database()
  db <- update_awards(db, from_date = as.Date('2018-06-28'), to_date = as.Date('2018-07-05'))
  db$rt_ticket[1] <- 'test_ticket_number'
  
  # update awards with the same information 
  db <- update_awards(db, from_date = as.Date('2018-06-28'), to_date = as.Date('2018-07-05'))
  
  expect_equal(db$rt_ticket[1], 'test_ticket_number')
})

test_that('we can set intial annual report due dates', {
  db <- import_awards_db(file.path(system.file('example_db.csv', package = 'awardsBot')))
  db <- set_first_annual_report_due_date(db, annual_report_time = 8)
  
  expect_equal(db$contact_annual_report_next, c('2019-03-01', '2019-05-01'))
})

test_that('we can update annual report due dates', {
  db <- import_awards_db(file.path(system.file('example_db.csv', package = 'awardsBot')))
  
  db <- set_first_annual_report_due_date(db, annual_report_time = 8)
  db$contact_annual_report_previous <- db$contact_annual_report_next
  db <- update_annual_report_due_date(db)
  
  expect_equal(db$contact_annual_report_next, c('2020-03-01', '2020-05-01'))
})

test_that('we can set initial aon data due dates', {
  db <- import_awards_db(file.path(system.file('example_db.csv', package = 'awardsBot')))
  db <- set_first_aon_data_due_date(db, initial_aon_offset = 11)
  
  expect_equal(db$contact_aon_next, c('2019-06-01', NA))
})

test_that('we can update aon data due dates', {
  db <- import_awards_db(file.path(system.file('example_db.csv', package = 'awardsBot')))
  
  db <- set_first_aon_data_due_date(db, initial_aon_offset = 11)
  db$contact_aon_previous <- db$contact_aon_next
  db <- update_aon_data_due_date(db, aon_recurring_interval = 6)
  
  expect_equal(db$contact_aon_next, c('2019-12-01', NA))
})

test_that('we can set one month remaining date', {
  db <- import_awards_db(file.path(system.file('example_db.csv', package = 'awardsBot')))
  
  db <- set_one_month_remaining_date(db)
  expect_equal(db$contact_1mo, as.character(as.Date(db$exp_date) %m+% months(-1)))
})

test_that('we can read in the last time the bot ran', {
    file_path <- file.path(tempdir(), 'LASTRUN')
    writeLines(as.character(Sys.Date()), file_path)
    lastrun <- get_lastrun(file_path)
    
    expect_equal(lastrun, Sys.Date())
})

test_that('get_lastrun errors gracefully', {})

test_that('we can save the last time the bot ran', {
  file_path <- file.path(tempdir(), 'LASTRUN')
  writeLines('dummy text', file_path)
  save_lastrun('text to save', file_path)
  
  expect_equal(readLines(file_path), 'text to save')
})

test_that('get_award works and does not produce duplicates', {
  nsf_awards <- awardsBot::get_awards(from_date = '06/25/2021', to_date = "09/02/2021")
  
  expect_equal(nsf_awards$id, unique(nsf_awards$id))
})

test_that('get_award works when there are no new awards', {
  nsf_awards <- awardsBot::get_awards(from_date = '09/08/2021', to_date = "09/09/2021")
  
  expect_equal(nsf_awards, data.frame())
  
})

test_that('update_contact_dates wrapper works', {})


