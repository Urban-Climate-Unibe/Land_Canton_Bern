# Load the meta data of the climate network
metadata.logger <- read_csv('../data/Metadata_19-22.csv')

# This function evaluates and visualize the model
evaluation_function <- function(data_evaluate = combined_test, train_data = combined_train, model,
                                advanced_model = FALSE){

###############################################################################
# Data preparation

if('Log_Nr' %in% colnames(data_evaluate)){
unique_numbers <- sort(unique(data_evaluate$Log_Nr))
print(paste('Your model contains:',length(unique_numbers),'Loggers'))
logger.names <- metadata.logger|>
  filter(Log_Nr %in% unique_numbers)|>
  select(Name)|>
  pull()}



#------------------------------------------------------------------------------
# Metrics Train (RMSE, MAE, RSQ, Bias)

train_data <- train_data |>
  drop_na()
train_data$fitted <- predict(model, newdata = train_data)

metrics_train <- train_data |>
  yardstick::metrics(temperature, fitted)

# RMSE
rmse_train <- round(metrics_train |>
  filter(.metric == "rmse") |>
  pull(.estimate), digits = 3)
# MAE
mae_train <- round(metrics_train |>
  filter(.metric == "mae") |>
  pull(.estimate), digits = 3)
#RSQ
rsq_train <- round(metrics_train |>
  filter(.metric == "rsq") |>
  pull(.estimate), digits = 3)


# RMSE
rmse_model <- round(model$results$RMSE, digits = 3)
# MAE
mae_model <- round(model$results$MAE, digits = 3)
# RSQ
rsq_model <- round(model$results$Rsquared, digits = 3)
# Bias
train_data <- train_data|>mutate(Bias = fitted - temperature)
bias.train <- round(mean(train_data$Bias), digits = 3)

# -----------------------------------------------------------------------------
# Metrics Test (RMSE, MAE, RSQ, Bias)
data_evaluate$fitted <- predict(model, newdata = data_evaluate)

metrics_test <- data_evaluate |>
  yardstick::metrics(temperature, fitted)

# RMSE
rmse_test <- round(metrics_test |>
  filter(.metric == "rmse") |>
  pull(.estimate), digits = 3)
# MAE
mae_test <- round(metrics_test |>
  filter(.metric == "mae") |>
  pull(.estimate), digits = 3)
#RSQ
rsq_test <- round(metrics_test |>
  filter(.metric == "rsq") |>
  pull(.estimate), digits = 3)

# Bias
# --> if the bias is negative, then the model underestimate the temperature
# --> if the bias is positive, then the model overestimate the temperature
data_evaluate <- data_evaluate|>mutate(Bias = fitted - temperature)
bias.test <- round(mean(data_evaluate$Bias), digits = 3)

###############################################################################
# We want a list as a return for our evaluations:

#------------------------------------------------------------------------------
# Position 1: Table which gives a overview about the metrics: RSQ, RMSE, MAE, Bias

tabl <- tibble::tibble('Metric' = c('RSQ', ' RMSE', 'MAE', 'Bias'),
                       'Values of the model' =c(rsq_model, rmse_model, mae_model, NA),
                       'Values of training set' = c(rsq_train, rmse_train, mae_train, bias.train),
                       'Values of the test set' = c(rsq_test, rmse_test, mae_test, bias.test))|>
  kableExtra::kbl(align = 'lccc')|>
  kableExtra::kable_classic_2(full_width = T, html_font = "Cambria")

#------------------------------------------------------------------------------
# Position 2: ggplot as a overview about the training set and test set

# We create the plot for the training set
p1 <- ggplot(data = train_data, aes(temperature, fitted)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", se = FALSE, color = "red", linewidth = 1) +
  geom_abline(slope = 1, intercept = 0,
              linewidth = 0.5, color = "orange", linewidth = 0.5) +
  labs(subtitle = bquote(italic(R)^2 == .(format(rsq_train, digits = 2)) ~~
                          RMSE == .(format(rmse_train, digits = 3)) ~~
                          Bias == .(format(bias.train, digits = 3))),
                         x = 'Measured temperature [°C]' , y = "Predicted temperature [°C]",
       title = "Train set evaluation") +
  theme_classic()

# We create the plot for the test set
p2 <- ggplot(data = data_evaluate, aes(temperature, fitted)) +
 geom_point(alpha = 0.3) +
 geom_smooth(method = "lm", se = TRUE, color = "red", linewidth = 1) +
 geom_abline(slope = 1, intercept = 0, color = 'orange', linewidth = 0.5) +
 labs(subtitle = bquote(italic(R)^2 == .(format(rsq_test, digits = 2)) ~~
                           RMSE == .(format(rmse_test, digits = 3)) ~~
                           Bias == .(format(bias.test, digits = 3))),
      x = 'Measured temperature [°C]' , y = "Predicted temperature [°C]",
  title = "Test set evaluation") +
  theme_classic()

# We put both plots together
out <- cowplot::plot_grid(p1, p2)

#------------------------------------------------------------------------------
# Position 3: Boxplot for each logger station (where is the bias highest)

boxplot_logger <- ggplot(data = data_evaluate,
             aes(x = as.factor(Log_Nr), y = Bias))+
  geom_boxplot(fill = "skyblue", alpha = 0.5, linewidth = 0.3, width = 0.5,
               outlier.color = "red", outlier.shape = 20, outlier.size = 0.7) +
  stat_boxplot(geom = "errorbar", linewidth = 0.3, width = 0.5)+
  geom_hline(yintercept = 0,linewidth = 0.3) +
  labs(x = "Name of the station and logger number", y = 'Bias [°C]') +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1, size = 8)) +
  scale_x_discrete(labels = paste(logger.names,'[Log Nr:',unique_numbers,']'))


#------------------------------------------------------------------------------
# Position 4: Boxplot for each hour of the day (bias)

boxplot_hour <- ggplot(data = data_evaluate,
       aes(x = as.factor(hour), y = Bias))+
  geom_boxplot(fill = "skyblue", alpha = 0.5, linewidth = 0.3, width = 0.5,
               outlier.color = "red", outlier.shape = 20, outlier.size = 0.7) +
  geom_hline(yintercept = 0,linewidth = 0.3) +
  stat_boxplot(geom = "errorbar", linewidth = 0.3, width = 0.5)+
  labs(x = "Hour of the day", y = 'Bias [°C]') +
  theme_classic()

###############################################################################
# We define our list for the return:
output <- list(tabl, out, boxplot_logger, boxplot_hour)


return(output)}

