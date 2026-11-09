rm(list=ls())

library(tigris)
library(sf)
library(tidyverse)
library(tidycensus)

#Define Variables
  close.ness <- c(5, 15)

# Set Options and References
  options(tigris_use_cache = TRUE)
  remove <- c("02", "15", "60", "66", "69", "72", "74", "78")
  rating_colors.1 <- c("DEM Hold" = "#244999","DEM Pickup" = "#244999","DEM Leading" = "#8aafff",
                       "REP Hold" = "#bf1d29","REP Pickup" = "#bf1d29","REP Leading" ="#ff8b98",
                       "Runoff"   = "#c1d6bf","Undecided"  = "#FFFFFF")
  rating_colors.2 <- c("Strong D" = "#244999","Likely D" = "#577ccc","Close D"   = "#8aafff",
                       "Close R"   = "#ff8b98","Likely R" = "#ff5865","Strong R" = "#bf1d29",
                       "Runoff"   = "#c1d6bf","Undecided"  = "#FFFFFF")
    
# Load Vote Data
  v.data <- read.csv("./Build/Input/2026elec_house.csv", header = TRUE)

  #Fetch US House Districts for the entire United States
    map <- congressional_districts(cb = TRUE)

  #Get FIPS code from tidycensus
    data("fips_codes")
    fips <- unique(fips_codes[, c("state", "state_code", "state_name")])

#Replicate CNN graph
    v.data.1 <- v.data %>%
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
             Demo.Per = replace_na(Demo.Per, 0.00),
             Repub.Per = replace_na(Repub.Per, 0.00),
             Hold.or.pickup = case_when(Hold.or.pickup == "" & Repub.Per > Demo.Per ~ "REP Leading",
                                        Hold.or.pickup == "" & Repub.Per < Demo.Per ~ "DEM Leading",
                                        Hold.or.pickup == "" ~ "Undecided",
                                        TRUE ~ Hold.or.pickup)) %>%
      select(State, District, Demo.Per, Repub.Per, Hold.or.pickup) %>%
      left_join(., fips, by = c("State" = "state")) 
    
    map.1 <- map %>%
      rename("state_code" = "STATEFP") %>%
      rename("District" = "CD119FP") %>%
      select("state_code", "District", "ALAND", "AWATER", "geometry") %>%
      left_join(., v.data.1, by = c("state_code", "District")) %>%
      filter(!state_code %in% remove)
    
    
    
    
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
             Demo.Per = replace_na(Demo.Per, 0.0),
             Repub.Per = replace_na(Repub.Per, 0.0),
             Diff = Repub.Per - Demo.Per,
             test = Repub.Per + Demo.Per,
             Res = case_when(Diff == 0 ~ "Undecided",
                             Diff > 0 & Diff <= 5.0 ~ "Lean R",
                             Diff > 5.0 & Diff <= 15.00 ~ "Likely R",
                             Diff > 15 ~ "Strong R",
                             Diff < 0 & Diff >= -5.0 ~ "Lean D",
                             Diff < -5.0 & Diff >= -15.00 ~ "Likely D",
                             Diff < -15.00 ~ "Strong D",
                             TRUE ~ NA),
             Res = case_when(test > 0 & test < 40.0 ~ "Runoff",
                             TRUE ~ Res),
             Res2 = case_when(Diff == 0 ~ "Undecided",
                              Diff >= -2.5 & Diff <= 2.5 ~"Toss Up",
                              Diff > 2.5 & Diff <= 5.0 ~ "Lean R",
                              Diff > 5.0 & Diff <= 10.00 ~ "Likely R",
                              Diff > 10 ~ "Strong R",
                              Diff < -2.50 & Diff >= -5.0 ~ "Lean D",
                              Diff < -5.0 & Diff >= -10.00 ~ "Likely D",
                              Diff < -10.00 ~ "Strong D",
                              TRUE ~ NA),
             Res2 = case_when(test > 0 & test < 40.0 ~ "Runoff",
                             TRUE ~ Res2),
             Res = factor(Res, levels = c("Strong D","Likely D","Lean D",
                                          "Lean R","Likely R","Strong R","Runoff","Undecided"))) %>%
      add_count(Res, name = "Seats") %>%
      add_count(Res2, name = "Seats2") %>%
      select(State, District, Demo.Per, Repub.Per, test, Hold.or.pickup, Diff, Res, Res2, Seats, Seats2) %>%
      left_join(., fips, by = c("State" = "state")) 

  
    
    
    
    
    
    
    
      
  
  map.2 <- map %>%
    rename("state_code" = "STATEFP") %>%
    rename("District" = "CD119FP") %>%
    select("state_code", "District", "ALAND", "AWATER", "geometry") %>%
    left_join(., v.data.2, by = c("state_code", "District")) %>%
    filter(!state_code %in% remove)
  
  
  
  
  
  
