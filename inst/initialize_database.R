## Initialize the database 
## Storing this script in inst for historical interest
library(datamgmt)
library(data.table)
library(dplyr)

db <- get_awards(to_date = "07/29/2018")  # pulls all awards up to the current date
write.csv(db, file = file.path(tempdir(), "temp_db.csv"), row.names = FALSE)

db <- dplyr::bind_rows(db, awardsBot:::create_blank_database()) %>%
  apply(2, as.character) %>%
  awardsBot:::check_date_format() %>%
  data.table() %>% 
  dplyr::distinct()

# Filter out all NA rows 
row_all_NA <- which(apply(db, 1, function(x) all(is.na(x))))
db <- db[-row_all_NA,]

db[,expired_award_flag := ifelse(as.Date(expDate) > Sys.Date(), "not_expired", "expired")]

## Initialize active awards contact dates ======================================
indices <- which(db$expired_award_flag == "not_expired")
active_db <- db[indices,]

active_db <- update_contact_dates(active_db, 8, 11, 6)

## Set all annual report contact dates to after Sys.Date()
while(any(as.Date(active_db$contact_annual_report_next) < Sys.Date())) {
active_db[,contact_annual_report_next := ifelse(as.Date(contact_annual_report_next) < Sys.Date(),
                                       as.character(as.Date(contact_annual_report_next) + years(1)),
                                       contact_annual_report_next)]
}
  
# Set all contact aon next to dates after Sys.Date)
while(any(as.Date(active_db$contact_aon_next) < Sys.Date(), na.rm = TRUE)) {
  active_db[,contact_aon_next := ifelse(as.Date(contact_aon_next) < Sys.Date(),
                                        as.character(as.Date(contact_aon_next) %m+% months(6)),
                                        contact_aon_next)]
}

# Set 3 month contact before award expires
active_db$contact_3mo <- as.character((as.Date(active_db$expDate) %m+% months(-3)))


