# General exported ad non-exported utilities

# Tabulation tools -------

#' Tabulate a vector: calculate frequency of elements.
#'
#' @description
#' Function `tab()` computes frequencies and, optionaly, percentages of
#' elements of a vector.
#'
#' @return
#' If `as_vector = TRUE`, the function returns a vector with counts, percentages,
#' or percentages and counts (general form: percentage % (n = )).
#' If `as_vector = FALSE`, the function returns a single string with percentages,
#' counts, and numbers of complete cases.
#'
#' @param x an atomic vector.
#' @param type type of the output: counts, percentages, or percentages and
#' counts. Defaults to counts and is ignored if `as_vector = FALSE`.
#' @param as_vector logical, should a named vector of counts, percentages, or
#' percentages and counts be returned?
#' @param signif_digits number of significant digits to round the percentages.
#' Used only if `as_vector = FALSE` or `type = 'both'`.
#'
#' @export

  tab <- function(x,
                  type = c('counts', 'percents', 'both'),
                  as_vector = TRUE,
                  signif_digits = 2) {

    ## entry checks ----------

    if(!is.atomic(x)) stop("'x' has to be an atomic vector", call. = FALSE)

    type <- match.arg(type[1], c('counts', 'percents', 'both'))

    stopifnot(is.logical(as_vector))

    stopifnot(is.numeric(signif_digits))

    signif_digits <- as.integer(signif_digits)

    ## counts, percentages and both -------

    counts <- table(x)

    counts <- set_names(as.integer(counts), names(counts))

    if(type == 'counts' & as_vector) return(counts)

    percents <- counts/sum(counts) * 100

    if(type == 'percents' & as_vector) return(percents)

    percents <- signif(percents, signif_digits)

    perc_str <-
      map2_chr(percents, counts, ~paste0(.x, '% (n = ', .y, ')'))

    if(type == 'both' & as_vector) return(perc_str)

    ## returning a single string ------

    complete_cases <- sum(counts)

    if(length(counts) == 0) return(paste('complete: n =', complete_cases))

    out_str <- map2_chr(names(counts), perc_str, paste, sep = ': ')

    out_str <- paste(out_str, collapse = '\n')

    paste(out_str, complete_cases, sep = '\ncomplete: n = ')

  }

#' Counts of unique elements in a vector.
#'
#' @description
#' Counts of unique elements in an atomic vector.
#'
#' @return an integer with the number of unique elements.
#'
#' @param x an atomic vector.
#'
#' @export

  n_unique <- function(x) length(table(x))

# Statistics for numeric features and dates ---------

#' Statistics for numeric features and dates.
#'
#' @description
#' The function computes medians, interquartile ranges, and ranges for numeric
#' vectors and dates.
#'
#' @return if `as_vector = TRUE` a numeric vector with the statistics is
#' returned, otherwise a pre-formatted sting with the statistic names
#' and values.
#'
#' @param x a numeric or date (Date, POSIXct, POSIXt, POSIXlt) vector
#' @param as_vector logical, should a named vector of counts, percentages, or
#' percentages and counts be returned?
#' @param signif_digits number of significant digits to round the function's
#' output. Use only if `as_vector = FALSE`
#'
#' @export

  num_stats <- function(x, as_vector = FALSE, signif_digits = 2) {

    ## input control ------

    if(!is.atomic(x)) stop("'x' has to be an atomic vector", call. = FALSE)

    if(!is.numeric(x) &
       !inherits(x, 'Date') &
       !inherits(x, 'POSIXt') &
       !inherits(x, 'POSIXct') &
       !inherits(x, 'POSIXlt')) {

      stop("'x' has to be a numeric or date vector", call. = FALSE)

    }

    stopifnot(is.logical(as_vector))

    stopifnot(is.numeric(signif_digits))

    signif_digits <- as.integer(signif_digits[1])

    all_na <- length(na.omit(x)) == 0

    ## computation of the distribution stats -----

    stats <- quantile(x, c(0.5, 0.25, 0.75, 0, 1), na.rm = TRUE)

    stats <- set_names(stats, c('median', 'Q25', 'Q75', 'min', 'max'))

    if(as_vector) return(stats)

    if(is.numeric(x)) stats <- signif(stats, signif_digits)

    stat_str <- paste0(stats[1], ' [IQR: ', stats[2], ' to ', stats[3], ']',
                       '\nrange: ', stats[4], ' to ', stats[5],
                       '\ncomplete: n = ', length(na.omit(x)))

    stat_str

  }

# Enumeration tools -------

#' Enumerate elements of a character vector.
#'
#' @description
#' Creates a string with enumerated unique elements of the character vector.
#'
#' @param x a character vector.
#'
#' @return
#' a string with the following numbers of elements and the elements of `x`
#' the `number: element` form separated by semicolons

  character_coding <- function(x) {

    if(!is.character(x)) stop("'x' has to be a character.", call. = FALSE)

    unique_vals <- unique(x)

    paste(seq_along(unique_vals),
          unique_vals,
          sep = ": ",
          collapse = "; ")

  }

