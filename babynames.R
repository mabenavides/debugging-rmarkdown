library(tidyverse)
library(babynames)
library(glue)
library(RColorBrewer) # I added this for the top_n_trend function 

# plot total US births
applicants %>%
  mutate(
    sex = if_else(sex == "F", "Female", "Male"),
    n_all = n_all / 1e06
  ) %>%
  ggplot(mapping = aes(x = year, y = n_all, color = sex)) + # Since we don't have an area, we should use color, instead of fill
  geom_line() + # If we're interested in the total births, makes more sense to use geom_line 
  scale_fill_brewer(type = "qual") +
  labs(
    title = "Total US births",
    x = "Year",
    y = "Millions",
    fill = NULL,
    caption = "Source: Social Security Administration"
  ) +
  theme_minimal()

# write function to show trends over time for specific name
name_trend <- function(person_name) {
  babynames %>%
    filter(name == person_name) %>%
    ggplot(mapping = aes(x = year, y = n, color = sex)) +
    geom_line() +
    scale_color_brewer(type = "qual") +
    labs(
      title = glue("Name: {person_name}"), # The function requieres the use of quotes, since it refers to characters 
      x = "Year",
      y = "Number of births",
      color = NULL
    ) +
    theme_minimal()
}

name_trend("Benjamin")

# write function to show trends over time for top N names in a specific year
top_n_trend <- function(n_year, n_rank = 5) { 
  # create lookup table
  top_names <- babynames %>%
    group_by(name, sex) %>%
    summarize(count = as.numeric(sum(n))) %>% # It cannot sum over a variable that doesn't exist. Changed to n
    filter(count > 1000) %>%
    select(name, sex)
  
  # filter babynames for top_names
  filtered_names <- babynames %>%
    inner_join(top_names)
  
  # get the top N names from n_year
  top_names_filtered <- filtered_names %>% # Set another name to object to avoid overwriting it 
    filter(year == n_year) %>%
    group_by(name, sex) %>%
    summarize(count = sum(n)) %>%  # Again it cannot sum over a variable that doesn't exist.
    group_by(sex) %>%
    mutate(rank = min_rank(desc(count))) %>%
    filter(rank < n_rank) %>%
    arrange(sex, rank) %>%
    select(name, sex, rank)
  
  
  # Adding colors to the palette so the function can graph more values 
  nb.cols <- 20
  mycolors <- colorRampPalette(brewer.pal(8, "Set2"))(nb.cols)
  
  # keep just the top N names over time and plot
  filtered_names %>%
    inner_join(select(top_names_filtered, sex, name)) %>% # Change the name of the top_names object
    ggplot(mapping = aes(x = year, y = n, color = name)) +
    facet_wrap(~sex, ncol = 1) +
    geom_line() +
    scale_color_manual(values = mycolors) + # Changed to the extended palette 
    labs(
      title = glue("Most Popular Names of {n_year}"),
      x = "Year",
      y = "Number of births",
      color = "Name"
    ) +
    theme_minimal()
}

top_n_trend(n_year = 1986)
top_n_trend(n_year = 2014)
top_n_trend(n_year = 1986, n_rank = 10)

# compare naming trends to disney princess film releases
disney <- tribble(
  ~princess,  ~film, ~release_year, # Should use the ~ syntax 
  "Snow White", "Snow White and the Seven Dwarfs", 1937,
  "Cinderella", "Cinderella", 1950,
  "Aurora", "Sleeping Beauty", 1959,
  "Ariel", "The Little Mermaid", 1989,
  "Belle", "Beauty and the Beast", 1991,
  "Jasmine", "Aladdin", 1992,
  "Pocahontas", "Pocahontas", 1995,
  "Mulan", "Mulan", 1998,
  "Tiana", "The Princess and the Frog", 2009,
  "Rapunzel", "Tangled", 2010,
  "Merida", "Brave", 2012,
  "Elsa", "Frozen", 2013,
  "Moana", "Moana", 2016
)

## join together the data frames
babynames %>%
  # ignore men named after princesses - is this fair?
  filter(sex == "F") %>% # Sex column is in characters, so we need quotation marks
  inner_join(disney, by = c("name" = "princess")) %>%
  mutate(name = fct_reorder(.f = name, .x = release_year)) %>%
  # plot the trends over time, indicating release year
  ggplot(mapping = aes(x = year, y = n)) +
  facet_wrap(~ name + film, scales = "free_y", labeller = label_both) + # labeller doesn't need the ()
  geom_line() +
  geom_vline(mapping = aes(xintercept = release_year), linetype = 2, alpha = .5) +
  scale_x_continuous(breaks = c(1880, 1940, 2000)) +
  theme_minimal() +
  labs(title = "Popularity of Disney princess names",
       x = "Year",
       y = "Number of births")
