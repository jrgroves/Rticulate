rm(list=ls())

library(tidyverse)
library(scales)

educ <- read.csv(file = "./Build/Input/educate.csv")

educ <- educ %>%
  rename("Year" = "Educational.attainment.and.year") 

educ.1 <- educ %>%
  filter(Education == "Bachelor's Degree") %>%
  select(Year, Average, Full.Cost) %>%
  pivot_longer(cols = -c("Year"), values_to = "Value", names_to = "group")

educ.2 <- educ %>%
  filter(Education == "Bachelor's Degree") %>%
  select(Year, Average, Annual.Cost) %>%
  mutate(Annual.Cost = as.numeric(gsub(",", "", Annual.Cost)) )%>%
  pivot_longer(cols = -c("Year"), values_to = "Value", names_to = "group")

educ.3 <- educ %>%
  select(Year, Education, Average, Annual.Cost) %>%
  mutate(Educ2 = case_when(Education == "Bachelor's Degree" ~ "BS",
                           Education == "High School" ~ "HS",
                           TRUE ~ NA)) %>%
  mutate(Annual.Cost = as.numeric(gsub(",", "", Annual.Cost)) )%>%
  pivot_longer(cols = -c("Year", "Education", "Educ2"), values_to = "Value", names_to = "group") %>%
  mutate(group = paste0(group, Educ2)) %>%
  filter(group != "Annual.CostHS") %>%
  select(-c(Education, Educ2))

educ.4 <- educ %>%
  select(Year, Education, Time.to.Pay) 

ggplot(educ.1) +
  geom_line(aes(x = Year, y = Value, group = group, color = group)) +
  labs(title = "The diminishing financial return of higher education",
       subtitle = "Costs of 4-yr degree vs. earnings of 4-yr degree",
       caption = "All figures adjusted to 2023 dollars according to CPI") +
  scale_y_continuous(labels = label_dollar()) +
  scale_color_manual(
    values = c("Full.Cost" = "#2166ac", "Average" = "#b2182b"),
    labels = c("Full.Cost" = "Tuition, Room & Board", "Average" = "Bachelor's Degree Earnings"),
    name   = NULL      # removes the legend title
  ) +
  theme_light() +
  theme(legend.position = "bottom") +
  theme(
    plot.title    = element_text(face = "bold", size = 12, family = "sans"),
    plot.subtitle = element_text(color = "grey40", size = 10),
    plot.caption  = element_text(face = "italic", size = 8, hjust = 0),
    axis.text.y   = element_text(face = "bold"),
    legend.text   = element_text(size = 9)
  )

ggsave(file = "./Build/Output/Figure1.png")


ggplot(educ.2) +
  geom_line(aes(x = Year, y = Value, group = group, color = group)) +
  labs(title = "The ?diminishing? financial return of higher education",
       subtitle = "Annual Cost of 4-yr degree vs. Annual earnings of 4-yr degree",
       caption = "All figures adjusted to 2023 dollars according to CPI") +
  scale_y_continuous(labels = label_dollar()) +
  scale_color_manual(
    values = c("Annual.Cost" = "#2166ac", "Average" = "#b2182b"),
    labels = c("Annual.Cost" = "Tuition, Room & Board", "Average" = "Bachelor's Degree Earnings"),
    name   = NULL      # removes the legend title
  ) +
  theme_light() +
  theme(legend.position = "bottom") +
  theme(
    plot.title    = element_text(face = "bold", size = 12, family = "sans"),
    plot.subtitle = element_text(color = "grey40", size = 10),
    plot.caption  = element_text(face = "italic", size = 8, hjust = 0),
    axis.text.y   = element_text(face = "bold"),
    legend.text   = element_text(size = 9)
  )

ggsave(file = "./Build/Output/Figure2.png")

ggplot(educ.3) +
  geom_line(aes(x = Year, y = Value, group = group, color = group)) +
  labs(title = "The financial return of higher education",
       subtitle = "Annual Costs of 4-yr degree, Annual earnings of 4-yr degree, and 
       Annual earnings of High School Diploma",
       caption = "All figures adjusted to 2023 dollars according to CPI") +
  scale_y_continuous(labels = label_dollar()) +
  scale_color_manual(
    values = c("Annual.CostBS" = "#2166ac", 
               "AverageBS" = "#b2182b", 
               "AverageHS" = "black"),
    labels = c("Annual.CostBS" = "Tuition, Room & Board", 
               "AverageBS" = "Bachelor's Degree Earnings",
               "AverageHS" = "High School Only Earnings"),
    name   = NULL      # removes the legend title
  ) +
  theme_light() +
  theme(legend.position = "bottom") +
  theme(
    plot.title    = element_text(face = "bold", size = 12, family = "sans"),
    plot.subtitle = element_text(color = "grey40", size = 10),
    plot.caption  = element_text(face = "italic", size = 8, hjust = 0),
    axis.text.y   = element_text(face = "bold"),
    legend.text   = element_text(size = 9)
  )
ggsave(file = "./Build/Output/Figure3.png")

ggplot(educ.4) +
  geom_line(aes(x = Year, y = Time.to.Pay, group = Education, color = Education)) +
  labs(title = "The changing financial return of higher education",
       subtitle = "Years to Pay for the Total Cost of 4 Years of College",
       caption = "All figures adjusted to 2023 dollars according to CPI",
       y = "Years to Pay") +
  scale_color_manual(
    values = c("Bachelor's Degree" = "#b2182b", 
               "High School" = "black"),
    name   = NULL      # removes the legend title
  ) +
  theme_light() +
  theme(legend.position = "bottom") +
  theme(
    plot.title    = element_text(face = "bold", size = 12, family = "sans"),
    plot.subtitle = element_text(color = "grey40", size = 10),
    plot.caption  = element_text(face = "italic", size = 8, hjust = 0),
    axis.text.y   = element_text(face = "bold"),
    legend.text   = element_text(size = 9)
  )

ggsave(file = "./Build/Output/Figure4.png")
