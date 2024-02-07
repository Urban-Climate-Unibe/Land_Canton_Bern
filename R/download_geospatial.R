#setwd("./vignettes")

download_geospatial <- function(extent= c(xmin = 2594313, xmax = 2605813, ymin = 1194069, ymax = 1204804)){#default is Bern as in Burger et al.2019

packages <- c('influxdbclient', 'ggplot2', 'tidyverse', 'lubridate', 'dplyr', 'caret',
              'vip', 'parsnip', 'workflows', 'tune', 'dials', 'stringr', 'terra', 'stars',
              'sf', 'plyr', 'doParallel', 'foreach', 'terrainr', 'starsExtra', 'pdp',
              'recipes', 'tidyterra', 'shiny', 'xgboost', 'kableExtra', 'rnaturalearth', 'zoo',
              'moments', 'tibble', 'rsample', 'yardstick', 'cowplot', 'purrr', 'renv',
              'ranger','Boruta','sp',"jsonlite","httr","scales","MODISTools")

# Load the R script to install and load all the packages from above
source("../R/load_packages.R")
load_packages(packages = packages)








library(dplyr)#sf, modistools

options(timeout=4000) #to allaw large downloads
download.file("https://geofiles.be.ch/geoportal/pub/download/MOPUBE/MOPUBE.zip",destfile = paste0(tempdir(),"mopu.zip"))

#unzip
unzip(paste0(tempdir(),"mopu.zip"),exdir = paste0(tempdir(),"mopu"))



# Read in the shapefile MPOU
shapefile <- st_read(paste0(tempdir(),"mopu/data/MOPUBE_BBF.shp"))
shapefile <- st_make_valid(shapefile)
# Define the extent to cut

extent_to_cut <- st_bbox(extent, crs = st_crs(shapefile))

#crop the shapefile to the specified extent
shapefile_cropped <- st_crop(shapefile, extent_to_cut)


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
  Abbreviation = rep("25/50/150/250/500", 6),
  Buffer_radii_tested = rep("25/50/150/250/500", 6),
  Unit = rep("%", 6),
  Chosen_buffer_radiusm = c(250, 500, 250, 25, 150, 500)
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


  terra::writeRaster(temp_raster,paste0("../data-raw/",class,".tif"),overwrite = T)

}


#Now BH

download.file("https://geofiles.be.ch/geoportal/pub/download/GEBHOEHE/GEBHOEHE.zip",destfile = paste0(tempdir(),"GEBHOEHE.zip"))
unzip(paste0(tempdir(),"GEBHOEHE.zip"),exdir = paste0(tempdir(),"/GEBHOEH"))

# Read in the shapefile

shapefile <- st_read(paste0(tempdir(),"/GEBHOEH/GEBHOEHE/data/GEBHOEHE_GEBHOEHE.shp"))
shapefile <- st_make_valid(shapefile)
# Define the extent, same as before



# Cut the shapefile to the specified extent
shapefile_cropped <- st_crop(shapefile, extent_to_cut)


#now we rasterize the shapefile
st_rasterize(shapefile_cropped,file = paste0(tempdir(),"/GEBHOEH/GEBHOEHE/data/GEBHOEHE_GEBHOEHE.shp"),dx = 5, dy = 5) #resolution of 5 meters
#read in as raster in terra
raster_BH <- terra::rast(paste0(tempdir(),"/GEBHOEH/GEBHOEHE/data/GEBHOEHE_GEBHOEHE.shp"))
raster_BH <- raster_BH[[2]]
terra::writeRaster(raster_BH,paste0("../data-raw/BH_NA.tif"),overwrite = T)

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


DEM_paths <- paste0(paste0(tempdir(),"/DEM/"),list.files(paste0(tempdir(),"/DEM")))

terrainr::merge_rasters(DEM_paths,output_raster = paste0(tempdir(),"/DEM/DEM.tif"),options = "BIGTIFF=YES",overwrite = TRUE)


DEM <- terra::rast(paste0(tempdir(),"/DEM/DEM.tif"))
ex <- terra::rast("../data-raw/OS_AC.tif") #not very elegant, maybe improve?

DEM <- terra::resample(DEM,ex)

terra::writeRaster(DEM, filename = "../data-raw/DEM.tif",overwrite = T)

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
terra::writeRaster(NDVI_raster,"../data-raw//NDVI.tif")


slope <- terra::terrain(DEM,v = "slope")

slope <- terra::resample(slope,ex)
terra::writeRaster(slope,"../data-raw/SLO.tif")

aspect <- terra::terrain(DEM,v = "aspect")
aspect <- terra::resample(aspect,ex)

terra::writeRaster(aspect,"../data-raw/ASP.tif")

flowacc <- terra::terrain(DEM,v = "flowdir")
flowacc <- terra::resample(flowacc,ex)

terra::writeRaster(flowacc,"../data-raw/FLAC.tif")

roughness <- terra::terrain(DEM,v = "roughness")
roughness <- terra::resample(roughness,ex)
terra::writeRaster(roughness,"../data-raw/ROU.tif")

TPI <- terra::terrain(DEM,v = "TPI")
TPI <- terra::resample(TPI,ex)
terra::writeRaster(TPI,"../data-raw/TPI.tif")

}
