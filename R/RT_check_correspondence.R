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
  incoming <- ticket_history[grep("Correspondence added by [_a-z0-9-]+(\\.[_a-z0-9-]+)*@[a-z0-9-]+(\\.[a-z0-9-]+)*(\\.[a-z]{2,4})", ticket_history)]

  if (length(incoming) == 0) {
    return(correspondences)
  }

  for (inc in incoming) {

    # get the specific correspondence
    id <- regmatches(inc, regexpr("[0-9]*", inc))
    
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
  # paste0(msg['Type']," by ", on <{}/Ticket/Display.html?id={}|Ticket {}>:\n>{}{}".format(, , RT_URL, msg['Ticket'], msg['Ticket'], msg['Content'][0:(trunc_at-1)], ellipsis)

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
#' @param after date YYYY-MM-DD
#'
#' @return
#' @export
#'
#' @examples 
get_tickets_with_new_incoming_correspondence <- function(after) {
  #   # RT search uses local time whereas the API uses UTC. Go figure.
  #   after_localtime = after.astimezone(pytz.timezone('America/Los_Angeles'))
  tickets <- rt::rt_ticket_search(paste0("Queue='arcticAwards' AND LastUpdated >'", after, " 00:00:00'"))

  if (nrow(tickets) > 0) {
    correspondence <- lapply(tickets$id, get_recent_incoming_correspondence, after)
  }
}
