## Set up environment variables 
readRenviron(file.path(getwd(), ".Renviron"))

## Source the bot
remotes::install_github("NCEAS/awards-bot")
library(awardsBot)

# Log in to RT/SLACK 
rt::rt_login(Sys.getenv("RT_USER"), Sys.getenv("RT_PASS"), Sys.getenv("RT_URL"))
slackr::slackr_setup(channel = "#awardbot", username = "awardbot",
                     incoming_webhook_url = Sys.getenv("SLACK_WEBHOOK_URL"))

awardsBot::main()