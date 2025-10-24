#Code for the R-ticulate Data Seminar 

#Author: Jeremy R. Groves
#Date: October 16, 2024
  #Update: October 18, 2025
#-------------------------------


rm(list=ls())

library(tidyverse)
library(sf)
library(usethis)

## Gretting the Data
 #  usethis::use_course("https://github.com/jrgroves/Rticulate/archive/master.zip", destdir = "./")

## Getting the Data   
      
    ufo <- read.csv("./Build/Input/ufo.csv")

    load("./Build/Input/census.RData")

    st_as_sf(census)  

## Observing the Mess
    
    head(ufo)
    
    names(ufo)

    
## Cleaning off the Dirt

    ufo.us <- ufo %>%
      select(datetime, state, country, latitude, longitude) %>%
      mutate(year = str_split_i(str_split_i(datetime, " ", 1), "/", 3)) %>%
      filter(year=="2000" | year=="2010") %>%
      filter(latitude > 25 & latitude < 50) %>%
      filter(longitude < -70 & longitude > -125) %>%
      filter(state != "")

    
  ufo.us <- ufo.us %>%
    select(state, year) %>%
    mutate(sight = 1) %>%
    pivot_wider(id_cols = state, names_from = year, names_prefix = "YR",
                values_from = sight, values_fn = sum)

## Use GEOID and Abbreviation Bridge to join UFO to Census Data
  load("./Build/Input/bridge.RData")

  core <- ufo.us %>%
    left_join(., bridge, by = c("state" = "Abbr"))%>%
    left_join(., census, by="GEOID") %>%
    filter(!is.na(State))


## Modifying the variables for better display and percentage change.

  core2 <- core %>%
    mutate(pop_2000 = pop_2000/1000000,
           pop_2010 = pop_2010/1000000) %>%
    mutate(spp_2000 = YR2000/pop_2000,
           spp_2010 = YR2010/pop_2010,
           delta_spp = ((spp_2010 - spp_2000)/spp_2000)) %>%
    filter(GEOID != "15") %>%
    st_as_sf()

##Visualization

  ## Creation of 2000 Plot - Simple
      ggplot(core2) +
        geom_sf(aes(fill = spp_2000)) 
      
  ## Creation of 2000 Plot - some modifications
      ggplot(core2) +
        geom_sf(aes(fill = spp_2000)) +
        scale_fill_gradient(low = "#e8f4f8", high = "#72bcd4", na.value="white" ) +
        labs(title = "UFO Sightings per 1 Million Persons in 2000",
             fill = "Sightings") +
        theme_bw()
  
  ## Creation of 2000 Plot - more modifications and save
      g1 <- ggplot(core2) +
        geom_sf(aes(fill = spp_2000)) +
        scale_fill_gradient(low = "#e8f4f8", high = "#72bcd4", na.value="white" ) +
        labs(title = "UFO Sightings per 1 Million Persons in 2000",
             fill = "Sightings") +
        theme_bw() +
          theme(legend.position="bottom",
                axis.text.x = element_blank(),
                axis.text.y = element_blank(),
                panel.grid.major = element_blank(),
                #panel.border = element_blank(),
                axis.ticks = element_blank())
  
  ## Creation of 2010 Plot - more modifications and save
    g2 <- ggplot(core2) +
            geom_sf(aes(fill = spp_2010)) +
            scale_fill_gradient(low = "#e8f4f8", high = "#72bcd4", na.value="white" ) +
            labs(title = "UFO Sightings per 1 Million Persons in 2010",
                 fill = "Sightings") +
            theme_bw() +
            theme(legend.position="bottom",
                  axis.text.x = element_blank(),
                  axis.text.y = element_blank(),
                  panel.grid.major = element_blank(),
                  #panel.border = element_blank(),
                  axis.ticks = element_blank())

  ## Use cowplot to display both graphson same image
      install.packages("cowplot")
      library(cowplot)
      
      plot_grid(g1, g2, nrow = 1)
  
  ## Creation of Percentage Change Plot - more modifications and save
    g3 <- ggplot(core2) +
      geom_sf(aes(fill = delta_spp)) +
      scale_fill_gradient(low = "#e8f4f8", high = "#72bcd4", na.value="white" ) +
      labs(title = "Percentage Change in UFO sightings per 1 Million Person between 1990 and 2010",
           fill = "Sightings") +
      theme_bw() +
      theme(legend.position="bottom",
            axis.text.x = element_blank(),
            axis.text.y = element_blank(),
            panel.grid.major = element_blank(),
            #panel.border = element_blank(),
            axis.ticks = element_blank())
  
  ggsave(g3, file = "./Figure One.png", dpi = 300)
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  














