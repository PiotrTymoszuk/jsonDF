# class constructors, checkers, and coercion functions

# `documentation` class -------

#' `documentation` objects with variable documentation and validation information.
#'
#' @description
#' `documentation` data frames are special objects that contain documentation
#' of variables and variable properties in form of
#' [JSON Schema](https://json-schema.org/) expressions that
#' can be easily used for generation of fully-fledged JSON Schema used for
#' validation e.g, with \code{\link[jsonvalidate]{json_validate}}.
#'
#' @details
#' The input data frame has to have the following columns:
#'
#' * `variable`: unique variable names
#'
#' * `enumeration`: unique values of the variable
#'
#' * `coding`: coding for factor levels provided as a string of
#' `value: label` pairs separated by semicolons
#'
#' * `description`: description of a variable
#'
#' * `json_expr`: ready-to-use variable properties as JSON Schema
#' keyword: value pairs
#'
#' * `required`: a logical that specifies if a variable is required
#'
#' Other, user-defined columns are possible.
#' The object inherits from `data.frame` and can be easily manipulated with the
#' `tidyverse` environment.
#' See also:
#' * \code{\link{create_doc}} for a `documentation` generating function.
#'
#' @return a data frame of class `documentation` with the columns specified in
#' __Details__ and, optionally, user-defined columns.
#'
#' @param x an input data frame.
#' @param ... extra arguments passed to \code{\link{documentation}} and methods.
#'
#' @export

  documentation <- function(x, ...) {

    ## input control -------

    if(!is.data.frame(x)) stop("'x' has to be a data frame", call. = FALSE)

    if(!all(c('variable',
              'enumeration',
              'coding',
              'description',
              'json_expr',
              'required') %in% names(x))) {

      stop(paste("At least one of 'variable', 'enumeration', 'coding',",
                 "'description', 'json_expr', or 'required' is missing",
                 "from the data frame 'x'"),
           call. = FALSE)

    }

    if(sum(duplicated(x[['variable']])) > 0) {

      stop("Duplicated variable names ('variable' column of 'x') not allowed",
           call. = FALSE)

    }

    coding_present <- na.omit(x[['coding']])

    if(length(coding_present > 0)) {

      if(any(!stri_detect(coding_present, fixed = ':'))) {

        stop(paste("Malformed coding detected. `value: label` pairs",
                   "separated by semicolons are required"),
             call. = FALSE)

      }

    }

    ## structure -------

    structure(x, class = c('documentation', class(x)))

  }

#' @rdname documentation
#' @export

  as_documentation <- function(x, ...) UseMethod('as_documentation')

#' @rdname documentation
#' @export

  as_documentation.data.frame <- function(x, ...) {

    documentation(x, ...)

  }

#' @rdname documentation
#' @export

  is_documentation <- function(x) inherits(x, 'documentation')

# `schema_sting` class --------

#' JSON Schema strings.
#'
#' @description
#' Creates an instance of `schema_string`: a string that contains a complete
#' minimal [JSON Schema](https://json-schema.org/).
#'
#' @details
#' See \code{\link{write_schema}} for a function for saving the JSON Schema
#' string as a JSON file on the disc.
#'
#' @return a string of class `json_schema`.
#'
#' @param x a string.
#' @param ... extra arguments, currently none.
#'
#' @export

  schema_string <- function(x, ...) {

    ## input control: a minimalist one at the moment, in progress --------

    if(!is.character(x)) {

      stop("'x' has to ba a character string", call. = FALSE)

    }

    ## structure -------

    structure(x, class = 'schema_string')

  }

#' @rdname schema_string
#' @export

  is_schema_string <- function(x) inherits(x, 'schema_string')

# `schema` class ---------

