# Generation and manipulation of coding schemes from `documentation` objects

#' Coding scheme of variables.
#'
#' @description
#' The function generates a data frame with the variable coding scheme from a
#' \code{\link{documentation}} object or a data frame.
#'
#' @details
#' The coding information is extracted from the `coding` column of the
#' \code{\link{documentation}} object, which contains the a string of
#' `value: label` pairs separated by semicolons.
#'
#'
#' @return a data frame with the following columns:
#'
#' * `variable`: name of the variable
#'
#' * `description`: variable description extracted from the
#' `documentation` object
#'
#' * `value`: value assigned to the variable category
#'
#' * `label`: label of the variable category
#'
#' If the `documentation` object or the data frame has no coding information,
#' the function return `NULL` with a warning.
#'
#' @param x a \code{\link{documentation}} object or a data frame.
#' @param safely logical: should any errors during parsing of the coding
#' strings be ignored? Possible parsing problems are returned as warnings.
#' @param ... extra arguments passed to \code{\link{create_doc}}.
#'
#' @export

  create_coding <- function(x, ...) UseMethod('create_coding')

#' @rdname create_coding
#' @export

  create_coding.documentation <- function(x, safely = FALSE, ...) {

    ## input control ------

    if(!is_documentation(x)) {

      stop("'x' has to be a 'documentation' object", call. = FALSE)

    }

    if(!'coding' %in% names(x)) {

      stop("'x' seems to be a malformed 'documentation' object: no coding found",
           call. = FALSE)

    }

    stopifnot(is.logical(safely))

    coding_present <- na.omit(x[['coding']])

    if(length(coding_present) == 0) {

      warning("No coding found in 'x'", call. = FALSE)

      return(NULL)

    }

    ## processing ---------

    coding <- NULL ## to avoid meta-programming warnings in the package

    x <-
      filter(x[c('variable', 'description', 'coding')],
             !is.na(coding))

    var_fct <- factor(x$variable, x$variable)

    x_lst <- split(x, var_fct)

    descs <- map(x_lst, ~.x[['description']])
    codings <- map(x_lst, ~.x[['coding']])

    codings <- map(codings,
                   parse_coding,
                   as_data_frame = TRUE,
                   safely = safely)

    ## identification of parsing problems -------

    parse_problems <- map_lgl(codings, is.null)

    problem_sum <- sum(parse_problems)

    if(problem_sum > 0) {

      problem_vars <- which(parse_problems)

      problem_vars <- paste(as.character(var_fct)[parse_problems],
                            collapse = ', ')

      warning(paste("There were n =", problem_sum,
                    "parsing problems with the following variables:",
                    problem_vars),
              call. = FALSE)

    }

    ## the output data frame with the coding scheme -----

    variable <- NULL
    description <- NULL
    value <- NULL
    label <- NULL

    coding_lst <-
      pmap(list(x = var_fct,
                y = descs,
                z = codings),
           function(x, y, z) {

             if(is.null(z)) {

               return(NULL)

             } else {

               return(tibble(variable = x,
                             description = y,
                             value = z$value,
                             label = z$label))

             }

           })

    reduce(compact(coding_lst), rbind)

  }

#' @rdname create_coding
#' @export

  create_coding.data.frame <- function(x, safely = FALSE, ...) {

    ## rudimentary input control --------

    if(!is.data.frame(x)) {

      stop("'x' has to be a data frame", call. = FALSE)

    }

    stopifnot(is.logical(safely))

    ## parsing -------

    create_coding(create_doc(x, safely = safely, ...))

  }

# END --------
