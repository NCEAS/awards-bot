# awardsBot <img src="man/figures/logo.png" align="right" width="129px" height="150px"/> 
[![R build status](https://github.com/NCEAS/awards-bot/workflows/R-CMD-check/badge.svg)](https://github.com/NCEAS/awards-bot/actions)

The NSF awards bot regularly contacts principal investigators with reminders on their project specific deadlines.  Please read the [schedule readme](https://github.com/NCEAS/awards-bot/tree/master/inst/emails) for more detailed information on automated correspondences.

## How the bot works 
Every 24 hours the bot queries NSF's award [API](https://www.research.gov/common/webapi/awardapisearch-v1.htm) for newly awarded grants and stores this information in a pre-existing database.  When it finds a new award it creates a new ticket in [Request Tracker](https://bestpractical.com/request-tracker/) and sends an initial correspondence that outlines project-specific expectations and deadlines.  It sends reminders to submit annual reports, submit data for Arctic Observing Network (AON) projects, and that the award is expiring soon.  The bot sends a summary of the number of each type of correspondence sent and error messages to a slack channel. 

## Setup
- Copy the bot [cron script](https://github.com/NCEAS/awards-bot/blob/master/inst/main_cron_script.R) to a directory 

- Create a file called `.Renviron` in the same directory as the script. 
  Include the following variables: 
  ```text
  DATABASE_PATH                            # Path to the database of awards and correspondences
  LASTRUN_PATH=LASTRUN                     # Determines where the bot stores its state
  SLACK_WEBHOOK_URL="{URL}"                # Your Slack webhook URL
  SLACK_OAUTH_TOKEN="TOKEN"                # Slack OAUTH token (see your bot admin for access)
  RT_BASE_URL="https://example.com/rt"          # The URL of your RT install
  RT_USER="your_rt_user"                   # Your RT username
  RT_PASSWORD="your_rt_password"               # Your RT password
  INITIAL_ANNUAL_REPORT_OFFSET=8           # Number of months after award startDate to send annaul report reminder
  INITIAL_AON_OFFSET=11                    # Number of months after award startDate to send first AON data due reminder
  AON_RECURRING_INTERVAL=6                 # Number of months to send recurring emails for AON data due
  ```

- see the `server` vignette for more details

## Running 
Run the bot [cron script](https://github.com/NCEAS/awards-bot/blob/master/inst/main_cron_script.R) every 24 hours.    
Example crontab: `0 15 * * * Rscript ~/home/awardsBot/main_cron_script.R`

## How the database works 
The awards bot uses a csv file as a database.  It stores metadata about each award harvested from NSF's award [API](https://www.research.gov/common/webapi/awardapisearch-v1.htm), along with dates at which specific correspondences should be sent.  For instance, the database includes the column `contact_3mo`, which lists the date when the bot should send a reminder that there are 3 months remaining until an award expires.  This value is initialized to 3 months before the `expDate` field.  Each time the bot runs, it checks whether the system date is equivalent to `contact_3mo` and sends a reminder email if this is true.  For recurring correspondences, such as annual report reminders, the database contains previous and next response columns.  For example, `contact_annual_report_next` specifies what date to send the reminder, and when `contact_annual_report_previous` is equivalent to `contact_annual_report_next` it will update the latter field forward by one year.  

## Adding a correspondence
In this example we will assume the submission policies changed to require an initial metadata submission within the first two years of an award `startDate`.  The following steps illustrate how to send a one-time correspondence.  In order to send a recurring correspondence copy the logic used by `set_first_aon_data_due_date()` and `update_aon_data_due_date()`, in addition to the following steps.
- Add the email template to the [inst/emails](https://github.com/NCEAS/awards-bot/tree/master/inst/emails) folder 
- Add an appropriately named `NA` column to the database, such as `contact_two_year`. 
- Add a function to [database_functions.R](https://github.com/NCEAS/awards-bot/blob/master/R/database_functions.R) that initializes `contact_two_year` to two years after `startDate`
  - Add this to the `update_contact_dates` wrapper function, which is used in `main()`.
- Add an RT correspondence function to [RT_functions.R](https://github.com/NCEAS/awards-bot/blob/master/R/RT_functions.R).  Use the existing correspondence functions as templates.  
  - Add this to the `send_correspondences` wrapper function, which is used in `main()`
- Unit tests!!  

## Testing the bot
The awards-bot package contains modular unit tests, however, many of these don't run, by default, unless the R session is connected to [RT](https://bestpractical.com/request-tracker/) and [Slack](https://slack.com/). A thorough test of the bot would involve signing in to RT and Slack, and running `devtools::check()`; although, if the [test_main unit test](https://github.com/NCEAS/awards-bot/blob/master/tests/testthat/test_main.R) passes it's generally safe to assume the more modular tests will pass as well.

General notes:
- only use `awardsBot:::test_main()` in testing.  This a wrapper for `awardsBot::main()` except with an additional `email` argument
- set `email = your test email address` in the unit test script  
- modify `test_main()` calls in the unit test script accordingly, including any additional arguments 


### Testing Locally
Please follow this closely so no emails are sent to researchers by mistake while testing.

1. Add the following lines to the `.Renviron` (can be accessed by `usethis::edit_r_environ()`)
```
  SLACK_WEBHOOK_URL="{URL}"                # Your Slack webhook URL
  SLACK_OAUTH_TOKEN="TOKEN"
  RT_BASE_URL="https://example.com/rt"          # The URL of your RT install
  RT_USER="your_rt_user"                   # Your RT username
  RT_PASSWORD="your_rt_password"               # Your RT password
```

2. Set up slackbot: `slackr::slackr_setup(channel = "#awardbot", username = 'awardbot', incoming_webhook_url = Sys.getenv("SLACK_WEBHOOK_URL"), bot_user_oauth_token = Sys.getenv("SLACK_OAUTH_TOKEN"))`

3. Login to RT: `rt::rt_login()`

4. Run `devtools::load_all()` to source the scripts for testing so you can run the test file line by line

5. Run the [test_main unit test](https://github.com/NCEAS/awards-bot/blob/master/tests/testthat/test_main.R) locally, ideally line by line.

6. Two test tickets should be created in RT.  

## Style
Code generally follows the [tidyverse style conventions](http://style.tidyverse.org/), with the following specific style preferences: 
- underscore for all variable names unless referring to an NSF awards API return field (i.e. expDate, startDate, etc.)

## Acknowledgements
Work on this package was supported by:

- The Arctic Data Center: NSF-PLR grant #1546024 to M. B. Jones, S. Baker-Yeboah, J. Dozier, M. Schildhauer, and A. Budden

Additional support was provided by the National Center for Ecological Analysis and Synthesis, a Center funded by the University of California, Santa Barbara, and the State of California.

<img src="https://live-ncea-ucsb-edu-v01.pantheonsite.io/sites/default/files/2020-03/NCEAS-full%20logo-4C.png" width=50% height=50%>
