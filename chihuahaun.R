### Chihuahuan Desert

Let's now focus on the Chihuahuan Desert, one of the most diverse deserts in the world.

![This area is of interest because desert ecosystems are sensitive indicators of climate change due to the fact that even moderate changes in temperature and precipitation can have a large effect on ecosystem services and physical resources (Chihuahuan Desert Network I&M Program 2011). Here, you can inform your own analysis of changes in FPAR and LAI following the same steps for our analysis of the Lacandon Jungle.](desert_map.png)

First, set the region of interest as the Chihuahuan Desert:

```{python}
#| warning: false
# Create two regions of interest
POI_desert = ee.Geometry.Point(-106.506416, 31.767759) # point for Chihuahuan Desert
```

### FPAR Visualization of Chihuahuan Desert[¶](https://taylor.bren.ucsb.edu/s/577d721f2ed720cf76837/#FPAR-Visualization-of-Chihuahuan-Desert)

Create data frame to use for data visualization:

```{python}
#| warning: false
# Create data frame for FPAR variable in Chihuahuan Desert 
fparD = gdat.select('Fpar') # select FPAR band name/variable
fpar_tsD = fparD.getRegion(POI_desert, scale).getInfo() # extract data
df_fparD = pd.DataFrame(fpar_tsD).dropna() # save data frame

# Tidy data frame
headers_1 = df_fparD.loc[0] # extract headers
df_fparD = pd.DataFrame(df_fparD.values[1:], columns = headers_1) # add headers
print(df_fparD) # view data frame with headers

# Convert time to datetime
df_fparD['datetime'] = pd.to_datetime(df_fparD['time'], unit = 'ms')
```

Now, let's make a time series plot:
  
  ```{python}
#| warning: false
# Plot time series for FPAR variable in Chihuahuan Desert 
plt.figure(figsize = (10, 6), dpi = 300) # create figure; set size and resolution (dpi)
plt.plot(df_fparD['datetime'], df_fparD['Fpar']) # add data to plot
plt.title('Fraction of Photosynthetically Active Radiation in Chihuahuan Desert (FPAR), 2002 to 2022', fontsize = 14) # add title to plot
plt.xlabel('Year', fontsize = 12) # add x label to plot
plt.ylabel('FPAR (%)', fontsize = 12) # add y label to plot
```

And let's make a histogram plot:

```{python}
#| warning: false
# Plot histogram for FPAR variable in Chihuahuan Desert
fig, ax = plt.subplots(figsize = (10, 6), dpi = 300) # create figure; set size and resolution (dpi)
n, bins, patches = ax.hist(x = df_fparD['Fpar'], bins = 'auto') # add histogram to plot
plt.title('Fraction of Photosynthetically Active Radiation (FPAR) in Chihuahuan Desert, 2002 to 2022', fontsize = 14) # add title to plot
plt.xlabel('FPAR (%)', fontsize = 12) # add x label to plot
plt.ylabel('Count', fontsize = 12) # add y label to plot
ax.yaxis.set_minor_locator(AutoMinorLocator()) # set automatic tick selection for y-axis
ax.xaxis.set_minor_locator(AutoMinorLocator()) # set automatic tick selection for x-axis
ax.tick_params(which = 'major', length = 7) # set major ticks
ax.tick_params(which = 'minor', length = 4) # set minor ticks
```

From our time series and histogram we see that FPAR in the desert is on average much lower than the jungle. It is seemingly seasonal with some variablility. The range is smaller than in the jungle. The data have a small right tail but fairly well distributed.

### LAI Visualization of Chihuahuan Desert

Now, we repeat this same process for Leaf Area Index!

First, create data frame to use for data visualization:

```{python}
#| warning: false
# Create data frame for LAI variable in Chihuahuan Desert 
laiD = gdat.select('Lai') # select LAI band name/variable
lai_tsD = laiD.getRegion(POI_desert, scale).getInfo() # extract data
df_laiD = pd.DataFrame(lai_tsD).dropna() # save data frame

# Tidy data frame
headers_2 = df_laiD.loc[0] # extract headers
df_laiD = pd.DataFrame(df_laiD.values[1:], columns = headers_2) # add headers
print(df_laiD) # view data frame 

# Convert time to datetime
df_laiD['datetime'] = pd.to_datetime(df_laiD['time'], unit = 'ms')
```

Now, let's make a time series plot:
  
  ```{python}
#| warning: false
# Plot time series for LAI variable in Chihuahuan Desert 
plt.figure(figsize = (10, 6), dpi = 300) # create figure; set size and resolution (dpi)
plt.plot(df_laiD['datetime'], df_laiD['Lai']) # add data to plot
plt.title('Leaf Area Index in Chihuahuan Desert, 2002 to 2022', fontsize = 14) # add title to plot
plt.xlabel('Year', fontsize = 12) # add x label to plot
plt.ylabel('Leaf Area Index (m²/m²)', fontsize = 12) # add y label to plot
```

