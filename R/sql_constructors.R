# Functions taht generate SQL expressions for constructing tables given
# JSON Schema objects (classes `schema` and `schema_string`)

# SQL table construction --------

#' Create a SQL table given a JSON Schema.
#'
#' @description
#' `schema2sql()` methods generate SQL expressions that create a table given
#' a [JSON Schema](https://json-schema.org/).
#'
#' @details
#' The methods are specified for \code{\link{schema}} and
#' \code{\link{schema_string}} objects. Note: tables can be created only from
#' JSON Schemes with a non-empty keyword `$id`; the `$id` keyword serves as the
#' table name.
#'
#' @return a character string containing a `CREATE TABLE` SQL expression.
#'
#' @param x a \code{\link{schema}} or \code{\link{schema_string}} object
#' @param beautiful logical, should line breaks be introduced?
#' @param ... extra arguments passed to methods
#'
#' @export

  schema2sql <- function(x, ...) UseMethod('schema2sql')

#' @rdname schema2sql
#' @export

  schema2sql.schema_string <- function(x, beautiful = TRUE, ...) {

    if(!is_schema_string(x)) {

      stop("'x' has to be a 'schema_string' class object", call. = FALSE)

    }

    stopifnot(is.logical(beautiful))

    x <- string2schema(x)

    schema2sql(x, beautiful, ...)

  }

#' @rdname schema2sql
#' @export

  schema2sql.schema <- function(x, beautiful = TRUE, ...) {

    ## input control -------

    if(!is_schema(x)) {

      stop("'x' has to be a schema object", call. = FALSE)

    }

    if(is.null(x[['$id']]) | x[['$id']] == '') {

      stop("The '$id' keyword of the schema must be a non-empty string",
           call. = FALSE)

    }

    stopifnot(is.logical(beautiful))

    ## SQL table header -------

    tableName <- x[['$id']]

    ## SQL expressions from variable properties ------

    variable_json <- x$properties

    variable_names <- names(variable_json)

    required_variables <- x$required

    variable_sql <-
      pmap(list(x = variable_json,
                name = variable_names),
           mapColSpecs,
           required = required_variables)

    ## the SQL `CREATE TABLE` expression ------

    if(!beautiful) {

      sql_expr <- paste("CREATE TABLE",
                        tableName,
                        "(",
                        paste(variable_sql, collapse = ", "),
                        ");")

    } else {

      sql_expr <- paste("CREATE TABLE",
                        tableName,
                        "(\n",
                        paste(variable_sql, collapse = ",\n"),
                        "\n);")

    }

    sql_expr

  }

# END ---------
