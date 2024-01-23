set.seed(123)

#To run in batch mode consider:

# setwd("C:/Users/ntinner/Documents/AGDS_Bigler_Tinner/")
setwd("./vignettes")
jpg_files <- list.files(path = "../data/Current_Output", pattern = "\\.jpg$", full.names = TRUE)
file.remove(jpg_files)


packages <- c('influxdbclient', 'ggplot2', 'tidyverse', 'lubridate', 'dplyr', 'caret',
              'vip', 'parsnip', 'workflows', 'tune', 'dials', 'stringr', 'terra', 'stars',
              'sf', 'plyr', 'doParallel', 'foreach', 'terrainr', 'starsExtra', 'pdp',
              'recipes', 'tidyterra', 'shiny', 'xgboost', 'kableExtra', 'rnaturalearth', 'zoo',
              'moments', 'tibble', 'rsample', 'yardstick', 'cowplot', 'purrr', 'renv',
              'ranger','Boruta','sp',"jsonlite","httr","scales")

# Load the R script to install and load all the packages from above
source("../R/load_packages.R")
load_packages(packages = packages)


name.of.file <- "../data/Combined.csv"


if (!file.exists(name.of.file)){
  dir.create("../data-raw/", showWarnings = FALSE) #create data-raw if missing...
  dir.create("../data/Tiffs/", showWarnings = FALSE) #create data-raw if missing...

  # List all files within Tiffs
  files <- list.files(path = "../data/Tiffs", full.names = TRUE)


  # Remove all Tiffs when processing, to keep organised
  if (length(files) > 0) {
    unlink(files, recursive = TRUE)
  }


  source("../R/raw_tif_processing.R")

  source("../R/data_combination.R")
  data_combination()
}
combined <- read_csv("../data/Combined.csv") |>
  mutate(temperature = temperature-temp) |>
  drop_na()


url <- "https://api.open-meteo.com/v1/forecast?latitude=46.99905&longitude=7.45809&hourly=temperature_2m,relative_humidity_2m,precipitation,surface_pressure,wind_speed_10m,wind_direction_10m,soil_temperature_6cm,soil_temperature_54cm,shortwave_radiation&timezone=Europe%2FBerlin&past_days=5"

response <- GET(url)
data_api <- fromJSON(content(response, "text"), flatten = TRUE)
#Things to change: 10meter temp in zol instead of 2m, also add from zol soilmoisture, and soiltemp

forecast <- data_api$hourly
forecast <- as_tibble(forecast)
forecast <- forecast |> mutate(time = datetime <- as.POSIXct(time, format = "%Y-%m-%dT%H:%M"))

# Take all column-names you need as predictors from the combined file
predictors <- combined |>
  # select our predictors (we want all columns except those in the select() function)
  dplyr::select(-c(Log_Nr,temperature,timestamp,Name,pres,
                   year,month,day,LV_03_E,LV_03_N,-sum_precipitation_10_days,hour)) |>
  colnames()

# Define a formula in the following format: target ~ predictor_1 + ... + predictor_n
formula_local <- as.formula(paste("temperature","~", paste(predictors,collapse  = "+")))

# Make a recipe which can be used for the lm, KNN, and Random Forest model
pp <- recipes::recipe(formula_local,
                      data = combined) |>
  # Yeo-Johnsen transformation (includes Box Cox and an extansion. Now it can handle x ≤ 0)
  recipes::step_YeoJohnson(all_numeric(), -all_outcomes()) |>
  # subsracting the mean from each observation/measurement
  recipes::step_center(recipes::all_numeric(), -recipes::all_outcomes()) |>
  # transforming numeric variables to a similar scale
  recipes::step_scale(recipes::all_numeric(), -recipes::all_outcomes())


source("../R/random_forest.R")

# The function needs the recipe and a dataset which can be used for model training
random_forest <- random_forest(pp, combined, tuning = F)


print('read geopsatial data...')
tiff_names <- str_sub(list.files("../data/Tiffs/"),end = -5)
tiffs_only <- terra::rast(paste0("../data/Tiffs/",tiff_names,".tif"))




forecast <- forecast |> mutate(hour = hour(time),
                   month = month(time),
                   temp = temperature_2m,
                   rain = precipitation,
                   rad = shortwave_radiation,
                   winds = wind_speed_10m,
                   windd = wind_direction_10m,
                   pres = surface_pressure,
                   relhum = relative_humidity_2m,
                   temp_5cm = soil_temperature_54cm) |>
  select(any_of(predictors),time)|>
  ungroup()|>
  arrange(time)|>
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
  ) |>
  mutate_at(vars(starts_with("sum_precip")), ~ ifelse(. < 0.1, 0, .))|>
  filter(time >= Sys.Date())

