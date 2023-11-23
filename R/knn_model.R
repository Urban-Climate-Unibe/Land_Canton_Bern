# We define a function to calculate the KNN model
KNN_Model <- function(pp, training_data = combined_train, tuning = FALSE){

tuning.vector = (8:12)


if(tuning == FALSE){
  group_folds <- groupKFold(training_data$Log_Nr, k = 3)
  model <- caret::train(pp, data = training_data |> tidyr::drop_na(),
                        # We want a KNN model
                        method = "knn",
                        # we use cross validation as method
                        trControl = caret::trainControl(method = "cv",                                                         index = group_folds,
                                                        number = 3,
                                                        savePredictions = "final"),
                        # we set k = k to optimize the hyperparameter k. We substitute it later with a vector
                        tuneGrid = data.frame(k = 10),
                        # we want the RMSE as our metrics
                        metric = "RMSE")

}else{
  group_folds <- groupKFold(training_data$Log_Nr, k = 3)
  model <- caret::train(pp, data = training_data |> tidyr::drop_na(),
                        # We want a KNN model
                        method = "knn",
                        # we use cross validation as method
                        trControl = caret::trainControl(method = "cv",
                                                        index = group_folds,
                                                        number = 3,
                                                        savePredictions = "final"),
                        # we set k = k to optimize the hyperparameter k. We substitute it later with a vector
                        tuneGrid = data.frame(k = tuning.vector),
                        # we want the RMSE as our metrics
                        metric = "RMSE")

}


    return(model)
}
