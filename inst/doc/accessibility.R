## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = identical(tolower(Sys.getenv("NOT_CRAN")), "true"),
  out.width = "100%"
)

## ----message = FALSE----------------------------------------------------------
# options(java.parameters = "-Xmx2G")
# 
# library(r5r)
# library(accessibility)
# library(sf)
# library(data.table)
# library(ggplot2)
# library(interp)
# library(h3jsr)
# library(dplyr)

## ----message = FALSE----------------------------------------------------------
# # system.file returns the directory with example data inside the r5r package
# # set data path to directory containing your own data if not running this example
# data_path <- system.file("extdata/poa", package = "r5r")
# 
# r5r_core <- setup_r5(data_path)

## ----message = FALSE----------------------------------------------------------
# # read all points in the city
# points <- fread(file.path(data_path, "poa_hexgrid.csv"))
# 
# # routing inputs
# mode <- c("WALK", "TRANSIT")
# max_walk_time <- 30      # in minutes
# travel_time_cutoff <- 20 # in minutes
# time_window <- 60        # in minutes
# departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
#                                  format = "%d-%m-%Y %H:%M:%S")
# 
# # calculate accessibility
# access1 <- r5r::accessibility(r5r_core,
#                         origins = points,
#                         destinations = points,
#                         mode = mode,
#                         opportunities_colnames = c("schools", "healthcare"),
#                         decay_function = "step",
#                         cutoffs = travel_time_cutoff,
#                         departure_datetime = departure_datetime,
#                         max_walk_time = max_walk_time,
#                         time_window = time_window,
#                         progress = FALSE)
# 
# head(access1)

## ----message = FALSE----------------------------------------------------------
# # calculate travel time matrix
# ttm <- r5r::travel_time_matrix(r5r_core,
#                         origins = points,
#                         destinations = points,
#                         mode = mode,
#                         departure_datetime = departure_datetime,
#                         max_walk_time = max_walk_time,
#                         time_window = time_window,
#                         progress = FALSE)
# head(ttm)

## ----message = FALSE----------------------------------------------------------
# # calculate accessibility
# access_edu <- accessibility::cumulative_cutoff(travel_matrix = ttm,
#                                         land_use_data = points,
#                                         opportunity = 'schools',
#                                         travel_cost = 'travel_time_p50',
#                                         cutoff = 20)
# 
# access_health <- accessibility::cumulative_cutoff(travel_matrix = ttm,
#                                         land_use_data = points,
#                                         opportunity = 'healthcare',
#                                         travel_cost = 'travel_time_p50',
#                                         cutoff = 20)
# head(access_edu)
# head(access_health)

## ----message = FALSE, out.width='100%'----------------------------------------
# # retrieve polygons of H3 spatial grid
# grid <- h3jsr::cell_to_polygon(points$id, simple = FALSE)
# 
# # merge accessibility estimates
# access_sf <- left_join(grid, access1, by = c('h3_address'='id'))
# 
# # plot
# ggplot() +
#   geom_sf(data = access_sf, aes(fill = accessibility), color= NA) +
#   scale_fill_viridis_c(direction = -1, option = 'B') +
#   labs(fill = "Number of\nfacilities within\n20 minutes") +
#   theme_minimal() +
#   theme(axis.title = element_blank()) +
#   facet_wrap(~opportunity) +
#   theme_void()
# 

## ----message = FALSE, out.width='100%'----------------------------------------
# # interpolate estimates to get spatially smooth result
# access_schools <- access1 %>%
#   filter(opportunity == "schools") %>%
#   inner_join(points, by='id') %>%
#   with(interp::interp(lon, lat, accessibility)) %>%
#   with(cbind(acc=as.vector(z),  # Column-major order
#              x=rep(x, times=length(y)),
#              y=rep(y, each=length(x)))) %>% as.data.frame() %>% na.omit() %>%
#   mutate(opportunity = "schools")
# 
# access_health <- access1 %>%
#   filter(opportunity == "healthcare") %>%
#   inner_join(points, by='id') %>%
#   with(interp::interp(lon, lat, accessibility)) %>%
#   with(cbind(acc=as.vector(z),  # Column-major order
#              x=rep(x, times=length(y)),
#              y=rep(y, each=length(x)))) %>% as.data.frame() %>% na.omit() %>%
#   mutate(opportunity = "healthcare")
# 
# access.interp <- rbind(access_schools, access_health)
# 
# # find results' bounding box to crop the map
# bb_x <- c(min(access.interp$x), max(access.interp$x))
# bb_y <- c(min(access.interp$y), max(access.interp$y))
# 
# # extract OSM network, to plot over map
# street_net <- street_network_to_sf(r5r_core)
# 
# # plot
# ggplot(na.omit(access.interp)) +
#   geom_sf(data = street_net$edges, color = "gray55", size=0.01, alpha = 0.7) +
#   geom_contour_filled(aes(x=x, y=y, z=acc), alpha=.7) +
#   scale_fill_viridis_d(direction = -1, option = 'B') +
#   scale_x_continuous(expand=c(0,0)) +
#   scale_y_continuous(expand=c(0,0)) +
#   coord_sf(xlim = bb_x, ylim = bb_y, datum = NA) +
#   labs(fill = "Number of\nfacilities within\n20 minutes") +
#   theme_void() +
#   facet_wrap(~opportunity)

## ----message = FALSE----------------------------------------------------------
# r5r::stop_r5(r5r_core)
# rJava::.jgc(R.gc = TRUE)

