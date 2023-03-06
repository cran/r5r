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

## ---- eval = FALSE------------------------------------------------------------
#  # CRAN
#  install.packages('r5r')
#  
#  # dev version on github
#  devtools::install_github("ipeaGIT/r5r", subdir = "r-package")

## ---- eval = FALSE------------------------------------------------------------
#    rJava::.jinit()
#    rJava::.jcall("java.lang.System", "S", "getProperty", "java.version")
#  

## ---- message = FALSE---------------------------------------------------------
#  options(java.parameters = "-Xmx2G")

## ---- message = FALSE, warning = FALSE----------------------------------------
#  library(r5r)
#  library(sf)
#  library(data.table)
#  library(ggplot2)

## -----------------------------------------------------------------------------
#  data_path <- system.file("extdata/poa", package = "r5r")
#  list.files(data_path)

## -----------------------------------------------------------------------------
#  poi <- fread(file.path(data_path, "poa_points_of_interest.csv"))
#  head(poi)

## -----------------------------------------------------------------------------
#  points <- fread(file.path(data_path, "poa_hexgrid.csv"))
#  
#  # sample points
#  sampled_rows <-  sample(1:nrow(points), 200, replace=TRUE)
#  points <- points[ sampled_rows, ]
#  head(points)

## ---- message = FALSE---------------------------------------------------------
#  # Indicate the path where OSM and GTFS data are stored
#  r5r_core <- setup_r5(data_path = data_path)

## ---- message = FALSE---------------------------------------------------------
#  # set departure datetime input
#  departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
#                                   format = "%d-%m-%Y %H:%M:%S")
#  
#  # calculate accessibility
#  access <- accessibility(r5r_core = r5r_core,
#                          origins = points,
#                          destinations = points,
#                          opportunities_colnames = c("schools", "healthcare"),
#                          mode = c("WALK", "TRANSIT"),
#                          departure_datetime = departure_datetime,
#                          decay_function = "step",
#                          cutoffs = 60
#                          )
#  head(access)

## ---- message = FALSE---------------------------------------------------------
#  # set inputs
#  mode <- c("WALK", "TRANSIT")
#  max_walk_time <- 30 # minutes
#  max_trip_duration <- 120 # minutes
#  departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
#                                   format = "%d-%m-%Y %H:%M:%S")
#  
#  # calculate a travel time matrix
#  ttm <- travel_time_matrix(r5r_core = r5r_core,
#                            origins = poi,
#                            destinations = poi,
#                            mode = mode,
#                            departure_datetime = departure_datetime,
#                            max_walk_time = max_walk_time,
#                            max_trip_duration = max_trip_duration)
#  
#  head(ttm)

## ----ttm head, echo=FALSE, message=FALSE, out.width='100%', eval = FALSE------
#  knitr::include_graphics("https://github.com/ipeaGIT/r5r/blob/master/r-package/inst/img/vig_output_ttm.png?raw=true")

## ---- message = FALSE---------------------------------------------------------
#  # calculate a travel time matrix
#  ettm <- expanded_travel_time_matrix(r5r_core = r5r_core,
#                            origins = poi,
#                            destinations = poi,
#                            mode = mode,
#                            departure_datetime = departure_datetime,
#                            breakdown = TRUE,
#                            max_walk_time = max_walk_time,
#                            max_trip_duration = max_trip_duration)
#  
#  head(ettm)

## ---- message = FALSE---------------------------------------------------------
#  # set inputs
#  origins <- poi[10,]
#  destinations <- poi[12,]
#  mode <- c("WALK", "TRANSIT")
#  max_walk_time <- 60 # minutes
#  departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
#                                   format = "%d-%m-%Y %H:%M:%S")
#  
#  # calculate detailed itineraries
#  det <- detailed_itineraries(r5r_core = r5r_core,
#                              origins = origins,
#                              destinations = destinations,
#                              mode = mode,
#                              departure_datetime = departure_datetime,
#                              max_walk_time = max_walk_time,
#                              shortest_path = FALSE)
#  
#  head(det)

## ----detailed head, echo = FALSE, out.width='100%', message = FALSE, eval = FALSE----
#  knitr::include_graphics("https://github.com/ipeaGIT/r5r/blob/master/r-package/inst/img/vig_output_detailed.png?raw=true")

## ---- message = FALSE---------------------------------------------------------
#  # extract OSM network
#  street_net <- street_network_to_sf(r5r_core)
#  
#  # extract public transport network
#  transit_net <- r5r::transit_network_to_sf(r5r_core)
#  
#  # plot
#  ggplot() +
#    geom_sf(data = street_net$edges, color='gray85') +
#    geom_sf(data = det, aes(color=mode)) +
#    facet_wrap(.~option) +
#    theme_void()
#  

## ----ggplot2 output, echo = FALSE, out.width='100%', message = FALSE, eval = FALSE----
#  knitr::include_graphics("https://github.com/ipeaGIT/r5r/blob/master/r-package/inst/img/vig_detailed_ggplot.png?raw=true")

## ---- message = FALSE---------------------------------------------------------
#  r5r::stop_r5(r5r_core)
#  rJava::.jgc(R.gc = TRUE)

