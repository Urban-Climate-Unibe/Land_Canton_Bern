tiff_focal <- function(tiff_path,meter){

library(stringr)





  n <-2 * round(meter/2)/5+1 #get unequal number, div by 5 since 5m resolution
print(n)
  mean_focal <- focal(raster_data, w=matrix(1, nrow=n, ncol=n), fun=mean, na.rm=TRUE)
  filename1 = paste("../data/Tiffs/",str_sub(file, end = -5),"_",meter,".tif",sep = "")
  print(filename1)
  writeRaster(mean_focal, filename=filename1,overwrite = T)




}








