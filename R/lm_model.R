
LM_Model <- function(pp, training_data = combined_train){

group_folds <- groupKFold(training_data$Log_Nr, k = 3)
mod_cv <- caret::train(pp, data = training_data |> drop_na(),
                         method = "lm",
                         trControl = caret::trainControl(method = "cv",
                                                         index = group_folds,
                                                         number = 3,
                                                         savePredictions = "final"),
                       metric = "RMSE")

  return(mod_cv)
}
