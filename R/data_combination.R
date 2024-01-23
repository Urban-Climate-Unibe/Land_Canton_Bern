### Combines data sources ###
# Combines data from meteoswiss and the logger data, both aggregated to the hour, then also calculates rolling means
# Later, Tiffs files are used to add layer data to each measurement point, (land use classes value sand other geolayers)

data_combination <- suppressWarnings(function(){

  measurement_files <- list.files("../data/Measurements/")
  measurement_files <- purrr::map(as.list(paste("../data/Measurements/",measurement_files,sep = "")),~read_csv(.))
  measurement_files <- bind_rows(measurement_files, .id = "column_label")
  measurement_files <- measurement_files|> mutate(time = mdy_hm(Zeit))
  measurement_files <-  measurement_files|>mutate(time = if_else(is.na(time),Time,time)) |>
    dplyr::select(-Zeit,-Time)#weird because 2023 file different...
  measurement_files <- measurement_files |>
    mutate(hour = hour(time),
           month = month(time),
           day = day(time),
           year = year(time))

  measurement_files <- measurement_files |>
    group_by(hour, day, month, year) |>
    dplyr::summarise(across(where(is.numeric), mean))|>
    ungroup()

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
           windd = as.numeric(dkl010z0),
           pres = as.numeric(prestas0),
           relhum = as.numeric(rre150z0))|>
    dplyr::select(time,temp,rain,rad,winds,windd,pres,relhum) |>
    mutate(time = time+hours(2)) |>
    drop_na() #some parsing error,dk why, 60 NA..

  meteoswiss2 <- read_delim("../data/Meteoswiss/order_117685_data.txt",delim = ";")



  meteoswiss <- meteoswiss |>
    mutate(hour = hour(time),
           month = month(time),
           day = day(time),
           year = year(time))
  meteoswiss <- meteoswiss |>
    dplyr::group_by(hour, day, month, year) |>
    dplyr::summarise(across(where(is.numeric), mean),.groups = 'drop') |>
    mutate(rain = rain*6) # to get sum... was mean

  meteoswiss2 <- meteoswiss2 |>
    mutate(time = as.POSIXct(as.character(time), format = "%Y%m%d%H%M"),
           temp_5cm = as.numeric(tso005s0))|>
    select(-tso005s0)|>
    mutate(hour = hour(time),
           month = month(time),
           day = day(time),
           year = year(time))
  meteoswiss2 <- meteoswiss2 |>
    dplyr::group_by(hour, day, month, year) |>
    dplyr::summarise(across(where(is.numeric), mean),.groups = 'drop')

  meteoswiss <- meteoswiss|>
    mutate(timestamp = ymd_h(paste(year,month,day,hour,sep = "-"))) |>
    arrange(timestamp)|>
    mutate(
      mean_temp_6_hours = zoo::rollmean(temp, k = 6, fill = NA, align = "right"),
      mean_temp_12_hours = zoo::rollmean(temp, k = 12, fill = NA, align = "right"),
      mean_temp_1_day = zoo::rollmean(temp, k = 24 * 1, fill = NA, align = "right"),
      mean_temp_3_days = zoo::rollmean(temp, k = 24 * 3, fill = NA, align = "right"),
      mean_temp_5_days = zoo::rollmean(temp, k = 24 * 5, fill = NA, align = "right"),
      sum_precipitation_6_hours = zoo::rollsum(rain, k = 6, fill = NA, align = "right"),
      sum_precipitation_12_hours = zoo::rollsum(rain, k = 12, fill = NA, align = "right"),
      sum_precipitation_1_day = zoo::rollsum(rain, k = 24 * 1, fill = NA, align = "right"),
      sum_precipitation_3_days = zoo::rollsum(rain, k = 24 * 3, fill = NA, align = "right"),
      sum_precipitation_5_days = zoo::rollsum(rain, k = 24 * 5, fill = NA, align = "right"),
      sum_precipitation_10_days = zoo::rollsum(rain, k = 24 * 10, fill = NA, align = "right")
    ) |>
    mutate_at(vars(starts_with("sum_precip")), ~ ifelse(. < 0.1, 0, .))




  meteoswiss <- inner_join(meteoswiss,meteoswiss2,by = c("hour","day","month","year"))

  combined = inner_join(measurement_files,meteoswiss,by = c("hour","day","month","year"))

  measurement_metadata_19_22 <- read_csv("../data/Metadata_19-22.csv")|>  mutate(NORD_CHTOPO = NORD_CHTOP)|> select(-NORD_CHTOP)
  measurement_metadata_23 <- read_csv2("../data/metadata_network_2023.csv")|>
    mutate(Log_Nr = Log_NR,
           Name = STANDORT)|>
    select(-Log_NR)
  combined_metadata <- anti_join(measurement_metadata_23,measurement_metadata_19_22, by = "Log_Nr") |>
    bind_rows(measurement_metadata_19_22) |> select(Name, LV_03_N,LV_03_E,Log_Nr)

  combined = inner_join(combined, combined_metadata, by = "Log_Nr")

  combined <- combined |> ungroup()
#Bike measurements?
  bike_data <- read_csv("../data//Bicycle_data_complete_bugfix.csv")
  bike_data <- bike_data|>
    filter(!is.na(Latitude) & !is.na(Longitude))|>
    st_as_sf(coords = c("Longitude","Latitude"), crs = 4326)|>
    st_transform(2056)
  coords <- st_coordinates(bike_data)
  bike_data <- bind_cols(as.tibble(bike_data),coords)|>
    mutate(LV_03_E = X,
           LV_03_N = Y)
  bike_data <- bike_data |>
    mutate(timestamp = dmy_hms(Date.Time),
           temperature = Temp..C.)|>
    mutate(hour = hour(timestamp),
           month = month(timestamp),
           day = day(timestamp),
           year = year(timestamp),
           Log_Nr = 999,
           Name = "Meteobike")|>
    select(hour,day,month,year,temperature,Log_Nr,Name,LV_03_N,LV_03_E)

  bike_data <- inner_join(bike_data,meteoswiss,by = c("hour","day","month","year"))
  combined <- bind_rows(bike_data,combined)





  combined <- combined |> ungroup()

  combined <- combined |>
    dplyr::mutate(ID = row_number())


  tiff_names <- list.files("../data/Tiffs/")

  tiff_paths <- paste0("../data/Tiffs/",tiff_names)

  tiffs<-terra::rast(tiff_paths)



  spat_points <- combined |> dplyr::select(c(LV_03_E,LV_03_N))

  extracted <- terra::extract(tiffs,spat_points)
#up to here works...
  combined <- inner_join(combined,extracted,by = "ID")

combined <- combined |>
  select(-ID)

  write_csv(combined,"../data/Combined.csv")
  return(combined)
})