#' JSON Schema lists.
#'
#' @description
#' Creates an instance of `schema` class, which is a minimal representation of
#' a [JSON Schema](https://json-schema.org/).
#'
#' @details
#' The function returns a list with the following elements:
#'
#' * `$schema`: reference to the [JSON Schema](https://json-schema.org/) version
#' used by validator functions; this is a part of the JSON Schema header
#'
#' * `$id`: an object id, usually an identifier of a table or a project; this
#' is a part of the JSON Schema header
#'
#' * `title`: a title of the schema, usually a title of a table or a project;
#' this is a part of the JSON Schema header
#'
#' * `description`: a description of the schema, usually a description of a
#' table or a project; his is a part of the JSON Schema header
#'
#' * `type`: the value of the `type` keyword in the JSON Schema header; usually
#' set to `"type": "object"`
#'
#' * `properties`: a list of variable properties such as type, enumeration,
#' description, minimum, maximum, and so on
#'
#' * `required`: an optional element which specifies the required variables
#'
#' See \code{\link{write_schema}} for a function for saving the JSON Schema
#' list as a JSON file on the disc.
#'
#' @return a list of class `schema` with the elements specified in Details.
#'
#' @param x a list with elements specified in Details.
#' @param ... extra arguments, currently none.
#'
#' @export

  schema <- function(x, ...) {

    ## input checks --------

    if(!is.list(x)) stop("'x' has to be list", call. = FALSE)
    if(is.null(names(x))) stop("'x' has to be a named list", call. = FALSE)

    req_elements <- c('$schema', '$id', 'title', 'type', 'properties')

    req_string <- map_chr(req_elements, ~paste0("'", .x, "'"))

    req_string <- paste(req_string, collapse = ', ')

    if(!all(req_elements %in% names(x))) {

      stop(paste("At least one of the required elements is missing.",
                 "The required elements are:", req_string),
           call. = FALSE)

    }

    if(!is.list(x$properties)) {

      stop("The 'properties' element of 'x' has to be a list.", call. = FALSE)

    }

    if(is.null(names(x$properties))) {

      stop("The 'properties' element of 'x' has to be a named list.",
           call. = FALSE)

    }

    var_names <- names(x$properties)

    if(!is.null(x$required)) {

      if(!is.character(x$required)) {

        stop("The 'required' element of 'x' has to be a character vector.",
             call. = FALSE)

      }

      if(!all(x$required %in% names(x$properties))) {

        stop(paste("Some of variables specified as",
                   "required are missing from the schema"),
             call. = FALSE)

      }

    }

    ## structure ---------

    structure(x,
              class = 'schema')

  }

#' @rdname schema
#' @export

  is_schema <- function(x) inherits(x, 'schema')

# `json_data` class ---------

#' JSON data list.
#'
#' @description
#' A container list for JSON data strings or lists.
#'
#' @return a list of JSON data strings or JSON data lists.
#'
#' @param x a list with JSON data strings of JSON lists.
#' @param ... extra arguments, currently none.
#'
#' @export

  json_data <- function(x, ...) {

    ## at the moment only a rudimentary input control ------

    if(!is.list(x)) stop("'x' has to be list", call. = FALSE)

    ## structure -------

    structure(x, class = 'json_data')

  }

#' @rdname json_data
#' @export

  is_json_data <- function(x) inherits(x, 'json_data')

# `renDoc` class --------

#' `renDoc` objects holding markdown or HTML chunks with variable documentation.
#'
#' @description
#' `renDoc` class objects are generated by \code{\link{render_doc}} function
#' and hold markdown or HTML code with documentation of variables of a R data
#' frame.
#'
#' @details
#' `renDoc` objects are data frames with the following columns:
#'
#' * `variable` with name of the variable to be documented
#' * `code_type` which indicates the type of generated code (markdown or HTML)
#' * `code` with the markdown or HTML code with variable documentation
#'
#' `renDoc` data frames can be transformed like usual data frames.
#' See also \code{\link{toDocument.renDoc}} method that can be used to generate
#' ready-to-use Markdown and HTML documents with documentation of the data
#' frame's variables.
#'
#' @return
#' A data fame with of class `renDoc` with columns described in __Details__.
#'
#' @param x a data frame with the with columns described in __Details__.
#' @param ... extra arguments, currently none.

  renDoc <- function(x, ...) {

    ## entry control -------

    if(!is.data.frame(x)) stop("'x' has to ba a data frame", call. = FALSE)

    if(!all(c('variable', 'code_type', 'code') %in% names(x))) {

      stop("'x' has to have 'variable', 'code_type', and 'code' columns",
           call. = FALSE)

    }

    if(any(!x$code_type %in% c('markdown', 'html'))) {

      stop('Unrecognized code type', call. = FALSE)

    }

    ## the structure ---------

    structure(x, class = c('renDoc', class(x)))

  }

#' @rdname renDoc

  is_renDoc <- function(x) inherits(x, 'renDoc')

# END -------
