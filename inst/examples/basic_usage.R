# Testing the R toolbox for exploration of data frames and generation of
# documentation data frames

# packages -------

  library(tidyverse)
  library(stringi)

  library(jsonDF)

  library(furrr)

# exploration of the `my_cars` data set -------

  my_cars %>%
    get_stats

# documentation objects and JSON Schemas -------

  ## documentation object enriched with custom information

  car_documentation <- my_cars %>%
    create_doc %>%
    mutate(variable_class = ifelse(stri_detect(variable, regex = 'Price|MPG'),
                                   'affordability', 'other'))

  schema_string <- car_documentation %>%
    build_schema

  schema_json <- car_documentation %>%
    build_schema(as_schema = TRUE)

  ## rendering documentation as markdown or HTML documents

  car_documentation %>%
    toDocument(title = 'Documentation of MyCard data set',
               subtitle = 'Variable lexicon',
               type = 'markdown',
               sep = '<hr>')

  ## or a shortcut

  my_cars %>%
    build_schema(as_json = FALSE)

  ## saving a JSON files with the Schema

  schema_json %>%
    write_schema('./inst/json_schemas/car_json_schema.json')

  ## coding schemes with handling of parsing errors

  car_documentation %>%
    mutate(coding = ifelse(variable == 'Type', 'nonsense', coding)) %>%
    create_coding(safely = TRUE)

  my_cars %>%
    create_coding

# JSON files from data frames ----------

  #plan('multisession')

  ## a JSON data list with factors coded as integers

  json_data_lst <- my_cars %>%
    df2json(names_from = 'ID',
            as_list = TRUE)

  json_data_lst %>%
    write_json_data(path = './inst/json_data')

  ## a JSON data list with factors coded as strings

  json_data_fctstr_lst <- my_cars %>%
    df2json(names_from = 'ID',
            json_factor = 'string',
            as_list = TRUE)

# Validation of JSON data lists with JSON data schemes ---------

  ## validation of JSON data with factors coded as integers: passed

  plan('multisession')

  json_valid_results <-
    validate_json_data(schema = schema_json,
                     json_data_lst)

  ## validation of JSON data with factors coded as strings: failed

  plan('multisession')

  json_valid_fctstr_results <-
    validate_json_data(schema = schema_json,
                       json_data_fctstr_lst)

# END ------
