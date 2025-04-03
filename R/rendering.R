# Generation of human friendly documentation in markdown and HTMK format

# Rendering documentation as markdown or HTML code ------

#' Render table documentation as markdown or HTML code chunks.
#'
#' @description
#' Function `render_doc()` generates chunks of Markdown or HTML code based on
#' documentation of variables in R data frames.
#' Such chunks may be easily used to create user-friendly documantation and
#' help pages for the data frame's metadata.
#'
#' @return
#' A data frame of class \code{\link{renDoc}} with the following columns:
#'
#' * `variable` with name of the variable to be documented
#' * `code_type` which indicates the type of generated code (markdown or HTML)
#' * `code` with the markdown or HTML codem with variable documentation
#'
#' See also \code{\link{toDocument.renDoc}} method that can be used to generate
#' ready-to-use Markdown and HTML documents with documentation of the data
#' frame's variables.
#'
#' @param x a data frame or a `documentation` object.
#' @param type type of the generated code: markdown (default) or HTML.
#' @param col_include columns of the \code{\link{documentation}} object to be
#' rendered. By default, i.e. `NULL`, all columns in the documentation object
#' are rendered.
#' @param col_labels labels for the columns \code{\link{documentation}} object
#' which will be displayed as headers in the code. Defaults to `NULL`,
#' which causes the documentation columns `variable`, `type_r`, `enumeration`,
#' `coding`, `description`, `json_expr` and `required` to be displayed as,
#' respectively, 'Variable name', 'Format', 'Enumeration', 'Coding scheme',
#' 'Description', 'JSON Schema rules' and 'Required'.
#' With this default option, any extra columns in the documentation object will
#' get captions corresponding to their plain names.
#' @param heading_levels an integer tuple that defines markdown or HTML heading
#' levels. Defaults to `c(1, 2)`, which means that the caption of the chunk with
#' the variable name will be a `h1` header, and sub-captions will be displayed
#' as `h2` headers.
#' @param ... extra parameters passed to \code{\link{create_doc}} and methods.
#'
#' @export

  render_doc <- function(x, ...) UseMethod('render_doc')

#' @rdname render_doc
#' @export

  render_doc.documentation <- function(x,
                                       type = c('markdown', 'html'),
                                       col_include = NULL,
                                       col_labels = NULL,
                                       heading_levels = c(1, 2), ...) {

    ## input control --------

    if(!is_documentation(x)) {

      stop("'x' has to be a documentation object",
           call. = FALSE)

    }

    type <- match.arg(type[1], c('markdown', 'html'))

    if(is.null(col_include)) col_include <- names(x)

    stopifnot(is.character(col_include))

    if(!all(col_include %in% names(x))) {

      stop(paste("Some of requested column names in 'col_include'",
                 "are missing from 'x'"),
           call. = FALSE)

    }

    if(is.null(col_labels)) col_labels <- col_include

    stopifnot(is.character(col_labels))

    if(length(col_labels) != length(col_include)) {

      stop("Lengths of 'col_labels' and 'col_include' mus be equal",
           call. = FALSE)

    }

    if(!is.numeric(heading_levels) | length(heading_levels) < 2) {

      stop(paste("'heading_levels' has to be a numeric vector with",
                 "at least two elements"),
           call. = FALSE)

    }

    ## column labels and formats -------

    default_labels <-
      c(variable = 'Variable name',
        type_r = 'Format',
        enumeration = 'Enumeration',
        coding = 'Coding scheme',
        description = 'Description',
        json_expr = 'JSON Schema rules',
        required = 'Required')

    col_labels <-
      ifelse(col_labels %in% names(default_labels),
             unname(default_labels[col_labels]),
             col_labels)

    col_formats <-
      ifelse(col_include %in% c('json_expr', 'coding'),
             'inline.code', 'plain')

    var_names <- x$variable

    x <- set_names(x, col_labels)

    ## generating the code --------

    if(type == 'markdown') ren_fun = row2markdown else ren_fun = row2html

    code_str <-
      map_chr(1:nrow(x),
              function(idx) ren_fun(x[idx, , drop = FALSE],
                                    format = col_formats,
                                    heading_levels = heading_levels))

    ## the output data frame ------

    variable <- NULL
    code_type <- NULL
    code <- NULL

    renDoc(tibble(variable = var_names,
                  code_type = type,
                  code = code_str))

  }

