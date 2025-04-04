# Testing the R toolbox for exploration of data frames and generation of
# documentation data frames

# packages -------

  library(tidyverse)
  library(stringi)

  library(jsonDF)

  library(furrr)

  my_cars[1:5, 1:5]

# exploration of the `my_cars` data set -------

  car_stats <- my_cars %>%
    get_stats(enum_limit = 7,
              signif_digits = 3)

  car_stats[1:10, ]

  car_stats %>%
    filter(variable %in% c('Type', 'MPG.city', 'Cylinder_number'))

# documentation objects -------

  ## documentation object enriched with custom information:
  ## more informative descriptions and units

  car_documentation <- my_cars %>%
    create_doc(json_num_range = TRUE,
               json_date = 'date-time',
               enum_limit = 7) %>%
    mutate(description =
             car::recode(description,
                         "
                         'ID' = 'Unique identifier of the car';
                         'Manufacturer' = 'Manufacturer of the car';
                         'Model' = 'Car model';
                         'Type' = 'Classification of the car as compact, middle, etc.';
                         'Min.Price' = 'Minimum price';
                         'Price' = 'Average price';
                         'Max.Price' = 'Maximum price';
                         'MPG.city' = 'Mileage in city traffic';
                         'MPG.highway' = 'Mileage in highway traffic';
                         'AirBags' = 'Airbag location and numeber';
                         'DriveTrain' = 'Drive transmission';
                         'Cylinders' = 'Cylinder number and assembly';
                         'EngineSize' = 'Engine volume';
                         'Horsepower' = 'Engine power';
                         'RPM' = 'Optimal rotation speed';
                         'Rev.per.mile' = 'Revolutions per mile';
                         'Man.trans.avail' = 'Availability of manual transmission';
                         'Fuel.tank.capacity' = 'Fuel tank capacity';
                         'Passengers' = 'Number of passengers';
                         'Length' = 'Length of the car';
                         'Wheelbase' = 'Wheelbase of the car';
                         'Width' = 'Width of the car';
                         'Turn.circle' = 'Turning circle';
                         'Rear.seat.room' = 'Rear seat room';
                         'Luggage.room' = 'Luggage room';
                         'Weight' = 'Weight of the car';
                         'Origin' = 'Country of origin (USA or non-USA)';
                         'Make' = 'Manufacturer and model combined provided as string';
                         'Origin_free_text' = 'Extra information on the origin of the car';
                         'Cylinder_number' = 'Cylinder number as integer';
                         'Entry' = 'Date of entry into the database'
                         "),
           unit =
             car::recode(variable,
                         "
                         'Min.Price' = 'dollars';
                         'Price' = 'dollars';
                         'Max.price' = 'dollars';
                         'MPG.city' = 'MPG';
                         'MPG.highway' = 'MPG';
                         'EngineSize' = 'liters';
                         'Horsepower' = 'HP';
                         'RPM' = 'RPM';
                         'Rev.per.mile' = 'revolutions per mile';
                         'Fuel.tank.capacity' = 'gallons';
                         'Length' = 'inches';
                         'Wheelbase' = 'inches';
                         'Width' = 'inches';
                         'Turn.circle' = 'feet';
                         'Rear.seat.room' = 'inches';
                         'Luggage.room' = 'cubic feet';
                         'Weight' = 'pounds';
                         "),
           unit = ifelse(unit == variable, NA, unit))

  car_documentation[1:7,
                    c("variable", "type_r", "enumeration", "coding", "description", "unit")]

  car_documentation[1:7, c("variable", "json_expr")]

  ## rendering documentation as markdown or HTML documents

  car_documentation %>%
    toDocument(title = 'Documentation of MyCars data set',
               subtitle = 'Variable lexicon',
               type = 'markdown',
               sep = '<hr>',
               heading_levels = c(2, 3),
               file = 'variable_lexicon.md')

  car_documentation %>%
    toDocument(title = 'Documentation of MyCars data set',
               subtitle = 'Variable lexicon',
               type = 'html',
               sep = '<hr>',
               heading_levels = c(2, 3),
               file = 'variable_lexicon.html')

  ## creating a coding scheme/list-of-values

  car_coding_scheme <- my_cars %>%
    create_coding

# Construction of JSON Schemas -----

  ## creating

  schema_json <- car_documentation %>%
    build_schema(as_schema = TRUE,
                 description_extras = c('coding', 'unit'))

  schema_string <- car_documentation %>%
    build_schema(description_extras = c('coding', 'unit'))

  ## saving a JSON files with the Schema

  schema_json %>%
    write_schema('./inst/json_schemas/car_json_schema.json')

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
