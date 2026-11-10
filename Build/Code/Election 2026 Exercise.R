rm(list=ls())

if (!require("pacman")) install.packages("pacman")
pacman::p_load(usethis, tigris, sf, tidyverse, tidycensus, ggpattern, cowplot)


#Define Variables
  close.ness <- c(a, b)     #Input the bounds for "close" (a) and "moderately" (b)
  states <- c( )             #Input the States you want

#Define Functions
  mix <- function(a, b, t) rgb(colorRamp(c(a, b))(t), maxColorValue = 255)
  
#Set Options and References####
 
 #Set your base colors 
  purple <- "#7B3F9E"; blue <- "#008AEF"; red <- "#CC0000"
  white <- "#FFFFFF"; blue2 <- "blue"

  rating_colors.1 <- c("DEM Hold" = "#008AEF","DEM Pickup" = "#008AEF",
                       "DEM Leading" = "#84BBFA","REP Hold" = "#CC0000",
                       "REP Pickup" = "#CC0000","REP Leading" ="#ED9A9A",
                       "Runoff"   = "#c1d6bf","Undecided"  = "#FFFFFF")
  rating_colors.2 <- c("Strong D" = blue,"Moderately D" = mix(blue, white, .33),
                       "Close D"   = mix(blue, white, .66),
                       "Close R"  = mix(red, white, .66),
                       "Moderately R" = mix(red, white, .33),
                       "Strong R" = red,
                       "Runoff"   = "#c1d6bf","Undecided"  = "#FFFFFF")
    rating_colors.3 <- c("Strong D" = blue2, 
                         "Moderately D" = mix(blue, purple, .33),
                         "Close D" = mix(blue,purple, .66),
                         "Close R"   = mix(red, purple, .66),
                         "Moderately R" = mix(red, purple, .33),
                         "Strong R" = red,
                         "Undecided" = "#FFFFFF","Runoff"   = "#c1d6bf")

  options(tigris_use_cache = TRUE)

# Load Vote Data####
  v.data <- read.csv("./Build/Input/2026elec_house.csv", header = TRUE)

  #Fetch US House Districts for the entire United States
    map <- congressional_districts(cb = TRUE)

  #Get FIPS code from tidycensus
    data("fips_codes")
    fips <- unique(fips_codes[, c("state", "state_code", "state_name")])

#Replicate CNN graph####
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
      filter(state_code %in% states)

#Process Data for New Graphs####
    
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
             outcome = case_when(str_split_i(Hold.or.pickup, " ", 2) == "Pickup" ~ "Yes",
                                 TRUE ~ "No")) %>%
      left_join(., fips, by = c("State" = "state")) 
    
    map.base <-  map %>%
      rename("state_code" = "STATEFP") %>%
      rename("District" = "CD119FP") %>%
      select("state_code", "District", "ALAND", "AWATER", "geometry") 
    
#Generate Closeness Maps
    
    temp <- v.data.2 %>%
      mutate(Res = case_when(Diff == 0 ~ "Undecided",
                             Diff > 0 & Diff <= close.ness[1] ~ "Close R",
                             Diff > close.ness[1] & Diff <= close.ness[2] ~ "Moderately R",
                             Diff > close.ness[2] ~ "Strong R",
                             Diff < 0 & Diff >= -close.ness[1] ~ "Close D",
                             Diff < -close.ness[1] & Diff >= -close.ness[2] ~ "Moderately D",
                             Diff < -close.ness[2] ~ "Strong D",
                             TRUE ~ NA),
             Res = case_when(test > 0 & test < 40.0 ~ "Runoff",
                             TRUE ~ Res))
    
    temp.map <- map.base %>%
      left_join(., temp, by = c("state_code", "District")) %>%
      filter(state_code %in% states)

#Visualizations

 temp2 <- temp.map %>%
    filter(outcome == "Yes")
      
 g.cnn <- ggplot(map.1) +
   geom_sf(aes(fill = Hold.or.pickup), color = "white", linewidth = 0.2)+
   geom_sf_pattern(aes(pattern = outcome),
                   fill = NA,
                   color = NA,
                   pattern_fill = "white",
                   pattern_color = NA,
                   pattern_density = 0.4, pattern_spacing = 0.015,
                   linewidth = 0.02, data = temp2)+
   scale_fill_manual(values = rating_colors.1,
                     breaks = names(rating_colors.1),
                     labels = names(rating_colors.1),
                     na.value = "white", name = "Results") +
   scale_pattern_manual(values = c("Yes" = "stripe", "No" = "none"),
                        name = "Pickup") +
   theme_void() +
   theme(legend.position = "bottom") +
   guides(fill = guide_legend(nrow = 2, title.position = "top", 
                              title.hjust = 0.5), pattern = "none")
 
  g1 <- ggplot(temp.map) +
    geom_sf(aes(fill = Res), color = "white", linewidth = .2) +
    geom_sf_pattern(aes(pattern = outcome),
                    fill = NA,
                    color = NA,
                    pattern_fill = "white",
                    pattern_color = NA,
                    pattern_density = 0.4, pattern_spacing = 0.015,
                    linewidth = 0.02, data = temp2)+
    scale_fill_manual(values = rating_colors.2,
                      breaks = names(rating_colors.2),
                      labels = names(rating_colors.2),
                      na.value = "white", name = "Results") +
    scale_pattern_manual(values = c("Yes" = "stripe", "No" = "none"),
                         name = "Pickup") +
    theme_void() +
    theme(legend.position = "bottom") +
    guides(fill = guide_legend(nrow = 2, title.position = "top", 
                               title.hjust = 0.5), pattern = "none")

  g2 <- ggplot(temp.map) +
    geom_sf(aes(fill = Res), color = "white", linewidth = .2) +
    geom_sf_pattern(aes(pattern = outcome),
                    fill = NA,
                    color = NA,
                    pattern_fill = "white",
                    pattern_color = NA,
                    pattern_density = 0.4, pattern_spacing = 0.015,
                    linewidth = 0.02, data = temp2)+
    scale_fill_manual(values = rating_colors.3,
                      breaks = names(rating_colors.3),
                      labels = names(rating_colors.3),
                      na.value = "white", name = "Results") +
    scale_pattern_manual(values = c("Yes" = "stripe", "No" = "none"),
                         name = "Pickup") +
    theme_void() +
    theme(legend.position = "bottom") +
    guides(fill = guide_legend(nrow = 2, title.position = "top", 
                               title.hjust = 0.5), pattern = "none")
  
  combined_plot <- plot_grid(g.cnn, g1, g2, labels = c("CNN", "Red/Blue", "Purple"), 
                             ncol = 3)
 # ggsave(combined_plot, file = "./Build/Output/exercise.png")
  # Display the combined figure
  print(combined_plot) 