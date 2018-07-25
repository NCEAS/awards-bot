#' Create New Tickets
#' 
#' Run this code to create a new RT ticket based off NSF award number and requestor
#' (PI) email.  Requires a valid RT login in order to run.  
#'
#' @param award (character) NSF award number.
#' @param requestor (character) PI email
#' 
#' @return ticket_id (character) Newly generated RT ticket id
#'
#' @export
create_ticket <- function(award, requestor) {
  subject <- sprintf("Arctic Data Center NSF Award: %s",  award)
  ticket <- rt::rt_ticket_create(queue = "arcticAwards",
                                 requestor = requestor,
                                 subject = subject,
                                 rt_base = "https://support.nceas.ucsb.edu/rt")
  
  if (!grepl("created", httr::content(ticket))) {
    message <- sprintf("I failed to create a ticket for award: %s, from requestor: %s", award, requestor)
    slackr::slackr_bot(message)
    return("rt_ticket_create_error")
  }
  
  # get ticket_id
  ticket_id <- rawToChar(ticket$content) %>%
    gsub("(.*Ticket )([[:digit:]]+)( created.*)", "\\2", .)
  
  return(ticket_id)
}


#' Create New Tickets and send initial correspondences 
#' 
#' Run this code to create new RT tickets and send an initial correspondence, based 
#' off a database of new NSF awards.  The database must include: fundProgramName,
#' piEmail, piFirstName, id (NSF award #), title (NSF award title).  
#'
#' @param awards (data.frame) database of NSF awards pulled from NSF-API using datamgmt::get_awards
#'
#' @return awards_db (data.frame) The initial database with updated RT ticket numbers
#'
#' @export
create_ticket_and_send_initial_correspondence <- function(awards_db) {
  # Get awards without an initial correspondence
  indices <- which(is.na(awards_db$contact_initial)) # save indices to re-merge
  db <- awards_db[indices,]
  
  for (i in seq_len(nrow(db))) {
    # Create RT ticket
    db$rtTicket[i] <- create_ticket(db$id[i], db$piEmail[i])
    if (db$rtTicket[i] == "rt_ticket_create_error") {
      next 
    }
    # Create correspondence text 
    template <- read_initial_template(db$fundProgramName[i])
    text <- sprintf(template,
                    db$piFirstName[i],
                    db$id[i],
                    db$title[i])
    
    reply <- rt::rt_ticket_history_reply(ticket_id = db$rtTicket[i],
                                         text = text,
                                         rt_base = "https://support.nceas.ucsb.edu/rt")
    check_rt_reply(reply, db$rtTicket[i])
    
    db$contact_initial[i] <- as.character(Sys.Date())
  }
  
  # re-merge temporary database into permanent
  awards_db[indices,] <- db
  
  return(awards_db)
}


send_annual_report_correspondence <- function(awards_db) {
  # Get awards to send annual report correspondence 
  current_date <- as.character(Sys.Date())
  indices <- which(awards_db$contact_annual_report_next == current_date) # save indices to re-merge
  db <- awards_db[indices,]
  
  for (i in seq_len(nrow(db))) {
    # Create correspondence text 
    template <- read_file(file.path(system.file("emails", "contact_annual_report", package = "awardsBot")))
    text <- sprintf(template,
                    db$piFirstName[i])
    
    reply <- rt::rt_ticket_history_reply(ticket_id = db$rtTicket[i],
                                         text = text,
                                         rt_base = "https://support.nceas.ucsb.edu/rt")
    check_rt_reply(reply, db$rtTicket[i])
    
    # Update last contact date
    db$contact_annual_report_previous[i] <- db$contact_annual_report_next[i]
  }
  
  # re-merge temporary database into permanent
  awards_db[indices,] <- db
  
  ## TODO
  # add function that updates annual report correspondence times
  
  return(awards_db)
}


