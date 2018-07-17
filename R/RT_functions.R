#' Create New Tickets
#' 
#' Run this code to create new ticket in the awards database
#'
#' @param adc_nsf_awards (data.frame) result of \code{get_awards}
#' @param test_requestor (character) optional email to use for requestor for testing purposes
#'
#' @export
create_ticket <- function(award, requestor) {
  # TODO: add argument checks or is that overkill?
  subject <- sprintf("Arctic Data Center NSF Award: %s",  award)
  
  ticket <- rt::rt_ticket_create(queue = "arcticAwards",
                                 requestor = requestor,
                                 subject = subject,
                                 rt_base = "https://support.nceas.ucsb.edu/rt")
  
  if (ticket$status_code != 200) {
    slackr_bot(sprintf("I failed to create a ticket for award: %s, from requestor: %s", award, requestor))
  }
  
  # get ticket_id
  ticket_id <- rawToChar(ticket$content) %>%
    gsub("(.*Ticket )([[:digit:]]+)( created.*)", "\\2", .)
  
  return(ticket_id)
}


send_initial_correspondence <- function(awards_db) {
  # Get awards without an initial correspondence
  indices <- which(is.na(awards_db$contact_initial)) # save indices to re-merge
  db <- awards_db[indices,]
  
  for (i in seq_along(nrow(db))) {
    template <- read_initial_template(db$fundProgramName[i])
    # Create email text 
    text <- sprintf(template,
                    db$piFirstName[i],
                    db$id[i],
                    db$title[i])
    
    reply <- rt::rt_ticket_history_reply(ticket_id = db$rtTicket[i],
                                         text = text,
                                         rt_base = "https://support.nceas.ucsb.edu/rt")
    check_rt_reply(reply, db$rtTicket)
    
    db$contact_initial[i] <- FROM_DATE
  }
  
  # re-merge temporary database into permanent
  awards_db[indices,] <- db
  
  return(awards_db)
}

send_annual_report_correspondence <- function(awards_db, annual_report_time)
send_aon_correspondence <- function(awards_db, aon_time)
send_one_month_remaining <- function(awards_db, one_month_remaining_time) {
  ## find which awards have not been contacted
  contact_1mo <- which(is.na(adc_nsf_awards$contact_1mo))
  contact_1mo <- which(as.numeric(Sys.Date() - as.Date(adc_nsf_awards$expDate[contact_1mo])) > -30)
}
  
## helper function to check RT replies
check_rt_reply <- function(reply, rt_ticket_number) {
  if (reply$status_code != 200) {
    slackr_bot(paste0("I failed to reply on: ", rt_ticket_number, " with status code: ",
                      reply$status_code))
  }
  content <- rawToChar(reply$content)
  if (!grepl("Correspondence added", content)) {
    slackr_bot(paste0("I failed to send a correspondence on ticket: ", rt_ticket_number))
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
    path <- file.path(system.file(package = "awardsBot"), "emails/contact_initial_aon")
  } else if (grepl("SOCIAL", fundProgramName)) {
    path <- file.path(system.file(package = "awardsBot"), "emails/contact_initial_social_sciences")
  } else {
    path <- file.path(system.file(package = "awardsBot"), "emails/contact_initial")
  }
  
  if (!file.exists(path)) {
    slackr::slackr_bot("I failed to read in a contact_initial email template, please check that the file paths returned by 'awardsBot::read_initial_template' all exist.")
  }
  
  template <- read_file(path)
  return(template)
}