## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ---- eval = FALSE------------------------------------------------------------
#  # CRAN
#  install.packages('r5r')
#  
#  # github
#  devtools::install_github("ipeaGIT/r5r", subdir = "r-package")

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  options(java.parameters = "-Xmx2G")

## ---- message = FALSE---------------------------------------------------------
library(r5r)
library(sf)
library(data.table)
library(ggplot2)
library(mapview)

## -----------------------------------------------------------------------------
data_path <- system.file("extdata/poa", package = "r5r")
list.files(data_path)

## -----------------------------------------------------------------------------
poi <- fread(file.path(data_path, "poa_points_of_interest.csv"))
head(poi)

## -----------------------------------------------------------------------------
points <- fread(file.path(data_path, "poa_hexgrid.csv"))
points <- points[ c(sample(1:nrow(points), 10, replace=TRUE)), ]
head(points)

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  # Indicate the path where OSM and GTFS data are stored
#  r5r_core <- setup_r5(data_path = data_path, verbose = FALSE)

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  # set inputs
#  mode <- c("WALK", "TRANSIT")
#  max_walk_dist <- 5000
#  max_trip_duration <- 120
#  departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
#                                   format = "%d-%m-%Y %H:%M:%S")
#  
#  # calculate a travel time matrix
#  ttm <- travel_time_matrix(r5r_core = r5r_core,
#                            origins = points,
#                            destinations = points,
#                            mode = mode,
#                            departure_datetime = departure_datetime,
#                            max_walk_dist = max_walk_dist,
#                            max_trip_duration = max_trip_duration,
#                            verbose = FALSE)
#  
#  head(ttm)

## ----ttm head, echo=FALSE, message=FALSE, out.width='100%'--------------------
knitr::include_graphics("https://github.com/ipeaGIT/r5r/blob/master/r-package/inst/img/vig_output_ttm.png?raw=true")

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  # set inputs
#  origins <- poi[10,]
#  destinations <- poi[12,]
#  mode <- c("WALK", "TRANSIT")
#  max_walk_dist <- 10000
#  departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
#                                   format = "%d-%m-%Y %H:%M:%S")
#  
#  # calculate detailed itineraries
#  dit <- detailed_itineraries(r5r_core = r5r_core,
#                              origins,
#                              destinations,
#                              mode,
#                              departure_datetime,
#                              max_walk_dist,
#                              shortest_path = FALSE,
#                              verbose = FALSE)
#  
#  head(dit)

## ----detailed head, echo = FALSE, out.width='100%', message = FALSE-----------
knitr::include_graphics("https://github.com/ipeaGIT/r5r/blob/master/r-package/inst/img/vig_output_detailed.png?raw=true")

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  # extract OSM network
#  street_net <- street_network_to_sf(r5r_core)
#  
#  # plot
#  ggplot() +
#    geom_sf(data = street_net$edges, color='gray85') +
#    geom_sf(data = dit, aes(color=mode)) +
#    facet_wrap(.~option) +
#    theme_void()
#  

## ----ggplot2 output, echo = FALSE, out.width='100%', message = FALSE----------
knitr::include_graphics("https://github.com/ipeaGIT/r5r/blob/master/r-package/inst/img/vig_detailed_ggplot.png?raw=true")

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  mapview(dit, zcol = 'option')

## ----mapview output, echo = FALSE, out.width='80%', message = FALSE-----------
knitr::include_graphics("https://github.com/ipeaGIT/r5r/blob/master/r-package/inst/img/vig_detailed_mapview.png?raw=true")

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  stop_r5(r5r_core)
#  rJava::.jgc(R.gc = TRUE)

