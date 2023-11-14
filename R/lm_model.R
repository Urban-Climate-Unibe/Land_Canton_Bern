
LM_Model <- function(pp, training_data = combined_train){

mod_cv <- caret::train(pp, data = combined_train |> drop_na(),
                         method = "lm",
                         trControl = caret::trainControl(method = "cv", 2),
                         metric = "RMSE")

  return(mod_cv)
}
