#' Import awards database 
#' 
#' Import awards database as an all-character data.frame. 
#' 
#' @param path (character) path to the awards database 
#' 
#' @export
import_awards_db <- function(path) {
  tryCatch({
    awards_db <- utils::read.csv(path) %>% 
      apply(2, as.character) %>% # force all fields into characters
      data.frame(stringsAsFactors = FALSE)
  },
  error = function(e) {
    slackr::slackr_bot('I failed to read in the awards database file')
  })
  
  return(awards_db)
}

#' Update Awards Database
#' 
#' Update the awards database with new awards information from the NSF API 
#' (https://www.research.gov/common/webapi/awardapisearch-v1.htm) using 
#'
#' @param awards_db (data.frame) awards database
#' @param from_date (date) date to begin search from 
#' @param to_date (date) date to end search at 
#'
#' @export
update_awards <- function(awards_db, from_date, to_date) {
  
  ## format dates
  format <- '%m/%d/%Y'
  to_date <- format(as.Date(to_date), format)
  from_date <- format(as.Date(from_date), format)
  
  ## get new awards from NSF API
  new_nsf_awards <- get_awards(from_date = from_date, to_date = to_date)
  
  if (nrow(new_nsf_awards) > 0) {
    colnames(new_nsf_awards) <- c('awardee', 'date', 'exp_date', 'fund_program_name',
                                  'id', 'pi_email', 'pi_first_name', 'pi_last_name',
                                  'pi_phone', 'po_name', 'start_date', 'title')
    new_nsf_awards <- new_nsf_awards[!(new_nsf_awards$id %in% awards_db$id), ]
    
    ## combine awards
    awards_db <- suppressWarnings(dplyr::bind_rows(awards_db, new_nsf_awards)) %>%
      check_date_format()
  }
  
  awards_db$active_award_flag <- ifelse(awards_db$exp_date >= Sys.Date(), 'yes', 'no')
  
  return(awards_db)
}

#' Update contact dates in awards database
#' 
#' Wrapper function for set_first_annual_report_due_date, update_annual_report_due_date
#' set_first_aon_data_due_date, update_aon_data_due_date
#' 
#' @param awards_db (data.frame) awards database
#' @param annual_report_time (numeric) time in months after 'start_date' to send the first annual report reminder
#' @param initial_aon_offset (numeric) time in months after 'start_date' to send the first aon data reminder
#' @param aon_recurring_interval (numeric) time in months to send aon data recurring reminders
#' 
#' @importFrom magrittr '%>%'
#' @importFrom lubridate '%m+%'
update_contact_dates <- function(awards_db,
                                 annual_report_time,
                                 initial_aon_offset,
                                 aon_recurring_interval) {
  indices <- which(awards_db$active_award_flag == 'yes') 
  db <- awards_db[indices,]
  
  db <- set_first_annual_report_due_date(db, annual_report_time) %>%
    update_annual_report_due_date() %>%
    set_first_aon_data_due_date(initial_aon_offset) %>%
    update_aon_data_due_date(aon_recurring_interval) %>%
    set_one_month_remaining_date()
  
  awards_db[indices,] <- db
  
  return(awards_db)
}


set_first_annual_report_due_date <- function(awards_db, annual_report_time) {
  indices <- which(is.na(awards_db$contact_annual_report_next))
  if (length(indices) > 0 ) {
    db <- awards_db[indices,]
    
    # Initialize first annual report as 'annual_report_time' months after 'start_date'
    start_date <- lubridate::ymd(db$start_date)
    db$contact_annual_report_next <- 
      start_date %m+% months(as.integer(annual_report_time)) %>% as.character()
    
    awards_db[indices,] <- db
  }
  
  return(awards_db)
}


update_annual_report_due_date <- function(awards_db) {
  indices <- which(awards_db$contact_annual_report_previous == awards_db$contact_annual_report_next)
  if (length(indices) > 0) {
    db <- awards_db[indices,]
    
    # Set next annual report date ahead 1 year
    date <- lubridate::ymd(db$contact_annual_report_next)
    db$contact_annual_report_next <- (date + lubridate::years(1)) %>%
      as.character()
    
    awards_db[indices,] <- db
  }
  
  return(awards_db)
}


set_first_aon_data_due_date <- function(awards_db, initial_aon_offset){
  indices <- which((is.na(awards_db$contact_aon_next) & grepl('AON', awards_db$fund_program_name)))
  if (length(indices) > 0) {
    db <- awards_db[indices,]
    
    # Initialize first aon submissions as 'initial_aon_offset' months after 'start_date'
    start_date <- lubridate::ymd(db$start_date)
    db$contact_aon_next <- 
      start_date %m+% months(as.integer(initial_aon_offset)) %>% as.character()
    
    awards_db[indices,] <- db
  }
  
  return(awards_db)
}

update_aon_data_due_date <- function(awards_db, aon_recurring_interval) {
  indices <- which(awards_db$contact_aon_previous == awards_db$contact_aon_next)
  if (length(indices) > 0) {
    db <- awards_db[indices,]
    
    # Set next aon data due date ahead 'aon_recurring_interval' months
    date <- lubridate::ymd(db$contact_aon_next)
    db$contact_aon_next <- 
      (date %m+% months(as.integer(aon_recurring_interval))) %>% as.character()
    
    awards_db[indices,] <- db
  }
  
  return(awards_db)
}

set_one_month_remaining_date <- function(awards_db) {
  exp_date <- lubridate::ymd(awards_db$exp_date)
  awards_db$contact_1mo <- exp_date %m+% months(-1) %>%
    as.character()
  
  return(awards_db)
}


