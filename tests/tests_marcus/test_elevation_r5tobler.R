# options(java.parameters = '-Xmx2G')

# library(r5r)
devtools::load_all(".")
library(data.table)
library(tidyverse)


# rst <- raster::raster(system.file("extdata/poa/poa_el_2.tif", package = "r5r"))
# rst <- raster::raster("/Users/marcussaraiva/Repos/poa_data/topografia3_poa.tif")

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE,
                     temp_dir = FALSE,
                     use_elevation = FALSE,
                     use_native_elevation = TRUE,
                     overwrite = TRUE)

# load origin/destination points
points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))

# r5r_core$setTravelTimesBreakdown(FALSE)
ttm_r5tobler_walk <- travel_time_matrix(r5r_core,
                            origins = points,
                            destinations = points,
                            breakdown = FALSE,
                            mode = c("WALK"),
                            max_trip_duration = 60,
                            max_walk_dist = Inf,
                            time_window = 1,
                            percentiles = c(50),
                            verbose = FALSE,
                            progress = TRUE)


ttm_r5tobler_bike <- travel_time_matrix(r5r_core,
                                    origins = points,
                                    destinations = points,
                                    breakdown = FALSE,
                                    mode = c("BICYCLE"),
                                    max_trip_duration = 60,
                                    max_walk_dist = Inf,
                                    time_window = 1,
                                    percentiles = c(50),
                                    verbose = FALSE,
                                    progress = TRUE)

ttm_r5tobler_walk$scenario <- "r5minetti"
ttm_r5tobler_walk$mode <- "walk"
ttm_r5tobler_bike$scenario <- "r5minetti"
ttm_r5tobler_bike$mode <- "bike"

write_csv(ttm_r5tobler_walk, here::here("elevation", "walk_r5minetti.csv"))
write_csv(ttm_r5tobler_bike, here::here("elevation", "bike_r5minetti.csv"))
