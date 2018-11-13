# This script is intended to run as a command line accessible test of the bot

library(dplyr)
library(httr)
library(lubridate)
library(magrittr)
library(RCurl)
remotes::install_github('NCEAS/rt@a9fe278ac0b74cf9ef3912c01d1e1559e1816eae')
library(rt)
library(slackr)
library(stringr)
library(XML)

## Set up environment variables 
readRenviron(file.path(getwd(), '.Renviron'))

## Source the bot
remotes::install_github('NCEAS/awards-bot')
library(awardsBot)

# Log in to RT/SLACK 
rt::rt_login(Sys.getenv('RT_USER'), Sys.getenv('RT_PASS'), Sys.getenv('RT_URL'))
slackr::slackr_setup(channel = '#awardbot', username = 'awardbot',
                     incoming_webhook_url = Sys.getenv('SLACK_WEBHOOK_URL'))

testthat:::test_package_dir(package = 'awardsBot', test_path = 'tests/testthat',
                            filter = NULL, reporter = 'check', stop_on_failure = TRUE,
                            stop_on_warning = FALSE)