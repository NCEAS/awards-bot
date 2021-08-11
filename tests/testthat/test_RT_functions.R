library(rt)
context('Send RT correspondences')

rt_url <- 'https://support.nceas.ucsb.edu/rt'
db_path<- tempfile()

## TODO these tests could be improved with an rt::get_last_correspondence_text function

test_that('we can create an RT ticket', {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  db <- create_dummy_database()
  
  #does not return ticket but creates ticket
  ticket <- create_ticket(db$id, db$pi_email)
  
  expect_type(ticket, 'double')
})

test_that('we can send an initial correspondence', {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  db <- create_dummy_database()

  db <- create_ticket_and_send_initial_correspondence(db, database_path = db_path)
  
  ticket <- rt::rt_ticket_properties(db$rt_ticket[2])
  expect_equal(ticket$Requestors, 'jasminelai@nceas.ucsb.edu')
})

test_that('we can send an annual report correspondence', {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  db <- create_dummy_database()
  db <- create_ticket_and_send_initial_correspondence(db, database_path = db_path)
  db$contact_annual_report_next[2] <- as.character(Sys.Date())
  db <- send_annual_report_correspondence(db, database_path = db_path)
  
  expect_equal(db$contact_annual_report_next[2], db$contact_annual_report_previous[2])
})

test_that('we can send a one month remaining correspondence',{
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  db <- create_dummy_database()
  db <- create_ticket_and_send_initial_correspondence(db, database_path = db_path)
  # Set expiration date to one month from now
  db$contact_1mo <- as.character(Sys.Date())
  db <- send_one_month_remaining_correspondence(db, database_path = db_path)
  
  expect_equal(db$contact_1mo[2], as.character(Sys.Date()))
})

test_that('we can send an aon correspondence', {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  db <- create_dummy_database()
  db <- create_ticket_and_send_initial_correspondence(db, database_path = db_path)
  db$contact_aon_next[2] <- as.character(Sys.Date())
  db <- send_aon_correspondence(db, database_path = db_path)
  
  expect_equal(db$contact_aon_previous, db$contact_aon_next)
})

test_that('one error in the database does not the initial contact for loop', {
  # this is the test for 'rt_ticket_create_error' error handling
})

test_that('check_rt_reply catches both potential errors', {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  db <- create_dummy_database()
  db <- create_ticket_and_send_initial_correspondence(db, database_path = db_path)
  
  template <- read_initial_template(db$fund_program_name[1])
  email_text <- sprintf(template,
                        db$pi_first_name[1],
                        db$id[1],
                        db$title[1])
  
  reply <- check_rt_reply(db$rt_ticket[1], email_text)
  expect_type(reply, "double")
})

test_that('send correspondences works', {})