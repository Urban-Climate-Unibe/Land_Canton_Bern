


meteoswiss <- c(22,0,0,0,0,30,27,23,21,20,0,0,0,0,0)

meteoswiss_selection <- paste(c("temp","precip","rad","wind","rain"), collapse = "|")
names(meteoswiss) <- combined |>
  dplyr::select(matches(meteoswiss_selection),
                -temperature) |>
  colnames()
# Goes:""temp"                       "rad"                        "winds"                      "windd"                      "mean_temp_6_hours"    "mean_temp_12_hours"         "mean_temp_1_day"            "mean_temp_3_days"           "mean_temp_5_days"           "sum_precipitation_6_hours" "sum_precipitation_12_hours" "sum_precipitation_1_day"    "sum_precipitation_3_days"   "sum_precipitation_5_days"



tiffs<-tiffs_only


for (name_var in names(meteoswiss)) {
  temp <- terra::rast(ncol=293, nrow=247, xmin=2592670, xmax=2607320, ymin=1193202, ymax=1205552,names = name_var)
  terra::values(temp) <- unname(meteoswiss[name_var])
  print(unname(meteoswiss[name_var]))
  temp <- crop(temp,tiffs)
  temp <- resample(temp,tiffs)
  tiffs <- c(tiffs,temp)


}







temperature <- terra::predict(tiffs,random_forest_model,na.rm = T)


extent <- rgdal::readOGR("../data/Map/Extent_Bern.shp")
rivers <- rgdal::readOGR("../data/Map/Aare.shp")
color = colorRampPalette(c("blue","deepskyblue", "white","orange", "red"))(100)
terra::plot(temperature,color = color)
sp::plot(extent, add = T)
sp::plot(rivers, add = T)
points( 2601930.3,1204410.1 , pch = 16, cex = 1)
