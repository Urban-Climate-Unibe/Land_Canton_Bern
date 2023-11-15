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
    dplyr::summarise(across(where(is.numeric), mean))

  measurement_files <-  measurement_files |> pivot_longer(cols = starts_with("L"), names_to = "Log_Nr",values_to = "temperature") |>
    mutate(Log_Nr = as.numeric(str_replace(Log_Nr, "Log_", ""))) |>
    drop_na()


  meteoswiss <- read_delim("../data/Meteoswiss/order_114596_data.txt",delim = ";")
  meteoswiss <- meteoswiss |>
    mutate(time = as.POSIXct(as.character(time), format = "%Y%m%d%H%M"),
           temp = as.numeric(tre200s0),
           rain = as.numeric(rre150z0),
           rad = as.numeric(gre000z0),
           winds = as.numeric(fkl010z0),
           windd = as.numeric(dkl010z0))|>
    dplyr::select(time,temp,rain,rad,winds,windd) |>
    mutate(time = time+hours(2)) |>
    drop_na() #some parsing error,dk why, 60 NA..





  meteoswiss <- meteoswiss |>
    mutate(hour = hour(time),
           month = month(time),
           day = day(time),
           year = year(time))
  meteoswiss <- meteoswiss |>
    dplyr::group_by(hour, day, month, year) |>
    dplyr::summarise(across(where(is.numeric), mean),.groups = 'drop')

  meteoswiss <- meteoswiss|>
    mutate(timestamp = ymd_h(paste(year,month,day,hour,sep = "-")))|>
    mutate(temp_1 = dplyr::lag(temp,order_by = timestamp,n = 24),
           temp_3 = dplyr::lag(temp,order_by = timestamp, n = 3*24),
           temp_5 = dplyr::lag(temp,order_by = timestamp, n = 5*24))

  meteoswiss_rain_day1 <- meteoswiss|>
    mutate(timestamp = timestamp-hours(24))|>
    mutate(day = day(timestamp),
           hour = hour(timestamp),
           month = month(timestamp),
           year = year(timestamp))|>
    dplyr::group_by(year,month,day)|>
    dplyr::summarise(rain1 = mean(rain),.groups = 'drop')


  meteoswiss_rain_day2 <- meteoswiss|>
    mutate(timestamp = timestamp-hours(24*2))|>
    mutate(day = day(timestamp),
           hour = hour(timestamp),
           month = month(timestamp),
           year = year(timestamp))|>
    dplyr::group_by(year,month,day)|>
    dplyr::summarise(rain2 = mean(rain),.groups = 'drop')

  meteoswiss_rain_day3 <- meteoswiss|>
    mutate(timestamp = timestamp-hours(24*3))|>
    mutate(day = day(timestamp),
           hour = hour(timestamp),
           month = month(timestamp),
           year = year(timestamp))|>
    dplyr::group_by(year,month,day)|>
    dplyr::summarise(rain3 = mean(rain),.groups = 'drop')

  meteoswiss<- inner_join(meteoswiss,meteoswiss_rain_day1,by = c("day","month","year")) |>
    inner_join(meteoswiss_rain_day2) |>
    inner_join(meteoswiss_rain_day3)


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