#Visualizations
  
  labs <- setNames(paste0(v.data.2$Res, " (", v.data.2$Seats, ")"),
                            v.data.2$Res)
  labs.2 <- setNames(paste0(v.data.2$Res2, " (", v.data.2$Seats2, ")"),
                   v.data.2$Res2)
  
  
  

  
  rating_colors.1a <- c(
    "Strong D" = "#244999",
    "Likely D" = "#577ccc",
    "Lean D"   = "#8aafff",
    "Toss Up"  = "#6C419F",
    "Lean R"   = "#ff8b98",
    "Likely R" = "#ff5865",
    "Strong R" = "#bf1d29", 
    "Runoff"   = "#c1d6bf",
    "Undecided"  = "#FFFFFF")
  
  rating_colors.2 <- c(
    "Strong D" = "#1A4FA3",   # blue
    "Likely D" = "#3A4AA1",   # was #4B47A1
    "Lean D"   = "#6C419F",
    "Lean R"   = "#853B8D",
    "Likely R" = "#A92F53",
    "Strong R" = "#C0272D" ,   # red
    "Undecided" = "#FFFFFF",
    "Runoff"   = "#c1d6bf"
  )       
  
   rating_colors.3 <- c(
    "Strong D" = "#244999",   # blue
    "Likely D" = "#5945A0",   # was #4B47A1
    "Lean D"   = "#6C419F",
    "Lean R"   = "#853B8D",
    "Likely R" = "#933776",
    "Strong R" = "#bf1d29" ,   # red
    "Undecided" = "#FFFFFF",
    "Runoff"   = "#c1d6bf"
  )
  
 g.cnn <- ggplot(map.1) +
   geom_sf(aes(fill = Hold.or.pickup), color = "white", linewidth = 0.2)+
   scale_fill_manual(values = rating_colors.1,
                     breaks = names(rating_colors.1),
                     labels = names(rating_colors.1),
                     na.value = "white", name = "Results") +
   theme_void() +
   theme(legend.position = "bottom") +
   guides(fill = guide_legend(nrow = 2, title.position = "top", title.hjust = 0.5))
 
   
  g1 <- ggplot(map.2) +
    geom_sf(aes(fill = Res), color = "white", linewidth = 0.1) +
    scale_fill_manual(values = rating_colors.2,
                      breaks = names(rating_colors.2),
                      labels = names(rating_colors.2),
                      na.value = "white", name = "Rating") +
    theme_void() +
    theme(legend.position = "bottom") +
    guides(fill = guide_legend(nrow = 2, title.position = "top", title.hjust = 0.5))
  
  ggsave(filename = "./Build/Output/Figure1.png")

  g2 <- ggplot(map.2) +
    geom_sf(aes(fill = Res), color = "white", linewidth = 0.1) +
    scale_fill_manual(values = rating_colors.2,
                      breaks = names(rating_colors.2),
                      na.value = "white", name = "Rating") +
    theme_void() +
    theme(legend.position = "bottom") +
    guides(fill = guide_legend(nrow = 2, title.position = "top", title.hjust = 0.5))
  
   ggsave(filename = "./Build/Output/Figure2.png")
  
   g3 <- ggplot(map.2) +
     geom_sf(aes(fill = Res), color = "white", linewidth = 0.1) +
     scale_fill_manual(values = rating_colors.3,
                       breaks = names(rating_colors.1),
                       na.value = "white", name = "Rating") +
     theme_void() +
     theme(legend.position = "bottom") +
     guides(fill = guide_legend(nrow = 2, title.position = "top", title.hjust = 0.5))
   
  ggsave(filename = "./Build/Output/Figure3.png")     
  
  g4 <- ggplot(map.2) +
    geom_sf(aes(fill = Res2), color = "white", linewidth = 0.1) +
    scale_fill_manual(values = rating_colors.1a,
                      breaks = names(labs.2),
                      labels = labs.2,
                      na.value = "white", name = "Rating") +
    theme_void() +
    theme(legend.position = "bottom") +
    guides(fill = guide_legend(nrow = 2, title.position = "top", title.hjust = 0.5))
  
  ggsave(filename = "./Build/Output/Figure4.png")     