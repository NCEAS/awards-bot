library(rt)
context('Send RT correspondences')

rt_url <- 'https://support.nceas.ucsb.edu/rt'

test_that('we can get all the correspondences for all the tickets', {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  tickets <- get_tickets_with_new_incoming_correspondence("2021-05-03")
  expect_equal(length(tickets), 20)
  
  ticket_none <- get_tickets_with_new_incoming_correspondence("2021-05-11")
  expect_null(ticket_none)

})

test_that('we can get a correspondence for a ticket', {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  corr <- get_recent_incoming_correspondence("21866", "2021-05-03")
  
  expect_equal(corr[[1]][1],
               "Correspondence by nhbigelow@alaska.edu on <https://support.nceas.ucsb.edu/rt/Ticket/Display.html?id=21866|Ticket 21866>:\n>Dear Jasmine,Thanks for the info about NSF's Arctic Data Center.  I've pasted below ourdata management plan.FYI, I've just enquired about getting a no-cost extension as our analyseshave been signif...")
  expect_equal(get_recent_incoming_correspondence("21801", "2021-05-03"), list())
  
})

test_that('we can format the response message correctly', {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  response <- rt::rt_ticket_history_entry("21866", "520747")
  expect_equal(format_history_entry(response, trunc_at = 200),
               "Correspondence by nhbigelow@alaska.edu on <https://support.nceas.ucsb.edu/rt/Ticket/Display.html?id=21866|Ticket 21866>:\n>Dear Jasmine,Thanks for the info about NSF's Arctic Data Center.  I've pasted below ourdata management plan.FYI, I've just enquired about getting a no-cost extension as our analyseshave been signif...")
  
})

test_that("send slack messages for all new correspondences", {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  #test slack 
  tickets <- get_tickets_with_new_incoming_correspondence("2021-05-03")
  
  # slack_login is NULL if the message sends 
  slack_login <- tryCatch(slackr::slackr_bot('Testing awardsBot check slack correspondence functions'),
                          error = function(e) return(TRUE))
  if (is.null(slack_login)) {
    skip('Slack not configured. Skipping Test.')
  }
  
  for(ticket in tickets){
    for(corr in ticket){
      slackr::slackr_bot(corr)
    }
  }  
})

