

looking_for_Combined.csv <- function(){
  # We want to know, if a certain file already exists
  name.of.file <- '../data/Combined.csv'

  # If do not exists such a file, create it!
  if (!file.exists(name.of.file)){

    # Data from urban climate network of the city of Bern
    measurement_files <- list.files("../AGDS_Bigler_Tinner/data/Measurements/")
    measurement_files <- purrr::map(as.list(paste("../AGDS_Bigler_Tinner/data/Measurements/",measurement_files,sep = "")),~read_csv(.))
    measurement_files <- bind_rows(measurement_files, .id = "column_label")
    measurement_files <-  measurement_files |> pivot_longer(cols = starts_with("L"), names_to = "Log_Nr",values_to = "temperature") |>
      mutate(Log_Nr = as.numeric(str_replace(Log_Nr, "Log_", "")))
    measurement_files <-  mutate(measurement_files,time = mdy_hm(Zeit)) |>
      dplyr::select(-Zeit)
    measurement_metadata <- read_csv("../AGDS_Bigler_Tinner/data/Metadata_19-22.csv")

    # Data from Meteo Schweiz
    meteoswiss <- read_csv2("../AGDS_Bigler_Tinner/data/Meteoswiss/order_114596_data.txt")
    meteoswiss <- meteoswiss |>
      mutate(time = as.POSIXct(as.character(time), format = "%Y%m%d%H%M"))
    meteoswiss_names <-meteoswiss|>
      dplyr::select(-stn)|>
      colnames()

    combined = inner_join(measurement_files,meteoswiss,by = "time")
    combined = inner_join(combined, measurement_metadata, by = "Log_Nr")

    tiff_names <- list.files("../AGDS_Bigler_Tinner/data/Tiffs/")
    tiff_names_short <- tiff_names |>
      str_sub(end = -5)

    for (file in tiff_names){
      # Read the TIF file
      raster_data <- raster::raster(paste("../AGDS_Bigler_Tinner/data/Tiffs/",file,sep = ""))
      # Extract values at the points
      points_values <- raster::extract(raster_data, combined[, c("LV_03_E", "LV_03_N")])
      # Add the extracted values to the points_table
      combined[paste(str_sub(file,end = -5))] <- points_values
      print(file)
    } # End of the for loop

    write_csv(combined,"../AGDS_Bigler_Tinner/data/Combined.csv")

    Combined <- read_csv("../AGDS_Bigler_Tinner/data/Combined.csv")

    return(Combined)

    # If exists such a file, read it only!
  }else {Combined <- read_csv("../AGDS_Bigler_Tinner/data/Combined.csv")
    return(Combined)
  } # end of the if/else statement

} # end of the function

Combined <- looking_for_Combined.csv()
