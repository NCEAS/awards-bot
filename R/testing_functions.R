## Testing functions 

create_blank_database <- function() {
  col_names <- c('awardee',
                 'date',
                 'exp_date',
                 'fund_program_name',
                 'id',
                 'pi_email',
                 'pi_first_name',
                 'pi_last_name',
                 'pi_phone',
                 'po_name',
                 'start_date',
                 'title',
                 'rt_ticket',
                 'pi_orcid',
                 'contact_initial',
                 'contact_annual_report_previous',
                 'contact_annual_report_next',
                 'contact_aon_previous',
                 'contact_aon_next',
                 'contact_1mo',
                 'active_award_flag')
   
  blank_db <- data.frame(matrix(ncol = length(col_names), nrow = 1))
  colnames(blank_db) <- col_names
  
  return(blank_db)
}


write_blank_database <- function(path) {
  stopifnot(file.exists(dirname(path)))
  
  db <- create_blank_database()
  utils::write.csv(db, path, row.names = FALSE)
  
  return(invisible())
}

## TODO - this doesn't appear to work properly 
write_inst_database <- function() {
  db <- create_blank_database() %>%
    update_awards(from_date = as.Date('2018-06-28'), to_date = as.Date('2018-07-05')) %>%
    check_date_format() %>%
    apply(2, as.character) 
  utils::write.csv(db[2:3,], file.path(system.file('example_db.csv', package = 'awardsBot')),
                   row.names = FALSE)
}


create_dummy_database <- function() {
  db <- create_blank_database()
  
  db$pi_email <- 'jasminelai@nceas.ucsb.edu'
  db$pi_first_name <- 'Dominic'
  db$pi_last_name <- 'Mullen'
  db$title <- '**Test** AwardBot Title'
  db$fund_program_name <- 'ARCTIC NATURAL SCIENCES'
  db$id <- '1234567'  # NSF award number 
  db$start_date <- '2016-01-01'
  db$active_award_flag <- "no"
  
  #make 2  more rows
  db <- rbind(db[1,], db[1,], db[1,])
  
  db$id[2] <- "7654321"
  db$id[3] <- "9999999"
  
  db$active_award_flag[1] <- "yes"
  
  return(db)
}


with_dir <- function(directory, expr) {
  old_wd <- getwd()
  on.exit(setwd(old_wd))
  setwd(directory)
  evalq(expr)
}

