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

test_that("we can set intial annual report due dates", {
  # Read in environmental contact times
  readRenviron(file.path(system.file(package = "awardsBot"), "contact_times"))
  annual_report_time <- as.numeric(Sys.getenv("ANNUAL_REPORT_TIME"))
  
  db <- read.csv(file.path(system.file(package = "awardsBot"), "example_db.csv"))
  db <- set_first_annual_report_due_date(db, annual_report_time)
  
  expect_equal(db$contact_annual_report_next, c("2019-03-01", "2019-05-01"))
})

test_that("we can update annual report due dates", {
  db <- read.csv(file.path(system.file(package = "awardsBot"), "example_db.csv"))
  
  db <- set_first_annual_report_due_date(db, annual_report_time)
  db$contact_annual_report_previous <- db$contact_annual_report_next
  db <- update_annual_report_due_date(db)
  
  expect_equal(db$contact_annual_report_next, c("2020-03-01", "2020-05-01"))
})

