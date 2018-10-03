## Initialize the database 
## Storing this script in inst for historical interest
library(data.table)
library(dplyr)
library(lubridate)
library(magrittr)

db <- awardsBot::get_awards(to_date = format.Date(Sys.Date(), '%m/%d/%Y'))  # pulls all awards up to the current date
write.csv(db, file = file.path(tempdir(), 'temp_db.csv'), row.names = FALSE)

db <- dplyr::bind_rows(db, awardsBot:::create_blank_database()) %>%
  apply(2, as.character) %>%
  awardsBot:::check_date_format() %>%
  data.table() %>% 
  dplyr::distinct()

# Filter out all NA rows 
row_all_NA <- which(apply(db, 1, function(x) all(is.na(x))))
db <- db[-row_all_NA,]

# Filter out expired awards 
db %>% filter(exp_d)

## Initialize active awards contact dates ======================================
indices <- which(db$active_award_flag == 'yes')
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

# Set 1 month contact before award expires
active_db$contact_1mo <- as.character((as.Date(active_db$expDate) %m+% months(-1)))

