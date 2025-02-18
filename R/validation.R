# Vaidation of JSON data listss with JSON Schemes

#' Validate JSON data lists with JSON Schemes.
#'
#' @description
#' `validate_json_data()` methods take a JSON Schema object (an object of class
#' \code{\link{schema}} or \code{\link{schema_string}}) and a
#' \code{\link{json_data}} list of JSON data objects.
#'
#' @details
#' A handy wrapper around \code{\link[jsonvalidate]{json_validate}}.
#' For details, please consult
#' [jsonvalidate manuals](https://docs.ropensci.org/jsonvalidate/articles/jsonvalidate.html).
#' The function will run in parallel if a parallel backend is declared with
#' \code{\link[future]{plan}}. The backend will be closed afterwards.
#'
#' @examples
#' car_documentation <- create_doc(my_cars)
#' car_schema <- build_schema(car_documentation)
#' car_data <- df2json(my_cars, names_from = 'ID')
#' validate_json_data(schema = car_schema, data = car_data)
#'
#' @return a logical vector: `TRUE` stands for positive validation.
#'
#' @param schema JSON Schema: \code{\link{schema}} or
#' \code{\link{schema_string}} object
#' @param data a list of class \code{\link{json_data}} with JSON data objects
#' @param engine validation engine. See:
#' \code{\link[jsonvalidate]{json_validate}} for details
#' @param ... extra arguments passed to methods and
#' \code{\link[jsonvalidate]{json_validate}}
#'
#' @export

  validate_json_data <- function(schema, data, ...) {

    UseMethod('validate_json_data')

  }

#' @rdname validate_json_data
#' @export

  validate_json_data.schema <- function(schema,
                                        data,
                                        engine = 'ajv', ...) {

    ## input control ------

    if(!is_schema(schema)) {

      stop("'schema' must be a 'schema' object", call. = FALSE)

    }

    if(!is_json_data(data)) {

      stop("'data' has to be a 'json_data_object'", call. = FALSE)

    }

    ## validation -------

    schema <- schema2string(schema)

    validate_json_data(schema = schema, data = data, engine = engine, ...)

  }

#' @rdname validate_json_data
#' @export

  validate_json_data.schema_string <- function(schema,
                                               data,
                                               engine = 'ajv', ...) {

    ## input control ------

    if(!is_schema_string(schema)) {

      stop("'schema' must be a 'schema_string' object", call. = FALSE)

    }

    if(!is_json_data(data)) {

      stop("'data' has to be a 'json_data_object'", call. = FALSE)

    }

    ## formatting of the data list ------

    if(is.list(data[[1]])) {

      data <- map(data, toJSON, auto_unbox = TRUE, ...)

    }

    ## exit handler ------

    on.exit(plan('sequential'))

    ## validation --------

    future_map2_lgl(data,
                    schema,
                    json_validate,
                    engine = engine, ...,
                    .options = furrr_options(seed = TRUE))

  }

# END ------
