## Create initial contact schedule 
## Uses active_db from inst/initialize_datbase.R
library(plotly)

dim(active_db) # 405 active awards 

# How many are not already in the ADC? 
adc_info <- read.csv('/home/dmullen/Github/arctic-data/reporting/R/funding/funding_summary.csv', stringsAsFactors = FALSE)
text <- paste(adc_info$funding_text, collapse = ' ')
indices <- which(sapply(active_db$id, function(x) grepl(x, text)))

length(indices) # 42/405 active awards are already in the ADC - don't need to contact these?
active_db2 <- active_db[-indices,]

indices_contact1mo <- which(as.Date(active_db2$contact_1mo) <= Sys.Date())
length(indices_contact1mo) #44 awards have less than 3 months to go - contact these with report end reminder
active_db2 <- active_db2[-indices_contact1mo,]

# 417 remaining 
sort(unique(active_db2$startDate))
plyr::count(active_db2$fundProgramName)
plyr::count(as.Date(active_db$startDate) > (Sys.Date() - months(12))) #190 - 2 years, #122 - 1.5 years, #106 - 1 year

# plot remaining by time 
df <- data.frame(awards = seq(1:314), date = sort(as.Date(active_db$startDate)))
g <- ggplot(df, aes(x=date, y=awards)) + geom_point()
ggplotly(g)
