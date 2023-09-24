


CurrentMap <- function(){
  #Managing Packages




  # You can generate an API token from the "API Tokens Tab" in the UI
  token = "tu3zUeCazQobS4TrIIRftQS3Tr4xoZQoZaRf0Ve0iCrU4LZSY1jTS3laCJ_OjwJxWJ6WsKuwXN_tVV10R73hyg=="

  client <- InfluxDBClient$new(url = "https://influx.smcs.abilium.io",
                               token = token,
                               org = "abilium")

  #reading tables
  tables <- client$query('from(bucket: "smcs") |> range(start: 2023-07-27) |> filter(fn: (r) => r["_measurement"] == "mqtt_consumer") |> filter(fn: (r) => r["_field"] == "decoded_payload_temperature" or r["_field"] == "decoded_payload_humidity") |> filter(fn: (r) => r["topic"] != "v3/dynamicventilation@ttn/devices/eui-f613c9feff19276a/up") |> filter(fn: (r) => r["topic"] != "helium/eeea9617559b/rx") |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")')

  #getting time
  currenttime <- Sys.time()
  laggingtime <- currenttime - lubridate::minutes(30)


  #Setup for inital dataframe
  combined <- tibble(name = character(), temperature = double())

  #adding of data to dataframe
  for (x in 1:length(tables)) {
    tables[[x]]$time <- with_tz(tables[[x]]$time,"Europe/Zurich")
    temp <- tables[[x]] |>
      filter(time > laggingtime)|>
      group_by(topic)|>
      summarise(temp = mean(decoded_payload_temperature))

    combined <- combined |>
      add_row(name = temp$topic, temperature = temp$temp)
    #somewhow emtpy rows are dropped, nice ;)

  }
  combined <- combined |>
    mutate(name = str_extract(name, "(?<=/)[^/]+(?=/)"))



  #reading in metadata
  meta <- read_csv("./data/Messnetz_2023_MODIFIED.csv")|>
    mutate(name = Code_grafana)


  #only take ours
  combined <- combined |>
    filter(name %in% meta$Code_grafana)


  #Attach meta information
  combined <- combined |>
    inner_join(meta, by = "name")





  tiff_names <- list.files("./data/Tiffs/")
  tiff_names_short <- tiff_names |>
    str_sub(end = -5)

  for (file in tiff_names) {
    # Read the TIF file
    raster_data <- raster::raster(paste("./data/Tiffs/",file,sep = ""))

    # Extract values at the points
    points_values <- raster::extract(raster_data, combined[, c("LV_03_E", "LV_03_N")])

    # Add the extracted values to the points_table
    combined[paste(str_sub(file,end = -5))] <- points_values
  }

  combined <- combined |>
    filter(complete.cases(across(all_of(tiff_names_short))))


  #Dataframe to (cleanup):

  correlators <- tiff_names_short|>
    paste(collapse  = "+")

  formula_local = as.formula(paste("temperature","~", correlators))

  model <- lm(formula_local, data = combined)
  nullModel = lm(temperature ~ 1, data = combined)

  model <- MASS::stepAIC(model, # start with a model containing all the variables
                         direction = 'forward', # run backward selection
                         scope = list(upper = model, # the maximum to consider is a model with all variables
                                      lower = nullModel), # the minimum to consider is a model with no variables
                         trace = 1)



  tiffs <- list()
  for(coef in names(model$coefficients)[-1]){
    print(coef)
    tiffs[[coef]] <- raster::raster(paste("./data/Tiffs/",coef,".tif",sep = ""))
    coeff_temp <- unname(coefficients(model)[coef])
    tiffs[[coef]] <- tiffs[[coef]]*coeff_temp
    print(coeff_temp)
  }

  out = unname(coefficients(model)["(Intercept)"])
  for (tiff in tiffs) {
    out = out + tiff
  }
  combined$residuals <- model$residuals
  # Define the three main colors
  red_ish <- rgb(1, 0, 0, alpha = 1)  # Red-ish (fully opaque)
  green <- rgb(0, 1, 0, alpha = 1)    # Green (fully opaque)





  tiff(filename = "./analysis/CurrentMap.tif",width = 1000, height = 1000)
  extent <- rgdal::readOGR("./data/Extent_Bern.shp")
  rivers <- rgdal::readOGR("./data/Aare.shp")
  color = colorRampPalette(c("blue","deepskyblue", "white","orange", "red"))(100)
  raster::plot(out, col = color)
  sp::plot(extent, add = T)
  sp::plot(rivers, add = T)
  points(combined$LV_03_E,combined$LV_03_N , pch = 16, cex = 1)
  text(combined$LV_03_E, combined$LV_03_N, round(combined$temperature,1), pos = 3,cex = 0.7, adj = c(1, 1))
  title(paste("R^2 = ",round(summary(model)$r.squared,2),", Mean Temp Logger = ",mean(round(combined$temperature),2),", Logger Count = ",length(combined$name)), currenttime,paste("predictors = ",paste(names(model$coefficients)[-1],collapse = ", ")))
  dev.off()


  drive_upload(media = "./analysis/CurrentMap.tif", path = as_dribble("https://drive.google.com/drive/folders/1ZJqhB6zUb443ltvpOS-8tWQbX39M01bx"),overwrite = TRUE)


  #Night plot at 4:30 AM local time...
  if ((currenttime > with_tz(Sys.Date()+lubridate::hm("00:00")-lubridate::hm("02:00"),Sys.timezone()))&&(currenttime < with_tz(Sys.Date()+lubridate::hm("00:15")-lubridate::hm("02:00"),Sys.timezone()))) {
    tiff(filename = "D:/Foto2_NilsTinner/Logger_Network_Bern/analysis/MidNightMap.tif",width = 1000, height = 1000)
    extent <- rgdal::readOGR("./data/Extent_Bern.shp")
    rivers <- rgdal::readOGR("./data/Aare.shp")
    color = colorRampPalette(c("blue","deepskyblue", "white","orange", "red"))(100)
    raster::plot(out, col = color)
    sp::plot(extent, add = T)
    sp::plot(rivers, add = T)
    points(combined$LV_03_E,combined$LV_03_N , pch = 16, cex = 1)
    text(combined$LV_03_E, combined$LV_03_N, round(combined$temperature,1), pos = 3,cex = 0.7, adj = c(1, 1))
    title(paste("R^2 = ",round(summary(model)$r.squared,2),", Mean Temp Logger = ",mean(round(combined$temperature),2),", Logger Count = ",length(combined$name)), currenttime,paste("predictors = ",paste(names(model$coefficients)[-1],collapse = ", ")))
    dev.off()
    drive_upload(media = "D:/Foto2_NilsTinner/Logger_Network_Bern/analysis/MidNightMap.tif", path = as_dribble("https://drive.google.com/drive/folders/1ZJqhB6zUb443ltvpOS-8tWQbX39M01bx"),overwrite = TRUE)
    lowest_temp <<- mean(combined$temperature)#reset every midnight
  }

if(lowest_temp > mean(combined$temperature)) {
  tiff(filename = "D:/Foto2_NilsTinner/Logger_Network_Bern/analysis/ColdestMap.tif",width = 1000, height = 1000)
  extent <- rgdal::readOGR("./data/Extent_Bern.shp")
  rivers <- rgdal::readOGR("./data/Aare.shp")
  color = colorRampPalette(c("blue","deepskyblue", "white","orange", "red"))(100)
  raster::plot(out, col = color)
  sp::plot(extent, add = T)
  sp::plot(rivers, add = T)
  points(combined$LV_03_E,combined$LV_03_N , pch = 16, cex = 1)
  text(combined$LV_03_E, combined$LV_03_N, round(combined$temperature,1), pos = 3,cex = 0.7, adj = c(1, 1))
  title(paste("R^2 = ",round(summary(model)$r.squared,2),", Mean Temp Logger = ",mean(round(combined$temperature),2),", Logger Count = ",length(combined$name)), currenttime,paste("predictors = ",paste(names(model$coefficients)[-1],collapse = ", ")))
  dev.off()
  drive_upload(media = "D:/Foto2_NilsTinner/Logger_Network_Bern/analysis/ColdestMap.tif", path = as_dribble("https://drive.google.com/drive/folders/1ZJqhB6zUb443ltvpOS-8tWQbX39M01bx"),overwrite = TRUE)
  lowest_temp <<- mean(combined$temperature)
}









}

lowest_temp <- 50
packages <- c("influxdbclient","ggplot2","tidyverse","lubridate","raster","dplyr","googledrive")

source("./R/load_packages.R")
load_packages(packages)

while (T) {

  result <- tryCatch({
    CurrentMap()
    # ...
  }, error = function(err) {
    # Code to handle the error
    cat("An error occurred: ", err$message, "\n")
    # Additional error handling if needed
  })
  print("Next Map in 15 Minutes")
  for (x in 1:15) {
    Sys.sleep(60)
    print(paste("minutes passed:",x))
  }



}#Just to keep going if anything goes wrong...
#pretty ugly i know


