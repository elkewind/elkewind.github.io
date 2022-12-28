# Load libraries
library(tidyverse)
library(sf)
library(terra)
library(stars)
library(raster)
library(RColorBrewer)
library(tmap)

# Set data directory
datadir <- "/Users/elkewindschitl/Documents/MEDS/eds-223/homework/data4"

# Read in data
eez <- st_read(file.path(datadir, "/wc_regions_clean.shp"))
eez2 <- vect(file.path(datadir, "/wc_regions_clean.shp"))
sst_08 <- rast(file.path(datadir, "/average_annual_sst_2008.tif"))
sst_09 <- rast(file.path(datadir, "/average_annual_sst_2009.tif"))
sst_10 <- rast(file.path(datadir, "/average_annual_sst_2010.tif"))
sst_11 <- rast(file.path(datadir, "/average_annual_sst_2011.tif"))
sst_12 <- rast(file.path(datadir, "/average_annual_sst_2012.tif"))

# Stack the rasters
stack <- c(sst_08, sst_09, sst_10, sst_11, sst_12)
depth <- rast(file.path(datadir, "/depth.tif"))

# Match up CRS's
eez <- st_transform(eez, crs = "EPSG:4326")
crs(eez2) <- "EPSG:4326"
crs(stack) <- "EPSG:4326"
crs(depth) <- "EPSG:4326"

mean_sst <- mean(stack) %>% -273.15
depth_crop <- crop(depth, mean_sst)
depth_resamp <- resample(x = depth_crop, y = mean_sst, method = "near")

# Reclassify depth raster to = 1 when between -70 and 0
rcl_depth <- matrix(c(-Inf, -70, NA,
                      -70, 0, 1,
                      0, Inf, NA), ncol = 3, byrow = TRUE)
suitable_depth <- classify(depth_resamp, rcl = rcl_depth)
# Reclassify SST raster to = 1 when between 11 and 30 Celsuis 
rcl_sst <- matrix(c(-Inf, 11, NA,
                    11, 30, 1,
                    30, Inf, NA), ncol = 3, byrow = TRUE)
suitable_sst <- classify(mean_sst, rcl = rcl_sst)

# Find suitable locations for both depth and sst
suitable_stack <- c(suitable_depth, suitable_sst)
suit <- function(x, y) {x*y}
suitable <- lapp(suitable_stack[[c(1, 2)]], fun = suit)

# Crop the extent of suitable area
crop_suit <- crop(suitable, eez2)
# Mask to just the eez2 area
suit_masked <- mask(crop_suit, eez2)
# Find the total suitable area
crop_suit_area <- expanse(suit_masked, unit = "km")
# Find the cell size of each cell
cell_area <- cellSize(suit_masked, mask = TRUE, unit = "km")
# Rasterize eez2
eez_rast <- eez2 %>% rasterize(y = cell_area, field = "rgn_id")
# Mask
zone_mask <- terra::mask(eez_rast, cell_area)
# Final zonal area
zones_area <- terra::zonal(cell_area, zone_mask, fun = sum, na.rm = TRUE)
# Join to eez2
eez_sf <- st_as_sf(eez2)
eez_total <- left_join(eez_sf, zones_area, by = "rgn_id") |> 
  rename("suitable_area_km2" = "area")
# add column with percent of each region that is suitable
eez_percent <- eez_total |> 
  mutate("percent_suitable" = (suitable_area_km2/area_km2)*100)

# Map it
tmap_mode("view")
total_map <- tm_shape(eez_percent) +
  tm_polygons(col = "suitable_area_km2",
              title = "Total suitable oyster area",
              palette = brewer.pal(name = "Purples", n = 5))
percent_map <- tm_shape(eez_percent) +
  tm_polygons(col = "percent_suitable",
              title = "Percent suitable oyster area",
              palette = brewer.pal(name = "Purples", n = 5))
tmap_arrange(total_map, percent_map)

# Make a table too
table <- as.data.frame(cbind(eez_percent$rgn, eez_percent$suitable_area_km2, eez_percent$percent_suitable))
colnames(table) <- c("Region", "Total Suitable Area", "Percent Suitable Area")
print(table)

