## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = identical(tolower(Sys.getenv("NOT_CRAN")), "true"),
  out.width = "100%"
)


## ----message=FALSE------------------------------------------------------------
# # increase Java memory
# options(java.parameters = "-Xmx2G")
# 
# # load libraries
# library(r5r)
# library(dplyr)
# library(data.table)
# library(ggplot2)
# 
# # data path
# data_path <- system.file("extdata/poa", package = "r5r")
# 
# # build network
# r5r_network <- r5r::build_network(
#   data_path = data_path,
#   verbose = FALSE
#   )

## ----message=FALSE------------------------------------------------------------
# # read data.frame with new car speeds
# edge_speed_factors <- read.csv(
#   file.path(data_path, "poa_osm_congestion.csv")
#   )
# 
# head(edge_speed_factors)

## ----message=FALSE------------------------------------------------------------
# # origins and destination points
# points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
# 
# # travel time matrix
# ttm_congestion <- r5r::travel_time_matrix(
#   r5r_network = r5r_network,
#   origins = points,
#   destinations = points,
#   mode = 'car',
#   departure_datetime = Sys.time(),
#   max_trip_duration = 30,
#   new_carspeeds = edge_speed_factors,
#   carspeed_scale = 0.8
# )

## ----message=FALSE------------------------------------------------------------
# # path to OSM pbf
# pbf_path <- paste0(data_path, "/poa_osm.pbf")
# 
# # read layer of lines from pbf
# roads <- sf::st_read(
#   pbf_path,
#   layer = 'lines',
#   quiet = TRUE
#   )
# 
# # Filter only road types of interest
# rt <- c("motorway", "primary", "secondary", "tertiary")
# 
# roads <- roads |>
#   select(osm_id, highway) |>
#   filter(highway %in% rt)
# 
# head(roads)

## -----------------------------------------------------------------------------
# # map
# plot(roads["highway"])
# 

## -----------------------------------------------------------------------------
# new_edge_speeds <- roads |>
#   mutate(
#     osm_id = as.numeric(osm_id),
#     max_speed = case_when(
#       highway == "motorway"  ~ 0.75,
#       highway == "primary"   ~ 0.8,
#       highway == "secondary" ~ 0.85,
#       highway == "tertiary"  ~ 0.9)) |>
#   sf::st_drop_geometry()
# 
# new_edge_speeds$speed_type <- "scale"
# 
# head(new_edge_speeds)
# 

## ----message = FALSE, warning=FALSE-------------------------------------------
# # travel time matrix
# ttm_congestion <- r5r::travel_time_matrix(
#   r5r_network = r5r_network,
#   origins = points,
#   destinations = points,
#   mode = 'car',
#   departure_datetime = Sys.time(),
#   max_trip_duration = 30,
#   new_carspeeds = new_edge_speeds
#   )
# 

## ----message = FALSE----------------------------------------------------------
# # edit table with custom speeds to 40 km/h
# new_edge_speeds40 <- new_edge_speeds |>
#   mutate(max_speed = 40,
#          speed_type = "km/h")
# 
# # travel time matrix
# ttm_congestion <- r5r::travel_time_matrix(
#   r5r_network = r5r_network,
#   origins = points,
#   destinations = points,
#   mode = 'car',
#   departure_datetime = Sys.time(),
#   max_trip_duration = 30,
#   new_carspeeds = new_edge_speeds40
#   )

## ----message = FALSE----------------------------------------------------------
# # read sf with congestion polygons
# congestion_poly <- readRDS(file.path(data_path, "poa_poly_congestion.rds"))
# 
# # preview
# mapview::mapview(congestion_poly, zcol="scale")

## ----message = FALSE----------------------------------------------------------
# head(congestion_poly)

## ----message = FALSE----------------------------------------------------------
# ttm_congestion <- r5r::travel_time_matrix(
#   r5r_network = r5r_network,
#   origins = points,
#   destinations = points,
#   mode = 'car',
#   departure_datetime = Sys.time(),
#   max_trip_duration = 30,
#   new_carspeeds = congestion_poly,
#   carspeed_scale = 0.95
#   )

## ----message=FALSE------------------------------------------------------------
# # read data.frame with new lts
# edge_lts <- read.csv(
#   file.path(data_path, "poa_osm_lts.csv")
#   )
# 
# head(edge_lts)

## ----message = FALSE----------------------------------------------------------
# ttm_new_lts <- r5r::travel_time_matrix(
#   r5r_network = r5r_network,
#   origins = points,
#   destinations = points,
#   mode = 'bicycle',
#   departure_datetime = Sys.time(),
#   max_trip_duration = 30,
#   new_lts = edge_lts
#   )

## ----message = FALSE----------------------------------------------------------
# # read sf with congestion polygons
# lts_lines <- readRDS(file.path(data_path, "poa_ls_lts.rds"))
# 
# # preview
# mapview::mapview(lts_lines, zcol="lts")

## ----message = FALSE----------------------------------------------------------
# ttm_new_lts <- r5r::travel_time_matrix(
#   r5r_network = r5r_network,
#   origins = points,
#   destinations = points,
#   mode = 'bicycle',
#   departure_datetime = Sys.time(),
#   max_trip_duration = 30,
#   new_lts = lts_lines
#   )

## ----message = FALSE----------------------------------------------------------
# # stop an specific r5r network
# r5r::stop_r5(r5r_network)
# 
# # or stop all r5r networks at once
# r5r::stop_r5()
# rJava::.jgc(R.gc = TRUE)

