library(gtsummary)
library(gt)
library(usethis)

fips2 <- fips %>%
  filter(!state_code %in% remove)


usethis::use_course("https://github.com/jrgroves/Rticulate/archive/refs/heads/main.zip",
                    destdir = "./")

k <- 5   # number of side-by-side columns

states <- fips2 %>%
  distinct() %>%
  arrange(state_name) %>%
  select(State = state_name, FIPS = state_code)

n_per <- ceiling(nrow(states) / k)

# split into k pieces, pad short pieces with blank rows, then join side by side
pieces <- lapply(seq_len(k), function(i) {
  rows <- ((i - 1) * n_per + 1):min(i * n_per, nrow(states))
  p <- states[rows, ]
  if (nrow(p) < n_per) p[(nrow(p) + 1):n_per, ] <- NA
  setNames(p, paste0(names(p), "_", i))
})

wide <- bind_cols(pieces)

# header labels: "State" and "FIPS" for every column pair
labels <- setNames(rep(c("State", "FIPS"), k), names(wide))

tbl <- wide %>%
  gt() %>%
  tab_header(title = "States in Sample") %>%
  cols_label(.list = labels) %>%
  sub_missing(missing_text = "") %>%
  cols_align(align = "center", columns = starts_with("FIPS"))

# vertical divider before each column pair after the first
for (i in 2:k) {
  tbl <- tbl %>%
    tab_style(style = cell_borders(sides = "left", color = "grey60", weight = px(2)),
              locations = list(cells_body(columns = paste0("State_", i)),
                               cells_column_labels(columns = paste0("State_", i))))
}

tbl

gtsave(tbl, "./Build/Output/states_table.png")

install.packages("litedown")
library(litedown)
library(dplyr)
library(gt)

v.data.2 %>%
  summarise(
    `Min.`    = min(Diff, na.rm = TRUE),
    `1st Qu.` = quantile(Diff, 0.25, na.rm = TRUE),
    Median    = median(Diff, na.rm = TRUE),
    Mean      = mean(Diff, na.rm = TRUE),
    `3rd Qu.` = quantile(Diff, 0.75, na.rm = TRUE),
    `Max.`    = max(Diff, na.rm = TRUE)
  ) %>%
  gt() %>%
  fmt_number(columns = everything(), decimals = 2) %>%
  cols_align(align = "center") %>%
  gtsave(., "./Build/Output/Table.png")
