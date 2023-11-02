
xgb <- function(xgb_workflow,train){









# create a workflow compatible with
# the {tune} package which combines
# model settings with the desired
# model structure (data / formula)




hp_settings <- dials::grid_latin_hypercube(
  tune::extract_parameter_set_dials(xgb_workflow),
  size = 3
)

print(hp_settings)



hp_settings <- dials::grid_latin_hypercube(
  tune::extract_parameter_set_dials(xgb_workflow),
  size = 3
)

print(hp_settings)

# set the folds (division into different)
# cross-validation training datasets
folds <- rsample::vfold_cv(train, v = 3)

# optimize the model (hyper) parameters
# using the:
# 1. workflow (i.e. model)
# 2. the cross-validation across training data
# 3. the (hyper) parameter specifications
# all data are saved for evaluation
xgb_results <- tune::tune_grid(
  xgb_workflow,
  resamples = folds,
  grid = hp_settings,
  control = tune::control_grid(save_pred = TRUE)
)


# select the best model based upon
# the root mean squared error
xgb_best <- tune::select_best(
  xgb_results,
  metric = "rmse"
)

# cook up a model using finalize_workflow
# which takes workflow (model) specifications
# and combines it with optimal model
# parameters into a model workflow
xgb_best_hp <- tune::finalize_workflow(
  xgb_workflow,
  xgb_best
)

print(xgb_best_hp)





# train a final (best) model with optimal
# hyper-parameters
xgb_best_model <- fit(xgb_best_hp, train)


return(xgb_best_model)

}
