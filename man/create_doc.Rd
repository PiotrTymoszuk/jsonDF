% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/exploration.R
\name{create_doc}
\alias{create_doc}
\title{Create a backbone documentation for a data frame.}
\usage{
create_doc(
  x,
  json_num_range = TRUE,
  json_date = c("date-time", "date"),
  enum_limit = 5,
  ...
)
}
\arguments{
\item{x}{an R data frame}

\item{json_num_range}{logical, should the minimum and maximum of the numeric
variables be included in the JSON properties (\code{json_expr} column of the
output documentation)}

\item{json_date}{a string that specifies JSON date format, currently either
\code{date-time} (ISO 8601, default) or \code{date}}

\item{enum_limit}{the maximum of unique values of the variables, which turns
it into an enumerated variable}

\item{...}{extra arguments, currently none}
}
\value{
a data frame of class \code{documentation} with the following columns:
\itemize{
\item \code{variable}: unique variable name
\item \code{type_r}: variable type compatible R
\item \code{enumeration}: unique values of the variable
\item \code{coding}: coding for factor levels provided as a string of \code{value: label}
pairs separated by semicolons
\item \code{description}: description of a variable, at the moment, it is a copy of
\code{variable} column
\item \code{json_expr}: ready-to-use string with variable properties as JSON Schema
keyword: value pairs
\item \code{required}: a logical indicating if a variable is required
}
}
\description{
Creates a documentation table for a R data frame. such documentation table
contains \href{https://json-schema.org/}{JSON Schema-compatible} variable types,
and, optionally, minimum, maximum and enumeration.
}
\details{
If \code{json_num_range = TRUE} for every non-enumerated numeric variable minimum
and maximum will be included in the \code{json_expr} column of the output.
The argument \code{enum_limit} specifies the maximum count of unique values of a
variable required to consider it as an enumerated string, number, or integer.
These unique values will appear in the \code{enumeration} column of the output and
as \code{"enum"} key values in the \code{json_expr} column.
Factors are always handled as enumerated integers: the integer value - level
assignment in included in the \code{coding} column of the output.
Required columns are inferred with a simple heuristics: if there are no
\code{NA} values in the column, the variable is deemed required.
Of note, the \code{documentation} class data frame returned by the function can
be modified by the user just as a very normal data frame. In particular,
it is possible to modify and append JSON Schema expressions per hand.
See also:
\code{\link{build_schema}} functions for building JSON Schemas from
\code{documentation} objects, and \code{\link{render_doc}} and
\code{\link{toDocument.documentation}} for creating markdown and HTML documents
with variable documentation.
}
\examples{
create_doc(my_cars)

}
