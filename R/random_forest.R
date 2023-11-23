
random_forest <- function(pp,training_data,tuning = FALSE){
  pred_count <- length(pp$var_info$variable)
  if (tuning == FALSE) {
    grid <- expand.grid(
      .mtry = pred_count/3, #default p/3
      .min.node.size = 5,         # set to 5
      .splitrule = "variance"     # default variance
    )
  }else{
    grid <- expand.grid(
      .mtry = c(pred_count/2,pred_count/2.5,pred_count/3,pred_count/3.5,pred_count/4),
      .min.node.size = c(3,5,8,10),         # set to 5
      .splitrule = "variance"     # default variance
    )
  }
group_folds <- groupKFold(training_data$Log_Nr, k = 3)
mod_cv <- caret::train(
  pp,
  data = training_data,
  method = "ranger",
  metric = "RMSE",
  trControl = trainControl(
    method = "cv",
    index = group_folds,
    number = 3,
    savePredictions = "final"
  ),
  tuneGrid = grid,
  # arguments specific to "ranger" method
  replace = FALSE,
  sample.fraction = 0.5,
  num.trees = 100,
  seed = 1982
)

return(mod_cv)
}
