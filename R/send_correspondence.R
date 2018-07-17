#' Send Correspondence
#' 
#' Run this code to send new emails
#'
#' @param adc_nsf_awards (data.frame) result of \code{get_awards}
#' @param name (character) name of person to use as email sender
#'
#' @export
send_correspondence <- function(adc_nsf_awards, name) {
  
  ## send initial contact emails ##
  
  ## find which awards have not been contacted
  contact_initial <- which(is.na(adc_nsf_awards$contact_initial))
  
  ## send emails
  for (i in contact_initial) {
    
  ## get email text
  text <- sprintf(read_file(system.file("emails/contact_initial", package = "awardsBotADC")),
          adc_nsf_awards$piFirstName[i],
          adc_nsf_awards$id[i],
          adc_nsf_awards$title[i],
          name,
          name)
  
  ## send reply
  reply <- rt::rt_ticket_history_reply(ticket_id = adc_nsf_awards$rtTicket[i],
                                       text = text,
                                       cc = NULL,
                                       bcc = NULL,
                                       time_worked = NULL,
                                       attachment_path = NULL,
                                       rt_base = "https://support.nceas.ucsb.edu/rt")
  
  ## update database
  adc_nsf_awards$contact_initial[i] <- paste0(Sys.Date())
  }
  
  ## send 1 month to go emails ##
  
  ## find which awards have not been contacted
  contact_1mo <- which(is.na(adc_nsf_awards$contact_1mo))
  contact_1mo <- which(as.numeric(Sys.Date() - as.Date(adc_nsf_awards$expDate[contact_1mo])) > -30)
  
  ## send emails
  for (i in contact_1mo) {
    
    text <- sprintf(read_file(system.file("emails/contact_initial", package = "awardsBotADC")),
                    adc_nsf_awards$piFirstName[i],
                    name,
                    adc_nsf_awards$id[i],
                    adc_nsf_awards$title[i],
                    name)
    
    reply <- rt::rt_ticket_history_reply(ticket_id = adc_nsf_awards$rtTicket[i],
                                         text = text,
                                         cc = NULL,
                                         bcc = NULL,
                                         time_worked = NULL,
                                         attachment_path = NULL,
                                         rt_base = "https://support.nceas.ucsb.edu/rt")
    
    adc_nsf_awards$contact_1mo[i] <- paste0(Sys.Date())
  }
  
  return(adc_nsf_awards)
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
send_one_month_remaining <- function(awards_db, one_month_remaining_time)
  
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