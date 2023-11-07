KNN_Model <- function(pp,training_data){
  library(plyr)
  library(doParallel)
  cores <- detectCores()
  registerDoParallel(cores=detectCores())

  mod_cv <- caret::train(pp, data = combined_train |> drop_na(),
                         method = "knn",
                         trControl = trainControl(method = "cv", 2),
                         tuneGrid = data.frame(k = 10),
                         metric = "RMSE")

  return(mod_cv)
}
