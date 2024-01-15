packages <- c('influxdbclient', 'ggplot2', 'tidyverse', 'lubridate', 'dplyr', 'caret',
              'vip', 'parsnip', 'workflows', 'tune', 'dials', 'stringr', 'terra', 'stars',
              'sf', 'plyr', 'doParallel', 'foreach', 'terrainr', 'starsExtra', 'pdp',
              'recipes', 'tidyterra', 'shiny', 'xgboost', 'kableExtra', 'rnaturalearth', 'zoo',
              'moments', 'tibble', 'rsample', 'yardstick', 'cowplot', 'purrr', 'renv',
              'ranger','Boruta','devtools','sp','keras','tensorflow','influxdbclient')


set.seed(123)
setwd("./vignettes")
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
  drop_na() |>
  select(-starts_with(c("mean","sum")),
         -c(windd,winds,rad,temp,rain)
         )
predictor_loggers_nr <- c(98,7) #Brunnmatt und Zollikofen als referenzen, stabil...

predictor_loggers <- combined |>
  filter(Log_Nr %in% predictor_loggers_nr)|>
  select(timestamp,temperature,Log_Nr) |>
  pivot_wider(names_from = Log_Nr,values_from = temperature) |>
  mutate(Log_7 = "7", Log_98 = "98")|>
  select(-c("7","98"))


combined <- combined |>
  filter(!(Log_Nr %in% predictor_loggers_nr))#remove them

combined <- dplyr::inner_join(predictor_loggers,combined,by = "timestamp") |> drop_na()


loggers_test <- sample(unique(combined$Log_Nr), 5)

# Generate a test set
combined_test <- combined |>
  filter((Log_Nr %in% loggers_test))

# Generate a training set
combined_train <- combined |>
  filter(!(Log_Nr %in% loggers_test))



predictors <- combined |>
  # select our predictors (we want all columns except those in the select() function)
  dplyr::select(-c(Log_Nr,temperature,timestamp,Name,NORD_CHTOP,OST_CHTOPO,
                   year,LV_03_E,LV_03_N)) |>
  colnames()

# Define a formula in the following format: target ~ predictor_1 + ... + predictor_n
formula_local <- as.formula(paste("temperature","~", paste(predictors,collapse  = "+")))

# Make a recipe which can be used for the lm, KNN, and Random Forest model
pp <- recipes::recipe(formula_local,
                      data = combined_train) |>
  # Yeo-Johnsen transformation (includes Box Cox and an extansion. Now it can handle x ≤ 0)
  recipes::step_YeoJohnson(all_numeric(), -all_outcomes()) |>
  # subsracting the mean from each observation/measurement
  recipes::step_center(recipes::all_numeric(), -recipes::all_outcomes()) |>
  # transforming numeric variables to a similar scale
  recipes::step_scale(recipes::all_numeric(), -recipes::all_outcomes())
pred_count <- length(pp$var_info$variable)

grid <- expand.grid(
  .mtry = pred_count/3.5, #default p/3.5
  .min.node.size = 6,         # set to 3
  .splitrule = "variance"     # default variance
) #Result of hyperparameter tuning

group_folds <- groupKFold(combined_train$Log_Nr, k = 3)
mod_cv <- caret::train(
  pp,
  data = combined_train,
  method = "ranger",
  metric = "RMSE",
  trControl = trainControl(
    method = "cv",
    index = group_folds,
    number = 3,
    savePredictions = "final"),
  tuneGrid = grid,
  # arguments specific to "ranger" method
  replace = FALSE,
  sample.fraction = 0.5,
  num.trees = 100,
  seed = 1982
)

