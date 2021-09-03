suppressMessages(library(dplyr))
library(httr)
suppressMessages(library(lubridate))
library(magrittr)
library(RCurl)
library(rt)
library(slackr)
library(stringr)
library(XML)

setwd("~/awards-bot")

## Set up environment variables
readRenviron(file.path(getwd(), ".Renviron"))

## Source the bot
#remotes::install_github("NCEAS/awards-bot")
library(awardsBot)

# Log in to RT/SLACK
rt::rt_login(Sys.getenv("RT_USER"), Sys.getenv("RT_PASSWORD"), Sys.getenv("RT_BASE_URL"))

slackr::slackr_setup(channel = "#awardbot", username = 'awardbot',
                     incoming_webhook_url = Sys.getenv("SLACK_WEBHOOK_URL"),
                     token = Sys.getenv("SLACK_OAUTH_TOKEN"))
#check awards
awardsBot::main()

#check for new correspondences
tickets <- awardsBot::get_tickets_with_new_incoming_correspondence(Sys.Date())

for(ticket in tickets){
  for(corr in ticket){
    slackr::slackr_bot(corr)
  }
}
