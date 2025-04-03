# Generation of JSON data lists and data strings with data from a data frame

# JSON data lists from a data frame --------

#' Row-wise JSON data lists and JSON data strings from a data frame.
#'
#' @description
#' Function `df2json` Converts a data frame into a list of JSON data stings or
#' JSON data lists in a row-wise manner, i.e. each element of the output list
#' represents a row of the data frame.
#'
#' @details
#' The function will run in parallel if a parallel backend is declared with
#' \code{\link[future]{plan}}. The backend will be closed afterwards.
#'
#' @examples
#' df2json(my_cars, names_from = 'ID')
#'
#'
#' @return a list of class \code{\link{json_data}} with JSON data strings or
#' JSON data lists.
#'
#' @param x a data frame
#' @param names_from name of a variable in `x`, which specifies a unique
#' identifier used as names of the output list. If `names_from = '.rownames'`,
#' row names of x will be used. If `names_from = NULL`, the output list will
#' have no numbers
#' @param as_list logical, should JSON data lists be returned?
#' If `as_list = FALSE`, a list of JSON data strings is returned
#' @param json_factor specifies how factors of the data frame will be saved
#' in JSON data objects; by default as integers
#' @param json_date a string that specifies JSON date format, currently either
#' `date-time` (ISO 8601, default) or `date`
#' @param ... arguments passed to \code{\link[jsonlite]{toJSON}}
#'
#' @export

  df2json <- function(x,
                      names_from = NULL,
                      json_factor = c('integer', 'string'),
                      json_date = c('date-time', 'date'),
                      as_list = FALSE, ...) {

    ## input control -------

    if(!is.data.frame(x)) {

      stop("'x' has to be a data frame", call. = FALSE)

    }

    idx <- 1:nrow(x)

    if(!is.null(names_from)) {

      if(names_from == '.rownames') {

        if(is.null(rownames(x))) stop("'x' has no rownames", call. = FALSE)

        name_vec <- rownames(x)

      } else {

        names_from <- as.character(names_from[1])

        if(!names_from %in% names(x)) {

          stop("'names_from' does not match any of variables in 'x'",
               call. = FALSE)

        }

        name_vec <- x[[names_from]]

        if(sum(duplicated(name_vec)) > 0) {

          stop('Names of the JSON objects must be unique', call. = FALSE)

        }

      }

      idx <- set_names(idx, name_vec)

    }

    json_factor <- match.arg(json_factor[1], c('integer', 'string'))

    json_date <- match.arg(json_date[1], c('date-time', 'date'))

    stopifnot(is.logical(as_list))

    ## handling of the factors and dates -------

    if(json_factor == 'integer') {

      x <-
        map_dfc(x, function(x) if(is.factor(x)) as.integer(x) else x)

    }

    if(json_date == 'date-time') {

      x <-
        map_dfc(x, function(x) if(check_date(x)) format_ISO8601(x) else x)

    }

    ## exit handlers -------

    on.exit(plan('sequential'))

    ## JSON string generation --------

    json_lst <- future_map(idx,
                           row2json,
                           x = x,
                           as_list = as_list,
                           ...,
                           .options = furrr_options(seed = TRUE))

    json_data(json_lst)

  }

# Saving lists of JSON data on the disc -------

#' Save lists of JSON data on the disc.
#'
#' @description
#' `write_json´_data()` family methods save the row-wise data frame content or
#' lists of JSON data objects as a series of JSON files on the disc.
#'
#' @details
#' Names of the files are derived from unique identifier column in the input
#' data frame (specified by `names_from` argument). If no identifier
#' information was provided (`names_from = NULL` or unnamed list of JSON
#' objects), the files will be named with the index numbers.
#'
#' @return returns invisibly a character vector with paths to the JSON
#' data files.
#'
#' @param x a data frame or a list of JSON data objects
#' (\code{\link{json_data}} object)
#' @param path path to the folder where JSON data files will
#' be saved
#' @param names_from name of a variable in `x`, which specifies a unique
#' identifier used as names of the output list. If `names_from = '.rownames'`,
#' row names of x will be used. If `names_from = NULL`, the output list will
#' have no numbers
#' @param ... arguments passed to methods and to \code{\link[jsonlite]{toJSON}}
#'
#' @export

  write_json_data <- function(x, path, ...) UseMethod('write_json_data')

#' @rdname write_json_data
#' @export

  write_json_data.data.frame <- function(x,
                                         path = '.',
                                         names_from = NULL, ...) {

    ## input control -------

    if(!is.data.frame(x)) stop("'x' has to be a data frame", call. = FALSE)

    ## validity of other arguments is controlled by a downstream functions

    ## JSON data list ------

    json_lst <-
      df2json(x = x, names_from = names_from, as_list = FALSE, ...)

    write_json_data(json_lst)

  }

#' @rdname write_json_data
#' @export

  write_json_data.json_data <- function(x,
                                        path = '.', ...) {

    ## input control -------

    if(!is_json_data(x)) {

      stop("'x' has to be a 'json_data' object", call. = FALSE)

    }

    path <- path[1]

    stopifnot(is.character(path))

    if(!dir.exists(path)) stop("'path' does not exist", call. = FALSE)

    ## serialization of a list (optional) ------

    if(is.list(x[[1]])) {

      x <- map(x, toJSON, auto_unbox = TRUE, ...)

    }

    ## file names -------

    if(is.null(names(x))) {

      file_names <- as.character(seq_along(x))

    } else {

      file_names <- names(x)

    }

    file_names <- map_chr(file_names, ~paste0(.x, '.json'))

    file_paths <- paste(path, file_names, sep = '/')

    walk2(x, file_paths, write_file)

    invisible(file_paths)

  }

# END -------
