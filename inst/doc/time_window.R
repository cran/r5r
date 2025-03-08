## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = identical(tolower(Sys.getenv("NOT_CRAN")), "true"),
  out.width = "100%"
)


## ----message = FALSE----------------------------------------------------------
# # increase Java memory
# options(java.parameters = "-Xmx2G")
# 
# # load libraries
# library(r5r)
# library(sf)
# library(data.table)
# library(ggplot2)
# library(dplyr)
# 
# # build a routable transport network with r5r
# data_path <- system.file("extdata/spo", package = "r5r")
# r5r_core <- setup_r5(data_path)
# 
# # routing inputs
# mode <- c('walk', 'transit')
# max_walk_time <- 30 # minutes
# max_trip_duration <- 90 # minutes
# 
# # load origin/destination points
# points <- fread(file.path(data_path, "spo_hexgrid.csv"))
# 
# # departure datetime
# departure_datetime = as.POSIXct("13-05-2019 14:00:00",
#                                 format = "%d-%m-%Y %H:%M:%S")

## ----message = FALSE----------------------------------------------------------
# # estimate accessibility
# acc <- r5r::accessibility(r5r_core = r5r_core,
#                           origins = points,
#                           destinations = points,
#                           opportunities_colnames = 'schools',
#                           mode = mode,
#                           max_walk_time = max_walk_time,
#                           decay_function = "step",
#                           cutoffs = 45,
#                           departure_datetime = departure_datetime,
#                           progress = FALSE,
#                           time_window = 60,
#                           percentiles = c(10, 20, 50, 70, 80)
#                           )
# 
# head(acc, n = 10)
# 

## -----------------------------------------------------------------------------
# # summarize
# df <- acc[, .(min_acc = min(accessibility),
#               median = accessibility[which(percentile == 50)],
#               max_acc = max(accessibility)), by = id]
# 
# # plot
# ggplot(data=df) +
#   geom_linerange(color='gray', alpha=.5, aes(x = reorder(id, median) ,
#                       y=median, ymin=min_acc, ymax=max_acc)) +
#   geom_point(color='#0570b0', size=.5, aes(x = reorder(id, median), y=median)) +
#   labs(y='N. of schools accessible\nby public transport', x='Origins sorted by accessibility',
#        title="Accessibility uncertainty between 2pm and 3pm",
#        subtitle = 'Upper limit 10% and lower limit 80% of the times') +
#   theme_classic() +
#   theme(axis.text.x=element_blank(),
#         axis.ticks.x=element_blank())

## ----message = FALSE----------------------------------------------------------
# # estimate travel time matrix
# ttm <- travel_time_matrix(r5r_core = r5r_core,
#                           origins = points,
#                           destinations = points,
#                           mode = mode,
#                           max_walk_time = max_walk_time,
#                           max_trip_duration = max_trip_duration,
#                           departure_datetime = departure_datetime,
#                           progress = TRUE,
#                           time_window = 60,
#                           percentiles = c(10, 20, 50, 70, 80)
#                           )
# 
# head(ttm, n = 10)
# 

## -----------------------------------------------------------------------------
# ettm <- r5r::expanded_travel_time_matrix(r5r_core = r5r_core,
#                                     origins = points[1:30,],
#                                     destinations = points[31:61,],
#                                     mode = mode,
#                                     max_walk_time = max_walk_time,
#                                     max_trip_duration = max_trip_duration,
#                                     departure_datetime = departure_datetime,
#                                     progress = FALSE,
#                                     time_window = 20)
# 
# head(ettm, n = 10)
# 

## ----message = FALSE----------------------------------------------------------
# r5r::stop_r5(r5r_core)
# rJava::.jgc(R.gc = TRUE)

