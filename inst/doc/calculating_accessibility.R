## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  options(java.parameters = "-Xmx2G")
#  
#  library(r5r)
#  library(sf)
#  library(data.table)
#  library(ggplot2)
#  library(akima)
#  library(dplyr)

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  # system.file returns the directory with example data inside the r5r package
#  # set data path to directory containing your own data if not using the examples
#  data_path <- system.file("extdata/poa", package = "r5r")
#  
#  r5r_core <- setup_r5(data_path, verbose = FALSE)

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  # read all points in the city
#  points <- fread(file.path(data_path, "poa_hexgrid.csv"))
#  
#  # routing inputs
#  mode <- c("WALK", "TRANSIT")
#  max_walk_dist <- 1000 # in meters
#  travel_time_cutoff <- 21 # in minutes
#  departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
#                                   format = "%d-%m-%Y %H:%M:%S")
#  
#  time_window <- 60 # in minutes
#  percentiles <- 50
#  
#  # calculate travel time matrix
#  access <- accessibility(r5r_core,
#                          origins = points,
#                          destinations = points,
#                          mode = mode,
#                          opportunities_colname = "schools",
#                          decay_function = "step",
#                          cutoffs = travel_time_cutoff,
#                          departure_datetime = departure_datetime,
#                          max_walk_dist = max_walk_dist,
#                          time_window = time_window,
#                          percentiles = percentiles,
#                          verbose = FALSE)
#  
#  
#  head(access)
#  #>            from_id percentile cutoff accessibility
#  #> 1: 89a901291abffff         50     21             3
#  #> 2: 89a9012a3cfffff         50     21             0
#  #> 3: 89a901295b7ffff         50     21             6
#  #> 4: 89a901284a3ffff         50     21             1
#  #> 5: 89a9012809bffff         50     21             5
#  #> 6: 89a901285cfffff         50     21             3

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  # interpolate estimates to get spatially smooth result
#  access.interp <- access %>%
#    inner_join(points, by=c('from_id'='id')) %>%
#    with(interp(lon, lat, accessibility)) %>%
#                          with(cbind(acc=as.vector(z),  # Column-major order
#                                     x=rep(x, times=length(y)),
#                                     y=rep(y, each=length(x)))) %>% as.data.frame() %>% na.omit()
#  
#  # find results' bounding box to crop the map
#  bb_x <- c(min(access.interp$x), max(access.interp$x))
#  bb_y <- c(min(access.interp$y), max(access.interp$y))
#  
#  # extract OSM network, to plot over map
#  street_net <- street_network_to_sf(r5r_core)
#  
#  # plot
#  ggplot(na.omit(access.interp)) +
#    geom_contour_filled(aes(x=x, y=y, z=acc), alpha=.8) +
#    geom_sf(data = street_net$edges, color = "gray55", size=0.1, alpha = 0.9) +
#    scale_fill_viridis_d(direction = -1, option = 'B') +
#    scale_x_continuous(expand=c(0,0)) +
#    scale_y_continuous(expand=c(0,0)) +
#    coord_sf(xlim = bb_x, ylim = bb_y) +
#    labs(fill = "Schools within\n20 minutes\n(median travel time)") +
#    theme_minimal() +
#    theme(axis.title = element_blank())

## ----detailed head, echo = FALSE, out.width='100%', message = FALSE-----------
knitr::include_graphics("https://github.com/ipeaGIT/r5r/blob/master/r-package/inst/img/vig_accessibility.png?raw=true")

