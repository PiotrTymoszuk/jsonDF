# Non-exported utils for generation of SQL code

# Mapping of JSON Schema types to SQL variable types -------

#' Map JSON Schema variable types to SQL data types.
#'
#' @description
#' Maps the JSON Schema variable types to SQL data types.
#'
#' @return a string with the SQL data type.
#'
#' @param type a character string with the JSON Data type.
#' @param char_size size of th character strings

  mapDataType <- function(type, char_size = 255) {

    stopifnot(is.character(type))

    switch(type,
           "string" = paste0("VARCHAR(", char_size, ")"),
           "integer" = "INTEGER",
           "number" = "DOUBLE",
           "boolean" = "BOOLEAN",
           "date-time" = "TIMESTAMP",
           "date" = "DATE",
           stop("Unsupported data type"))

  }

# Turning variable properties into SQL expressions ---------

#' Convert JSON Schema variable properties to column-defining SQL expressions.
#'
#' @description
#' Takes variable properties specified within the `properties` key of a
#' JSON Schema and turns them into SQL expressions that define a table column.
#'
#' @return a string with SQL expressions that define table columns.
#'
#' @param x a list of variable (column) properties corresponding to the
#' JSON Schema key: value pairs.
#' @param name variable name.
#' @param required a character vector with names of required variables
#' @param char_size size of th character strings

  mapColSpecs <- function(x, name, required = NULL, char_size = 255) {

    ## input control -------

    stopifnot(is.list(x))
    stopifnot(is.character(name))

    if(!is.null(required)) {

      stopifnot(is.character(required))

    }

    stopifnot(is.numeric(char_size))

    char_size <- as.integer(char_size[1])

    ## data types --------

    type <- x$type

    sqlType <- mapDataType(type)

    ## Handle enumerated values -------

    if (!is.null(x$enum)) {

      enumValues <- paste(shQuote(x$enum), collapse = ", ")

      sqlType <-
        paste(sqlType,
              "CHECK(", name, "IN (", enumValues, "))")

    }

    ## Handle string length constraints ----------

    if (type == "string") {

      if (!is.null(x$minLength)) {

        sqlType <-
          paste(sqlType,
                "CHECK(LENGTH(", name, ") >=", x$minLength, ")")

      }

      if (!is.null(x$maxLength)) {

        sqlType <-
          paste(sqlType,
                "CHECK(LENGTH(", name, ") <=", x$maxLength, ")")

      }

    }

    ## Handle numeric constraints --------

    if (type %in% c("integer", "number")) {

      if (!is.null(x$minimum)) {

        sqlType <-
          paste(sqlType,
                "CHECK(", name, ">=", x$minimum, ")")

      }

      if (!is.null(x$maximum)) {

        sqlType <-
          paste(sqlType,
                "CHECK(", name, "<=", x$maximum, ")")

      }

      if (!is.null(x$exclusiveMinimum)) {

        sqlType <-
          paste(sqlType,
                "CHECK(", name, ">", x$exclusiveMinimum, ")")

      }

      if (!is.null(x$exclusiveMaximum)) {

        sqlType <-
          paste(sqlType,
                "CHECK(", name, "<", x$exclusiveMaximum, ")")

      }

    }

    # Add NOT NULL for required fields -----

    if (name %in% required) {

      sqlType <- paste(sqlType, "NOT NULL")

    }

    ## Adding variable descriptions --------

    var_desc <- x$description

    if(!is.null(var_desc)) {

      var_desc <- shQuote(var_desc)

      sqlType <-
        paste(sqlType, var_desc, sep = ' COMMENT ')

    }

    ## output --------

    paste(name, sqlType)

  }

# END ------
