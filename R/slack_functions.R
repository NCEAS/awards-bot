## Slack functions 

## Import global variables 
SLACKWEBHOOK_URL

# Set ennvironment variables 
slackr_setup(channel = "#awardbot", username = "awardbot",
             incoming_webhook_url = SLACKWEBHOOK_URL)

# Test slack 
test_slack <- function() {
  # send a test message to slack
  print("Sending a test message..")
  slackr_bot("Testing bot messages")
}