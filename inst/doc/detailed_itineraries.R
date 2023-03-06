## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = identical(tolower(Sys.getenv("NOT_CRAN")), "true"),
  out.width = "100%"
)

## ---- message = FALSE---------------------------------------------------------
#  # increase Java memory
#  options(java.parameters = "-Xmx2G")
#  
#  # load libraries
#  library(r5r)
#  library(sf)
#  library(ggplot2)
#  library(data.table)
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
#  poi <- fread(file.path(data_path, "poa_points_of_interest.csv"))
#  

## ---- message = FALSE---------------------------------------------------------
#  # set inputs
#  origins <- poi[10,]
#  destinations <- poi[12,]
#  mode <- c("WALK", "TRANSIT")
#  max_walk_time <- 60
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
#                              suboptimal_minutes = 8,
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
#  fig <- ggplot() +
#          geom_sf(data = street_net$edges, color='gray85') +
#          geom_sf(data = subset(det, option <4), aes(color=mode)) +
#          facet_wrap(.~option) +
#          theme_void()
#  
#  fig

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  # SAVE image
#  ggsave(plot = fig, filename = 'inst/img/vig_detailed_ggplot.png',
#         height = 5, width = 15, units='cm', dpi=200)

## ----ggplot2 output, echo = FALSE, out.width='100%', message = FALSE, eval = FALSE----
#  knitr::include_graphics("https://github.com/ipeaGIT/r5r/blob/master/r-package/inst/img/vig_detailed_ggplot.png?raw=true")

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  library(gtfstools)
#  
#  # location of your frequency-based GTFS
#  freq_gtfs_file <- system.file("extdata/spo/spo.zip", package = "r5r")
#  
#  # read GTFS data
#  freq_gtfs <- gtfstools::read_gtfs(freq_gtfs_file)
#  
#  # convert from frequencies to time tables
#  stop_times_gtfs <- gtfstools::frequencies_to_stop_times(freq_gtfs)
#  
#  # save it as a new GTFS.zip file
#  gtfstools::write_gtfs(gtfs = stop_times_gtfs,
#                        path = tempfile(pattern = 'stop_times_gtfs', fileext = '.zip'))
#  
#  

## ---- message = FALSE---------------------------------------------------------
#  r5r::stop_r5(r5r_core)
#  rJava::.jgc(R.gc = TRUE)

