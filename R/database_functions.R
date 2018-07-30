#' Read in awards 
#' 
#' Run this to get the awards database file 
#' 
#' @param DATABASE_PATH (character) globally defined 
#' 
#' @export
import_awards_db <- function(DATABASE_PATH) {
  tryCatch({
    awards_db <- utils::read.csv(DATABASE_PATH) %>% 
      apply(2, as.character) %>% # force all fields into characters
      data.frame(stringsAsFactors = FALSE)
  },
  error = function(e) {
    slackr::slackr_bot("I failed to read in the awards database file")
  })
  
  return(awards_db)
}

#' Update Awards Database
#' 
#' Run this code to get the awards database with updated awards
#'
#' @param awards_db (data.frame) awards database to file containing database
#' @param from_date (date) date to begin search from 
#' @param to_date (date) date to end search at 
#'
#' @export
update_awards <- function(awards_db, from_date, to_date) {
  
  ## format dates
  format <- "%m/%d/%Y"
  to_date <- format(as.Date(to_date), format)
  from_date <- format(as.Date(from_date), format)
  
  ## get new awards from NSF API
  new_nsf_awards <- datamgmt::get_awards(from_date = from_date, to_date = to_date)
  new_nsf_awards <- new_nsf_awards[!(new_nsf_awards$id %in% awards_db$id), ]
  
  ## combine awards
  awards_db <- suppressWarnings(dplyr::bind_rows(awards_db, new_nsf_awards)) %>%
    check_date_format()

  return(awards_db)
}

#' Wrapper function for set_first_annual_report_due_date, update_annual_report_due_date
#' set_first_aon_data_due_date, update_aon_data_due_date
update_contact_dates <- function(awards_db,
                                 annual_report_time,
                                 initial_aon_offset,
                                 aon_recurring_interval) {
  awards_db <- set_first_annual_report_due_date(awards_db, annual_report_time) %>%
    update_annual_report_due_date() %>%
    set_first_aon_data_due_date(initial_aon_offset) %>%
    update_aon_data_due_date(aon_recurring_interval)
  
  return(awards_db)
}

set_first_annual_report_due_date <- function(awards_db, annual_report_time) {
  indices <- which(is.na(awards_db$contact_annual_report_next))
  db <- awards_db[indices,]
  
  # Initialize first annual report as 'annual_report_time' months after 'startDate'
  startDate <- lubridate::ymd(db$startDate)
  db$contact_annual_report_next <- startDate %m+% months(annual_report_time) %>%
    as.character()
  
  awards_db[indices,] <- db
  
  return(awards_db)
}


update_annual_report_due_date <- function(awards_db) {
  indices <- which(awards_db$contact_annual_report_previous == awards_db$contact_annual_report_next)
  db <- awards_db[indices,]
  
  # Set next annual report date ahead 1 year
  date <- lubridate::ymd(db$contact_annual_report_next)
  db$contact_annual_report_next <- (date + lubridate::years(1)) %>%
    as.character()
  
  awards_db[indices,] <- db
  
  return(awards_db)
}


set_first_aon_data_due_date <- function(awards_db, initial_aon_offset){
  indices <- which((is.na(awards_db$contact_aon_next) & grepl("AON", awards_db$fundProgramName)))
  db <- awards_db[indices,]
  
  # Initialize first aon submissions as 'initial_aon_offset' months after 'startDate'
  startDate <- lubridate::ymd(db$startDate)
  db$contact_aon_next <- startDate %m+% months(initial_aon_offset) %>%
    as.character()
  
  awards_db[indices,] <- db
  
  return(awards_db)
}

#' Update AON data due dates
#' @importFrom lubridate "%m+%"
update_aon_data_due_date <- function(awards_db, aon_recurring_interval) {
  indices <- which(awards_db$contact_aon_previous == awards_db$contact_aon_next)
  db <- awards_db[indices,]
  
  # Set next aon data due date ahead 'aon_recurring_interval' months
  date <- lubridate::ymd(db$contact_aon_next)
  db$contact_aon_next <- (date %m+% months(aon_recurring_interval)) %>%
    as.character()
  
  awards_db[indices,] <- db
  
  return(awards_db)
}


#' this is needed if someone opens the database in excel and saves it as a csv, the dates format changes in this case
#' Also NSF dates are m-d-y whereas R dates are y-m-d
#' potentially there is a more elegant solution than the one here
#' Forcing date columns to y-m-d
check_date_format <- function(awards_db) {
  is_date <- which(colnames(awards_db) %in% c("date",
                                              "expDate",
                                              "startDate",
                                              "contact_initial",
                                              "contact_annual_report_previous",
                                              "contact_annual_report_next",
                                              "contact_aon_previous",
                                              "contact_aon_next",
                                              "contact_3mo"))
  
  awards_db[, is_date] <- apply(awards_db[, is_date], c(1,2), function(x){
    if (!is.na(x)) {  
      
      ## if not NA try to reformat date from m-d-y to y-m-d
      ## TODO need to test edge cases to ensure this always works
      tryCatch({
        paste0(lubridate::mdy(x))
      }, warning = function(w) {
        x
      })
      
    } else {
      NA
    }
  })
  
  return(awards_db)
}


get_lastrun <- function(path) {
  lastrun <- NULL

  if (file.exists(path)) {
    lastrun <- as.Date(readLines(path, n = 1))
  } 
  if (is.null(lastrun)) {
    out <- sprintf("I failed to read in my LASTRUN time. Check that %s exists. Setting LASTRUN to Sys.Date()", path)
    slackr::slackr_bot(out)
    lastrun <- Sys.Date()
  }
  
  return(lastrun)
}


save_lastrun <- function(lastrun, path) {
  writeLines(lastrun, path)
}

# TODO make a check_database() function
## can't have any NA db$expDate values, or startDate
# - probably can't have any NA date values for functions to work 
