tiff_names <- str_sub(list.files("./data/Tiffs/"),end = -5)


tiffs_only <- terra::rast(paste0("./data/Tiffs/",tiff_names,".tif"))

meteoswiss <- c(22, 0, 0, 0, 0, 30, 27, 23, 21, 20, 0, 0, 0, 0, 0, 0)

meteoswiss_selection <- paste(c("temp","precip","rad","wind","rain"), collapse = "|")
names(meteoswiss) <- combined |>
  dplyr::select(matches(meteoswiss_selection),
                -c(temperature)) |>
  colnames()

# Goes:""temp" "rad" "winds" "windd" "mean_temp_6_hours" "mean_temp_12_hours" "mean_temp_1_day"
# "mean_temp_3_days" "mean_temp_5_days" "sum_precipitation_6_hours" "sum_precipitation_12_hours"
# "sum_precipitation_1_day" "sum_precipitation_3_days" "sum_precipitation_5_days" "sum_precipitation_10_days"


for (name_var in names(meteoswiss)) {
  temp <- terra::rast(ncol=293, nrow=247, xmin=2592670, xmax=2607320, ymin=1193202, ymax=1205552,names = name_var)
  terra::values(temp) <- unname(meteoswiss[name_var])
  print(unname(meteoswiss[name_var]))
  temp <- crop(temp,tiffs_only)
  temp <- resample(temp,tiffs_only)
  tiffs_only <- c(tiffs_only,temp)
}


temperature <- terra::predict(tiffs_only, random_forest_model, na.rm = T)
temperature_range <- range(values(temperature), na.rm = TRUE)
mylevs <- max(max(temperature_range),abs(min(temperature_range)))*(c(0:16)-8)/8
color_breaks <- c(seq(temperature_range[1], temperature_range[2], length.out = 5), seq(0, temperature_range[2], length.out = 5))
my_palette <- colorRampPalette(c("blue", "white", "red"))

extent <- rgdal::readOGR("./data/Map/Extent_Bern.shp")
rivers <- rgdal::readOGR("./data/Map/Aare.shp")

spplot(temperature, col.regions = my_palette, at = color_breaks, main = "Temperature Map")

terra::plot(temperature,col = my_palette(20), at = mylevs)
sp::plot(extent, add = T)
sp::plot(rivers, add = T)
points(2601930.3, 1204410.1, pch = 16, cex = 1)
