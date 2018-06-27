## set variables
database_path <- "/Users/path_to_database/adc_nsf_awards.csv"
n_days <- 10
RT_username <- "RT_username"
name <- "User Name" # For email signatures
test_requestor <- "User email address" # email for test tickets, NULL if not a test

## run code
## NOTE: print commands will output to cron log file
awardsBotADC::login_rt(RT_username)
adc_nsf_awards <- awardsBotADC::get_awards(database_path, n_days)
print("harvested new awards")
adc_nsf_awards <- awardsBotADC::create_tickets(adc_nsf_awards, test_requestor = test_requestor)
print("created new tickets")
adc_nsf_awards <- awardsBotADC::send_correspondence(adc_nsf_awards, name)
print("sent correspondence")
utils::write.csv(adc_nsf_awards, database_path, row.names = FALSE)
print("updated database")

## log date
print(paste0("bot finished at ", Sys.time()))
