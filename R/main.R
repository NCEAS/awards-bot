## Main 

# Set up environment variables 
#readRenviron(file.path(getwd(), ".env"))

# Source the bot 
# remotes::install_github("NCEAS/awards-bot")
# library(awardsBot)

# Log in to RT 

main <- function() {
# Read in LASTRUN
# import database 

# update database 

# send emails for new awards 
# send slack messages for emails sent 
# update db that new awards emails were sent 

# check for crons emails to send 
# send slack messages for cron emails sent 
# update db that cron emails were sent 

# save db 
# save Sys.Date as from_date
}

## Run a separate cron bot that notifies with correspondences 
## include some logic to only run this when Sys.Date() changes, the rest can run every 15 minutes.  