species_suitability2 <- function(min_temp, max_temp, min_depth, max_depth, species) {
  # Set directory
  datadir <- "/Users/elkewindschitl/Documents/MEDS/eds-223/homework/data4"
  # Read in data
  eez2 <- vect(file.path(datadir, "/wc_regions_clean.shp"))
  sst_08 <- rast(file.path(datadir, "/average_annual_sst_2008.tif"))
  sst_09 <- rast(file.path(datadir, "/average_annual_sst_2009.tif"))
  sst_10 <- rast(file.path(datadir, "/average_annual_sst_2010.tif"))
  sst_11 <- rast(file.path(datadir, "/average_annual_sst_2011.tif"))
  sst_12 <- rast(file.path(datadir, "/average_annual_sst_2012.tif"))
  # Stack the rasters
  stack <- c(sst_08, sst_09, sst_10, sst_11, sst_12)
  depth <- rast(file.path(datadir, "/depth.tif"))
  # Match up CRS's
  eez <- st_transform(eez, crs = "EPSG:4326")
  crs(eez2) <- "EPSG:4326"
  crs(stack) <- "EPSG:4326"
  crs(depth) <- "EPSG:4326"
  mean_sst <- mean(stack) %>% -273.15
  depth_crop <- crop(depth, mean_sst)
  depth_resamp <- resample(x = depth_crop, y = mean_sst, method = "near")
  #Reclassify depth raster to = 1 when between -70 and 0
  rcl_depth <- matrix(c(-Inf, -max_depth, NA,
                        -max_depth, -min_depth, 1,
                        -min_depth, Inf, NA), ncol = 3, byrow = TRUE)
  suitable_depth <- classify(depth_resamp, rcl = rcl_depth)
  # Reclassify SST raster to = 1 when between 11 and 30 Celsuis
  rcl_sst <- matrix(c(-Inf, min_temp, NA,
                      min_temp, max_temp, 1,
                      max_temp, Inf, NA), ncol = 3, byrow = TRUE)
  suitable_sst <- classify(mean_sst, rcl = rcl_sst)
  # Find suitable locations for both depth and sst
  suitable_stack <- c(suitable_depth, suitable_sst)
  suit <- function(x, y) {x*y}
  suitable <- lapp(suitable_stack[[c(1, 2)]], fun = suit)
  # Do this with zonal instead
  # Crop the extent of suitable area
  crop_suit <- crop(suitable, eez2)
  # Mask to just the eez2 area
  suit_masked <- mask(crop_suit, eez2)
  # Find the total suitable area
  crop_suit_area <- expanse(suit_masked, unit = "km")
  # Find the cell size of each cell
  cell_area <- cellSize(suit_masked, mask = TRUE, unit = "km")
  # Rasterize eez2
  eez_rast <- eez2 %>% rasterize(y = cell_area, field = "rgn_id")
  # Mask
  zone_mask <- terra::mask(eez_rast, cell_area)
  # Final zonal area
  zones_area <- terra::zonal(cell_area, zone_mask, fun = sum, na.rm = TRUE)
  # Join to eez2
  eez_sf <- st_as_sf(eez2)
  eez_total <- left_join(eez_sf, zones_area, by = "rgn_id") |> 
    rename("suitable_area_km2" = "area")
  # add column with percent of each region that is suitable
  eez_percent <- eez_total |> 
    mutate("percent_suitable" = (suitable_area_km2/area_km2)*100)
  # Make a table too
  table <- as.data.frame(cbind(eez_percent$rgn, eez_percent$suitable_area_km2, eez_percent$percent_suitable))
  colnames(table) <- c("Region", "Total Suitable Area", "Percent Suitable Area")
  print(table)
  # Map it
  tmap_mode("view")
  total_map <- tm_shape(eez_percent) +
    tm_polygons(col = "suitable_area_km2",
                title = paste0("Total suitable ", species, " area"),
                palette = brewer.pal(name = "Purples", n = 5))
  percent_map <- tm_shape(eez_percent) +
    tm_polygons(col = "percent_suitable",
                title = paste0("Total percent ", species, " area"),
                palette = brewer.pal(name = "Purples", n = 5))
  tmap_arrange(total_map, percent_map)
}

# Test function on California spiny lobster
species_suitability2(min_temp = 14.8, max_temp = 22.3, min_depth = 0, 
                     max_depth = 150, species = "spiny lobster")
# Test to reproduce oysters
species_suitability2(min_temp = 11, max_temp = 30, min_depth = 0,
                     max_depth = 70, species = "Oyster")
  
  