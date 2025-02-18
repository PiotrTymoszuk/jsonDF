# Construction of SQL tables given JSON Schemas

# tools -------

  library(tidyverse)
  library(jsonDF)

# JSON Schemas --------

  schema_list <- my_cars %>%
    create_doc %>%
    build_schema(id_key = 'my_cars',
                 title_key = 'Automobile models in 1993',
                 description_key = 'A data set of automobile models in 1993',
                 description_extras = 'coding',
                 as_schema = TRUE)


  schema_string <- my_cars %>%
    create_doc %>%
    build_schema(id_key = 'my_cars',
                 title_key = 'Automobile models in 1993',
                 description_key = 'A data set of automobile models in 1993',
                 description_extras = 'coding',
                 as_schema = FALSE)

# SQL statements -------

  sql_create_table <- schema_string %>%
    schema2sql(beautiful = TRUE)

  sql_create_table %>%
    write_file('./inst/sql_statements/my_cars_create_table.txt')

# END ------
