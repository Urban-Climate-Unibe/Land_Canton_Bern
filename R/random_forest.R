
random_forest <- function(pp,training_data){

mod_cv <- caret::train(
  pp,
  data = combined_train,
  method = "ranger",
  metric = "RMSE",
  trControl = trainControl(
    method = "cv",
    number = 5,
    savePredictions = "final"
  ),
  tuneGrid = expand.grid(
    .mtry = 7,       # default p/3
    .min.node.size = 2,         # set to 5
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
