% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/classes.R
\name{documentation}
\alias{documentation}
\alias{as_documentation}
\alias{as_documentation.data.frame}
\alias{is_documentation}
\title{\code{documentation} objects with variable documentation and validation information.}
\usage{
documentation(x, ...)

as_documentation(x, ...)

\method{as_documentation}{data.frame}(x, ...)

is_documentation(x)
}
\arguments{
\item{x}{an input data frame.}

\item{...}{extra arguments passed to \code{\link{documentation}} and methods.}
}
\value{
a data frame of class \code{documentation} with the columns specified in
\strong{Details} and, optionally, user-defined columns.
}
\description{
\code{documentation} data frames are special objects that contain documentation
of variables and variable properties in form of
\href{https://json-schema.org/}{JSON Schema} expressions that
can be easily used for generation of fully-fledged JSON Schema used for
validation e.g, with \code{\link[jsonvalidate]{json_validate}}.
}
\details{
The input data frame has to have the following columns:
\itemize{
\item \code{variable}: unique variable names
\item \code{enumeration}: unique values of the variable
\item \code{coding}: coding for factor levels provided as a string of
\code{value: label} pairs separated by semicolons
\item \code{description}: description of a variable
\item \code{json_expr}: ready-to-use variable properties as JSON Schema
keyword: value pairs
\item \code{required}: a logical that specifies if a variable is required
}

Other, user-defined columns are possible.
The object inherits from \code{data.frame} and can be easily manipulated with the
\code{tidyverse} environment.
See also:
\itemize{
\item \code{\link{create_doc}} for a \code{documentation} generating function.
}
}
