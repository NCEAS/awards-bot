# Set the CRAN mirror to use
options(repos=structure(c(CRAN="https://cran.cnr.berkeley.edu/")))
# Check for installed dependencies
packages <- 
    c("dplyr", "lubridate", "magrittr", "RCurl", "slackr", "stringr", "XML", "devtools")
new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]

# Install unsatisfied dependencies
if(length(new_packages)) {
    install.packages(new_packages)
}
library(dplyr)
library(httr)
library(lubridate)
library(magrittr)
library(RCurl)
library(slackr)
library(stringr)
library(XML)
library(devtools)

# Install rt separately
if (!("rt" %in% installed.packages()[,"Package"]) ) {
    # Last stable version since this is so far unreleased
    remotes::install_github('NCEAS/rt@a9fe278ac0b74cf9ef3912c01d1e1559e1816eae', 
        upgrade = "never")}
library(rt)

## Source the bot
if (!("awardsBot" %in% installed.packages()[,"Package"]) ) {
    remotes::install_github('NCEAS/awards-bot@1.0.3', upgrade = "never")
}
library(awardsBot)

## Set up environment variables 
readRenviron(file.path(getwd(), '.Renviron'))

# Log in to RT/SLACK 
rt::rt_login(Sys.getenv('RT_USER'), Sys.getenv('RT_PASS'), Sys.getenv('RT_URL'))
slackr::slackr_setup(channel = '#awardbot', username = 'awardbot',
    incoming_webhook_url = Sys.getenv('SLACK_WEBHOOK_URL'))

awardsBot:::main()