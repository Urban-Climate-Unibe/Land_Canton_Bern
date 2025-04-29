
download_geospatial <- function(extent= c(xmin = 2594313, xmax = 2605813, ymin = 1194069, ymax = 1204804), city = "Bern"){#default is Bern as in Burger et al.2019

packages <- c('influxdbclient', 'ggplot2', 'tidyverse', 'lubridate', 'dplyr', 'caret',
              'vip', 'parsnip', 'workflows', 'tune', 'dials', 'stringr', 'terra', 'stars',
              'sf', 'plyr', 'doParallel', 'foreach', 'terrainr', 'starsExtra', 'pdp',
              'recipes', 'tidyterra', 'shiny', 'xgboost', 'kableExtra', 'rnaturalearth', 'zoo',
              'moments', 'tibble', 'rsample', 'yardstick', 'cowplot', 'purrr', 'renv',
              'ranger','Boruta','sp',"jsonlite","httr","scales","MODISTools", "gdalUtilities", "utils")

# Load the R script to install and load all the packages from above
source("../R/load_packages.R")
load_packages(packages = packages)



# Land use data of canton Bern (MOPUBE) ----------------------------------------

options(timeout=4000) #to allaw large downloads
download.file("https://geofiles.be.ch/geoportal/pub/download/MOPUBE/MOPUBE.zip",destfile = paste0(tempdir(),"mopu.zip"))

#unzip
unzip(paste0(tempdir(),"mopu.zip"),exdir = paste0(tempdir(),"mopu"))


# Read in the shapefile MOPUBE
shapefile <- st_read(paste0(tempdir(),"mopu/data/MOPUBE_BBF.shp"))
shapefile <- st_make_valid(shapefile)
# Define the extent to cut

extent_to_cut <- st_bbox(extent, crs = st_crs(shapefile))

#crop the shapefile to the specified extent
shapefile_cropped <- st_crop(shapefile, extent_to_cut)

# Save shapefile
# TODO

#rasterize the shapefile
st_rasterize(shapefile_cropped,file = paste0(tempdir(),"mopu/data/MOPUBE_BBF.tif"),dx = 5, dy = 5) #resolution of 5 meters

#rast the now raster file in terra
raster <- terra::rast(paste0(tempdir(),"mopu/data/MOPUBE_BBF.tif"))
raster <- raster[[1]]


#define classification by Burger et al.2019 for LU-classes in MPOU
classification <- tibble(
  Number_raw_data = 0:25,
  Description_raw_data = c(
    "Gebäude", "Strasse Weg", "Trottoir", "Verkehrsinsel", "Bahn", "Flugplatz", "Wasserbecken",
    "Übrige befestigte", "Acker Wiese Weide", "Reben", "Übrige Intensivkulturen", "Gartenanlage",
    "Hoch- Flachmoor", "Übrige humusierte", "Stehendes Gewässer", "Fliessenden Gewässer",
    "Schilfgürtel", "Geschlossener Wald", "Wytweide dicht", "Wytweide offen", "Übrige bestockte",
    "Fels", "Gletscher Firn", "Geröll Sand", "Abbau Deponie", "Übrige Vegetationslose"
  ),
  Reclassified_category = c(
    "Land Cover Building", "Open Space Sealed", "Open Space Sealed", "Open Space Sealed",
    "Open Space Sealed", "Open Space Sealed", "Open Space Water", "Open Space Sealed",
    "Open Space Agriculture", "Open Space Agriculture", "Open Space Agriculture", "Open Space Garden",
    "Did not appear", "Open Space Agriculture", "Open Space Water", "Open Space Water",
    "Open Space Water", "Open Space Forest", "Did not appear", "Did not appear", "Open Space Forest",
    "Open Space Sealed", "Did not appear", "Open Space Sealed", "Open Space Sealed", "Open Space Sealed"
  )
) |> tidyr::drop_na()

#define the meters according to Burger et al.
meters <- tibble(
  Reclassified_category = c("Land Cover Building", "Open Space Sealed", "Open Space Forest", "Open Space Garden", "Open Space Water", "Open Space Agriculture"),
  Variable = c("LC_B", "OS_SE", "OS_FO", "OS_GA", "OS_WA", "OS_AC"),
  # Abbreviation = rep("25/50/150/250/500", 6),
  # Buffer_radii_tested = rep("25/50/150/250/500", 6), # Buffer radii are calculated in other script
  Unit = rep("%", 6),
  # Chosen_buffer_radiusm = c(250, 500, 250, 25, 150, 500)
)
#combined to one dataframe
classification <- inner_join(classification,meters, by = "Reclassified_category")


#write rasters according to LU-class in data-raw
for (class in unique(classification$Variable)) {
  number_classes <- classification |>
    filter(Variable == class) |>
    dplyr::select(Number_raw_data) |>
    unlist() #numbers of raster value that corresponds to class
  print(class)
  print(number_classes)
  temp_raster <- raster %in% number_classes*1

  dir.create(paste0("../data-raw/", city), showWarnings = FALSE)
  terra::writeRaster(temp_raster,paste0("../data-raw/", city, "/",class,".tif"),overwrite = T)
}



# DEM --------------------------------------------------------------------------

#for download, making all possible combinations of coordinates
file_data <- expand.grid(x = round(extent[1]/1000):round(extent[2]/1000),y = round(extent[3]/1000):round(extent[4]/1000))

file_data <- paste0("https://data.geo.admin.ch/ch.swisstopo.swissalti3d/swissalti3d_2019_",file_data$x,"-",file_data$y,"/swissalti3d_2019_",file_data$x,"-",file_data$y,"_2_2056_5728.tif")
download_files <- function(url, destination_folder) {
  # Extract the file name from the URL
  file_name <- basename(url)

  # Create the destination file path
  destination_path <- file.path(destination_folder, file_name)

  # Download the file
  download.file(url, destfile = destination_path, mode = "wb")
}

# Folder where to save
output_folder <- paste0(tempdir(),"/DEM")

# Create the output folder if it doesn't exist
dir.create(output_folder, showWarnings = FALSE)

# Loop through each link and download the file
for (link in file_data) {
  download_files(link, output_folder)
}

# Get list of downloaded DEM files
DEM_paths <- list.files(output_folder, full.names = TRUE)
# Read all rasters into a SpatRaster list
rasters <- lapply(DEM_paths, terra::rast)
# Merge all rasters
merged_raster <- do.call(terra::merge, rasters)
terra::writeRaster(merged_raster, filename = file.path(output_folder, "DEM.tif"), overwrite = TRUE, filetype = "GTiff", gdal = "BIGTIFF=YES")


DEM <- terra::rast(paste0(tempdir(),"/DEM/DEM.tif"))

ex <- terra::rast(paste0("../data-raw/", city, "/OS_AC.tif")) #not very elegant, maybe improve?

DEM <- terra::resample(DEM,ex)

terra::writeRaster(DEM, filename = paste0("../data-raw/", city, "/DEM.tif"), overwrite = TRUE)


# NDVI -------------------------------------------------------------------------

lv95_point <- st_sfc(st_point(c(mean(extent[1]:extent[2]),mean(extent[3]:extent[4]))), crs = 2056)
middle_modis <- st_coordinates(st_transform(lv95_point, crs = 4326))

extent_modis_lr <- round(length(extent[1]:extent[2])/1000)+2
extent_modis_ab <- round(length(extent[1]:extent[2])/1000)+2

NDVI <- MODISTools::mt_subset(
  product = "MOD13Q1",
  lat = middle_modis[2],
  lon = middle_modis[1],
  band = "250m_16_days_NDVI",
  start = "2020-07-15",
  end = "2020-08-01",
  km_lr = extent_modis_lr/2+5,
  km_ab = extent_modis_ab/2+5,
  internal = T,
  progress = T
)

NDVI_raster <- MODISTools::mt_to_terra(
  NDVI,
  reproject = TRUE
)
NDVI_raster <- terra::project(NDVI_raster,ex)
NDVI_raster  <- terra::resample(NDVI_raster,ex)
terra::writeRaster(NDVI_raster, paste0("../data-raw/", city, "/NDVI.tif"), overwrite = TRUE)



# Calculate CAD variables from DEM ---------------------------------------------
slope <- terra::terrain(DEM,v = "slope")
slope <- terra::resample(slope,ex)
terra::writeRaster(slope, paste0("../data-raw/", city, "/SLO.tif"), overwrite = TRUE)

aspect <- terra::terrain(DEM,v = "aspect")
aspect <- terra::resample(aspect,ex)
terra::writeRaster(aspect, paste0("../data-raw/", city, "/ASP.tif"), overwrite = TRUE)

flowacc <- terra::terrain(DEM,v = "flowdir")
flowacc <- terra::resample(flowacc,ex)
terra::writeRaster(flowacc, paste0("../data-raw/", city, "/FLAC.tif"), overwrite = TRUE)

roughness <- terra::terrain(DEM,v = "roughness")
roughness <- terra::resample(roughness,ex)
terra::writeRaster(roughness, paste0("../data-raw/", city, "/ROU.tif"), overwrite = TRUE)

TPI <- terra::terrain(DEM,v = "TPI")
TPI <- terra::resample(TPI,ex)
terra::writeRaster(TPI, paste0("../data-raw/", city, "/TPI.tif"), overwrite = TRUE)



# Building Height BH -----------------------------------------------------------

download.file("https://geofiles.be.ch/geoportal/pub/download/GEBHOEHE/GEBHOEHE.zip",
              destfile = paste0(tempdir(), "GEBHOEHE.zip"))

unzip(paste0(tempdir(), "GEBHOEHE.zip"), exdir = paste0(tempdir(), "/GEBHOEH"))

# Read in the shapefile
building_height <- st_read(paste0(tempdir(), "/GEBHOEH/GEBHOEHE/data/GEBHOEHE_GEBHOEHE.shp"))

# Crop the vector layer to the extent
BH_vect <- st_crop(building_height, ex)

# save the shpefile
terra::writeVector(BH_vect, paste0("../data-raw/", city, "/BH.shp"), overwrite = TRUE)

# Convert to raster (match resolution and extent of VH_rast)
BH_rast <- terra::rasterize(
  vect(BH_vect),
  ex,                     # Use vegetation raster as template
  field = "GEBHOEHE",          # Column with building height
  fun = "mean"                 # Average height if multiple features overlap
)

BH_rast <- terra::project(BH_rast,ex)
BH_rast <- terra::resample(BH_rast,ex)

writeRaster(BH_rast, paste0("../data-raw/", city, "/BH_NA.tif"), overwrite = TRUE)



# Vegetation Height VH -----------------------------------------------------------

# Convert extent vector to a bbox string for gdalwarp
bbox <- c(extent["xmin"], extent["ymin"], extent["xmax"], extent["ymax"])

# Crop directly from the remote URL using gdalwarp
gdalwarp(
  srcfile = "/vsicurl/https://s3.eu-west-1.amazonaws.com/data.geo.admin.ch/ch.bafu.landesforstinventar-vegetationshoehenmodell/Vegetationshoehenmodell_2021_1m_2056.tif",
  dstfile = paste0(tempdir(), "VH.tif"),
  te = bbox,  # Bounding box: xmin, ymin, xmax, ymax
  tr = c(1, 1),  # 1-meter resolution
  t_srs = "EPSG:2056",  # Target projection
  overwrite = TRUE
)

# Load the cropped raster
VH_rast <- terra::rast(paste0(tempdir(), "VH.tif"))
VH_rast <- terra::project(VH_rast,ex)
# save the raster in 1m resolution
terra:writeRaster(VH_rast, paste0("../data-raw/", city, "/VH_1m.tif"), overwrite = TRUE)
# Resample to match the resolution of the other rasters (5m)
VH_rast <- terra::resample(VH_rast,ex)
terra::writeRaster(VH_rast, paste0("../data-raw/", city, "/VH.tif"), overwrite = TRUE)

}
