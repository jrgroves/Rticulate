rm(list=ls())

library(tigris)
library(sf)
library(tidyverse)
library(tidycensus)

# Set Options
  options(tigris_use_cache = TRUE)
  
# Load Vote Data
  v.data <- read.csv("./Build/Input/2026elec_house.csv", header = TRUE)

  #Fetch US House Districts for the entire United States
    map <- congressional_districts(cb = TRUE)

  #Get FIPS code from tidycensus
    data("fips_codes")
    fips <- unique(fips_codes[, c("state", "state_code", "state_name")])

#Process Data
    
    v.data.2 <- v.data %>%
      mutate(across(.cols = c(Democrat, Republican, Third.candidate), .fns = ~ gsub("\x82", "", .x, useBytes = TRUE)),
             across(.cols = c(Democrat, Republican, Third.candidate), .fns = ~ gsub("\xa4a", "", .x, useBytes = TRUE)),
             across(.cols = c(Democrat, Republican, Third.candidate), .fns = ~ gsub("\\?", "", .x)),
             across(.cols = c(Democrat, Republican, Third.candidate), .fns = ~ gsub("\\*", "", .x)),
             across(.cols = c(Democrat, Republican, Third.candidate), .fns = ~ gsub("([A-Za-z])([0-9])", "\\1|\\2", .x)),
             Race = gsub(" District ", "|", Race),
             Race = trimws(gsub(" At-Large", "|", Race)) )%>%
      filter(Expected.vote.reporting != "") %>%
      mutate(State = str_split_i(Race, "\\|", 1),
             District = str_pad(str_split_i(Race, "\\|", 2), 2, "left", "0"), 
             Demo.Per = as.numeric(str_split_i(Democrat, "\\|", 2)),
             Repub.Per = as.numeric(str_split_i(Republican, "\\|", 2)),
             Diff = Repub.Per - Demo.Per,
             Res = case_when(Diff > 0 & Diff <= 5.0 ~ "Lean R",
                             Diff > 5.0 & Diff <= 15.00 ~ "Likely R",
                             Diff > 15 ~ "Strong R",
                             Diff < 0 & Diff >= -5.0 ~ "Lean D",
                             Diff < -5.0 & Diff >= -15.00 ~ "Likely D",
                             Diff < -15.00 ~ "Strong D",
                             TRUE ~ NA)) %>%
      filter(State != "AK" & State != "HI") %>%
      mutate(test = Demo.Per + Repub.Per) %>%
      filter(test > 39) %>%  #Removes two runoff elections in LA 
      select(State, District, Demo.Per, Repub.Per, Hold.or.pickup, Diff, Res) %>%
      left_join(., fips, by = c("State" = "state"))
    
  remove <- c("02", "15", "60", "66", "69", "72", "74", "78")
  
  map.2 <- map %>%
    rename("state_code" = "STATEFP") %>%
    rename("District" = "CD119FP") %>%
    select("state_code", "District", "ALAND", "AWATER", "geometry") %>%
    left_join(., v.data.2, by = c("state_code", "District")) %>%
    filter(!state_code %in% remove)
  
#Visualizations
  
  ggplot(map.2) +
    geom_sf(aes(fill = Res)) +
    scale_fill_manual(
      values = c(    "Strong D" = "#244999","Likely D" = "#577ccc","Lean D"   = "#8aafff",
                     "NA"  = "#FFFFFF","Lean R"   = "#ff8b98", 
                     "Likely R" = "#ff5865",
                     "Strong R" = "#bf1d29", na.value = "#FFFFFF"),
      breaks = c("Strong D", "Likely D", "Lean D",
                 "No Result",
                 "Lean R", "Likely R", "Strong R"),               # legend order
      name   = "Winning party",                      # legend title
      drop   = FALSE  )+                               # keep categories with no districts
    theme_bw()
 

  
  
          
        