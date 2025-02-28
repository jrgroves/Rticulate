library(tidyverse)
library(sf)
library(usethis)

rm(list=ls())


## Gretting the Data
  #usethis::use_course("https://github.com/jrgroves/Rticulate/archive/master.zip", destdir = "./")

  #ufo <- read.csv("./Rticulate-main/ufo.csv")
  #load("./Rticulate-main/census.RData)

  census <- st_as_sf(census)

## Observing the Mess
  
  head(ufo)
  
  names(ufo)
  
## Cleaning off the Dirt
 
  ufo.us <- ufo %>%
    select(datetime, state, country, latitude, longitude)
   
  ufo.us <- ufo %>%
    select(datetime, state, country, latitude, longitude) %>%
    mutate(year = str_split_i(str_split_i(datetime, " ", 1), "/", 3)) %>%
    select(datetime, state, country, latitude, longitude) %>%
    mutate(year = str_split_i(str_split_i(datetime, " ", 1), "/", 3)) %>%
    filter(year=="1990" | year=="2010") %>%
    filter(latitude > 25 & latitude < 50) %>%
    filter(longitude < -70 & longitude > -125) %>%
    filter(state != "")
  
  ufo.us <- ufo.us %>%
    select(state, year) %>%
    mutate(sight = 1) %>%
    pivot_wider(id_cols = state, names_from = year, names_prefix = "YR",
                values_from = sight, values_fn = sum)
  
  #bridge <- read.csv("./Rticulate-main/bridge.csv")
  
  core <- ufo.us %>%
    left_join(., bridge, by="Abbr") %>%
    left_join(., census, by=GEOID)
  
  core <- ufo.us %>%
    mutate(Abbr = state) %>%
    left_join(., bridge, by="Abbr") %>%
    left_join(., census, by="GEOID") %>%
    filter(!is.na(State))
  
## Finding the believers
  
  core2 <- core %>%
    mutate(pop_1990 = pop_1990/1000000,
           pop_2010 = pop_2010/1000000) %>%
    mutate(spp_1990 = YR1990/pop_1990,
           spp_2010 = YR2010/pop_2010,
           delta_spp = ((spp_2010 - spp_1990)/spp_1990)) %>%
    filter(GEOID != "15") %>%
    st_as_sf()

  ggplot(core2) +
    geom_sf(aes(fill = spp_1990)) +
    scale_fill_gradient(low = "#ADD8E6", high = "#00094B", na.value="white" ) +
    labs(title = "UFO Sightings per 1 Million Persons in 1990") +
    theme_bw()
  
  ggplot(core2) +
    geom_sf(aes(fill = spp_2010)) +
    scale_fill_gradient(low = "#ADD8E6", high = "#00094B", na.value="white" ) +
    labs(title = "UFO Sightings per 1 Million Persons in 2010") +
    theme_bw()
  
  ggplot(core2) +
    geom_sf(aes(fill = delta_spp)) +
    scale_fill_gradient(low = "#ADD8E6", high = "#00094B", na.value="white" ) +
    labs(title = "Percentage Change in UFO sightings per 1 Million Person between 1990 and 2010") +
    theme_bw()
  
  
           