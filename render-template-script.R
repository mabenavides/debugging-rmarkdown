library(tidyverse)
library(countrycode)


# Create a list of the iso3 values

iso3_list <- read_csv("data/hiv_rates.csv") %>% 
  janitor::clean_names() %>%
  mutate(country_name = countrycode(iso3, "iso3c", "country.name")) %>%
  distinct(iso3) %>%
  pull()


# 

for (i in iso3_list) {
  file <- paste(
    "reports/", i, ".html", sep = "")
  rmarkdown::render("hiv-profile-template.Rmd", params = list(
    iso3 = i
  ), 
  output_file = file)
}
