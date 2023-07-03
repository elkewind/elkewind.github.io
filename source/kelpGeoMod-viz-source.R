library(tidyverse)
library(raster)
library(terra)
library(sf)
library(RColorBrewer)
library(tmap)
library(tmaptools)
library(exactextractr)
library(leaflet)

#---- Set up the data directory (wherever your download of our Google Shared Drive lives)
data_dir <- "/Users/elkewindschitl/Documents/MEDS/kelpGeoMod/final-data"

# Set color palette
light_blue <- "#c7e0d8"
dark_blue <- "#083763"
sst_pal <- "-YlGnBu"
nutrient_pal <- "OrRd"
kelp_pal <- "YlGn"
maxent_pal <- "BuGn" 
    
# Read in AOI
aoi <- st_read(file.path(data_dir, "02-intermediate-data/02-aoi-sbchannel-shapes-intermediate/aoi-sbchannel.shp"))
# Create a slightly larger bounding box
bbox <- st_bbox(c(xmin = -120.65 - 0.1, 
                  xmax = -118.8 + 0.1,
                  ymax = 34.59 + 0.1,
                  ymin = 33.85 - 0.1))
    
# Define basemap options
basemap <- tm_basemap("Stamen.Terrain")
# Plot
tmap_mode("view")
aoi_map <- tm_shape(aoi, bbox = bbox) +
  basemap +
  tm_borders(lwd = 2, col = dark_blue)

# Prep data for output
kelp <- brick(file.path(data_dir, "02-intermediate-data/05-kelp-area-biomass-intermediate/kelp-area-brick.tif"))

# Read in the counties data
counties <- st_read(file.path(data_dir, "01-raw-data/02-ca-county-land-boundaries-raw/California_County_Boundaries/cnty19_1.shp"))

# Convert counties data to WGS84
counties <- st_transform(counties, "+proj=longlat +datum=WGS84")

calc_seasonal_means_brick <- function(rast_to_convert) {
  
  quarter_sets <- list(seq(from = 1, to = 36, by = 4), # Q1s (winter)
                       seq(from = 2, to = 36, by = 4), # Q2s (spring)
                       seq(from = 3, to = 36, by = 4), # Q3s (summer)
                       seq(from = 4, to = 36, by = 4)) # Q4s (fall)
  
  all_seasons_brick <- brick() # set up brick to hold averaged layers for each season (will have 4 layers at the end)
  
  for (i in seq_along(quarter_sets)) {
    
    season_brick_holder <- brick() # hold all layers for one season, then reset for next season
    
    for (j in quarter_sets[[i]]) {
      season_brick <- brick() # hold single layer in a season, then reset for next layer
      season_brick <- addLayer(season_brick, rast_to_convert[[j]]) # add single layer to initialized brick
      season_brick_holder <- addLayer(season_brick_holder, season_brick) # add this layer to the holder for this season, and repeat until have all layers from season
    }
    
    season_averaged_layer <- calc(season_brick_holder, mean) # after having all layers from season, take the mean
    all_seasons_brick <- addLayer(all_seasons_brick, season_averaged_layer) # add mean to the brick holding all averaged layers, and then repeat for the next season
  }
  
  return(all_seasons_brick) # return the resulting brick object
}

kelp_all <- calc_seasonal_means_brick(rast_to_convert = kelp)

kelp_quarter1 <- kelp_all[[1]]
kelp_quarter2 <- kelp_all[[2]]
kelp_quarter3 <- kelp_all[[3]]
kelp_quarter4 <- kelp_all[[4]]

# Read in depth data
depth <- raster(file.path(data_dir, "02-intermediate-data/06-depth-intermediate/depth.tif"))

# Read in sst data
sst_quarter1 <- raster(file.path(data_dir, "02-intermediate-data/07-sst-intermediate/sst-quarter-1.tif"))
sst_quarter2 <- raster(file.path(data_dir, "02-intermediate-data/07-sst-intermediate/sst-quarter-2.tif"))
sst_quarter3 <- raster(file.path(data_dir, "02-intermediate-data/07-sst-intermediate/sst-quarter-3.tif"))
sst_quarter4 <- raster(file.path(data_dir, "02-intermediate-data/07-sst-intermediate/sst-quarter-4.tif"))

