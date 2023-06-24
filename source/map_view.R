#----------- Creating a map of where I've lived ----------------------#

# Load libraries
library(tidyverse)
library(sf)
library(tmap)
library(mapview)
library(leafpop)
library(leaflet)
library(viridis)

# Read in US city data
file_path <- "/Users/elkewindschitl/Documents/github-website/data/simplemaps_uscities_basicv1.75/uscities.csv"

us_cities <- read_csv(file_path) %>% 
  select(c(city, state_name, lat, lng))

# Create df for cities I've lived in
my_cities <- tribble(
  ~city, ~state_name, ~months_sincecol,
  "Iowa City", "Iowa", 21,
  "Tucson", "Arizona", 5,
  "Ames", "Iowa", 20,
  "Hilo", "Hawaii", 5,
  "St. Louis", "Missouri", 5,
  "Monterey", "California", 3,
  "Virginia Beach", "Virginia", 3,
  "Seattle", "Washington", 8,
  "Santa Barbara", "California", 11
)
my_cities <- as.data.frame(my_cities)

# Left join the data sets
my_cities_lat_lng <- left_join(my_cities, us_cities)

# Rename columns for nice map viewing
cols <- c("City", "State", "Months", "Latitude", "Longitude")
names(my_cities_lat_lng) <- cols

# Map view it
my_map <- mapview(my_cities_lat_lng, 
                  xcol = "Longitude", 
                  ycol = "Latitude", 
                  zcol = "City",
                  crs = 4269, 
                  grid = FALSE,
                  legend = FALSE)
my_map

### ------------------- Customize! --------------------------###
# Add an image for every city
ic_img <- file.path("images", "IC.jpg")
az_img <- file.path("images", "AZ.jpg")
am_img <- file.path("images", "AMES.jpg")
hi_img <- file.path("images", "HI.jpg")
stl_img <- file.path("images", "STL.jpg")
mb_img <- file.path("images", "MB.jpg")
vb_img <- file.path("images", "vB.jpg")
sea_img <- file.path("images", "SEA.jpg")
sb_img <- file.path("images", "SB.jpg")

# Make a vector of the images and add to df
img_vec <- c(ic_img, az_img, am_img, hi_img, stl_img, 
           mb_img, vb_img, sea_img, sb_img)

# Make a leaflet map
my_leaflet <- leaflet(my_cities_lat_lng) %>%
  addProviderTiles("CartoDB.Positron", 
                   group = "CartoDB.Positron") %>% 
  setView(lng = -110.35, 
          lat = 42.3601, 
          zoom = 2.5) %>% 
  addCircles(lng = ~Longitude,
             lat = ~Latitude,
             weight = ~Months * 3,
             radius = ~Months,
             fill = TRUE, 
             color = "#1cd4ce", 
             group = "Cities",
             label = ~City) %>%
  addPopupImages(img_vec, 
                 group = "Cities", 
                 width = 175, 
                 tooltip = FALSE)

my_leaflet






