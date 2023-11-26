# We define a function to calculate the KNN model
KNN_Model <- function(pp, training_data = combined_train, tuning = FALSE){

cores <- makeCluster(detectCores())
registerDoParallel(cores)
tuning.vector = (8:12)

numbers.of.rows <- nrow(training_data)

if(numbers.of.rows > 50000){
  print('The data will be split because we assume high computational time!')
  split.percent <- as.numeric(round(100000/numbers.of.rows, digits = 3))
  percent <- as.numeric(round(100*split.percent, digits = 0))
  set.seed(123)  # for reproducibility
  split <- rsample::initial_split(training_data, prop = split.percent)
  training_data <- rsample::training(split)
  new.numbers.of.rows <- nrow(training_data)
  print(paste('Your data frame has been reduced from',numbers.of.rows,
              'rows to',new.numbers.of.rows,
              'rows which means you work now with',
              percent,'% of your the original data'))
}

if(tuning == FALSE){
  print('Your model will be calculatet with k = 10')
  group_folds <- groupKFold(training_data$Log_Nr, k = 3)
  model <- caret::train(pp, data = training_data |> tidyr::drop_na(),
                        # We want a KNN model
                        method = "knn",
                        # we use cross validation as method
                        trControl = caret::trainControl(method = "cv",                                                         index = group_folds,
                                                        number = 3,
                                                        savePredictions = "final"),
                        parallel = 'foreach',
                        # we set k = k to optimize the hyperparameter k. We substitute it later with a vector
                        tuneGrid = data.frame(k = 10),
                        # we want the RMSE as our metrics
                        metric = "RMSE")

}

if(tuning == TRUE){
  print('Your model will be tuned')
  group_folds <- groupKFold(training_data$Log_Nr, k = 3)
  model <- caret::train(pp, data = training_data |> tidyr::drop_na(),
                        # We want a KNN model
                        method = "knn",
                        # we use cross validation as method
                        trControl = caret::trainControl(method = "cv",
                                                        index = group_folds,
                                                        number = 3,
                                                        savePredictions = "final"),
                        parallel = 'foreach',
                        # we set k = k to optimize the hyperparameter k. We substitute it later with a vector
                        tuneGrid = data.frame(k = tuning.vector),
                        # we want the RMSE as our metrics
                        metric = "RMSE")

  best.tune <- knn_model$bestTune$k
  print(paste('Your model has been optimized (k = 8, 9, 10, 11, 12) and k is now:',best.tune))

}


    return(model)
}