And let's make a histogram plot:

```{python}
#| warning: false
# Plot histogram for LAI variable in Chihuahuan Desert 
fig, ax = plt.subplots(figsize = (10, 6), dpi = 300) # create figure; set size and resolution (dpi)
n, bins, patches = ax.hist(x = df_laiD['Lai'], bins = 'auto') # add histogram to plot
plt.title('Leaf Area Index in Chihuahuan Desert, 2002 to 2022', fontsize = 14) # add title to plot
plt.xlabel('Leaf Area Index (m²/m²)', fontsize = 12) # add x-axis to plot
plt.ylabel('Count', fontsize = 12) # add y label to plot
ax.yaxis.set_minor_locator(AutoMinorLocator()) # set automatic tick selection for y-axis
ax.xaxis.set_minor_locator(AutoMinorLocator()) # set automatic tick selection for x-axis
ax.tick_params(which = 'major', length = 7) # set major ticks
ax.tick_params(which = 'minor', length = 4) # set minor ticks
```

From our time series and histogram we see that LAI in the desert is on average much lower than the jungle. It is seemingly seasonal with less variablility. The range is much smaller than in the jungle.

### Use Case Example: FPAR in Chihuahuan Desert

```{python}
#| warning: false
# Select FPAR band name/variable
gee1 = gdat.filter(ee.Filter.date('2010-11-01', '2012-11-01')).select('Fpar').mean() # select for time period of interest 1
gee2 = gdat.filter(ee.Filter.date('2020-11-01', '2022-11-01')).select('Fpar').mean() # select for time period of interest 2

# Create basemap with spatial parameters for Chihuahuan Desert
Map = geemap.Map(center = [31.767759, -106.506416], zoom = 9)

# Define palette
palette = ['#fffff9', '#d7eba8', '#addd8e',
'#78c679', '#41ab5d', '#238443', '#005a32']

# Define visual parameters
visParams = {'bands': ['Fpar'], # select band/variable
  'min': 0, # set minimum parameter
  'max': 100, # set maximum parameter
  'palette': palette} # set palette

# Define color bar
colors = visParams['palette'] # set colors from visual parameters
vmin = visParams['min'] # set minimum from visual parameters
vmax = visParams['max'] # set maximum from visual parameters

# Add layer for time period of interest 1 to the left tile
left  = geemap.ee_tile_layer(gee1, visParams, 'Mean FPAR (%) in Chihuahuan Desert from 2010 to 2012')

# Add layer for time period of interest 2 to the right tile
right = geemap.ee_tile_layer(gee2, visParams, 'Mean FPAR (%) in Chihuahuan Desert from 2020 to 2022')

# Add tiles to the map
Map.split_map(left, right)

# Add color bar
Map.add_colorbar_branca(colors = colors, 
                        vmin = vmin, 
                        vmax = vmax)
Map # view map
```

### Use Case Example: LAI in Chihuahuan Desert

Again, we now repeat this same process for Leaf Area Index!
  
  ```{python}
#| warning: false
# Select LAI band name/variable
gee3 = gdat.filter(ee.Filter.date('2010-11-01', '2012-11-01')).select('Lai').mean() # select for time period of interest 1
gee4 = gdat.filter(ee.Filter.date('2020-11-01', '2022-11-01')).select('Lai').mean() # select for time period of interest 2

# Create basemap with spatial parameters for Chihuahuan Desert
Map2 = geemap.Map(center = [31.767759, -106.506416], zoom = 9)

# Define palette
palette = ['#fffff9', '#d7eba8', '#addd8e',
                    '#78c679', '#41ab5d', '#238443', '#005a32'] # can just use the same one as for the first map, no need to rewrite this if you did
                    
# Define visual parameters
visParams2 = {'bands': ['Lai'], # select band/variable
  'min': 0, # set minimum parameter
  'max': 100, # set maximum parameter
  'palette': palette} # set palette

# Define color bar
colors2 = visParams2['palette'] # set colors from visual parameters
vmin2 = visParams2['min'] # set minimum from visual parameters
vmax2 = visParams2['max'] # set maximum from visual parameters

# Add layer for time period of interest 1 to the left tile
left2 = geemap.ee_tile_layer(gee3, visParams2, 'Mean LAI (m²/m²) in Chihuahuan Desert from 2010 to 2012')

# Add layer for time period of interest 2 to the right tile
right2 = geemap.ee_tile_layer(gee4, visParams2, 'Mean LAI (m²/m²) in Chihuahuan Desert from 2020 to 2022')

# Add tiles to the map
Map2.split_map(left2, right2)

# Add color bar
Map2.add_colorbar_branca(colors = colors2, 
                         vmin = vmin2, 
                         vmax = vmax2)
Map2 # view map
```