# Read in nitrogen data
nitr_all <- brick(file.path(data_dir, "03-analysis-data/02-nutrient-interpolation-analysis/nitrate-nitrite/nitrate-nitrite-quarter-brick.tif"))

nitr_quarter1 <- nitr_all[[1]]
nitr_quarter2 <- nitr_all[[2]]
nitr_quarter3 <- nitr_all[[3]]
nitr_quarter4 <- nitr_all[[4]]

# Read in phosphate data
phos_all <- brick(file.path(data_dir, "03-analysis-data/02-nutrient-interpolation-analysis/phosphate/phosphate-quarter-brick.tif"))

phos_quarter1 <- phos_all[[1]]
phos_quarter2 <- phos_all[[2]]
phos_quarter3 <- phos_all[[3]]
phos_quarter4 <- phos_all[[4]]

# Read in ammonium data
amm_all <- brick(file.path(data_dir, "03-analysis-data/02-nutrient-interpolation-analysis/ammonium/ammonium-quarter-brick.tif"))

amm_quarter1 <- amm_all[[1]]
amm_quarter2 <- amm_all[[2]]
amm_quarter3 <- amm_all[[3]]
amm_quarter4 <- amm_all[[4]]

# Map it with tmap
tm1 <- tm_shape(kelp_quarter1) +
  tm_raster(style = "cont",
            breaks = c(0, 500, 1000, 5000, 10000, 20000, 50000),
            title = "Kelp Area (m)",
            palette = kelp_pal) +
  tm_layout(main.title = "Kelp Area (m)") +
  
  tm_shape(counties) +
  tm_polygons() +
  
  tm_shape(sst_quarter1) +
  tm_raster(style = "cont",
            title = "Sea Surface Temperature (°C)",
            palette = sst_pal) +
  tm_layout(main.title = "Sea Surface Temperature") +
  
  tm_shape(depth) +
  tm_raster(style = "cont",
            breaks = c(-2000, -1000, -500, -200, -100, -60, -40, -20, 0),
            title = "Depth (m)",
            palette = "Blues") +
  tm_layout(main.title = "Bathymetry of the Santa Barbara Channel") +
  
  tm_shape(nitr_quarter1) + 
  tm_raster(style = "cont",
            title = "Nitrate + Nitrite (mcmol/L)",
            palette = nutrient_pal,
            breaks = c(0, 2, 5, 10, 15, 20)) +
  tm_layout(main.title = "Nitrate + Nitrite (mcmol/L)") +
  
  tm_shape(phos_quarter1) +
  tm_raster(style = "cont",
            title = "Phosphate (mcmol/L)",
            palette = nutrient_pal) +
  tm_layout(main.title = "Phosphate (mcmol/L)") +
  
  tm_shape(amm_quarter1) +
  tm_raster(style = "cont",
            title = "Ammonium (mcmol/L)",
            palette = nutrient_pal) +
  tm_layout(main.title = "Ammonium (mcmol/L)") +
  tm_shape(aoi, bbox = bbox) +
  tm_borders(lwd = 2, col = dark_blue)

# Convert to leaflet to manipulate default layers
tm1 <- tm1 %>% 
  tmap_leaflet() %>%
  leaflet::hideGroup("sst_quarter1") %>% 
  hideGroup("depth") %>% 
  hideGroup("nitr_quarter1") %>% 
  hideGroup("phos_quarter1") %>% 
  hideGroup("amm_quarter1")

