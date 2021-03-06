#' plot.response Plots the marginal response of a model to an environmental variable with all other variables held at their mean in env
#'
#'
#' @param model An enmtools model object
#' @param env A RasterLayer or RasterStack object containing environmental data
#' @param layer The name of the layer to plot
#'
#' @return results A plot of the marginal response of the model to the environmental variable
#'
#' @keywords plot, sdm, enm, response
#'
#' @export plot.response
#'
#' @examples
#'

plot.response <- function(model, env, layer){

  if(!layer %in% names(env)){
    stop(paste("Couldn't find layer named", layer, "in environmental rasters!"))
  }

  if(inherits(model, c("enmtools.bc", "enmtools.dm"))){
    points <- model$analysis.df
  } else {
    points <- model$analysis.df[model$analysis.df$presence == 1,1:2]
  }

  # Create a vector of names in the right order for plot.df
  names <- layer

  plot.df <- seq(minValue(env[[layer]]), maxValue(env[[layer]]), length = 100)

  for(i in names(env)){
    if(i != layer){
      layer.values <- extract(env[[i]], points)
      plot.df <- cbind(plot.df, rep(mean(layer.values), 100))
      names <- c(names, i)
    }
  }

  plot.df <- data.frame(plot.df)

  colnames(plot.df) <- names

  pred <- predict(model$model, plot.df, type = "response")

  #print(pred)

  response.plot <- qplot(plot.df[,1], pred, geom = "line",
                         xlab = layer, ylab = "Response")

  return(response.plot)

}
