library(rt)
context('Send RT correspondences')

rt_url <- 'https://support.nceas.ucsb.edu/rt'

test_that('we can get all the correspondences for all the tickets', {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  tickets <- get_tickets_with_new_incoming_correspondence("2021-05-03")
  
  expect_equal(length(tickets),20)
  
  ticket_none <- get_tickets_with_new_incoming_correspondence("2021-05-11")
  expect_null(ticket_none)

})

test_that('we can get a correspondence for a ticket', {
  if (!check_rt_login(rt_url)) {
    skip('Not logged in to RT. Skipping Test.')
  }
  
  corr <- get_recent_incoming_correspondence("21866", "2021-05-03")
  
  expect_equal(corr[[1]][1],
               "Correspondence by nhbigelow@alaska.edu on <https://support.nceas.ucsb.edu/rt/Ticket/Display.html?id=21866|Ticket 21866>:\n> Thanks for the info about NSF's Arctic Data Center.  I've pasted below our data management plan.  FYI, I've just enquired about getting a no-cost extension as our analyses have been significantly del...")
  expect_equal(get_recent_incoming_correspondence("21801", "2021-05-03"), list())
  
})