#' @rdname render_doc
#' @export

  render_doc.data.frame <- function(x,
                                    type = c('markdown', 'html'),
                                    col_include = NULL,
                                    col_labels = NULL,
                                    heading_levels = c(1, 2), ...) {

    ## the entry control is conducted by the downstream function ------

    type <- match.arg(type[1], c('markdown', 'html'))

    doc_obj <- create_doc(x, ...)

    render_doc(doc_obj,
               type = type,
               col_include = col_include,
               col_labels = col_labels,
               heading_levels = heading_levels)

  }

# Single-document variable documentation in markdown or HTML format ---------

#' Markdown and HTML documents with variable documentation.
#'
#' @description
#' `toDocument()` applied to \code{\link{documentation}} or \code{\link{renDoc}}
#' objects, the later created with \code{\link{render_doc}} function, generates
#' ready-to-use markdown or HTML documents with documentation of a data frame's
#' variables. Such markdown or HTML documents may be used e.g. as help pages or
#' fo construction of metadata catalogs.
#'
#' @return
#' `toDocument()` method returns a single character string that represents the
#' entire markdown or HTML document with the variable documentation.
#' If a file path is provided as `file` argument, the document is additionally
#' saved on a disc.
#'
#' @param x a `renDoc` or `documentation` object.
#' @param title a character string to be used as the document's title.
#' @param subtitle a character string to be used as the document's subtitle.
#' @param sep separator between the variable documentation chunks.
#' @param file a optional argument that specifies path of the markdown ('.md')
#' or HTML file ('.html'), or a connection to write to.
#' @param ... additional arguments passed to \code{\link{render_doc}}
#' and methods.
#'
#' @export

  toDocument <- function(x, ...) UseMethod('toDocument')

#' @rdname toDocument
#' @export

  toDocument.renDoc <- function(x,
                                title = 'Variables',
                                subtitle = 'Variable documentation',
                                sep = '<hr>',
                                file = NULL,
                                ...) {

    ## entry control ------

    if(!is_renDoc(x)) stop("'x' has to be a renDoc object", call. = FALSE)

    title <- as.character(title[1])
    subtitle <- as.character(subtitle[1])
    sep <- as.character(sep[1])

    doc_type <- x$code_type[[1]]

    ## construction of a markdown or HTML string ---------

    if(doc_type == 'markdown') {

      head_str <-
        paste0(title, '\n------------\n',
               '_', subtitle, '_',
               '\n<hr>')

      body_str <- paste(x$code, collapse = paste0('\n', sep, '\n\n'))

      out_str <- paste(head_str, body_str, sep = '\n\n')

    } else {

      head_str <- paste0('<head><title>', title, '</title></head>')

      body_str <- paste0('<h1>', title, '</h1>',
                         '<br>',
                         '<p><em>', subtitle, '</em></p>',
                         '<hr>',
                         '<br>')

      chunk_str <- paste(x$code, collapse = paste0('<br>', sep, '<br>'))

      body_str <- paste(body_str, chunk_str, sep = '<br>')

      body_str <- paste0('<body>', body_str, '</body>')

      out_str <- paste(head_str, body_str)

    }

    ## output -------

    if(!is.null(file)) write_file(out_str, file = file)

    out_str

  }

#' @rdname toDocument
#' @export

  toDocument.documentation <- function(x,
                                       title = 'Variables',
                                       subtitle = 'Variable documentation',
                                       sep = '<hr>',
                                       file = NULL,
                                       ...) {

    if(!is_documentation(x)) stop("'x' ha to be a 'documentation' object",
                                  call. = FALSE)

    renDoc_obj <- render_doc(x, ...)

    toDocument(renDoc_obj,
               title = title,
               subtitle = subtitle,
               sep = sep,
               file = file)

  }

# END ------
