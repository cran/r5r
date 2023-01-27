## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = identical(tolower(Sys.getenv("NOT_CRAN")), "true"),
  out.width = "100%"
)

## ---- message = FALSE---------------------------------------------------------
options(java.parameters = "-Xmx2G")

library(r5r)
library(sf)
library(data.table)
library(ggplot2)
library(interp)
library(dplyr)

## ---- message = FALSE---------------------------------------------------------
# system.file returns the directory with example data inside the r5r package
# set data path to directory containing your own data if not using the examples
data_path <- system.file("extdata/poa", package = "r5r")

r5r_core <- setup_r5(data_path)

## ---- message = FALSE---------------------------------------------------------
# read all points in the city
points <- fread(file.path(data_path, "poa_hexgrid.csv"))

# subset point with the geolocation of the central bus station
central_bus_stn <- points[291,]

# routing inputs
mode <- c("WALK", "TRANSIT")
max_walk_time <- 30 # in minutes
max_trip_duration <- 120 # in minutes
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

time_window <- 120 # in minutes
percentiles <- 50

# calculate travel time matrix
ttm <- travel_time_matrix(r5r_core,
                          origins = central_bus_stn,
                          destinations = points,
                          mode = mode,
                          departure_datetime = departure_datetime,
                          max_walk_time = max_walk_time,
                          max_trip_duration = max_trip_duration,
                          time_window = time_window,
                          percentiles = percentiles,
                          progress = FALSE)

head(ttm)


## ---- message = FALSE, out.width='100%'---------------------------------------
# extract OSM network
street_net <- street_network_to_sf(r5r_core)

# add coordinates of destinations to travel time matrix
ttm[points, on=c('to_id' ='id'), `:=`(lon = i.lon, lat = i.lat)]

# interpolate estimates to get spatially smooth result
travel_times.interp <- with(na.omit(ttm), interp(lon, lat, travel_time_p50)) %>%
                        with(cbind(travel_time=as.vector(z),  # Column-major order
                                   x=rep(x, times=length(y)),
                                   y=rep(y, each=length(x)))) %>%
                            as.data.frame() %>% na.omit()

# find isochrone's bounding box to crop the map below
bb_x <- c(min(travel_times.interp$x), max(travel_times.interp$x))
bb_y <- c(min(travel_times.interp$y), max(travel_times.interp$y))

# plot
ggplot(travel_times.interp) +
  geom_sf(data = street_net$edges, color = "gray55", size=0.01, alpha = 0.7) +
  geom_contour_filled(aes(x=x, y=y, z=travel_time), alpha=.7) +
  geom_point(aes(x=lon, y=lat, color='Central bus\nstation'),
             data=central_bus_stn) +
  scale_fill_viridis_d(direction = -1, option = 'B') +
  scale_color_manual(values=c('Central bus\nstation'='black')) +
  scale_x_continuous(expand=c(0,0)) +
  scale_y_continuous(expand=c(0,0)) +
  coord_sf(xlim = bb_x, ylim = bb_y) +
  labs(fill = "travel time\n(in minutes)", color='') +
  theme_minimal() +
  theme(axis.title = element_blank())

## ---- message = FALSE---------------------------------------------------------
r5r::stop_r5(r5r_core)
rJava::.jgc(R.gc = TRUE)

