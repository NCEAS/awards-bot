**Awards Bot Contact Schedule**  
The awards bot contacts principal investigators with reminders one month prior to an upcoming deadline.  
- *Start:* send an initial congratulatory email at the start of each award.  This also provides details on project-specific information and guidelines.  
  - [AON](https://github.com/NCEAS/awards-bot/blob/master/inst/emails/contact_initial_aon)
  - [ANS](https://github.com/NCEAS/awards-bot/blob/master/inst/emails/contact_initial_ans)
  - [ASSP](https://github.com/NCEAS/awards-bot/blob/master/inst/emails/contact_initial_social_sciences) 
- *Annual Report:* annual reports are due 3 months prior to the "anniversary" of the award.  We will send the first annual report reminder 8 months after the award start date, and annually afterwards.  
  - [annual report reminder](https://github.com/NCEAS/awards-bot/blob/master/inst/emails/contact_annual_report)
- *AON:* send a reminder to submit AON data 11 months after the start of the award, along with a recurring reminder every 6 months onward
  - [AON recurring](https://github.com/NCEAS/awards-bot/blob/master/inst/emails/contact_aon_recurring)
- *One month remaining:* Send a reminder that the award will expire in one month
  - [one month remaining](https://github.com/NCEAS/awards-bot/blob/master/inst/emails/one_month_remaining)
  
Please note: if you read `%s` in an email template this simply indicates where to insert a value.  For example the three occurences of `%s` in the intial [ANS](https://github.com/NCEAS/awards-bot/blob/master/inst/emails/contact_initial_ans) contact template correspond to PI first name, funding number, and award title. 
