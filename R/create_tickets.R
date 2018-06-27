#' Create New Tickets
#' 
#' Run this code to create new ticket in the awards database
#'
#' @param adc_nsf_awards (data.frame) result of \code{get_awards}
#' @param test_requestor (character) optional email to use for requestor for testing purposes
#'
#' @export
create_tickets <- function(adc_nsf_awards, test_requestor = NULL) {
  
  ## get awards without tickets
  new_tickets <- which(is.na(adc_nsf_awards$rtTicket))
  
  ## create tickets
  for (i in new_tickets) {
    
    ## allow for a test requestor to create test tickets
    if (is.null(test_requestor)) {
      requestor <- adc_nsf_awards$piEmail[i]
    } else {
      requestor <- test_requestor
    }
    
    ## create subject for ticket
    if (is.null(test_requestor)) {
      subject <- sprintf("Arctic Data Center NSF Award: %s",  adc_nsf_awards$id[i])
    } else {
      subject <- sprintf("**TEST** Arctic Data Center NSF Award: %s",  adc_nsf_awards$id[i])
    }

    ## create ticket
    ticket <- rt::rt_ticket_create(queue = "arcticAwards",
                                   requestor = requestor,
                                   subject = subject,
                                   rt_base = "https://support.nceas.ucsb.edu/rt")
    
    ## get ticket_id
    ticket_content <- rawToChar(ticket$content)
    ticket_id <- gsub("(.*Ticket )([[:digit:]]+)( created.*)", "\\2", ticket_content)
    
    ## update adc_nsf_awards
    adc_nsf_awards$rtTicket[i] <- ticket_id
  }
  return(adc_nsf_awards)
}