# Map it with tmap
tm2 <- tm_shape(kelp_quarter2) +
  tm_raster(style = "cont",
            breaks = c(0, 500, 1000, 5000, 10000, 20000, 50000),
            title = "Kelp Area (m)",
            palette = kelp_pal) +
  tm_layout(main.title = "Kelp Area (m)") +
  
  tm_shape(counties) +
  tm_polygons() +
  
  tm_shape(sst_quarter2) +
  tm_raster(style = "cont",
            title = "Sea Surface Temperature (°C)",
            palette = sst_pal) +
  tm_layout(main.title = "Sea Surface Temperature") +
  
  tm_shape(depth) +
  tm_raster(style = "cont",
            breaks = c(-2000, -1000, -500, -200, -100, -60, -40, -20, 0),
            title = "Depth (m)",
            palette = "Blues") +
  tm_layout(main.title = "Bathymetry of the Santa Barbara Channel") +
  
  tm_shape(nitr_quarter2) + 
  tm_raster(style = "cont",
            title = "Nitrate + Nitrite (mcmol/L)",
            palette = nutrient_pal,
            breaks = c(0, 2, 5, 10, 15, 20)) +
  tm_layout(main.title = "Nitrate + Nitrite (mcmol/L)") +
  
  tm_shape(phos_quarter2) +
  tm_raster(style = "cont",
            title = "Phosphate (mcmol/L)",
            palette = nutrient_pal) +
  tm_layout(main.title = "Phosphate (mcmol/L)") +
  
  tm_shape(amm_quarter2) +
  tm_raster(style = "cont",
            title = "Ammonium (mcmol/L)",
            palette = nutrient_pal) +
  tm_layout(main.title = "Ammonium (mcmol/L)") +
  tm_shape(aoi, bbox = bbox) +
  tm_borders(lwd = 2, col = dark_blue)

# Convert to leaflet to manipulate default layers
tm2 <- tm2 %>% 
  tmap_leaflet() %>%
  leaflet::hideGroup("sst_quarter2") %>% 
  hideGroup("depth") %>% 
  hideGroup("nitr_quarter2") %>% 
  hideGroup("phos_quarter2") %>% 
  hideGroup("amm_quarter2")

# Map it with tmap
tm3 <- tm_shape(kelp_quarter3) +
  tm_raster(style = "cont",
            breaks = c(0, 500, 1000, 5000, 10000, 20000, 50000),
            title = "Kelp Area (m)",
            palette = kelp_pal) +
  tm_layout(main.title = "Kelp Area (m)") +
  
  tm_shape(counties) +
  tm_polygons() +
  
  tm_shape(sst_quarter3) +
  tm_raster(style = "cont",
            title = "Sea Surface Temperature (°C)",
            palette = sst_pal) +
  tm_layout(main.title = "Sea Surface Temperature") +
  
  tm_shape(depth) +
  tm_raster(style = "cont",
            breaks = c(-2000, -1000, -500, -200, -100, -60, -40, -20, 0),
            title = "Depth (m)",
            palette = "Blues") +
  tm_layout(main.title = "Bathymetry of the Santa Barbara Channel") +
  
  tm_shape(nitr_quarter3) + 
  tm_raster(style = "cont",
            title = "Nitrate + Nitrite (mcmol/L)",
            palette = nutrient_pal,
            breaks = c(0, 2, 5, 10, 15, 20)) +
  tm_layout(main.title = "Nitrate + Nitrite (mcmol/L)") +
  
  tm_shape(phos_quarter3) +
  tm_raster(style = "cont",
            title = "Phosphate (mcmol/L)",
            palette = nutrient_pal) +
  tm_layout(main.title = "Phosphate (mcmol/L)") +
  
  tm_shape(amm_quarter3) +
  tm_raster(style = "cont",
            title = "Ammonium (mcmol/L)",
            palette = nutrient_pal) +
  tm_layout(main.title = "Ammonium (mcmol/L)") +
  tm_shape(aoi, bbox = bbox) +
  tm_borders(lwd = 2, col = dark_blue)

# Convert to leaflet to manipulate default layers
tm3 <- tm3 %>% 
  tmap_leaflet() %>%
  leaflet::hideGroup("sst_quarter3") %>% 
  hideGroup("depth") %>% 
  hideGroup("nitr_quarter3") %>% 
  hideGroup("phos_quarter3") %>% 
  hideGroup("amm_quarter3")

