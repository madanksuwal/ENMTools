#' Takes an emtools.species object with presence and background points, and builds a gam
#'
#' @param formula Standard gam formula
#' @param species An enmtools.species object
#' @param env A raster or raster stack of environmental data.
#' @param test.prop Proportion of data to withhold for model evaluation
#' @param k Dimension of the basis used to represent the smooth term.  See documentation for s() for details.
#' @param ... Arguments to be passed to gam()
#'
#' @export enmtools.gam
#' @export print.enmtools.gam
#' @export summary.enmtools.gam
#' @export plot.enmtools.gam


enmtools.gam <- function(species, env, f = NULL, test.prop = 0, k = 4, ...){

  species <- check.bg(species, env, ...)

  # Builds a default formula using all env
  if(is.null(f)){
    smoothers <- unlist(lapply(names(env), FUN = function(x) paste0("s(", x, ", k = ", k, ")")))
    f <- as.formula(paste("presence", paste(smoothers, collapse = " + "), sep = " ~ "))
  }

  #print(f)

  gam.precheck(f, species, env)

  test.data <- NA
  test.evaluation <- NA

  if(test.prop > 0 & test.prop < 1){
    test.inds <- sample(1:nrow(species$presence.points), ceiling(nrow(species$presence.points) * test.prop))
    test.data <- species$presence.points[test.inds,]
    species$presence.points <- species$presence.points[-test.inds,]
  }

  ### Add env data
  species <- add.env(species, env)

  # Recast this formula so that the response variable is named "presence"
  # regardless of what was passed.
  f <- reformulate(attr(delete.response(terms(f)), "term.labels"), response = "presence")

  analysis.df <- rbind(species$presence.points, species$background.points)
  analysis.df$presence <- c(rep(1, nrow(species$presence.points)), rep(0, nrow(species$background.points)))

  this.gam <- gam(f, analysis.df[,-c(1,2)], family="binomial", ...)

  suitability <- predict(env, this.gam, type = "response")

  model.evaluation <- evaluate(species$presence.points[,1:2], species$background.points[,1:2],
                               this.gam, env)

  if(test.prop > 0 & test.prop < 1){
    test.evaluation <- evaluate(test.data, species$background.points[,1:2],
                                this.gam, env)
  }



  output <- list(formula = f,
                 analysis.df = analysis.df,
                 test.data = test.data,
                 test.prop = test.prop,
                 model = this.gam,
                 training.evaluation = model.evaluation,
                 test.evaluation = test.evaluation,
                 suitability = suitability)

  class(output) <- c("enmtools.gam", "enmtools.model")

  # Doing response plots for each variable.  Doing this bit after creating
  # the output object because plot.response expects an enmtools.model object
  response.plots <- list()

  for(i in names(env)){
    response.plots[[i]] <- plot.response(output, env, i)
  }

  output[["response.plots"]] <- response.plots

  return(output)

}

# Summary for objects of class enmtools.gam
summary.enmtools.gam <- function(this.gam){

  cat("\n\nFormula:  ")
  print(this.gam$formula)

  cat("\n\nData table (top ten lines): ")
  print(kable(head(this.gam$analysis.df, 10)))

  cat("\n\nModel:  ")
  print(summary(this.gam$model))

  cat("\n\ngam.check results:  ")
  print(gam.check(this.gam$model))

  cat("\n\nModel fit (training data):  ")
  print(this.gam$training.evaluation)

  cat("\n\nProportion of data wittheld for model fitting:  ")
  cat(this.gam$test.prop)

  cat("\n\nModel fit (test data):  ")
  print(this.gam$test.evaluation)

  cat("\n\nSuitability:  \n")
  print(this.gam$suitability)
  plot(this.gam)
}

# Print method for objects of class enmtools.gam
print.enmtools.gam <- function(this.gam){

  print(summary(this.gam))

}


# Plot method for objects of class enmtools.gam
plot.enmtools.gam <- function(this.gam){


  suit.points <- data.frame(rasterToPoints(this.gam$suitability))
  colnames(suit.points) <- c("Longitude", "Latitude", "Suitability")

  suit.plot <- ggplot(data = suit.points, aes(y = Latitude, x = Longitude)) +
    geom_raster(aes(fill = Suitability)) +
    scale_fill_viridis(option = "B", guide = guide_colourbar(title = "Suitability")) +
    coord_fixed() + theme_classic() +
    geom_point(data = this.gam$analysis.df[this.gam$analysis.df$presence == 1,], aes(x = Longitude, y = Latitude),
               pch = 21, fill = "white", color = "black", size = 2)

  if(!(all(is.na(this.gam$test.data)))){
    suit.plot <- suit.plot + geom_point(data = this.gam$test.data, aes(x = Longitude, y = Latitude),
                                        pch = 21, fill = "green", color = "black", size = 2)
  }

  return(suit.plot)

}

# Function for checking data prior to running enmtools.gam
gam.precheck <- function(f, species, env){

  # Check to see if the function is the right class
  if(!inherits(f, "formula")){
    stop("Argument \'formula\' must contain an R formula object!")
  }

  ### Check to make sure the data we need is there
  if(!inherits(species, "enmtools.species")){
    stop("Argument \'species\' must contain an enmtools.species object!")
  }

  check.species(species)

  if(!inherits(species$presence.points, "data.frame")){
    stop("Species presence.points do not appear to be an object of class data.frame")
  }

  if(!inherits(species$background.points, "data.frame")){
    stop("Species background.points do not appear to be an object of class data.frame")
  }

  if(!inherits(env, c("raster", "RasterLayer", "RasterStack"))){
    stop("No environmental rasters were supplied!")
  }

  if(ncol(species$presence.points) != 2){
    stop("Species presence points do not contain longitude and latitude data!")
  }

  if(ncol(species$background.points) != 2){
    stop("Species background points do not contain longitude and latitude data!")
  }
}

