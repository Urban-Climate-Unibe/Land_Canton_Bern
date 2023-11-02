
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




return(xgb_results)

}
