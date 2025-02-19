# R toolbox for exploration of data frames and generation of
# documentation data frames.

#' Create a backbone documentation for a data frame.
#'
#' @description
#' Creates a documentation table for a R data frame. such documentation table
#' contains [JSON Schema-compatible](https://json-schema.org/) variable types,
#' and, optionally, minimum, maximum and enumeration.
#'
#' @details
#' If `json_num_range = TRUE` for every non-enumerated numeric variable minimum
#' and maximum will be included in the `json_expr` column of the output.
#' The argument `enum_limit` specifies the maximum count of unique values of a
#' variable required to consider it as an enumerated string, number, or integer.
#' These unique values will appear in the `enumeration` column of the output and
#' as `"enum"` key values in the `json_expr` column.
#' Factors are always handled as enumerated integers: the integer value - level
#' assignment in included in the `coding` column of the output.
#' Required columns are inferred with a simple heuristics: if there are no
#' `NA` values in the column, the variable is deemed required.
#' Of note, the `documentation` class data frame returned by the function can
#' be modified by the user just as a very normal data frame. In particular,
#' it is possible to modify and append JSON Schema expressions per hand.
#' See also: \code{\link{build_schema}} functions for building JSON Schemas from
#' `documentation` objects.
#'
#' @return a data frame of class `documentation` with the following columns:
#'
#' * `variable`: unique variable name
#'
#' * `type_r`: variable type compatible R
#'
#' * `enumeration`: unique values of the variable
#'
#' * `coding`: coding for factor levels provided as a string of `value: label`
#' pairs separated by semicolons
#'
#' * `description`: description of a variable, at the moment, it is a copy of
#' `variable` column
#'
#' * `json_expr`: ready-to-use string with variable properties as JSON Schema
#' keyword: value pairs
#'
#' * `required`: a logical indicating if a variable is required
#'
#' @examples
#' create_doc(my_cars)
#'
#' @param x an R data frame
#' @param json_num_range logical, should the minimum and maximum of the numeric
#' variables be included in the JSON properties (`json_expr` column of the
#' output documentation)
#' @param json_date a string that specifies JSON date format, currently either
#' `date-time` (ISO 8601, default) or `date`
#' @param enum_limit the maximum of unique values of the variables, which turns
#' it into an enumerated variable
#' @param ... extra arguments, currently none
#'
#' @export

  create_doc <- function(x,
                         json_num_range = TRUE,
                         json_date = c('date-time', 'date'),
                         enum_limit = 5,
                         ...) {

    ## entry control ---------

    if(!is.data.frame(x)) stop("'x' has to be a data frame.", call. = FALSE)

    stopifnot(is.logical(json_num_range))

    json_date <- match.arg(json_date[1], c('date-time', 'date'))

    if(!is.numeric(enum_limit)) {

      stop("'enum_limit' has to be a numeric value.", call. = FALSE)

    }

    ## JSON schema types -------

    json_types <- c(numeric = '"type": "number"',
                    integer = '"type": "integer"',
                    logical = '"type": "boolean"',
                    factor = '"type": "integer"',
                    character = '"type": "string"',
                    date = paste0('"type": "string", "format": "',
                                  json_date, '"'))

    ## variable names and classes, json type expressions ------

    var_names <- names(x)

    var_classes <- map(x, class)
    var_classes <- map_chr(var_classes, paste, collapse = ', ')

    var_numeric <- map_lgl(var_classes,
                           stri_detect,
                           regex = '^(inte|numer)')

    class_tbl <- tibble(variable = var_names,
                        type = ifelse(stri_detect(var_classes,
                                                  regex = '^dat|POS'),
                                      'date', var_classes))

    class_tbl[['json_expr']] <-
      json_types[class_tbl[['type']]]

    ## minima and maxima of numeric variables --------

    var_min <- map_dbl(x[var_numeric], min, na.rm = TRUE)
    var_max <- map_dbl(x[var_numeric], max, na.rm = TRUE)

    range_tbl <- tibble(variable = var_names[var_numeric],
                        min = var_min,
                        max = var_max)

    ## coding of the factors --------

    level_lst <- compact(map(x, levels)) ## levels for factor variables

    fct_tbl <-
      tibble(variable = names(level_lst),
             coding = map_chr(level_lst, character_coding))

    ## enumeration ---------

    enum_lst <-
      compact(map(x, enumeration_string, enum_limit = enum_limit))

    enum_tbl <-
      tibble(variable = names(enum_lst),
             enumeration = as.character(enum_lst))

    ## checking for required variables ------

    req_vec <- map_lgl(x, ~sum(is.na(.x)) == 0)

    req_tbl <- tibble(variable = names(req_vec),
                      required = req_vec)

    ## formatting of the output frame -------

    out_tbl <-
      reduce(list(class_tbl,
                  range_tbl,
                  fct_tbl,
                  enum_tbl,
                  req_tbl),
             left_join, by = 'variable')

    ### if enumeration is present, minima and maxima are not relevant

    out_tbl[['min']] <-
      ifelse(is.na(out_tbl[['enumeration']]),
             out_tbl[['min']], NA)

    out_tbl[['max']] <-
      ifelse(is.na(out_tbl[['enumeration']]),
             out_tbl[['max']], NA)

    ### inclusion of minimal and maximal values
    ### in the JSON expression column

    if(json_num_range) {

      out_tbl[['json_expr']] <-
        ifelse(is.na(out_tbl[['min']]),
               out_tbl[['json_expr']],
               paste0(out_tbl[['json_expr']],
                      ', "minimum": ', out_tbl[['min']]))

      out_tbl[['json_expr']] <-
        ifelse(is.na(out_tbl[['max']]),
               out_tbl[['json_expr']],
               paste0(out_tbl[['json_expr']],
                      ', "maximum": ', out_tbl[['max']]))

    }

    ### inclusion of enumeration in the the JSON expression

    out_tbl[['json_expr']] <-
      ifelse(is.na(out_tbl[['enumeration']]),
             out_tbl[['json_expr']],
             paste0(out_tbl[['json_expr']],
                    ', "enum": [', out_tbl[['enumeration']], "]"))

    ## output --------

    out_tbl[['type_r']] <- out_tbl[['type']]
    out_tbl[['description']] <- out_tbl[['variable']]

    out_tbl <- out_tbl[, c('variable',
                           'type_r', 'enumeration', 'coding',
                           'description', 'json_expr', 'required')]

    documentation(out_tbl)

  }

# END -------
