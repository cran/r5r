## ----include = FALSE----------------------------------------------------------
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

## ----eval = FALSE-------------------------------------------------------------
# # from CRAN
# install.packages('r5r')
# 
# # dev version with latest features
# devtools::install_github("ipeaGIT/r5r", subdir = "r-package")

## ----eval = FALSE-------------------------------------------------------------
# # install {rJavaEnv} from CRAN
# install.packages("rJavaEnv")
# 
# # check version of Java currently installed (if any)
# rJavaEnv::java_check_version_rjava()
# 
# ## if this is the first time you use {rJavaEnv}, you might need to run this code
# ## below to consent the installation of Java.
# # rJavaEnv::rje_consent(provided = TRUE)
# 
# # install Java 21
# rJavaEnv::java_quick_install(version = 21)
# 
# # check if Java was successfully installed
# rJavaEnv::java_check_version_rjava()
# 

## ----message = FALSE----------------------------------------------------------
# options(java.parameters = "-Xmx2G")
# 
# # By default, {r5r} uses all CPU cores available. If you want to limit the
# # number of CPUs to 4, for example, you can run:
# options(java.parameters = c("-Xmx2G", "-XX:ActiveProcessorCount=4"))

## ----message = FALSE, warning = FALSE-----------------------------------------
# library(r5r)
# library(sf)
# library(data.table)
# library(ggplot2)

## -----------------------------------------------------------------------------
# data_path <- system.file("extdata/poa", package = "r5r")
# list.files(data_path)

## -----------------------------------------------------------------------------
# poi <- fread(file.path(data_path, "poa_points_of_interest.csv"))
# head(poi)

## -----------------------------------------------------------------------------
# points <- fread(file.path(data_path, "poa_hexgrid.csv"))
# 
# # sample points
# sampled_rows <-  sample(1:nrow(points), 200, replace=TRUE)
# points <- points[ sampled_rows, ]
# head(points)

## ----message = FALSE----------------------------------------------------------
# # Indicate the path where OSM and GTFS data are stored
# r5r_core <- setup_r5(data_path = data_path)

## ----message = FALSE----------------------------------------------------------
# # set departure datetime input
# departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
#                                  format = "%d-%m-%Y %H:%M:%S")
# 
# # calculate accessibility
# access <- accessibility(r5r_core = r5r_core,
#                         origins = points,
#                         destinations = points,
#                         opportunities_colnames = c("schools", "healthcare"),
#                         mode = c("WALK", "TRANSIT"),
#                         departure_datetime = departure_datetime,
#                         decay_function = "step",
#                         cutoffs = 60
#                         )
# head(access)

## ----message = FALSE----------------------------------------------------------
# # set inputs
# mode <- c("WALK", "TRANSIT")
# max_walk_time <- 30 # minutes
# max_trip_duration <- 120 # minutes
# departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
#                                  format = "%d-%m-%Y %H:%M:%S")
# 
# # calculate a travel time matrix
# ttm <- travel_time_matrix(r5r_core = r5r_core,
#                           origins = poi,
#                           destinations = poi,
#                           mode = mode,
#                           departure_datetime = departure_datetime,
#                           max_walk_time = max_walk_time,
#                           max_trip_duration = max_trip_duration)
# 
# head(ttm)

## ----ttm head, echo=FALSE, message=FALSE, out.width='100%', eval = FALSE------
# knitr::include_graphics("https://github.com/ipeaGIT/r5r/blob/master/r-package/inst/img/vig_output_ttm.png?raw=true")

## ----message = FALSE----------------------------------------------------------
# # calculate a travel time matrix
# ettm <- expanded_travel_time_matrix(r5r_core = r5r_core,
#                           origins = poi,
#                           destinations = poi,
#                           mode = mode,
#                           departure_datetime = departure_datetime,
#                           breakdown = TRUE,
#                           max_walk_time = max_walk_time,
#                           max_trip_duration = max_trip_duration)
# 
# head(ettm)

## ----message = FALSE----------------------------------------------------------
# # set inputs
# origins <- poi[10,]
# destinations <- poi[12,]
# mode <- c("WALK", "TRANSIT")
# max_walk_time <- 60 # minutes
# departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
#                                  format = "%d-%m-%Y %H:%M:%S")
# 
# # calculate detailed itineraries
# det <- detailed_itineraries(r5r_core = r5r_core,
#                             origins = origins,
#                             destinations = destinations,
#                             mode = mode,
#                             departure_datetime = departure_datetime,
#                             max_walk_time = max_walk_time,
#                             shortest_path = FALSE)
# 
# head(det)

## ----detailed head, echo = FALSE, out.width='100%', message = FALSE, eval = FALSE----
# knitr::include_graphics("https://github.com/ipeaGIT/r5r/blob/master/r-package/inst/img/vig_output_detailed.png?raw=true")

## ----message = FALSE----------------------------------------------------------
# # extract OSM network
# street_net <- street_network_to_sf(r5r_core)
# 
# # extract public transport network
# transit_net <- r5r::transit_network_to_sf(r5r_core)
# 
# # plot
# ggplot() +
#   geom_sf(data = street_net$edges, color='gray85') +
#   geom_sf(data = det, aes(color=mode)) +
#   facet_wrap(.~option) +
#   theme_void()
# 

## ----ggplot2 output, echo = FALSE, out.width='100%', message = FALSE, eval = FALSE----
# knitr::include_graphics("https://github.com/ipeaGIT/r5r/blob/master/r-package/inst/img/vig_detailed_ggplot.png?raw=true")

## ----message = FALSE----------------------------------------------------------
# r5r::stop_r5(r5r_core)
# rJava::.jgc(R.gc = TRUE)

## ----eval = TRUE, include = FALSE, message = FALSE----------------------------
# clean cache (CRAN policy)
r5r::r5r_cache(delete_file = 'all')


