# documentation of example data sets

#' `my_cars`: a derivative of the Cars93 Data Set
#'
#' This data set contains information about 93 cars from the 1993 model year.
#' The data includes a variety of variables related to the characteristics,
#' performance, and pricing of the cars.
#'
#' @format A data frame with 93 rows and 31 variables:
#' * `ID`: unique identifier of the car
#' * `Manufacturer`: Manufacturer of the car
#' * `Model`: Model of the car
#' * `Type`: Type of car (e.g., Small, Midsize, Large, etc.)
#' * `Min.Price`: Minimum price of the car in thousands of dollars
#' * `Price`: Midrange price of the car in thousands of dollars
#' * `Max.Price`: Maximum price of the car in thousands of dollars
#' * `MPG.city`: Miles per gallon in city driving
#' * `MPG.highway`: Miles per gallon on the highway
#' * `AirBags`: Type of airbags (None, Driver only, Driver & Passenger)
#' * `DriveTrain`: Type of drivetrain (Rear, Front, 4WD)
#' * `Cylinders`: Number of cylinders
#' * `EngineSize`: Engine size in liters
#' * `Horsepower`: Horsepower of the car
#' * `RPM`: Revolutions per minute at which maximum horsepower is achieved
#' * `Rev.per.mile`: Revolutions per mile
#' * `Man.trans.avail`: Availability of manual transmission (Yes or No)
#' * `Fuel.tank.capacity`: Fuel tank capacity in gallons
#' * `Passengers`: Number of passengers
#' * `Length`: Length of the car in inches
#' * `Wheelbase`: Wheelbase in inches
#' * `Width`: Width of the car in inches
#' * `Turn.circle`: Turning circle in feet
#' * `Rear.seat.room`: Rear seat room in inches
#' * `Luggage.room`: Luggage room in cubic feet
#' * `Weight`: Weight of the car in pounds
#' * `Origin`: Country of origin (USA or non-USA)
#' * `Make`: Manufacturer and model combined provided as string
#' * `Origin_free_text`: a sting version of the `Origin` variable
#' * `Cylinder_number`: number of cylinders specified as an integer
#' * `Entry`: a fictional date of entry in the data set
#'
#' @source
#' \url{https://vincentarelbundock.github.io/Rdatasets/doc/MASS/Cars93.html}
#'
#' @examples
#' data(my_cars)
#' head(my_cars)
#' summary(my_cars)

  "my_cars"

