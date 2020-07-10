library(rt)
context('Send RT correspondences')

rt_url <- 'https://support.nceas.ucsb.edu/rt'

## TODO these tests could be improved with an rt::get_last_correspondence_text function

test_that('we can create an RT ticket', {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  db <- create_dummy_database()
  
  #does not return ticket but creates ticket
  ticket <- create_ticket(db$id, db$pi_email)
  
  expect_type(ticket, 'character')
})

test_that('create_ticket errors gracefully', {
  if (check_rt_login(rt_url)) {
    skip('Logged in to RT. Test will probably not pass')
  }
  if (Sys.getenv('SLACK_WEBHOOK_URL') == '') {
    skip('Run slackr_setup() to run this test')
  }
  
  db <- create_dummy_database()
  ticket <- create_ticket(db$id, db$pi_email)
  
  # create_ticket ouputs the character 'error' when it fails
  expect_equal(ticket, 'rt_ticket_create_error')
})

test_that('we can send an initial correspondence', {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  db <- create_dummy_database()
  db <- create_ticket_and_send_initial_correspondence(db)
  
  ticket <- rt::rt_ticket_properties(db$rt_ticket, rt_url)
  expect_equal(ticket$content$Requestors, 'jasminelai@nceas.ucsb.edu')
})

test_that('we can send an annual report correspondence', {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  db <- create_dummy_database()
  db <- create_ticket_and_send_initial_correspondence(db)
  db$contact_annual_report_next <- as.character(Sys.Date())
  db <- send_annual_report_correspondence(db)
  
  expect_equal(db$contact_annual_report_next, db$contact_annual_report_previous)
})

test_that('we can send a one month remaining correspondence',{
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  db <- create_dummy_database()
  db <- create_ticket_and_send_initial_correspondence(db)
  # Set expiration date to one month from now
  db$contact_1mo <- as.character(Sys.Date())
  db <- send_one_month_remaining_correspondence(db)
  
  expect_equal(db$contact_1mo, as.character(Sys.Date()))
})

test_that('we can send an aon correspondence', {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  db <- create_dummy_database()
  db <- create_ticket_and_send_initial_correspondence(db)
  db$contact_aon_next <- as.character(Sys.Date())
  db <- send_aon_correspondence(db)
  
  expect_equal(db$contact_aon_previous, db$contact_aon_next)
})

test_that('one error in the database does not the initial contact for loop', {
  # this is the test for 'rt_ticket_create_error' error handling
})

test_that('check_rt_reply catches both potential errors', {})

test_that('send correspondences works', {})