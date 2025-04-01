# R toolbox for exploration of data frames and generation of
# documentation data frames.


# Descriptive statistics for columns of a data frame ---------

#' Descriptive/exploratory statistics for a data frame.
#'
#' @description
#' Function `get_stats()` computes descriptive statistics for columns of a data
#' frame.
#'
#' @details
#' For factors, enumerated character strings and enumerated numerical variables,
#' percentages and counts of observations within the categories are returned
#' along with the total numbers of complete observations.
#' For numerical variables and dates, medians with interquartile ranges and
#' ranges are computed.
#'
#' @return a data frame with the variable names (column `variable`),
#' format (numeric, character, factor, date, column `format`) and descriptive
#' statistics (column `statistic`, see Details).
#'
#' @param x a R data frame.
#' @param variables a character vector with names of the variables to
#' be analyzed. Defaults to all variables in the data frame.
#' @param as_factor should character variables be returned to factors prior
#' to computation of the statistics? Defaults to `TRUE`.
#' @param enum_limit the maximum of unique values of the variables, which turns
#' it into an enumerated variable.
#' @param signif_digits number of significant digits used for rounding of
#' the statistics.
#' @param ... extra arguments, currently none.
#'
#' @export

  get_stats <- function(x,
                        variables = names(x),
                        as_factor = TRUE,
                        enum_limit = 10,
                        signif_digits = 2, ...) {

    ## input control --------

    if(!is.data.frame(x)) stop("'x' has to be a data frame", call. = FALSE)

    stopifnot(is.character(variables))

    if(!all(variables %in% names(x))) {

      stop("Some of the requested variables are absent from 'x'",
           call. = FALSE)

    }

    stopifnot(is.logical(as_factor))

    stopifnot(is.numeric(enum_limit))

    enum_limit <- as.integer(enum_limit[1])

    ## pre-processing --------

    x <- x[variables]

    var_classes <- map_chr(x, ~class(.x)[[1]])

    x <-
      map_dfc(x,
              function(x) {

                if(is.logical(x)) {

                  return(factor(as.character(x), c('TRUE', 'FALSE')))

                } else {

                  return(x)

                }

              })


    x <-
      map_dfc(x,
              function(x) {

                if(!is.factor(x) & n_unique(x) <= enum_limit) {

                  return(factor(x))

                } else {

                  return(x)

                }

              })

    char_variables <- map_lgl(x, is.character)
    fct_variables <- map_lgl(x, is.factor)
    num_variables <- map_lgl(x,
                             function(x) {

                               is.numeric(x) |
                                 inherits(x, 'Date') |
                                 inherits(x, 'POSIXt') |
                                 inherits(x, 'POSIXct') |
                                 inherits(x, 'POSIXlt')

                             })

    ## computation of the stats -------

    fct_metrics <- list()

    if(sum(fct_variables) > 0) {

      fct_metrics <-
        map(x[fct_variables],
            tab,
            type = 'both',
            as_vector = FALSE,
            signif_digits = signif_digits)

      fct_metrics <- set_names(fct_metrics,
                               names(fct_variables)[fct_variables])

    }

    num_metrics <- list()

    if(sum(num_variables) > 0) {

      num_metrics <-
        map(x[num_variables],
            num_stats,
            as_vector = FALSE,
            signif_digits = signif_digits)

      num_metrics <- set_names(num_metrics,
                               names(num_variables)[num_variables])

    }

    char_metrics <- list()

    if(sum(char_variables) > 0) {

      char_metrics <-
        map(x[char_variables],
            ~paste('complete: n =',
                   length(na.omit(.x))))

      char_metrics <- set_names(char_metrics,
                                names(char_variables)[char_variables])

    }

    ## the output -------

    out_df <- c(fct_metrics, num_metrics, char_metrics)

    variables <- droplevels(factor(names(out_df), variables))

    variable <- NULL
    statistic <- NULL
    format <- NULL

    out_df <-
      tibble(variable = variables,
             format = var_classes[variables],
             statistic = as.character(out_df))

    arrange(out_df, variable)

  }


# Documentation for a data frame -------

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