# Map it with tmap
tm4 <- tm_shape(kelp_quarter4) +
  tm_raster(style = "cont",
            breaks = c(0, 500, 1000, 5000, 10000, 20000, 50000),
            title = "Kelp Area (m)",
            palette = kelp_pal) +
  tm_layout(main.title = "Kelp Area (m)") +
  
  tm_shape(counties) +
  tm_polygons() +
  
  tm_shape(sst_quarter4) +
  tm_raster(style = "cont",
            title = "Sea Surface Temperature (°C)",
            palette = sst_pal) +
  tm_layout(main.title = "Sea Surface Temperature") +
  
  tm_shape(depth) +
  tm_raster(style = "cont",
            breaks = c(-2000, -1000, -500, -200, -100, -60, -40, -20, 0),
            title = "Depth (m)",
            palette = "Blues") +
  tm_layout(main.title = "Bathymetry of the Santa Barbara Channel") +
  
  tm_shape(nitr_quarter4) + 
  tm_raster(style = "cont",
            title = "Nitrate + Nitrite (mcmol/L)",
            palette = nutrient_pal,
            breaks = c(0, 2, 5, 10, 15, 20)) +
  tm_layout(main.title = "Nitrate + Nitrite (mcmol/L)") +
  
  tm_shape(phos_quarter4) +
  tm_raster(style = "cont",
            title = "Phosphate (mcmol/L)",
            palette = nutrient_pal) +
  tm_layout(main.title = "Phosphate (mcmol/L)") +
  
  tm_shape(amm_quarter4) +
  tm_raster(style = "cont",
            title = "Ammonium (mcmol/L)",
            palette = nutrient_pal) +
  tm_layout(main.title = "Ammonium (mcmol/L)") +
  tm_shape(aoi, bbox = bbox) +
  tm_borders(lwd = 2, col = dark_blue)

# Convert to leaflet to manipulate default layers
tm4 <- tm4 %>% 
  tmap_leaflet() %>%
  leaflet::hideGroup("sst_quarter4") %>% 
  hideGroup("depth") %>% 
  hideGroup("nitr_quarter4") %>% 
  hideGroup("phos_quarter4") %>% 
  hideGroup("amm_quarter4")

# Prep for plotting
# ---------------------------------Quarter 1  ---------------------------------
# Read in kelp data and make sf object
kelp_1 <- read_csv(file.path(data_dir, "03-analysis-data/04-maxent-analysis/quarter-1/kelp-presence-1.csv")) %>% 
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# Read in the maxent output
maxent_quarter_1 <- raster(file.path(data_dir, "03-analysis-data/04-maxent-analysis/results/maxent-quarter-1-output.tif"))

# ---------------------------------Quarter 2  ---------------------------------

kelp_2 <- read_csv(file.path(data_dir, "03-analysis-data/04-maxent-analysis/quarter-2/kelp-presence-2.csv")) %>% 
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# Read in the maxent output
maxent_quarter_2 <- raster(file.path(data_dir, "03-analysis-data/04-maxent-analysis/results/maxent-quarter-2-output.tif"))

# ---------------------------------Quarter 3  ---------------------------------

kelp_3 <- read_csv(file.path(data_dir, "03-analysis-data/04-maxent-analysis/quarter-3/kelp-presence-3.csv")) %>% 
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# Read in the maxent output
maxent_quarter_3 <- raster(file.path(data_dir, "03-analysis-data/04-maxent-analysis/results/maxent-quarter-3-output.tif"))

# ---------------------------------Quarter 4  ---------------------------------

read_csv(file.path(data_dir, "03-analysis-data/04-maxent-analysis/quarter-4/kelp-presence-4.csv")) %>% 
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# Read in the maxent output
maxent_quarter_4 <- raster(file.path(data_dir, "03-analysis-data/04-maxent-analysis/results/maxent-quarter-4-output.tif"))

