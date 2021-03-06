% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/enmtools.glm.R
\name{enmtools.glm}
\alias{enmtools.glm}
\title{Takes an emtools.species object with presence and background points, and builds a GLM}
\usage{
enmtools.glm(species, env, f = NULL, test.prop = 0, ...)
}
\arguments{
\item{species}{An enmtools.species object}

\item{env}{A raster or raster stack of environmental data.}

\item{test.prop}{Proportion of data to withhold for model evaluation}

\item{...}{Arguments to be passed to glm()}

\item{formula}{Standard GLM formula}
}
\description{
Takes an emtools.species object with presence and background points, and builds a GLM
}

