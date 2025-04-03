# Utilities used for generation of Markdown, HTML, ans SQL code

# formatting utilities ---------

#' Formats of strings in markdown and HTML.
#'
#' @description
#' Italic, bold, bold-italic, and code-style font face in Markdown- and
#' HTML-compatible format.
#'
#' @details
#' Options for `format` argument are:
#' * `'plain'`: plain font face
#' * `'italic'`: italic font face
#' * `'bold'`: bold font face
#' * `'bold.italic'`: bold-italic font face
#' * `'code'`: the content will be displayed as code
#'
#' @param x a character vector
#' @param format see __Details__ for available format options
#' @param div logical, should the elements of `x` be wrapped into `<div>` tags?
#'
#' @return a character vector

  format_markdown <-  function(x,
                               format = c('plain',
                                          'italic',
                                          'bold',
                                          'bold.italic',
                                          'inline.code',
                                          'code')) {

    x <- as.character(x)

    x <- na.omit(x)

    if(length(x) == 0) return(NULL)

    format <- match.arg(format[1],
                        c('plain',
                          'italic',
                          'bold',
                          'bold.italic',
                          'inline.code',
                          'code'))

    tag <- switch(format,
                  plain = '',
                  italic = '_',
                  bold = '__',
                  bold.italic = '***',
                  inline.code = '`',
                  code = '```')

    map_chr(x, ~paste0(tag, .x, tag))

  }

#' @rdname format_markdown

  format_html <- function(x,
                          format = c('plain',
                                     'italic',
                                     'bold',
                                     'bold.italic',
                                     'inline.code',
                                     'code'),
                          div = TRUE) {

    x <- as.character(x)

    x <- na.omit(x)

    if(length(x) == 0) return(NULL)

    stopifnot(is.logical(div))

    format <- match.arg(format[1],
                        c('plain',
                          'italic',
                          'bold',
                          'bold.italic',
                          'inline.code',
                          'code'))

    out_html <-
      switch(format,
             plain = x,
             italic = map_chr(x, ~paste0('<em>', .x, '</em>')),
             bold = map_chr(x, ~paste0('<b>', .x, '</b>')),
             bold.italic = map_chr(x, ~paste0('<b><em>', .x, '</em></b>')),
             inline.code = map_chr(x, ~paste0('<code>', .x, '</code>')),
             code = map_chr(x, ~paste0('<code>', .x, '</code>')))

    if(!div) return(out_html)

    map_chr(out_html, ~paste0('<div>', .x, '</div>'))

  }

# Markdown and HTML chunks for a data frame row -------

#' Markdown and HTML code for a row of a data frame.
#'
#' @description
#' Generates Markdown (`row2markdown()`) or HTML code (`row2html`) for the
#' column names as headers and the column content as paragraphs.
#'
#' @details
#' Intended for internal use.
#'
#' Options for `format` argument are:
#' * `'italic'`: italic font face
#' * `'bold'`: bold font face
#' * `'bold.italic'`: bold-italic font face
#' * `'code'`: the content will be displayed as code
#'
#' @param x a data frame. Only the first row will be processed.
#' @param title text to be displayed as the chunk title. Defaults to the content
#' of the first column of `x`
#' @param format `NULL` or an optional character vector with the length that
#' equals the number of columns in `x` and specifies the formatting of the
#' content. See __Details__ for available formatting options.
#' @param heading_levels an integer tuple that defines markdown or HTML heading
#' levels. Defaults to `c(1, 2)`, which means that the caption of the chunk with
#' the variable name will be a `h1` header, and sub-captions will be displayed
#' as `h2` headers.

  row2markdown <- function(x,
                           title = NULL,
                           format = NULL,
                           heading_levels = c(1, 2)) {


    # the entry control is executed primarily by an upstream function ------

    stopifnot(is.data.frame(x))
    stopifnot(nrow(x) >= 1)
    stopifnot(ncol(x) >= 1)

    x <- x[1, , drop = FALSE]

    if(is.null(title)) title <- x[, 1][[1]]

    stopifnot(is.character(title))

    if(is.null(format)) format <- rep('plain', ncol(x))

    stopifnot(length(format) == ncol(x))

    ## header tags and headers -----

    title_tag <- paste(rep('#', heading_levels[1]), collapse = '')

    sub_tag <- paste(rep('#', heading_levels[2]), collapse = '')

    title_header <- paste(title_tag, title)

    sub_headers <- set_names(paste(sub_tag, names(x)),
                             names(x))

    ## code body -------

    body_paras <-
      pmap(list(x = x,
                format = format),
           format_markdown)

    body_paras <- compact(body_paras)

    sub_headers <- sub_headers[names(body_paras)]

    code_body <-
      map2(sub_headers, body_paras,
           paste, sep = '\n')

    code_body <- paste(code_body, collapse = '\n\n')

    ## the output string -------

    paste(title_header, code_body, sep = '\n\n')

  }

#' @rdname row2markdown

  row2html <- function(x,
                       title = NULL,
                       format = NULL,
                       heading_levels = c(1, 2)) {

    # the entry control is executed primarily by an upstream function ------

    stopifnot(is.data.frame(x))
    stopifnot(nrow(x) >= 1)
    stopifnot(ncol(x) >= 1)

    x <- x[1, , drop = FALSE]

    if(is.null(title)) title <- x[, 1][[1]]

    stopifnot(is.character(title))

    if(is.null(format)) format <- rep('plain', ncol(x))

    stopifnot(length(format) == ncol(x))

    ## header tags and headers -----

    title_header <-
      paste0('<h', heading_levels[1], '>',
             title,
             '</h', heading_levels[1], '>')

    sub_headers <-
      map_chr(names(x),
              ~paste0('<h', heading_levels[2], '>',
                      .x,
                      '</h', heading_levels[2], '>'))

    sub_headers <- set_names(sub_headers, names(x))

    ## code body -------

    body_paras <-
      pmap(list(x = x,
                format = format),
           format_html)

    body_paras <- compact(body_paras)

    sub_headers <- sub_headers[names(body_paras)]

    code_body <-
      map2(sub_headers, body_paras, paste)

    code_body <- paste(code_body, collapse = '<br>')

    ## the output string -------

    paste(title_header, code_body, sep = '<br>')

  }

# END --------
