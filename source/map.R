#----------- Creating a map of where I've lived ----------------------#

# Load libraries
library(tidyverse)
library(sf)
library(tmap)

# Read in US city data
file_path <- "/Users/elkewindschitl/Documents/github-website/data/simplemaps_uscities_basicv1.75/uscities.csv"

us_cities <- read_csv(file_path) %>% 
  select(c(city, state_name, lat, lng))
us_cities_spaital <- us_cities %>% 
  st_as_sf(coords = c("lat", "lng")) %>% 
  st_set_crs("EPSG:4326") 

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

# Left join the data sets
my_cities_spatial <- st_as_sf(left_join(my_cities, us_cities_spaital))

# Make an interactive map!
tmap::tmap_mode("view")
tm_shape(my_cities_spatial) +
  tm_dots()




