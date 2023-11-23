# This function evaluates and visualize the model
evaluation_function <- function(data_evaluate = combined_test, train_data = combined_train, model){

###############################################################################
# Data preparation

data_evaluate$fitted <- unlist(predict(model, data_evaluate))
train_data$fitted <- unlist(predict(model, train_data))

#------------------------------------------------------------------------------
# Metrics Train (RMSE, MAE, RSQ, Bias)

# RMSE
rmse_train <- model$results$RMSE
# MAE
mae_train <- model$results$MAE
# RSQ
rsq_train <- model$results$Rsquared
# Bias
train_data <- train_data|>mutate(Bias = fitted - temperature)
bias.train <- mean(train_data$Bias)

# -----------------------------------------------------------------------------
# Metrics Test (RMSE, MAE, RSQ, Bias)

metrics_test <- data_evaluate |>
  yardstick::metrics(temperature, fitted)

# RMSE
rmse_test <- metrics_test |>
  filter(.metric == "rmse") |>
  pull(.estimate)
# MAE
mae_test <- metrics_test |>
  filter(.metric == "mae") |>
  pull(.estimate)
#RSQ
rsq_test <- metrics_test |>
  filter(.metric == "rsq") |>
  pull(.estimate)

# Bias
# --> if the bias is negative, then the model underestimate the temperature
# --> if the bias is positive, then the model overestimate the temperature
data_evaluate <- data_evaluate|>mutate(Bias = fitted - temperature)
bias.test <- mean(data_evaluate$Bias)

###############################################################################
# We want a list as a return for our evaluations:

#------------------------------------------------------------------------------
# Position 1: Table which gives a overview about the metrics: RSQ, RMSE, MAE, Bias

tabl <- tibble::tibble('Metric' = c('RSQ', ' RMSE', 'MAE', 'Bias'),
                       'Values of training set' = c(rsq_train, rmse_train, mae_train, bias.train),
                       'Values of the test set' = c(rsq_test, rmse_test, mae_test, bias.test))|>
  kableExtra::kbl(align = 'lcc')|>
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
       title = "Train set") +
  theme_classic()

# We create the plot for the test set
p2 <- ggplot(data = data_evaluate, aes(temperature, fitted)) +
 geom_point(alpha = 0.3) +
 geom_smooth(method = "lm", se = TRUE, color = "red", linewidth = 1) +
 geom_abline(slope = 1, intercept = 0, color = 'orange', linewidth = 0.5) +
 labs(subtitle = bquote(italic(R)^2 == .(format(rsq_test, digits = 2)) ~~
                           RMSE == .(format(rmse_test, digits = 3)) ~~
                           Bias == .(format(bias.test, digits = 3))),
  title = "Test set") +
  theme_classic()

# We put both plots together
out <- cowplot::plot_grid(p1, p2)

#------------------------------------------------------------------------------
# Position 3: Boxplot for each logger station (where is the bias highest)

boxplot_logger <- ggplot(data = train_data,
             aes(x = as.factor(Log_Nr), y = Bias))+
  geom_boxplot() +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

#------------------------------------------------------------------------------
# Position 4: Boxplot for each hour of the day (bias)

boxplot_hour <- ggplot(data = train_data,
       aes(x = as.factor(hour), y = Bias))+
  geom_boxplot(fill = "skyblue", alpha = 0.5, lwd = 0.3, width = 0.5,
               outlier.color = "red", outlier.shape = 17, outlier.size = 2) +
  stat_boxplot(geom = "errorbar", size = 0.3, width = 0.3)+
  theme_classic()

#------------------------------------------------------------------------------
# Position 5: Partial dependence of the variables

# The predictor variables are saved in our model's recipe
#preds <- model$recipe$var_info |>
  #dplyr::filter(role == "predictor") |>
  #dplyr::pull(variable)

#all_plots <- purrr::map(preds, ~pdp::partial(model,c('winds', 'windd'), plot = TRUE, plot.engine = "ggplot2"))

#pdps <- cowplot::plot_grid(all_plots[[1]], all_plots[[2]])

###############################################################################
# We define our list for the return:
output <- list(tabl, out, boxplot_logger, boxplot_hour)


return(output)}

