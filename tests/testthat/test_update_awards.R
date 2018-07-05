context("Update NSF awards database")

test_that("update_awards updates an existing database with NSF API information", {
  path <- file.path(tempdir(), "awardsDB.csv")
  
  db <- create_blank_database()
  write.csv(db, path, row.names = FALSE)
  
  db <- update_awards(path, from_date = as.Date("2018-06-28"), to_date = as.Date("2018-07-05"))
  
  expect_equal(db$piFirstName[2], "Bruce")
  expect_equal(db$id[3], "1822021")
})

