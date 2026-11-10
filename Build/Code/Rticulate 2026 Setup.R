#This is the script for initial setup for the in lecture excerise.

install.packages("usethis")

usethis::use_course("https://tinyurl.com/bdf6fntm",destdir = "./")

if (!require("pacman")) install.packages("pacman")
pacman::p_load(usethis, tigris, sf, tidyverse, tidycensus, ggpattern, cowplot)

#once finished, move the files in the Rticulate-Main director to the project
#directory.