#' Get recent incoming correspondence formatted
#'
#' @param ticket_id (character) the RT ticket number
#' @param after (character) check all the correspondences sent after this date
#'
#' @return list of correspondences per ticket to send
#' @export
#'
#' @examples
get_recent_incoming_correspondence <- function(ticket_id, after) {
  correspondences <- list()

  req <- rt::rt_ticket_history(ticket_id, format = "s")

  if (req$status != 200) {
    stop("Failed to log into RT")
  }

  # look for all instances with an email
  ticket_history <- unlist(strsplit(req$body, "\\n"))
  incoming <- ticket_history[stringr::str_detect(ticket_history, "Correspondence added by .+@.+")]

  if (length(incoming) == 0) {
    return(correspondences)
  }

  for (inc in incoming) {

    # get the specific correspondence
    id <- stringr::str_extract(inc, "[0-9]*")
    
    response <- rt::rt_ticket_history_entry(ticket_id, id)

    # !!! check if this works
    if (response$Created <= after) {
      next
    }

    correspondences <- append(correspondences, format_history_entry(response))
  }

  return(correspondences)
}

format_history_entry <- function(msg, trunc_at = 200) {
  if (nchar(msg["Content"]) > trunc_at) {
    ellipsis <- "..."
  } else {
    ellipsis <- ""
  }
  
  if (msg["Type"] == "Correspond") {
    msg["Type"] <- "Correspondence"
  } else if (msg["Type"] == "Create") {
    msg["Type"] <- "Ticket created"
  }
  
  #construct the slack message
  sprintf(
    "%s by %s on <%s/Ticket/Display.html?id=%s|Ticket %s>:\n>%s%s",
    msg$Type, msg$Creator,
    Sys.getenv("RT_BASE_URL"),
    msg$Ticket, msg$Ticket,
    strtrim(msg$Content, 200),
    ellipsis
  )
}

#' Get incoming correspondences
#' modified from the submissions bot python code
#'
#' @param after (character) date YYYY-MM-DD
#'
#' @return
#' @export
#'
#' @examples 
get_tickets_with_new_incoming_correspondence <- function(after) {
  tickets <- rt::rt_ticket_search(paste0("Queue='arcticAwards' AND LastUpdated >'", after, " 00:00:00'"))

  if (nrow(tickets) > 0) {
    correspondence <- lapply(tickets$id, get_recent_incoming_correspondence, after)
  }
}
