% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/json.R
\name{write_json_data}
\alias{write_json_data}
\alias{write_json_data.data.frame}
\alias{write_json_data.json_data}
\title{Save lists of JSON data on the disc.}
\usage{
write_json_data(x, path, ...)

\method{write_json_data}{data.frame}(x, path = ".", names_from = NULL, ...)

\method{write_json_data}{json_data}(x, path = ".", ...)
}
\arguments{
\item{x}{a data frame or a list of JSON data objects
(\code{\link{json_data}} object)}

\item{path}{path to the folder where JSON data files will
be saved}

\item{...}{arguments passed to methods and to \code{\link[jsonlite]{toJSON}}}

\item{names_from}{name of a variable in \code{x}, which specifies a unique
identifier used as names of the output list. If \code{names_from = '.rownames'},
row names of x will be used. If \code{names_from = NULL}, the output list will
have no numbers}
}
\value{
returns invisibly a character vector with paths to the JSON
data files.
}
\description{
\verb{write_json´_data()} family methods save the row-wise data frame content or
lists of JSON data objects as a series of JSON files on the disc.
}
\details{
Names of the files are derived from unique identifier column in the input
data frame (specified by \code{names_from} argument). If no identifier
information was provided (\code{names_from = NULL} or unnamed list of JSON
objects), the files will be named with the index numbers.
}
