# We define a function to calculate the KNN model
KNN_Model <- function(pp, training_data, hyperpar.k = c(2) ){
  # How many cores? (depends on your device)
  cores <- detectCores()
  # We make cluster to calculate parallel
  cl <- makeCluster(cores, type = 'FORK')
  registerDoParallel(cl)

  # for reproducibility
  set.seed(1982)
  split <- rsample::initial_split(training_data, prop = 0.3)
  new.data <- rsample::training(split)

  # We define a new training function to calculate our model faster by using foreach
  train_knn <- function(k) {

    model <- caret::train(pp, data = new.data |> tidyr::drop_na(),
                   # We want a KNN model
                   method = "knn",
                   # we use cross validation as method
                   trControl = caret::trainControl(method = "cv", 5),
                   # we set k = k to optimize the hyperparameter k. We substitute it later with a vector
                   tuneGrid = data.frame(k = k),
                   # we want the RMSE as our metrics
                   metric = "RMSE")
    return(model)
  }

  # Use foreach to train models in parallel for different k values. .combine = c means that the result is bind into vector
  models <- foreach(k = hyperpar.k, .combine = c) %dopar% {
    train_knn(k)
  }

  # Stop doParallel
  stopCluster(cl)

  return(models)
}
