context("Send RT correspondences")

rt_url <- "https://support.nceas.ucsb.edu/rt"

test_that("we can create an RT ticket", {
  if (!check_rt_login(rt_url)) {
    skip("Not logged in to RT. Skipping Test.")
  }
  
  db <- create_dummy_database()
  ticket <- create_ticket(db$id, db$piEmail)
  
  expect_type(ticket, "character")
})

test_that("we can send an initial correspondence", {
  if (!check_rt_login(rt_url)) {
    skip("Not logged in to RT. Skipping Test.")
  }
  
  db <- create_dummy_database()
  db <- create_ticket_and_send_initial_correspondence(db)
  
  ticket <- rt::rt_ticket_properties(db$rtTicket, rt_url)
  expect_equal(ticket$content$Requestors, "mullen@nceas.ucsb.edu")
})

test_that("one error in the database does not the for loop")

test_that("check_rt_reply catches both potential errors")