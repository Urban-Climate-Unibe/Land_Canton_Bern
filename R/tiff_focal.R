library(raster)
library(stringr)


files <- list.files("./data-raw/")

for (file in files) {


raster_data <- raster(paste("./data-raw/",file,sep = ""))

raster_data <- reclassify(raster_data, cbind(NA, 0))

for (x in c(5,11,21,51,101,201)) {
  mean_focal <- focal(raster_data, w=matrix(1, nrow=x, ncol=x), fun=mean, na.rm=TRUE)
  filename1 = paste("./data/Tiffs/",str_sub(file, end = -5),"_",x,".tif",sep = "")
  print(filename1)
  writeRaster(mean_focal, filename=filename1, format="GTiff")
    }
}
