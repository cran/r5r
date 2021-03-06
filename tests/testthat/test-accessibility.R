context("Accessibility function")

# skips tests on CRAN since they require a specific version of java
testthat::skip_on_cran()

# load required data and setup r5r_core

data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path)
points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))

# create testing function

default_tester <- function(r5r_core=r5r_core,
                           origins = points[1:10,],
                           destinations = points[1:10,],
                           opportunities_colname = "schools",
                           decay_function = "step",
                           cutoffs = 30L,
                           decay_value = 1.0,
                           mode = "BICYCLE",
                           departure_datetime = as.POSIXct("13-05-2019 14:00:00",
                                                           format = "%d-%m-%Y %H:%M:%S"),
                           time_window = 1L,
                           percentiles = 50L,
                           max_walk_dist = Inf,
                           max_bike_dist = Inf,
                           max_trip_duration = 120L,
                           walk_speed = 3.6,
                           bike_speed = 12,
                           max_rides = 3,
                           n_threads = Inf,
                           verbose = FALSE) {

  results <- accessibility(
    r5r_core=r5r_core,
    origins = origins,
    destinations = destinations,
    opportunities_colname = opportunities_colname,
    decay_function = decay_function,
    cutoffs = cutoffs,
    decay_value = decay_value,
    mode = mode,
    departure_datetime = departure_datetime,
    time_window = time_window,
    percentiles = percentiles,
    max_walk_dist = max_walk_dist,
    max_bike_dist = max_bike_dist,
    max_trip_duration = max_trip_duration,
    walk_speed = walk_speed,
    bike_speed = bike_speed,
    max_rides = max_rides,
    n_threads = n_threads,
    verbose = verbose
  )

  return(results)

}


# errors and warnings -----------------------------------------------------


test_that("adequately raises errors", {

  # error related to using object with wrong type as r5r_core
  expect_error(default_tester("r5r_core"))

  # error related to using wrong origins/destinations object type
  multipoint_origins      <- sf::st_cast(sf::st_as_sf(points[1:2,], coords = c("lon", "lat")), "MULTIPOINT")
  multipoint_destinations <- multipoint_origins
  list_origins      <- list(id = c("1", "2"), lat = c(-30.02756, -30.02329), long = c(-51.22781, -51.21886))
  list_destinations <- list_origins

  expect_error(default_tester(r5r_core, origins = multipoint_origins))
  expect_error(default_tester(r5r_core, destinations = multipoint_destinations))
  expect_error(default_tester(r5r_core, origins = list_origins))
  expect_error(default_tester(r5r_core, destinations = list_destinations))
  expect_error(default_tester(r5r_core, origins = "origins"))
  expect_error(default_tester(r5r_core, destinations = "destinations"))

  # error/warning related to using wrong origins/destinations column types
  origins <- destinations <- points[1:2, ]

  origins_char_lat   <- data.frame(id = origins$id, lat = as.character(origins$lat), lon = origins$lon)
  origins_char_lon   <- data.frame(id = origins$id, lat = origins$lat, lon = as.character(origins$lon))
  destinations_char_lat   <- data.frame(id = destinations$id, lat = as.character(destinations$lat), lon = destinations$lon)
  destinations_char_lon   <- data.frame(id = destinations$id, lat = destinations$lat, lon = as.character(destinations$lon))

  expect_error(default_tester(r5r_core, origins = origins_char_lat))
  expect_error(default_tester(r5r_core, origins = origins_char_lon))
  expect_error(default_tester(r5r_core, destinations = destinations_char_lat))
  expect_error(default_tester(r5r_core, destinations = destinations_char_lon))

  # error related to nonexistent mode
  expect_error(default_tester(r5r_core, mode = "pogoball"))

  # errors related to date formatting
  numeric_datetime <- as.numeric(as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S"))

  expect_error(default_tester(r5r_core, departure_datetime = "13-05-2019 14:00:00"))
  expect_error(default_tester(r5r_core, numeric_datetime))

  # errors related to max_walk_dist
  expect_error(default_tester(r5r_core, max_walk_dist = "1000"))
  expect_error(default_tester(r5r_core, max_walk_dist = NULL))

  # errors related to max_bike_dist
  expect_error(default_tester(r5r_core, max_bike_dist = "1000"))
  expect_error(default_tester(r5r_core, max_bike_dist = NULL))

    # error/warning related to max_street_time
  expect_error(default_tester(r5r_core, max_trip_duration = "120"))

  # error related to non-numeric walk_speed
  expect_error(default_tester(r5r_core, walk_speed = "3.6"))

  # error related to non-numeric bike_speed
  expect_error(default_tester(r5r_core, bike_speed = "12"))

  # error related to non-numeric max_rides
  expect_error(default_tester(r5r_core, max_rides = "3"))

  # error related to non-numeric n_threads
  expect_error(default_tester(r5r_core, n_threads = "1"))

  # error related to non-logical verbose
  expect_error(default_tester(r5r_core, verbose = "TRUE"))
  expect_error(default_tester(r5r_core, verbose = 1))
  expect_error(default_tester(r5r_core, verbose = NULL))

  # decay_function
  expect_error(default_tester(r5r_core, decay_function = "fixed_exponential"))
  expect_error(default_tester(r5r_core, decay_function = "bananas"))
  expect_error(default_tester(r5r_core, opportunities_colname = "bananas"))
  expect_error(default_tester(r5r_core, cutoffs = "bananas"))
  expect_error(default_tester(r5r_core, decay_value = "bananas"))

})

# test_that("adequately raises warnings - needs java", {
#
#   # error/warning related to using wrong origins/destinations column types
#   origins <- destinations <- points[1:2, ]
#
#   origins_numeric_id <- data.frame(id = 1:2, lat = origins$lat, lon = origins$lon)
#   destinations_numeric_id <- data.frame(id = 1:2, lat = destinations$lat, lon = destinations$lon)
#
#   expect_warning(default_tester(r5r_core, origins = origins_numeric_id))
#   expect_error(default_tester(r5r_core, destinations = destinations_numeric_id))
#
#
# })


# adequate behavior ------------------------------------------------------


test_that("output is correct", {

  # decay functions
  expect_true(is(default_tester(r5r_core, decay_function = "step"), "data.table"))
  expect_true(is(default_tester(r5r_core, decay_function = "exponential"), "data.table"))
  expect_true(is(default_tester(r5r_core, decay_function = "linear"), "data.table"))
  expect_true(is(default_tester(r5r_core, decay_function = "logistic"), "data.table"))
  expect_true(is(default_tester(r5r_core, decay_function = "fixed_exponential", decay_value=.4), "data.table"))





  #  * output class ---------------------------------------------------------


  # expect results to be of class 'data.table', independently of the class of
  # 'origins'/'destinations'

  origins_sf <- destinations_sf <-  sf::st_as_sf(points[1:10,], coords = c("lon", "lat"))

  result_df_input <- default_tester(r5r_core)
  result_sf_input <- default_tester(r5r_core, origins_sf, destinations_sf)

  expect_true(is(result_df_input, "data.table"))
  expect_true(is(result_sf_input, "data.table"))

  # expect each column to be of right class

  expect_true(typeof(result_df_input$from_id ) == "character")
  expect_true(typeof(result_df_input$accessibility) == "integer")


  #  * r5r options ----------------------------------------------------------







})

stop_r5(r5r_core)
