data_combination <- suppressWarnings(function(){

measurement_files <- list.files("../data/Measurements/")
measurement_files <- purrr::map(as.list(paste("../data/Measurements/",measurement_files,sep = "")),~read_csv(.))
measurement_files <- bind_rows(measurement_files, .id = "column_label")
measurement_files <-  mutate(measurement_files,time = mdy_hm(Zeit)) |>
  dplyr::select(-Zeit)
measurement_files <- measurement_files |>
  mutate(hour = hour(time),
         month = month(time),
         day = day(time),
         year = year(time))

measurement_files <- measurement_files |>
  group_by(hour, day, month, year) |>
  summarise(across(where(is.numeric), mean))

measurement_files <-  measurement_files |> pivot_longer(cols = starts_with("L"), names_to = "Log_Nr",values_to = "temperature") |>
  mutate(Log_Nr = as.numeric(str_replace(Log_Nr, "Log_", ""))) |>
  drop_na()


meteoswiss <- read_csv2("../data/Meteoswiss/order_114596_data.txt")
meteoswiss <- meteoswiss |>
  mutate(time = as.POSIXct(as.character(time), format = "%Y%m%d%H%M"),
         tre200s0 = as.numeric(tre200s0),
         rre150z0 = as.numeric(rre150z0),
         fkl010z0 = as.numeric(fkl010z0))

meteoswiss <- meteoswiss |>
  mutate(hour = hour(time+hours(2)),
         month = month(time),
         day = day(time),
         year = year(time))
meteoswiss <- meteoswiss |>
  group_by(hour, day, month, year) |>
  summarise(across(where(is.numeric), mean))



combined = inner_join(measurement_files,meteoswiss,by = c("hour","day","month","year"))

measurement_metadata <- read_csv("../data/Metadata_19-22.csv")


combined = inner_join(combined, measurement_metadata, by = "Log_Nr")




tiff_names <- list.files("../data/Tiffs/")
tiff_names_short <- tiff_names |>
  str_sub(end = -5)
lentiff <- length(tiff_names)
k = 1
for (file in tiff_names) {

  # Read the TIF file
  raster_data <- raster::raster(paste("../data/Tiffs/",file,sep = ""))

  # Extract values at the points
  points_values <- raster::extract(raster_data, combined[, c("LV_03_E", "LV_03_N")])

  # Add the extracted values to the points_table
  combined[paste(str_sub(file,end = -5))] <- points_values

  print(paste(k,"/",lentiff,"Tiffs processed"))
  k = k+1
  if(k%%10 == 0){
    print("Keep patient, things will work out")
  }
}

write_csv(combined,"../data/Combined.csv")
return(combined)
})
