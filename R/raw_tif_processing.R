library(terra)

options(timeout=2000)
download.file("https://geofiles.be.ch/geoportal/pub/download/MOPUBE/MOPUBE.zip",destfile = "./data-raw/mopu.zip")


unzip("./data-raw/mopu.zip",exdir = "./data-raw/mopu")



# https://geofiles.be.ch/geoportal/pub/download/GEBHOEHE/GEBHOEHE.zip


#Todo:
#1. cut and make raster
#2. convert calsses/aggregate
#3. buffer -> done


library(sf)
library(stars)
library(dplyr)
library(terra)
# Read in the shapefile
shapefile <- st_read("./data-raw/mopu/data/MOPUBE_BBF.shp")

# Define the extent you want to cut to
# Replace these values with your desired extent (xmin, xmax, ymin, ymax)
extent_to_cut <- st_bbox(c(xmin = 2594313, xmax = 2605813, ymin = 1194069, ymax = 1204804), crs = st_crs(shapefile))

# Cut the shapefile to the specified extent
shapefile_cropped <- st_crop(shapefile, extent_to_cut)



st_rasterize(shapefile_cropped,file = "./data-raw/mopu/data/MOPUBE_BBF.tif",dx = 5, dy = 5) #resolution of 5 meters

raster <- terra::rast("./data-raw/mopu/data/MOPUBE_BBF.tif")
raster <- raster[[1]]

land_classes <- dplyr::tibble(Art = shapefile$ART, Bez = shapefile$BBARTT_BEZ)
land_classes <- land_classes |> group_by(Art,Bez) |>
  summarise()


raster %in% c(0,1,2)*1 #works!: all with 0,1,2 get a 1 else 0