send_aon_correspondence <- function(awards_db){
  current_date <- as.character(Sys.Date())
  indices <- which(awards_db$contact_aon_next == current_date)
  db <- awards_db[indices,]
  
  for (i in seq_len(nrow(db))) {
    # Create correspondence text 
    template <- read_file(file.path(system.file("emails", "contact_aon", package = "awardsBot")))
    text <- sprintf(template,
                    db$piFirstName[i])
    
    reply <- rt::rt_ticket_history_reply(ticket_id = db$rtTicket[i],
                                         text = text,
                                         rt_base = "https://support.nceas.ucsb.edu/rt")
    check_rt_reply(reply, db$rtTicket[i])
    
    # Update last contact date
    db$contact_aon_previous[i] <- db$contact_aon_next[i]
  }
  
  # re-merge temporary database into permanent
  awards_db[indices,] <- db
  
  return(awards_db)
}

  
send_one_month_remaining_correspondence <- function(awards_db) {
  dates <- as.character((as.Date(db$expDate) %m+% months(-1)))
  indices <- which(dates == as.character(Sys.Date()))
  db <- awards_db[indices,]
  
  for (i in seq_len(nrow(db))) {
    # Create correspondence text 
    template <- read_file(file.path(system.file("emails", "contact_1mo", package = "awardsBot")))
    text <- sprintf(template,
                    db$piFirstName[i],
                    db$id[i],
                    db$title[i])
    
    reply <- rt::rt_ticket_history_reply(ticket_id = db$rtTicket[i],
                                         text = text,
                                         rt_base = "https://support.nceas.ucsb.edu/rt")
    check_rt_reply(reply, db$rtTicket[i])
    
    # Update last contact date
    db$contact_1mo[i] <- as.character(Sys.Date())
  }
  
  # re-merge temporary database into permanent
  awards_db[indices,] <- db

  return(awards_db)
}
  

#' General function that sends a correspondence based on a specified time
#' 
#' This function sends a correspondence based on a specified time interval from 
#' the startDate or the expDate.  You can specify which direction in time you'd like
#' to go based on the starting point, as well as the time interval in years, months,
#' and days.  
#' @param 
send_correspondence_at_time_x <- function(awards_db,
                                          starting_point,
                                          direction,
                                          years = 0,
                                          months = 0, 
                                          days = 0,
                                          rtTicket, text) {
  if (!(starting_point %in% c("startDate", "expDate"))) {
    stop("starting point must be one of 'startDate' or 'expDate'")
  }
  if (!is.numeric(c(years, months, days))) {
    stop("'years', 'months', and 'days' arguments must be numeric")
  } 
  
  db <- awards_db
  dates <- as.Date(db[[starting_point]])
  time_int <- period(c(days, months, years), c("day", "month", "year"))
  dates + time_int
  
}

  
## helper function to check RT replies
check_rt_reply <- function(reply, rt_ticket_number) {
  if (reply$status_code != 200) {
    message <- sprintf("I failed to reply on: %s, with status code: %s", rt_ticket_number, reply$status_code)
    slackr::slackr_bot(message)
  }
  content <- httr::content(reply)
  if (!grepl("Correspondence added", content)) {
    message <- paste0("I failed to send a correspondence on ticket: ", rt_ticket_number)
    slackr::slackr_bot(message)
  }
} 

## helper function to read in email templates
read_file <- function(path) {
  suppressWarnings(paste0(readLines(path), collapse = "\n"))
}

## helper function read in general, AON, or SS initial template
read_initial_template <- function(fundProgramName) {
  stopifnot(is.character(fundProgramName))
  
  if (grepl("AON", fundProgramName)) {
    path <- file.path(system.file("emails", "contact_initial_aon", package = "awardsBot"))
  } else if (grepl("SOCIAL", fundProgramName)) {
    path <- file.path(system.file("emails", "contact_initial_social_sciences", package = "awardsBot"))
  } else {
    path <- file.path(system.file("emails", "contact_initial", package = "awardsBot"))
  }
  
  if (!file.exists(path)) {
    slackr::slackr_bot("I failed to read in a contact_initial email template, please check that the file paths used by 'awardsBot::read_initial_template' all exist.")
  }
  
  template <- read_file(path)
  return(template)
}


## Helper function to check if RT is logged in 
check_rt_login <- function(rt_base) {
  base_api <- paste(stringr::str_replace(rt_base, "\\/$", ""),
                    "REST", "1.0", sep = "/")
  content <- httr::GET(base_api) %>%
    httr::content()
  
  if (stringr::str_detect(content, "Credentials required")) {
    return(FALSE)
  } else {
    return(TRUE)
  }
}

## TODO write send_correspondence function that takes extra arguments