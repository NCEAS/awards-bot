## Packages
library(knitr)
library(rmarkdown)
library(tidyverse)

## Data
emails <- list.files("inst/emails/rmarkdown/", 
                     pattern = "*.Rmd")

## Loop
for (i in emails){
  
  name <- str_split(i, "\\.")
  
  rmarkdown::render(input = paste0("inst/emails/rmarkdown/", i),
                    output_format = "md_document",
                    output_file = paste0(name[[1]][1]),
                    output_dir = "inst/emails/rmarkdown/filled_email/")
}
