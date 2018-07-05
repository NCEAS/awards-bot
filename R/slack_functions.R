## Slack functions 

## Import global variables 
SLACKWEBHOOK_URL

# Set ennvironment variables 
slackr_setup(channel = "#awardbot", username = "awardbot",
             incoming_webhook_url = SLACKWEBHOOK_URL)

# Test slack 
test_slack <- function(message) {
  # send a test message to slack
  
  print("Sending a test message..")
  
  slackr_bot("Testing bot messages")
}

resp <- POST(url = incoming_webhook_url, encode = "form",
             add_headers(`Content-Type` = "application/x-www-form-urlencoded", 
                         Accept = "*/*"),
             body = URLencode(sprintf("payload={\"channel\": \"%s\", \"username\": \"%s\", \"text\": \"```%s```\"%s}", 
                                      channel, username, output, icon_emoji)))
warn_for_status(resp)

sprintf("payload={\"channel\": \"%s\", \"username\": \"%s\", \"text\": \"```%s```\"%s}", 
        channel, username, output, icon_emoji))