max_temp <- max(forecast$temp)+5
min_temp <- min(forecast$temp)-2

color_palette <- c("blue4","#0000FF", "#00FFFF", "purple2", "purple4","darkgreen","yellow2","orange2" ,"darkred","black")

break_points <- seq(min_temp, max_temp, length.out = length(color_palette))

map_generator <- function(row){
  tiff_names <- str_sub(list.files("../data/Tiffs/"),end = -5)
  tiffs_only <- terra::rast(paste0("../data/Tiffs/",tiff_names,".tif"))
  print(str(row))
#------------------------------------------------------------------------------
# Loop to process the tiffs
for (name_var in colnames(row |> select(-time))) {
  temp <- terra::rast(ncol=293, nrow=247, xmin=2592670, xmax=2607320, ymin=1193202, ymax=1205552,names = name_var)
  terra::values(temp) <- row |>select(any_of(name_var))

  print(paste0(row |>select(name_var),": ",name_var))
  temp <- crop(temp,tiffs_only)
  temp <- resample(temp,tiffs_only)
  tiffs_only <- c(tiffs_only,temp)
}



print('Tiff processing successful. Model prediction in progress...')
temperature <- terra::predict(tiffs_only, random_forest, na.rm = TRUE)

print('Model prediction sucessful. Create a data frame')
temperature_df <- terra::as.data.frame(temperature+row$temp, xy = TRUE)


#------------------------------------------------------------------------------
# load the spatial layer for communal boarders and the rivers
extent <- st_read("../data/Map/Extent_Bern.shp")
rivers <- st_read("../data/Map/Aare.shp")

xmin <- min(temperature_df$x)
xmax <- max(temperature_df$x)
ymin <- min(temperature_df$y)
ymax <- max(temperature_df$y)

new_bbox <- st_bbox(c(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax))
rivers <- st_crop(rivers, new_bbox)
extent <- st_crop(extent, new_bbox)

print('Your card will now be generated')

#------------------------------------------------------------------------------
# Read out the absolute maximum value to generate leveles for the legend


# Assuming you have a data frame 'df' with a temperature column 'temp

# Generate a color palette with the required number of colors


# Define your breakpoints and their corresponding colors manually





#------------------------------------------------------------------------------
# Generate the map
p <- ggplot() +
  geom_raster(data = temperature_df, aes(x = x, y = y, fill = lyr1)) +
  geom_sf(data = rivers, color = 'black', linewidth = .4) +
  geom_sf(data = extent, linewidth = .2, color = 'black') +
  geom_point(aes(x = 2601930.3, y = 1204410.1)) +
  annotate("text", x = 2602300, y = 1204410.1, label= "AWS Zollikofen", hjust = 0) +
  labs(title = paste('Temperatureanomaly for the suburban area of Bern'),
       subtitle = paste('This map uses a random forest and the following variable inputs:',
                        "\nTemp [°C]: = ",row$temp,
                        "\nPrec [mm]: =", row$rain,
                        '\nWindspeed [m/s] =',row$winds,', Winddirection [°] =',row$windd,
                        '\nRadiation [W/m^2*s] =',row$rad),
       fill = expression(paste(Delta,'Temperature (°C)'))) +
  scale_fill_gradientn(colors = color_palette,
                       values = scales::rescale(break_points),
                       limits = c(min_temp, max_temp),
                       guide = "colorbar") +
  theme_classic() +
  theme(panel.border = element_rect(colour = "black", fill=NA, size = 1))+
  theme(
    title = element_text(size = 10, face = 'bold'),  # Title text size # Subtitle text size
    axis.title = element_text(size = 8),  # Axis label text size
    axis.text = element_text(size = 8),  # Axis tick labels text size
    legend.title = element_text(size = 8),  # Legend title text size
    legend.text = element_text(size = 8),  # Legend labels text size
    plot.subtitle=element_text(size=8, face = 'plain'))

if (!dir.exists("../data/Current_Output")) {
  dir.create("../data/Current_Output")
}
ggsave(paste0("../data/Current_Output/",format(row$time, "%Y-%m-%d_%H-%M-%S"),".jpg"), plot = p, width = 10, height = 6, dpi = 300)
}

for (n in 1:(7*24)) {
  map_generator(forecast |> dplyr::slice(n))
}
