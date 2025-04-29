#setwd("./vignettes")

processing_geospatial <- function(meters = NULL, city = ""){ #a tibble of the format described in markdown Geo_Data, set to NULL if you want to use default values

packages <- c('influxdbclient', 'ggplot2', 'tidyverse', 'lubridate', 'dplyr', 'caret',
              'vip', 'parsnip', 'workflows', 'tune', 'dials', 'stringr', 'terra', 'stars',
              'sf', 'plyr', 'doParallel', 'foreach', 'terrainr', 'starsExtra', 'pdp',
              'recipes', 'tidyterra', 'shiny', 'xgboost', 'kableExtra', 'rnaturalearth', 'zoo',
              'moments', 'tibble', 'rsample', 'yardstick', 'cowplot', 'purrr', 'renv',
              'ranger','Boruta','sp',"jsonlite","httr","scales","MODISTools")

# Load the R script to install and load all the packages from above
source("../R/load_packages.R")
load_packages(packages = packages)


if(is.null(meters)){

    meters_burger <- tibble(
     Category = c("Land Cover Building", "Open Space Sealed", "Open Space Forest", "Open Space Garden", "Open Space Water", "Open Space Agriculture"),
     Variable = c("LC_B", "OS_SE", "OS_FO", "OS_GA", "OS_WA", "OS_AC"),
     Chosen_buffer_radiusm = c(250, 500, 250, 25, 150, 500)
    )



    meters_new <- tibble(
      Category = c("Aspect", "Flow accumulation", "Roughness", "Slope", "Terrain index", "NDVI","DEM"),
      Variable = c("ASP", "FLAC", "ROU", "SLO", "TPI", "NDVI","DEM"),
      Chosen_buffer_radiusm = c(5, 125, 5, 5, 5, 250,5)
    )

    meters <- bind_rows(meters_burger, meters_new)
}

tiff_focal <- function(tiff,meter,filename){
  names(tiff) <- paste0(filename,"_",meter)
  if(grepl("NDVI", filename)){
    writeRaster(tiff, filename=paste0("../data/Tiffs/", city, "/",filename,"_250",".tif"),overwrite = T)
  }#cannot be downloaded with a resolution of less than 250 meters, so this is the basic case.

  else if(meter == 5){
    writeRaster(tiff, filename=paste0("../data/Tiffs/", city, "/",filename,"_5",".tif"),overwrite = T)
  }else{ #to ensure no focal is applied when none should

    n <-2*round(meter/(5*2))+1 #get unequal number, div by 5 since 5m resolution

    mean_focal <- terra::focal(tiff, w=matrix(1, nrow=n, ncol=n), fun=mean, na.rm=TRUE)
    names(mean_focal) <- paste0(filename,"_",meter)

    writeRaster(mean_focal, filename=paste0("../data/Tiffs/", city, "/",filename,"_",meter,".tif"),overwrite = T)
  }
}

# Combining the old and new entries


for (i in 1:nrow(meters)) {
  row <- dplyr::slice(meters, i)
  print(row)
  tiff_focal(tiff=terra::rast(paste0("../data-raw/", city, "/",row$Variable,".tif")),meter = row$Chosen_buffer_radiusm,filename = row$Variable)
}

}
