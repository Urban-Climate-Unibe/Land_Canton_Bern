vis.and.dev.multi.model <- function(tibble.multi.model, label = NULL){

  # We define a new order because R would sort the column alphabetically
  new.level <- c(tibble.multi.model$Predictors)
  tibble.multi.model$Predictors <- factor(tibble.multi.model$Predictors,
                                          levels =  new.level,
                                          labels = new.level)

  p1 <- tibble.multi.model|>
    # We round our results
    mutate(AIC = round(AIC, digits = 1),
           RSQ = round(RSQ, digits = 6))|>
    # We use pivot longer...
    pivot_longer(cols = c(multi.model|>
                            dplyr::select("RSQ", "AIC")|>
                            colnames()), names_to = "Type")|>
    # We scale RSQ because we want a second y-axis
    mutate(scaled_value = ifelse(`Type` == "AIC", value, value*10000000))|>
    ggplot(aes(x = `Predictors`, y = scaled_value, fill = Type)) +
    # We chose a column plot instead of a bar plot because we want to be flexible
    geom_col(position="dodge")+
    # We set limits for the first y-axis
    # We create a second  y-axis and scale it. (that is why we scaled our pivot table)
    scale_y_continuous(name = "AIC", sec.axis = sec_axis(trans = ~ . / 10000000, name = "RSQ")) +
    # We label our columns. We want the label in the columns , centered and top
    geom_text(aes(label = `value`), vjust = 0.5, hjust = 1, colour = "black", angle = 90,
              position =  position_dodge(.9)) +
    # We add our standard boarders
    labs(x = "Predictors [Each variable contains all variables that are left of it]",
         y = "AIC", title = "Overview of the development of AIC and RSQ",
         subtitle = paste("Development of a multivariate linear Regression model",label)) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)) +
    theme(panel.border = element_rect(colour = "black", fill = NA, linewidth = 1)) +
    theme(legend.background = element_rect( fill = "lightblue",
                                            size = 0.5, linetype = "solid", colour = "black"))+
    theme(plot.margin = margin(0.3, 0.3, 0.3, 0.3, "cm"),
          panel.background = element_rect(fill = "white"),
          plot.background = element_rect(fill = "grey90",colour = "black", linewidth = 1))
  return(p1)
}
