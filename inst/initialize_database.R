## Initialize the database 
## Storing this script in inst for historical interest
library(data.table)
library(dplyr)
library(lubridate)
library(magrittr)

if(Sys.getenv('DATABASE_PATH') == "") {
  stop('Set Sys.getenv("DATABASE_PATH") in .Renviron file')
}

db <- awardsBot::get_awards(to_date = format.Date(Sys.Date(), '%m/%d/%Y'))  # pulls all awards up to the current date

# Update column names
colnames(db) <- c('awardee', 'date', 'exp_date', 'fund_program_name', 'id', 'pi_email',
                  'pi_first_name', 'pi_last_name', 'pi_phone', 'po_name', 'start_date',
                  'title')

db <- dplyr::bind_rows(db, awardsBot:::create_blank_database()) %>%
  apply(2, as.character) %>%
  awardsBot:::check_date_format() %>%
  data.table::data.table() %>% 
  dplyr::distinct()

# Filter out all NA rows 
row_all_NA <- which(apply(db, 1, function(x) all(is.na(x))))
db <- db[-row_all_NA,]

# Filter out expired awards 
db <- dplyr::filter(db, exp_date > Sys.Date())

## Initialize active awards contact dates ======================================
db$active_award_flag <- 'yes'

db <- awardsBot:::update_contact_dates(db, 8, 11, 6) %>% data.table()

## Set all annual report contact dates to after Sys.Date()
while(any(as.Date(db$contact_annual_report_next) < Sys.Date())) {
db[,contact_annual_report_next := ifelse(as.Date(contact_annual_report_next) < Sys.Date(),
                                       as.character(as.Date(contact_annual_report_next) + years(1)),
                                       contact_annual_report_next)]
}
  
# Set all contact aon next to dates after Sys.Date)
while(any(as.Date(db$contact_aon_next) < Sys.Date(), na.rm = TRUE)) {
  db[,contact_aon_next := ifelse(as.Date(contact_aon_next) < Sys.Date(),
                                        as.character(as.Date(contact_aon_next) %m+% months(6)),
                                        contact_aon_next)]
}

# Set 1 month contact before award expires
db$contact_1mo <- as.character((as.Date(db$exp_date) %m+% months(-1)))

# Set contact_initial so the first run of the bot doesn't email already started awards 
db$contact_initial <- as.character(Sys.Date())

# Create RT tickets for already existing awards 
for (i in seq_len(nrow(db))) {
  db$rt_ticket[i] <- awardsBot:::create_ticket(db$id[i], db$pi_email[i])
}

# Save database
write.csv(db, Sys.getenv('DATABASE_PATH'), row.names = FALSE)
