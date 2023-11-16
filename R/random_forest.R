
random_forest <- function(pp,training_data){
group_folds <- groupKFold(training_data$Log_Nr, k = 5)
mod_cv <- caret::train(
  pp,
  data = training_data,
  method = "ranger",
  metric = "RMSE",
  trControl = trainControl(
    method = "cv",
    index = group_folds,
    number = 5,
    savePredictions = "final"
  ),
  tuneGrid = expand.grid(
    .mtry = 60/3,       # default p/3
    .min.node.size = 5,         # set to 5
    .splitrule = "variance"     # default variance
  ),
  # arguments specific to "ranger" method
  replace = FALSE,
  sample.fraction = 0.5,
  num.trees = 100,
  seed = 1982
)

return(mod_cv)
}
