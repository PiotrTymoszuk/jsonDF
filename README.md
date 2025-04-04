# jsonDF
Metadata management and conversions Between R Data Frames, JSON Schemas, JSON data files, and markdown/HTML/SQL code

## Summary 

Metadata management is getting increasingly important also for data analysts, statisticians, and bioinformaticians. 
Documenting of data frames and variables as well as validation of data frame's records are crucial for efficient handling of metadata in your analysis pipelines. 

The `jsonDF` package facilitates generation of documentation of variables in R data frames, their validation via [JSON Schemas](https://json-schema.org/), and conversion between data frames and JSON data files. 
Tools for rendering variable documentation as markdown and HTML files accessible to your collaborators and customers are provided as well. 

## Remarks

The `data.frame` - `JSON` - `JSON Schema`, `data.frame` - `documentation` - `documentation Markdowm/HTML` conversion tools are more or less ready. 
Working on SQL code generators given variable documentation of a JSON Schema. 

## Terms of use

The package is available under a [GPL-3 license](https://github.com/PiotrTymoszuk/fastTest/blob/main/LICENSE). 
The package is being developed in collaboration with [Health Data Research Hub at the Medical University of Innsbruck](https://www.i-med.ac.at/forschung/Forschungsdatenmanagement/Forschungsdatenmanagement.html).

## Contact

The package maintainer is [Piotr Tymoszuk](mailto:piotr.s.tymoszuk@gmail.com).

## Basic usage

To demonstrate basic functions of the package, a derivative of the `Cars93` data set from `MASS` package will be used. 
The data set comes as a data frame together with our `jsonDF` package. 
In addition, the `tidyverse` package bundle and the`stringi` package will be used for operations on data frames and text. 
Package `furrr` will parallelize some validation steps.

```r 

  library(tidyverse)
  library(stringi)

  library(jsonDF)

  library(furrr)
  
```

```
>   my_cars[1:5, 1:5]

# A tibble: 5 × 5
  ID            Manufacturer Model   Type    Min.Price
  <chr>         <chr>        <chr>   <fct>       <dbl>
1 Acura_Integra Acura        Integra Small        12.9
2 Acura_Legend  Acura        Legend  Midsize      29.2
3 Audi_90       Audi         90      Compact      25.9
4 Audi_100      Audi         100     Midsize      30.8
5 BMW_535i      BMW          535i    Midsize      23.7

```

### Exploratory analysis, documentation of variables in a data frame, and coding schemes for enumerated features

<details>

#### Exploratory analysis

To obtain basic descriptive statistics of numeric, logical, factor, and character variables in the data frame, `get_stat()` function is called. 
For numeric and date variables, the function computes medians with interquartile ranges (IQR) and ranges. 
For enumerated variables, i.e. variables with fixed categories, percentages of complete observations and counts of records in the category are returned. 

Of note, factors are always regarded as enumerated variables, whose categories correspond to factor's levels and internally coded as integers. 
Following the R's convention, the first level is coded as 1, the second as 2 and so on. 
`enum_limit` argument specifies if and how non-factor variables with few unique values will be treated. 
For `enum_limit = 7` in the example below, character and numeric variables with no more than seven unique values will be treated as enumerated features. 
This concerns e.g. the variable named `Cylinder_number` and originally specified as a numeric feature.

```r

  car_stats <- my_cars %>%
    get_stats(enum_limit = 7,
              signif_digits = 3)

```

```
> car_stats[1:10, ]

# A tibble: 10 × 3
   variable     format    statistic                                                                                               
   <fct>        <chr>     <chr>                                                                                                   
 1 ID           character "complete: n = 93"                                                                                      
 2 Manufacturer character "complete: n = 93"                                                                                      
 3 Model        character "complete: n = 93"                                                                                      
 4 Type         factor    "Compact: 17.2% (n = 16)\nLarge: 11.8% (n = 11)\nMidsize: 23.7% (n = 22)\nSmall: 22.6% (n = 21)\nSporty…
 5 Min.Price    numeric   "14.7 [IQR: 10.8 to 20.3]\nrange: 6.7 to 45.4\ncomplete: n = 93"                                        
 6 Price        numeric   "17.7 [IQR: 12.2 to 23.3]\nrange: 7.4 to 61.9\ncomplete: n = 93"                                        
 7 Max.Price    numeric   "19.6 [IQR: 14.7 to 25.3]\nrange: 7.9 to 80\ncomplete: n = 93"                                          
 8 MPG.city     integer   "21 [IQR: 18 to 25]\nrange: 15 to 46\ncomplete: n = 93"                                                 
 9 MPG.highway  integer   "28 [IQR: 26 to 31]\nrange: 20 to 50\ncomplete: n = 93"                                                 
10 AirBags      factor    "Driver & Passenger: 17.2% (n = 16)\nDriver only: 46.2% (n = 43)\nNone: 36.6% (n = 34)\ncomplete: n = 9…


```

```
>   car_stats %>% 
+     filter(variable %in% c('Type', 'MPG.city', 'Cylinder_number'))

# A tibble: 3 × 3
  variable        format  statistic                                                                                               
  <fct>           <chr>   <chr>                                                                                                   
1 Type            factor  "Compact: 17.2% (n = 16)\nLarge: 11.8% (n = 11)\nMidsize: 23.7% (n = 22)\nSmall: 22.6% (n = 21)\nSporty…
2 MPG.city        integer "21 [IQR: 18 to 25]\nrange: 15 to 46\ncomplete: n = 93"                                                 
3 Cylinder_number integer "3: 3.26% (n = 3)\n4: 53.3% (n = 49)\n5: 2.17% (n = 2)\n6: 33.7% (n = 31)\n8: 7.61% (n = 7)\ncomplete: …

```

#### Documentation of variables

Documentation of variables of the data frame is generated by calling `create_doc()`. 
The function works basically with every data frame and automatically derives basic information such as range of numeric variables (`json_num_range = TRUE`), format of date features, enumeration and category coding. 
As explained above, by specifying `enum_limit` argument, the user can identify character and numeric variables with a limited numbers of unique values as enumerated features. 

The function's output is a data frame of class `documentation` with the following columns: 

* `variable`: variable name

* `type_r`: type of the variable according to the R's standards, e.g. numeric, character, integer, logical, or factor

* `enumeration`: listing of unique categories for enumerated features

* `coding`: coding of levels of factor variables. The first level corresponds to 1, the second to 2, and so on

* `description`: description of the variables. Without any user's modification, it is simply the variable name

* `json_expr`: basic validation rules for the variable compatible with syntax of [JSON Schema](https://json-schema.org/)

* `required`: a logical value indicating if the variable is required or can be left as NA. By default none of the variables is required

Of note, the documentation object can be modified by the user by adding extra columns or modification of the columns outlined above. 
In the example below, we'll create documentation of the `my_cars` data set and enrich it by providing human-friendly descriptions and information on units. 
By setting `enum_limit = 7`, we intend to treat character and numeric features with no more than seven unique values as enumerated features. 
`json_date = 'date-time'` makes the date to be [ISO 8601 compliant](https://www.iso.org/iso-8601-date-and-time-format.html). 
By specifying `json_num_range = TRUE`, we insert the ranges of numeric variables in the current table into JSON validation rules. 

```r

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

```

The final `documentation` object looks like that: 

```
> car_documentation[1:7, 
+                     c("variable", "type_r", "enumeration", "coding", "description", "unit")]

# A tibble: 7 × 6
  variable     type_r    enumeration      coding                                                        description          unit 
  <chr>        <chr>     <chr>            <chr>                                                         <chr>                <chr>
1 ID           character NA               NA                                                            Unique identifier o… NA   
2 Manufacturer character NA               NA                                                            Manufacturer of the… NA   
3 Model        character NA               NA                                                            Car model            NA   
4 Type         factor    1, 2, 3, 4, 5, 6 1: Compact; 2: Large; 3: Midsize; 4: Small; 5: Sporty; 6: Van Classification of t… NA   
5 Min.Price    numeric   NA               NA                                                            Minimum price        doll…
6 Price        numeric   NA               NA                                                            Average price        doll…
7 Max.Price    numeric   NA               NA                                                            Maximum price        NA  
```

```

> car_documentation[1:7, c("variable", "json_expr")]

# A tibble: 7 × 2
  variable     json_expr                                                  
  <chr>        <chr>                                                      
1 ID           "\"type\": \"string\""                                     
2 Manufacturer "\"type\": \"string\""                                     
3 Model        "\"type\": \"string\""                                     
4 Type         "\"type\": \"integer\", \"enum\": [1, 2, 3, 4, 5, 6]"      
5 Min.Price    "\"type\": \"number\", \"minimum\": 6.7, \"maximum\": 45.4"
6 Price        "\"type\": \"number\", \"minimum\": 7.4, \"maximum\": 61.9"
7 Max.Price    "\"type\": \"number\", \"minimum\": 7.9, \"maximum\": 80"  

```

For your non-programming collaborators or customers, and for presentation purposes, the documentation object can be easily turned into a markdown or HTML document with `toDocument()` function. 
In the example below, we generate simple markdown and HTML files with custom headers (`title` and `subtitle` arguments), line separators between the information chunks for particular variables (`sep = '<hr>'`), and `h2`/`h3` heading levels (`heading_levels = c(2, 3)`).

```r

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

```

Here some screenshots for the rendered markdown and HTML files with the documentation:

<img src="inst/screenshots/documentation_md.PNG" style="width: 50%;" alt="Documentation Markdown">

<br>

<img src="inst/screenshots/documentation_html.PNG" style="width: 50%;" alt="Documentation HTML">

#### Coding schemes and list of values

Many database platforms use tables with a coding schemes for enumerated variables, so called [lists of values (LOV)](https://docs.oracle.com/cd/E95904_01/books/AppsAdmin/working-with-lists-of-values.html), to match labels displayed to the user at the graphical interfaces, reports, and dashboards to the variable values stored in the database. 

Such ready-to-use lists of values can be easily extracted from `documentation` objects by calling `create_coding()` as in the example below for the documentation of the `my_cars` data set.

```r

  car_coding_scheme <- my_cars %>%
      create_coding

```

```
> car_coding_scheme[1:15, ]

# A tibble: 15 × 4
   variable   description value label             
   <fct>      <chr>       <chr> <chr>             
 1 Type       Type        1     Compact           
 2 Type       Type        2     Large             
 3 Type       Type        3     Midsize           
 4 Type       Type        4     Small             
 5 Type       Type        5     Sporty            
 6 Type       Type        6     Van               
 7 AirBags    AirBags     1     Driver & Passenger
 8 AirBags    AirBags     2     Driver only       
 9 AirBags    AirBags     3     None              
10 DriveTrain DriveTrain  1     4WD               
11 DriveTrain DriveTrain  2     Front             
12 DriveTrain DriveTrain  3     Rear              
13 Cylinders  Cylinders   1     3                 
14 Cylinders  Cylinders   2     4                 
15 Cylinders  Cylinders   3     5    
```

</details>

### Creating of JSON Schemas for data frame validation

<details>



</details>