maxent_tm <- tm_shape(maxent_quarter_1) +
  tm_raster(title = "Predicted habitat suitability (0.0-1.0)", 
            alpha = 1.0, 
            palette = maxent_pal) + 
  
  tm_shape(maxent_quarter_2) +
  tm_raster(title = "Predicted habitat suitability (0.0-1.0)", 
            alpha = 1.0, 
            palette = maxent_pal) +
  
  tm_shape(maxent_quarter_3) +
  tm_raster(title = "Predicted habitat suitability (0.0-1.0)", 
            alpha = 1.0, 
            palette = maxent_pal) +
  
  tm_shape(maxent_quarter_4) +
  tm_raster(title = "Predicted habitat suitability (0.0-1.0)", 
            alpha = 1.0, 
            palette = maxent_pal) +
  
  tm_shape(counties) +
  tm_polygons() +
  
  tm_shape(aoi, bbox = bbox) +
  tm_borders(lwd = 2, col = dark_blue)

# Convert to leaflet to manipulate default layers
maxent_tm <- maxent_tm %>% 
  tmap_leaflet() %>%
  leaflet::hideGroup("maxent_quarter_2") %>% 
  hideGroup("maxent_quarter_3") %>%  
  hideGroup("maxent_quarter_4") 

# Prep data
# Reclassify values <0.4 to NA for each quarter and mask out areas with kelp
rcl_1 <- maxent_quarter_1 %>% 
  reclassify(cbind(0, 0.4, NA), right=FALSE) %>% 
  mask(mask = kelp_quarter1, inverse = TRUE)
rcl_2 <- maxent_quarter_2 %>% 
  reclassify(cbind(0, 0.4, NA), right=FALSE) %>% 
  mask(mask = kelp_quarter2, inverse = TRUE)
rcl_3 <- maxent_quarter_3 %>%  
  reclassify(cbind(0, 0.4, NA), right=FALSE) %>% 
  mask(mask = kelp_quarter3, inverse = TRUE)
rcl_4 <- maxent_quarter_4 %>%  
  reclassify(cbind(0, 0.4, NA), right=FALSE) %>% 
  mask(mask = kelp_quarter4, inverse = TRUE)

good_cells_stack <- stack(rcl_1, rcl_2, rcl_3, rcl_4) #stack


# Mask to areas that meet a minimum of 0.4 for all quarters
# Create an empty raster with the same extent and resolution as the input rasters
maxent_mask <- raster(good_cells_stack[[1]])
values(maxent_mask) <- 1  # Set all cells in the mask raster to a common value

# Iterate over each raster and update the mask raster where they overlap
for (i in 2:4) {
  maxent_mask <- maxent_mask * (good_cells_stack[[i]] > 0)  # Update the mask where raster values are non-zero
}

# Mask rcl_1
masked_rcl_1 <- mask(rcl_1, maxent_mask)

# Mask rcl_2
masked_rcl_2 <- mask(rcl_2, maxent_mask)

# Mask rcl_3
masked_rcl_3 <- mask(rcl_3, maxent_mask)

# Mask rcl_4
masked_rcl_4 <- mask(rcl_4, maxent_mask)


# Take the mean value of all four quarters
mean_masked_maxent <- mean(masked_rcl_1, masked_rcl_2, masked_rcl_3, masked_rcl_4)


# Mask to sandy-bottom areas
# Read in sandy-bottom raster
sandy_raster <- raster(file.path(data_dir, "03-analysis-data/05-substrate-analysis/sandy-bottom-1km.tif"))

# Mask maxent to areas without sandy-bottom
sub_masked_model <- mask(x = mean_masked_maxent, mask = sandy_raster, inverse = FALSE)

masked_tm <- tm_shape(sub_masked_model) +
  tm_raster(title = "Mean predicted habitat suitability (0.0-1.0)", 
            alpha = 1.0, 
            palette = maxent_pal) + 
  
  tm_shape(counties) +
  tm_polygons() +
  
  
  tm_shape(aoi, bbox = bbox) +
  tm_borders(lwd = 2, col = dark_blue)

masked_tm 