# this is needed if someone opens the database in excel and saves it as a csv, the dates format changes in this case
# Also NSF dates are m-d-y whereas R dates are y-m-d
# potentially there is a more elegant solution than the one here
# Forcing date columns to y-m-d
check_date_format <- function(awards_db) {
  is_date <- which(colnames(awards_db) %in% c('date',
                                              'exp_date',
                                              'start_date',
                                              'contact_initial',
                                              'contact_annual_report_previous',
                                              'contact_annual_report_next',
                                              'contact_aon_previous',
                                              'contact_aon_next',
                                              'contact_3mo'))
  
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
    out <- sprintf('I failed to read in my LASTRUN time. Check that %s exists. Setting LASTRUN to Sys.Date()', path)
    slackr::slackr_bot(out)
    lastrun <- Sys.Date()
  }
  
  return(lastrun)
}


save_lastrun <- function(lastrun, path) {
  writeLines(lastrun, path)
}


#' Get NSF Arctic/Polar program award information.  
#'
#' Uses the \href{https://www.research.gov/common/webapi/awardapisearch-v1.htm}{NSF API}
#' to get all records pertaining to the Arctic or Polar programs. Originally in the
#' 'NCEAS/datamgmt' package.  Added to this repo because the import of datamgmt is too costly.  
#'
#' @param from_date (character) Optional. Returns all
#' records with start date after specified date.
#' Format = \emph{mm/dd/yyyy}
#' @param to_date (character) Optional. Returns all
#' records with start date before specified date.
#' Format = \emph{mm/dd/yyyy}
#' @param query (character) Optional. By default, the function
#' searches for all awards with either 'polar' or 'arctic' in
#' the fundProgramName. Additional queries can be specified
#' as defined in the \href{https://www.research.gov/common/webapi/awardapisearch-v1.htm}{NSF API}.
#' Use '&' to join multiple queries (i.e., \emph{keyword=water&agency=NASA})
#' @param print_fields (character) Optional. By default, the
#' following fields will be returned: id, date,
#' startDate, expDate, fundProgramName, poName,
#' title, awardee, piFirstName, piLastName, piPhone, piEmail.
#' Additional field names can be found in the printFields description
#' of the \href{https://www.research.gov/common/webapi/awardapisearch-v1.htm}{NSF API}.
#'
#' @import XML
#' @import stringr
#' @importFrom RCurl getURL
#'
#' @export
#'
#' @author Irene Steves
#'
#' @examples
#' \dontrun{
#' all_awards <- get_awards()
#' new_awards <- get_awards(from_date = '01/01/2017')
#' }

get_awards <- function(from_date = NULL,
                       to_date = NULL,
                       query = NULL,
                       print_fields = NULL) {
  # TODO use additional_fields instead of print_fields so that user can specify additional fields
  # without having to write out all default fields
  
  # TODO split iteration part of function (repeat...) and arctic/polar customization to make 2 functions:
  # 1 - a generalized get_awards(query_URL)
  # 2 - a wrapper for get_polar_awards() for typical use-cases within ADC/NCEAS
  
  # basic argument checks
  stopifnot(is.character(from_date) | is.null(from_date))
  stopifnot(is.character(to_date) | is.null(to_date))
  stopifnot(is.character(query) | is.null(query))
  stopifnot(is.character(print_fields) | is.null(print_fields))
  
  base_url <- 'https://api.nsf.gov/services/v1/awards.xml?fundProgramName=ARCTIC|fundProgramName=POLAR|fundProgramName=AON'
  if(!is.null(query)) {
    query <- paste0('&', query)
  }
  
  if(is.null(print_fields)) {
    print_fields <- 'id,date,startDate,expDate,fundProgramName,poName,title,awardee,piFirstName,piLastName,piPhone,piEmail'
  }
  
  query_url <- paste0(base_url, query,
                      '&printFields=', print_fields)
  
  if(!is.null(from_date)) {
    if(!stringr::str_detect(from_date, '\\d\\d/\\d\\d/\\d\\d\\d\\d')) {
      stop('The from_date is not in the format "mm/dd/yyyy".')
    } else {
      query_url <- paste0(query_url, '&dateStart=', from_date)
    }
  }
  
  if(!is.null(to_date)) {
    if(!stringr::str_detect(to_date, '\\d\\d/\\d\\d/\\d\\d\\d\\d')) {
      stop('The to_date is not in the format "mm/dd/yyyy".')
    } else {
      query_url <- paste0(query_url, '&dateEnd=', to_date)
    }
  }
  
  xml1 <- RCurl::getURL(paste0(query_url, '&offset=', 1))
  if(stringr::str_detect(xml1, 'ERROR')){
    stop('The query parameters are invalid.')
  }
  xml_df1 <- XML::xmlToDataFrame(xml1, stringsAsFactors = FALSE)
  
  # since we can only download 25 entries at a time, we need to loop through the query using different offsets
  n <- 1
  repeat {
    start <- 1 + 25 * n
    xml <- RCurl::getURL(paste0(query_url, '&offset=', start))
    xml_df <- XML::xmlToDataFrame(xml, stringsAsFactors = FALSE)
    if (length(xml_df) == 0) {break}
    
    #check column names, add in missing one
    missing <- colnames(xml_df1)[!colnames(xml_df1) %in% colnames(xml_df)]
    if(length(missing) > 0){
      xml_df[[missing]] <- NA
    }
    
    xml_df1 <- rbind(xml_df1, xml_df)
    n <- n + 1
  }
  
  return(xml_df1)
}

# TODO make a check_database() function
## can't have any NA db$exp_date values, or start_date
# - probably can't have any NA date values for functions to work 
