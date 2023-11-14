
evaluation_function <- function(data_evaluate = combined_test, train_data = combined_train, model){

#prepping data
data_evaluate$fitted <- unlist(predict(model, data_evaluate))

train_data$fitted <- unlist(predict(model, train_data))

###############################################################################
# Metrics

# -----------------------------------------------------------------------------
# Metrics Train (RMSE, MAE, RSQ, Bias)
rmse_train <- model$results$RMSE
mae_train <- model$results$MAE
rsq_train <- model$results$Rsquared

train_data <- train_data|>mutate(Bias = fitted - temperature)
bias.train <- mean(train_data$Bias)


# -----------------------------------------------------------------------------
# Metrics Test (RMSE, MAE, RSQ, Bias)

metrics_test <- data_evaluate |>
  yardstick::metrics(temperature, fitted)

rmse_test <- metrics_test |>
  filter(.metric == "rmse") |>
  pull(.estimate)

mae_test <- metrics_test |>
  filter(.metric == "mae") |>
  pull(.estimate)

rsq_test <- metrics_test |>
  filter(.metric == "rsq") |>
  pull(.estimate)



# We calculate the Bias
# --> if the bias is negative, then the model underestimate the temperature
# --> if the bias is positive, then the model overestimate the temperature
data_evaluate <- data_evaluate|>mutate(Bias = fitted - temperature)
bias.test <- mean(data_evaluate$Bias)

###############################################################################
# data frame

tabl <- tibble::tibble('Metric' = c('RSQ', ' RMSE', 'MAE', 'Bias'),
                       'Values of training set' = c(rsq_train, rmse_train, mae_train, bias.train),
                       'Values of the test set' = c(rsq_test, rmse_test, mae_test, bias.test))|>
  kableExtra::kbl(align = 'lcc')|>
  kableExtra::kable_classic_2(full_width = T, html_font = "Cambria")

###############################################################################
# Plots

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


p2 <- ggplot(data = data_evaluate, aes(temperature, fitted)) +
 geom_point(alpha = 0.3) +
 geom_smooth(method = "lm", se = TRUE, color = "red", linewidth = 1) +
 geom_abline(slope = 1, intercept = 0, color = 'orange', linewidth = 0.5) +
 labs(subtitle = bquote(italic(R)^2 == .(format(rsq_test, digits = 2)) ~~
                           RMSE == .(format(rmse_test, digits = 3)) ~~
                           Bias == .(format(bias.test, digits = 3))),
  title = "Test set") +
  theme_classic()




out <- cowplot::plot_grid(p1, p2)


boxplot_logger <- ggplot(data = train_data,
             aes(x = as.factor(Log_Nr), y = Bias))+
  geom_boxplot() +
  theme_classic()


boxplot_hour <- ggplot(data = train_data,
       aes(x = as.factor(hour), y = Bias))+
  geom_boxplot(fill = "skyblue", alpha = 0.5, lwd = 0.3, width = 0.5,
               outlier.color = "red", outlier.shape = 17, outlier.size = 2) +
  stat_boxplot(geom = "errorbar", size = 0.3, width = 0.3)+
  theme_classic()


vip_plot <- vip::vip(model,                        # Model to use
          train = model$trainingData,   # Training data used in the model
          method = "permute",            # VIP method
          target = "temperature",     # Target variable
          nsim = 10,                      # Number of simulations
          metric = "RMSE",               # Metric to assess quantify permutation
          sample_frac = 0.01,             # Fraction of training data to use
          pred_wrapper = predict ,
          num_features = 20L)

return(list(tabl, out, vip_plot, boxplot_logger, boxplot_hour))

#
# preds <-
#   model$recipe$var_info |>
#   dplyr::filter(role == "predictor") |>
#   dplyr::pull(variable)
#
#
#
# all_plots <- list()
#
# for (p in preds[1:6]) {
#   all_plots[[p]] <-
#     pdp::partial(
#       model,       # Model to use
#       p,            # Predictor to assess
#       plot = TRUE   # Whether output should be a plot or dataframe
#     )
# }
#
# pdps <- cowplot::plot_grid(all_plots[[1]], all_plots[[2]], all_plots[[3]],
#                            all_plots[[4]], all_plots[[5]], all_plots[[6]])
#
# pdps


}
