
options(timeout=4000)
download.file("https://geofiles.be.ch/geoportal/pub/download/MOPUBE/MOPUBE.zip",destfile = paste0(tempdir(),"mopu.zip"))


unzip(paste0(tempdir(),"mopu.zip"),exdir = paste0(tempdir(),"mopu"))






#Todo:

#DEM
#slope
#svf
#VH

library(dplyr)

# Read in the shapefile
shapefile <- st_read(paste0(tempdir(),"mopu/data/MOPUBE_BBF.shp"))

# Define the extent you want to cut to
# Replace these values with your desired extent (xmin, xmax, ymin, ymax)
extent_to_cut <- st_bbox(c(xmin = 2594313, xmax = 2605813, ymin = 1194069, ymax = 1204804), crs = st_crs(shapefile))

# Cut the shapefile to the specified extent
shapefile_cropped <- st_crop(shapefile, extent_to_cut)



st_rasterize(shapefile_cropped,file = paste0(tempdir(),"mopu/data/MOPUBE_BBF.tif"),dx = 5, dy = 5) #resolution of 5 meters

raster <- terra::rast(paste0(tempdir(),"mopu/data/MOPUBE_BBF.tif"))
raster <- raster[[1]]







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
    "Open Space Sealed", "Did not appear", "Open Space Sealed", "Open Space Sealed", NA
  )
) |> tidyr::drop_na()

meters <- tibble(
  Reclassified_category = c("Land Cover Building", "Open Space Sealed", "Open Space Forest", "Open Space Garden", "Open Space Water", "Open Space Agriculture"),
  Variable = c("LC_B", "OS_SE", "OS_FO", "OS_GA", "OS_WA", "OS_AC"),
  Abbreviation = rep("25/50/150/250/500", 6),
  Buffer_radii_tested = rep("25/50/150/250/500", 6),
  Unit = rep("%", 6),
  Chosen_buffer_radiusm = c(250, 500, 250, 25, 150, 500)
)
classification <- inner_join(classification,meters, by = "Reclassified_category")


for (class in unique(classification$Reclassified_category)) {
number_classes <- classification |>
    filter(Reclassified_category == class) |>
    dplyr::select(Number_raw_data) |>
  unlist()
print(class)
print(number_classes)
temp_raster <- raster %in% number_classes*1
name <- classification |>
  dplyr::filter(Reclassified_category == class) |>
  dplyr::select(Variable) |>
  unlist() |>
  unique()

terra::writeRaster(temp_raster,paste0("../data-raw/",name,".tif"),overwrite = T)

}








source("../R/tiff_focal.R")


files <- list.files("../data-raw/")

for (file in files) {


  raster_data <- rast(paste("../data-raw/",file,sep = ""))

  print(file)
  print(str_sub(file,end = -5))
  meter <- classification |>
    filter(Variable == str_sub(file,end = -5)) |>
    dplyr::select(Chosen_buffer_radiusm) |>
    unlist() |>
    unique() |>
    as.numeric()
print(meter)
  tiff_focal(raster_data,meter,file)

}

#Now BH

download.file("https://geofiles.be.ch/geoportal/pub/download/GEBHOEHE/GEBHOEHE.zip",destfile = paste0(tempdir(),"GEBHOEHE.zip"))
unzip(paste0(tempdir(),"GEBHOEHE.zip"),exdir = paste0(tempdir(),"/GEBHOEH"))

# Read in the shapefile
shapefile <- st_read(paste0(tempdir(),"/GEBHOEH/GEBHOEHE/data/GEBHOEHE_GEBHOEHE.shp"))

# Define the extent you want to cut to
# Replace these values with your desired extent (xmin, xmax, ymin, ymax)
extent_to_cut <- st_bbox(c(xmin = 2594313, xmax = 2605813, ymin = 1194069, ymax = 1204804), crs = st_crs(shapefile))

# Cut the shapefile to the specified extent
shapefile_cropped <- st_crop(shapefile, extent_to_cut)



st_rasterize(shapefile_cropped,file = paste0(tempdir(),"/GEBHOEH/GEBHOEHE/data/GEBHOEHE_GEBHOEHE.shp"),dx = 5, dy = 5) #resolution of 5 meters

raster <- terra::rast(paste0(tempdir(),"/GEBHOEH/GEBHOEHE/data/GEBHOEHE_GEBHOEHE.shp"))
raster <- raster[[2]]

tiff_focal(tiff = raster,150,"BH_NA.tif")

raster <- terra::rast("../data/Tiffs/BH_NA_150.tif")
subst(raster, NA, 0)
writeRaster(raster, filename="../data/Tiffs/BH_150.tif",overwrite = T)
file.remove("../data/Tiffs/BH_NA_150.tif")





#DEM



