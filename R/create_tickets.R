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

