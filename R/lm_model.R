
LM_Model <- function(pp,training_data){
  library(plyr)
  library(doParallel)
  cores <- detectCores()
  registerDoParallel(cores=detectCores())

  mod_cv <- caret::train(pp, data = combined_train |> drop_na(),
                         method = "lm",
                         trControl = trainControl(method = "cv", 2),
                         metric = "RMSE")

  return(mod_cv)
}
