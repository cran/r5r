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
# library(sf)
# library(data.table)
# library(ggplot2)
# library(patchwork)
# library(dplyr)
# library(h3jsr)

## -----------------------------------------------------------------------------
# # setup and load Porto Alegre multimodal network into memory
# 
# # system.file returns the directory with example data inside the r5r package
# # set data path to directory containing your own data if not using the examples
# data_path <- system.file("extdata/poa", package = "r5r")
# 
# r5r_core <- setup_r5(data_path)
# 
# # load transit network as an SF
# transit_network <- transit_network_to_sf(r5r_core)
# 
# # map
# ggplot() +
#   geom_sf(data=transit_network$routes, aes(color=mode)) +
#   theme_void()

## -----------------------------------------------------------------------------
# fare_structure <- setup_fare_structure(r5r_core,
#                                        base_fare = 4.8,
#                                        by = "MODE")

## -----------------------------------------------------------------------------
# head(fare_structure, n=7)
# 

## -----------------------------------------------------------------------------
# fare_structure$max_discounted_transfers
# fare_structure$transfer_time_allowance <- 60 # update transfer_time_allowance
# fare_structure$fare_cap

## -----------------------------------------------------------------------------
# fare_structure$fares_per_type

## -----------------------------------------------------------------------------
# fare_structure$fares_per_type[type == "RAIL", unlimited_transfers := TRUE]
# fare_structure$fares_per_type[type == "RAIL", fare := 4.50]
# fare_structure$fares_per_type[type == "RAIL", allow_same_route_transfer := TRUE]

## -----------------------------------------------------------------------------
# fare_structure$fares_per_type

## -----------------------------------------------------------------------------
# fare_structure$fares_per_transfer

## -----------------------------------------------------------------------------
# # conditional update fare value
# fare_structure$fares_per_transfer[first_leg == "BUS" & second_leg == "BUS", fare := 7.2]

## -----------------------------------------------------------------------------
# # conditional update fare value
# fare_structure$fares_per_transfer[first_leg != second_leg, fare := 8.37]
# 
# # use fcase instead ?
# fare_structure$fares_per_transfer[, fare := fcase(first_leg == "BUS" & second_leg == "BUS", 7.2,
#                                                  first_leg != second_leg, 8.37)]
# 

## -----------------------------------------------------------------------------
# # remove row
# fare_structure$fares_per_transfer <- fare_structure$fares_per_transfer[!(first_leg == "RAIL" & second_leg == "RAIL")]
# 

## -----------------------------------------------------------------------------
# fare_structure$fares_per_transfer

## -----------------------------------------------------------------------------
# tail(fare_structure$fares_per_route)

## -----------------------------------------------------------------------------
# ## load input data
# points <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))
# 
# # calculate travel times function
# calculate_travel_times <- function(fare) {
#   ttm_df <- travel_time_matrix(
#     r5r_core,
#     origins = points,
#     destinations = points,
#     mode = c("WALK", "TRANSIT"),
#     departure_datetime = as.POSIXct(
#       "13-05-2019 14:00:00",
#       format = "%d-%m-%Y %H:%M:%S"
#     ),
#     time_window = 1,
#     fare_structure = fare_structure,
#     max_fare = fare,
#     max_trip_duration = 40,
#     max_walk_time = 20
#   )
# 
#   return(ttm_df)
# }
# 
# 
# # calculate travel times, and combine results
# ttm <- calculate_travel_times(fare = Inf)
# ttm_500 <- calculate_travel_times(fare = 5)
# 
# # merge results
# ttm[ttm_500, on = .(from_id, to_id), travel_time_500 := i.travel_time_p50]
# ttm[, travel_time_unl := travel_time_p50]
# ttm[, travel_time_p50 := NULL]

## -----------------------------------------------------------------------------
# tail(ttm, 10)

## -----------------------------------------------------------------------------
# # plot of overall travel time differences between limited and unlimited cost travel time matrices
# time_difference = ttm[!is.na(travel_time_500), .(count = .N),
#                       by = .(travel_time_unl, travel_time_500)]
# 
# p1 <- ggplot(time_difference, aes(y = travel_time_unl, x = travel_time_500)) +
#   geom_point(size = 0.7) +
#   coord_fixed() +
#   scale_x_continuous(breaks = seq(0, 45, 5)) +
#   scale_y_continuous(breaks = seq(0, 45, 5)) +
#   theme_light() +
#   theme(legend.position = "none") +
#   labs(y = "travel time (minutes)\nunestricted monetary cost",
#        x = "travel time (minutes)\nmonetary cost restricted to BRL 5.00"
#        )
# 
# # plot of unreachable destinations when the monetary cost limit is too low
# unreachable <- ttm[, .(count = .N), by = .(travel_time_unl, is.na(travel_time_500))]
# unreachable[, perc := count / sum(count, na.rm = T), by = .(travel_time_unl)]
# unreachable <- unreachable[is.na == TRUE]
# unreachable <- na.omit(unreachable)
# 
# p2 <- ggplot(unreachable, aes(x=travel_time_unl, y=perc)) +
#   geom_col() +
#   coord_flip() +
#   scale_x_continuous(breaks = seq(0, 45, 5)) +
#   scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2),
#                      labels = paste0(seq(0, 100, 20), "%")) +
#   theme_light() +
#   labs(x = "travel time (minutes)\nwithout monetary cost restriction",
#        y = "% of unreachable destinations\nconsidering a R$ 5.00 monetary cost limit")
# 
# # combine both plots using patchwork
# p1 + p2 + plot_annotation(subtitle = "Comparing travel times with and without monetary cost restriction")
# 

## -----------------------------------------------------------------------------
# # calculate accessibility function
# calculate_accessibility <- function(fare, fare_string) {
#   access_df <- accessibility(
#     r5r_core,
#     origins = points,
#     destinations = points,
#     mode = c("WALK", "TRANSIT"),
#     departure_datetime = as.POSIXct(
#       "13-05-2019 14:00:00",
#       format = "%d-%m-%Y %H:%M:%S"
#     ),
#     time_window = 1,
#     opportunities_colname = "healthcare",
#     cutoffs = 40,
#     fare_structure = fare_structure,
#     max_fare = fare,
#     max_trip_duration = 40,
#     max_walk_time = 20,
#     progress = FALSE)
# 
#   access_df$max_fare <- fare_string
# 
#   return(access_df)
# }
# 
# # calculate accessibility, combine results, and convert to SF
# access_500 <- calculate_accessibility(fare=5, fare_string="R$ 5.00 budget")
# access_unl <- calculate_accessibility(fare=Inf, fare_string="Unlimited budget")
# 
# access <- rbind(access_500, access_unl)
# 
# # bring geometry
# access$geometry <- h3jsr::cell_to_polygon(access$id)
# access <- st_as_sf(access)
# 

## -----------------------------------------------------------------------------
# # plot accessibility maps
# ggplot(data = access) +
#   geom_sf(aes(fill = accessibility), color=NA, size = 0.2) +
#   scale_fill_distiller(palette = "Spectral") +
#   facet_wrap(~max_fare) +
#   labs(subtitle = "Effect of monetary cost on accessibility") +
#   theme_minimal() +
#   theme(legend.position = "bottom",
#         axis.text = element_blank())
# 

## ----message = FALSE----------------------------------------------------------
# r5r::stop_r5(r5r_core)
# rJava::.jgc(R.gc = TRUE)

