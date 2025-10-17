#Initial Data Setup for the R-ticulate Data for Tech Taco
#Created by: Jeremy R. Groves
#Date: February 26, 2025

rm(list=ls())

library(tidycensus)
library(tidyverse)
library(ipumsr)

#Get Geography Data

acs <- get_acs(geography = "state",	#defines geography level of data 
               variables = "B01001A_001",	    #specifics the data we want 
               year = 2020,	         #denotes the year
               geometry = TRUE)	     #downloads the TIGER shape file data  

#Get Population Data from IPUMS

    data_ext<- define_extract_nhgis(
      description = "TechTaco",
      time_series_tables =  list(
        tst_spec("A00", "state")
      )
    )
    
    ts<-submit_extract(data_ext)
    wait_for_extract(ts)
    filepath <- download_extract(ts)
    
    dat <- read_nhgis(filepath)
    
    rm(ts, data_ext, filepath)
    
#Clean and merge census/impus data
    
    census <- dat %>%
      select(STATEFP, STATE, contains("1990"), contains("2010")) %>%
      mutate(pop_1990 = A00AA1990,
             pop_2010 = A00AA2010,
             GEOID = STATEFP) %>%
      filter(!is.na(STATEFP)) %>%
      select(!contains("A00AA"), -STATEFP) %>%
      left_join(., acs, by="GEOID") %>%
      select(-c(variable, estimate, moe, NAME))
    
save(census, file="./census.RData")