#' Create enumeration for a numeric vector.
#'
#'@description
#'This function takes a vector and an enumeration limit.
#' If the vector has fewer unique values than the enumeration limit,
#' the function returns the a string of unique values.
#' Otherwise, it returns \code{NULL}. For factor vectors, the enumeration is
#' always returned.
#'
#' @param x an atomic vector.
#' @param enum_limit an integer representing the enumeration limit.
#'
#' @return A string of unique values separated by commas if the length of
#' unique values is less than the enumeration limit, or `NULL` otherwise.

  enumeration_string <- function(x, enum_limit) {

    ## input control --------

    stopifnot(is.atomic(x))
    stopifnot(is.numeric(enum_limit))

    enum_limit <- as.integer(enum_limit)

    stopifnot(enum_limit > 0)

    if(is.factor(x)) {

      new_x <- as.integer(x)

    } else {

      new_x <- x

    }

    ## enumeration -----

    unique_vals <- sort(unique(new_x))

    if(!is.factor(x)) {

      if(length(unique_vals) > enum_limit) {

        return(NULL)

      }

    }

    if(is.character(x)) {

      unique_vals <- map_chr(unique_vals, ~paste0('"', .x, '"'))

    }

    paste(unique_vals, collapse = ', ')

  }

# JSON data tools --------

#' Generate a JSON string from a row (record) of a data frame.
#'
#' @description
#' Converts a row of a data frame with the given index into a JSON string.
#'
#' @param x a data frame
#' @param idx a row index.
#' @param as_list logical, should JSON data lists be returned?
#' If `as_list = FALSE`, a list of JSON data strings is returned.
#' @param ... arguments passed to \code{\link[jsonlite]{toJSON}}.
#'
#' @return a JSON string generated by \code{\link[jsonlite]{toJSON}}

  row2json <- function(x, idx, as_list = FALSE, ...) {

    ## type control is realized by the upstream exported function

    stopifnot(is.numeric(idx))

    idx <- as.integer(idx)

    if(idx < 0 | idx > nrow(x)) {

      stop("'idx' row index beyond the data range", call. = FALSE)

    }

    ## an unboxed JSON data string

    json_str <- toJSON(x[idx, , drop = FALSE], ...)

    json_str <-
      stri_replace_all(json_str, regex = '(^\\[)|(\\]$)', replacement = '')

    if(!as_list) return(json_str)

    parse_json(json_str)

  }

# Dates ---------

#' Check if a vector contains dates.
#'
#' @description
#' checks if a vector consists of dates.
#'
#' @param x a vector
#'
#' @return a logical value.

  check_date <- function(x) {

    inherits(x, 'Date') |
      inherits(x, 'POSIXct') |
      inherits(x, 'POSIXt')

  }

# Extractors for coding strings ----------

#' Coding scheme from a coding string.
#'
#' @description
#' The function takes a single character string of `value: label` pairs
#' separated by semicolons and returns a list of `c(value, label)` tuples or
#' a data frame with `value` and `label` columns.
#'
#' @details
#' `value` is considered as a usually numeric value returned at the data base
#' side, while `label` is meant as the label presented at the user's interface
#' (for example in forms and views).
#'
#' @return a list of `c(value, label)` tuples or a data frame with
#' `value` and `label` columns.
#'
#' @param x a character string as described in __Description__.
#' @param as_data_frame logical: a data frame output?
#' @param safely logical. If `safely = TRUE`, the function returns `NULL`
#' with a warning if any parsing errors are encountered. Otherwise, an
#' error is raised.
#'
#' @export

  parse_coding <- function(x,
                           as_data_frame = FALSE,
                           safely = FALSE) {

    ## input control ------

    stopifnot(is.character(x))

    if(length(x) > 1) {

      warning("Only the first element of 'x' will be processed",
              call. = FALSE)

      x <- x[[1]]

    }

    stopifnot(is.logical(as_data_frame))
    stopifnot(is.logical(safely))

    ## processing the string -------

    x_lst <- stri_split_regex(x, pattern = ';\\s{0,999}')[[1]]

    x_lst <- stri_split_regex(x_lst, pattern = ':\\s{0,999}')

    x_lens <- map_dbl(x_lst, length)

    if(any(x_lens != 2)) {

      error_cat <- which(x_lst != 2)

      if(!safely) {

        stop(paste('Parsing errors for the', error_cat, 'category'),
             call. = FALSE)

      } else {

        warning(paste('Parsing problems for the', error_cat,
                      'category. NULL is returned'),
                call. = FALSE)

        return(NULL)

      }

    }

    x_lst <- map(x_lst, set_names, c('value', 'label'))

    if(!as_data_frame) return(x_lst)

    as.data.frame(reduce(x_lst, rbind))

  }

# END ------
