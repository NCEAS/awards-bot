#' Send Correspondence
#' 
#' Run this code to send new emails
#'
#' @param adc_nsf_awards (data.frame) result of \code{get_awards}
#' @param name (character) name of person to use as email sender
#'
#' @export
send_correspondence <- function(adc_nsf_awards, name) {
  
  ## helper function to read in email templates
  read_file <- function(path) {
    suppressWarnings(paste0(readLines(path), collapse = "\n"))
  }
  
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
    
    text <- sprintf(read_file(system.file("emails/contact_1mo", package = "awardsBotADC")),
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

