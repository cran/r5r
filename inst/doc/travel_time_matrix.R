## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = identical(tolower(Sys.getenv("NOT_CRAN")), "true"),
  out.width = "100%"
)

## removes files previously created by 'setup_r5()'
#data_path <- system.file("extdata/poa", package = "r5r")
#existing_files <- list.files(data_path)
#files_to_keep <- c(
#  "poa_hexgrid.csv",
#  "poa_osm.pbf",
#  "poa_points_of_interest.csv",
#  "poa_eptc.zip",
#  "poa_trensurb.zip",
#  'fares'
#  )
#files_to_remove <- existing_files[! existing_files %in% files_to_keep]
#invisible(file.remove(file.path(data_path, files_to_remove)))

## ---- message = FALSE---------------------------------------------------------
#  # increase Java memory
#  options(java.parameters = "-Xmx2G")
#  
#  # load libraries
#  library(r5r)
#  library(data.table)
#  library(ggplot2)
#  
#  # build a routable transport network with r5r
#  data_path <- system.file("extdata/poa", package = "r5r")
#  r5r_core <- setup_r5(data_path)
#  
#  # routing inputs
#  mode <- c('walk', 'transit')
#  max_trip_duration <- 60 # minutes
#  
#  # departure time
#  departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
#                                   format = "%d-%m-%Y %H:%M:%S")
#  
#  # load origin/destination points
#  points <- fread(file.path(data_path, "poa_points_of_interest.csv"))
#  

## ---- message = FALSE---------------------------------------------------------
#  # estimate travel time matrix
#  ttm <- travel_time_matrix(r5r_core,
#                            origins = points,
#                            destinations = points,
#                            mode = mode,
#                            max_trip_duration = max_trip_duration,
#                            departure_datetime = departure_datetime )
#  
#  head(ttm, n = 10)
#  

## ---- message = FALSE---------------------------------------------------------
#  ettm <- expanded_travel_time_matrix(r5r_core,
#                                      origins = points,
#                                      destinations = points,
#                                      mode = mode,
#                                      max_trip_duration = max_trip_duration,
#                                      departure_datetime = departure_datetime )
#  
#  head(ettm, n = 10)

## ---- message = FALSE---------------------------------------------------------
#  ettm2 <- expanded_travel_time_matrix(r5r_core,
#                                      origins = points,
#                                      destinations = points,
#                                      mode = mode,
#                                      max_trip_duration = max_trip_duration,
#                                      departure_datetime = departure_datetime,
#                                      breakdown = TRUE)
#  
#  head(ettm2, n = 10)

## ---- message = FALSE---------------------------------------------------------
#  ettm_window <- expanded_travel_time_matrix(r5r_core,
#                                             origins = points,
#                                             destinations = points,
#                                             mode = mode,
#                                             max_trip_duration = max_trip_duration,
#                                             departure_datetime = departure_datetime,
#                                             breakdown = TRUE,
#                                             time_window = 10)
#  
#  ettm_window[15:25,]

## ---- message = FALSE---------------------------------------------------------
#  r5r::stop_r5(r5r_core)
#  rJava::.jgc(R.gc = TRUE)

