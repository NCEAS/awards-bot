context("NSF awards database functions")

test_that("update_awards updates an existing database with NSF API information", {
  db <- create_blank_database()
  db <- update_awards(db, from_date = as.Date("2018-06-28"), to_date = as.Date("2018-07-05"))

  expect_equal(db$piFirstName[2], "Bruce")
  expect_equal(db$id[3], "1822021")
})

test_that("update_awards does not overwrite existing rows", {
  db <- create_blank_database()
  db <- update_awards(db, from_date = as.Date("2018-06-28"), to_date = as.Date("2018-07-05"))
  db$contact_3mo[2] <- "2018-07-05"
  
  # update awards with the same information 
  db <- update_awards(db, from_date = as.Date("2018-06-28"), to_date = as.Date("2018-07-05"))
  
  expect_equal(db$contact_3mo[2], "2018-07-05")
})

