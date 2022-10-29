#----------- Creating a map of where I've lived ----------------------#

# Load libraries
library(tidyverse)
library(sf)
library(tmap)
library(mapview)

# Read in US city data
file_path <- "/Users/elkewindschitl/Documents/github-website/data/simplemaps_uscities_basicv1.75/uscities.csv"

us_cities <- read_csv(file_path) %>% 
  select(c(city, state_name, lat, lng))

# Create df for cities I've lived in
my_cities <- tribble(
  ~city, ~state_name,
  "Iowa City", "Iowa", 
  "Tucson", "Arizona",
  "Ames", "Iowa",
  "Hilo", "Hawaii",
  "St. Louis", "Missouri",
  "Monterey", "California",
  "Virginia Beach", "Virginia",
  "Seattle", "Washington",
  "Santa Barbara", "California"
)
my_cities <- as.data.frame(my_cities)

# Left join the data sets
my_cities_lat_lng <- left_join(my_cities, us_cities)

# Map view it
my_map <- mapview(my_cities_lat_lng, xcol = "lng", ycol = "lat", crs = 4269, grid = FALSE)

my_map






