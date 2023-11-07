
evaluate <- function(data_evaluate,model){

library(plyr)
library(doParallel)
cores <- detectCores()
registerDoParallel(cores=detectCores())

#prepping data
data_evaluate$fitted <- unlist(predict(model, data_evaluate))
metrics_test <- data_evaluate |>
  yardstick::metrics(temperature, fitted)

data_evaluate<- data_evaluate|>mutate(difference = fitted-temperature)


rmse_test <- metrics_test |>
  filter(.metric == "rmse") |>
  pull(.estimate)
rsq_test <- metrics_test |>
  filter(.metric == "rsq") |>
  pull(.estimate)

#plots



p1 <- ggplot(data = data_evaluate, aes(temperature, fitted)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  geom_abline(slope = 1, intercept = 0, linetype = "dotted") +
  labs(subtitle = bquote( italic(R)^2 == .(format(rsq_test, digits = 2)) ~~
                            RMSE == .(format(rmse_test, digits = 3))),
       title = "Test set") +
  theme_classic()



# p2 <- ggplot(data = data_evaluate,
#        aes(x = as.factor(Log_Nr), y = abs(difference)))+
#   geom_boxplot()


p3 <- ggplot(data = data_evaluate,
       aes(x = as.factor(hour), y = abs(difference)))+
  geom_boxplot()


# p4 <- vip::vip(model,                        # Model to use
#          train = model$trainingData,   # Training data used in the model
#          method = "permute",            # VIP method
#          target = "temperature",     # Target variable
#          nsim = 1,                      # Number of simulations
#          metric = "RMSE",               # Metric to assess quantify permutation
#          sample_frac = 0.01,             # Fraction of training data to use
#          pred_wrapper = predict ,
#          num_features = 20L# Prediction function to use
# )

plot <- cowplot::plot_grid(p1,p3,
                   ncol = 2)

return(list(metrics_test,plot))

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
