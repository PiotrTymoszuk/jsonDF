# functions for tagging and searching the variable documentation

# Adding and removing variable tags, searching by tags -------

#' Display, add, remove, and search variable tags in data frame documentation.
#'
#' @description
#' Non-hierarchical and hierarchical tags are a convenient way to classify
#' metadata e.g. according to their semantics or quality.
#'
#' `show_tags()`, `add_tags()` and `delete_tags()` allow showing, adding and
#' removing user-specified tags of variables selected by one or more logical
#' conditions.
#' For details on storage and modification of tags, please refer to __Details__.
#'
#' `filter_tags()` filters the documentation object by presence of tags.
#'
#' @details
#' Technically, tags are stored as a list of character vectors in the `tags`
#' column of a `documentation` object.
#' Variables whose tags will be modified are selected by logical statements
#' provided via `...` argument of the `show_tags()` ,`add_tags()`, and
#' `delete_tags()` functions.
#' In general, this semantics copies the semantics of
#' \code{\link[dplyr]{filter}}.
#' If no statements are provided to `...`, all tags in the `documentation`
#' object are displayed or altered.
#'
#' `filter_tags()` executes full-text search for tags.
#' If `mode = 'any'`, rows are returned, where any of the searching tags
#' specified by `tags` matches the vaiable tags.
#' If `mode = 'all'`, a full march between the `tags` argument and the variable
#' tags is expected.
#'
#' @return a \code{\link{documentation}} object with column `tags` storing
#' character vectors of tags.
#'
#' @param x a `documentation` object.
#' @param tags a character vector with the tags.
#' @param ... one or more logical statements used for selection of variables in
#' the `documentation` object. See \code{\link[dplyr]{filter}} for details.
#' @param mode full-text search mode for filtering variable tags.
#' See __Details__.
#'
#' @export

  show_tags <- function(x, ...) {

    ## input control -------

    if(!is_documentation(x)) {

      stop("'x' has to be a documentation object", call. = FALSE)

    }

    if(!'tags' %in% names(x)) {

      warning("'x' has no tags", call. = FALSE)

      return(NULL)

    }

    ## filtering and tag retrieval -------

    x_selection <- try(filter(x, ...), silent = TRUE)

    if(inherits(x_selection, 'try-error')) {

      stop(paste('Evaluation error:', x_selection[[1]]), call. = FALSE)

    }

    reduce(x_selection$tags, union)

  }

#' @rdname show_tags
#' @export

  add_tags <- function(x, tags, ...) {

    ## input control -------

    if(!is_documentation(x)) {

      stop("'x' has to be a documentation object", call. = FALSE)

    }

    if(!is.character(tags)) {

      stop("'tags' has to be a character vector", call. = FALSE)

    }

    if(length(tags) == 0) stop("No tags provided", call. = FALSE)

    if(!'tags' %in% names(x)) {

      x[['tags']] <- map(1:nrow(x), function(x) character())

    }

    tibble_class <- is_tibble(x)

    x <- as.data.frame(x)

    if(is.null(rownames(x)) | tibble_class) {

      rownames(x) <- paste0('rw_', 1:nrow(x))

    }

    default_rownames <- rownames(x)

    ## filtering and adding the tags --------

    x_selection <- try(filter(x, ...), silent = TRUE)

    if(inherits(x_selection, 'try-error')) {

      stop(paste('Evaluation error:', x_selection[[1]]), call. = FALSE)

    }

    if(nrow(x_selection) == 0) {

      warning('No variables to tag', call. = FALSE)

      return(x)

    }

    x_selection$tags <- map(x_selection$tags, union, tags)

    ## the output documentation object ------

    x_out <- rbind(x_selection,
                   x[!rownames(x) %in% rownames(x_selection), ])

    x_out <- x_out[default_rownames, ]

    x_out <- as_tibble(x_out)

    documentation(x_out)

  }

#' @rdname show_tags
#' @export

  delete_tags <- function(x, tags, ...) {

    ## input control -------

    if(!is_documentation(x)) {

      stop("'x' has to be a documentation object", call. = FALSE)

    }

    if(!is.character(tags)) {

      stop("'tags' has to be a character vector", call. = FALSE)

    }

    if(length(tags) == 0) stop("No tags provided", call. = FALSE)

    if(!'tags' %in% names(x)) {

      warning("'x' has no tags", call. = FALSE)

      return(x)

    }

    tibble_class <- is_tibble(x)

    x <- as.data.frame(x)

    if(is.null(rownames(x)) | tibble_class) {

      rownames(x) <- paste0('rw_', 1:nrow(x))

    }

    default_rownames <- rownames(x)

    ## filtering and adding the tags --------

    x_selection <- try(filter(x, ...), silent = TRUE)

    if(inherits(x_selection, 'try-error')) {

      stop(paste('Evaluation error:', x_selection[[1]]), call. = FALSE)

    }

    if(nrow(x_selection) == 0) {

      warning('No variables to tag', call. = FALSE)

      return(x)

    }

    x_selection$tags <- map(x_selection$tags, setdiff, tags)

    ## the output documentation object ------

    x_out <- rbind(x_selection,
                   x[!rownames(x) %in% rownames(x_selection), ])

    x_out <- x_out[default_rownames, ]

    x_out <- as_tibble(x_out)

    documentation(x_out)

  }

#' @rdname show_tags
#' @export

  filter_tags <- function(x, tags, mode = c('any', 'all')) {

    ## input control -------

    if(!is_documentation(x)) {

      stop("'x' has to be a documentation object", call. = FALSE)

    }

    if(!is.character(tags)) {

      stop("'tags' has to be a character vector", call. = FALSE)

    }

    if(length(tags) == 0) stop("No tags provided", call. = FALSE)

    if(!'tags' %in% names(x)) {

      warning("'x' has no tags", call. = FALSE)

      return(x)

    }

    mode <- match.arg(mode[1], c('any', 'all'))

    ## filtering -------

    if(mode == 'any') {

      ft_vec <- map_lgl(x$tags, ~any(tags %in% .x))

    } else {

      ft_vec <- map_lgl(x$tags, ~all(tags %in% .x))

    }

    x[ft_vec, ]

  }

# END ------
