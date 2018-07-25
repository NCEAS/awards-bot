# awards_bot

The NSF award bot regularly contacts principal investigators with reminders on their project specific deadlines.

## How the bot works 
Every 24 hours the bot queries NSF's [award API](https://www.research.gov/common/webapi/awardapisearch-v1.htm) for newly awarded grants and stores this information in a pre-existing database.  When it finds a new award it creates a new ticket in [Request Tracker](https://bestpractical.com/request-tracker/) and sends an initial correspondence that outlines project-specific expectations and deadlines.  It sends reminders to submit annual reports, submit data for Arctic Observing Network (AON) projects, and that the award is expiring soon.  The bot sends error messages to a slack channel. 

## Setup 
- Copy the bot [cron script](https://github.com/NCEAS/awards-bot/blob/master/inst/main_cron_script.R) to a directory 

- Create a file called `.Renviron` in the same directory as the script
  Include the following variables: 
  ```text
  DATABASE_PATH                            # Path to the database of awards and correspondences
  LASTRUN_PATH=LASTRUN                     # Determines where the bot stores its state
  SLACK_WEBHOOK_URL="{URL}"                # Your Slack webhook URL
  RT_URL="https://example.com/rt"          # The URL of your RT install
  RT_USER="your_rt_user"                   # Your RT username
  RT_PASS="your_rt_password"                # Your RT password
  INITIAL_ANNUAL_REPORT_OFFSET=8           # Number of months after award start date to send annaul report reminder
  INITIAL_AON_OFFSET=11                    # Number of months after award start date to send AON data due reminder
  AON_RECURRING_INTERVAL=6                 # Number of months to data due reminders for AON awards
  ```

## Running 
Run the script every 24 hours.  Example crontab: 

## Adding a correspondence

## Style
Code generally follows the [tidyverse style conventions](http://style.tidyverse.org/), with the following specific style preferences: 
- underscore for all variable names unless referring to an NSF awards API return field (i.e. expDate, startDate, etc.)

## Acknowledgements
Work on this package was supported by:

- The Arctic Data Center: NSF-PLR grant #1546024 to M. B. Jones, S. Baker-Yeboah, J. Dozier, M. Schildhauer, and A. Budden

Additional support was provided by the National Center for Ecological Analysis and Synthesis, a Center funded by the University of California, Santa Barbara, and the State of California.

[![nceas_footer](https://www.nceas.ucsb.edu/files/newLogo_0.png)](http://www.nceas.ucsb.edu)
