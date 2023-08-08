### TO DO
# allow users to pass an sf points or polygons as "destination" input
# update entire documentation based on latest docs of r5r
# expose to users the same parameters available in travel_time_matrix()
  # max_trip_duration should be == to max(cutoffs)
#'# prep grid with destinations
#'dest_points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))
#'grid <- h3jsr::cell_to_polygon(input = dest_points$id, simple = FALSE)
#'grid$id <- dest_points$id
#'



#' Estimate isochrones from a given location
#'
#' @description Fast computation of isochrones from a given location.
#'
#' @template r5r_core
#' @param origins Either a `POINT sf` object with WGS84 CRS, or a
#'   `data.frame` containing the columns `id`, `lon` and `lat`.
#' @param cutoffs numeric vector. Number of minutes to define time span of each
#'                each Isochrone. Defaults to `c(0, 15, 30)`.
#' @param mode A character vector. The transport modes allowed for access,
#'   transfer and vehicle legs of the trips. Defaults to `WALK`. Please see
#'   details for other options.
#' @param mode_egress A character vector. The transport mode used after egress
#'   from the last public transport. It can be either `WALK`, `BICYCLE` or
#'   `CAR`. Defaults to `WALK`. Ignored when public transport is not used.
#' @param departure_datetime A POSIXct object. Please note that the departure
#'   time only influences public transport legs. When working with public
#'   transport networks, please check the `calendar.txt` within your GTFS feeds
#'   for valid dates. Please see details for further information on how
#'   datetimes are parsed.
#' @param max_walk_time An integer. The maximum walking time (in minutes) to
#'   access and egress the transit network, or to make transfers within the
#'   network. Defaults to no restrictions, as long as `max_trip_duration` is
#'   respected. The max time is considered separately for each leg (e.g. if
#'   you set `max_walk_time` to 15, you could potentially walk up to 15 minutes
#'   to reach transit, and up to _another_ 15 minutes to reach the destination
#'   after leaving transit). Defaults to `Inf`, no limit.
#' @param max_bike_time An integer. The maximum cycling time (in minutes) to
#'   access and egress the transit network. Defaults to no restrictions, as long
#'   as `max_trip_duration` is respected. The max time is considered separately
#'   for each leg (e.g. if you set `max_bike_time` to 15 minutes, you could
#'   potentially cycle up to 15 minutes to reach transit, and up to _another_ 15
#'   minutes to reach the destination after leaving transit). Defaults to `Inf`,
#'   no limit.
#' @param max_car_time An integer. The maximum driving time (in minutes) to
#'   access and egress the transit network. Defaults to no restrictions, as long
#'   as `max_trip_duration` is respected. The max time is considered separately
#'   for each leg (e.g. if you set `max_car_time` to 15 minutes, you could
#'   potentially drive up to 15 minutes to reach transit, and up to _another_ 15
#'   minutes to reach the destination after leaving transit). Defaults to `Inf`,
#'   no limit.
#' @param max_trip_duration An integer. The maximum trip duration in minutes.
#'   Defaults to 120 minutes (2 hours).
#' @param walk_speed A numeric. Average walk speed in km/h. Defaults to 3.6
#'   km/h.
#' @param bike_speed A numeric. Average cycling speed in km/h. Defaults to 12
#'   km/h.
#' @param max_rides An integer. The maximum number of public transport rides
#'   allowed in the same trip. Defaults to 3.
#' @param max_lts An integer between 1 and 4. The maximum level of traffic
#'   stress that cyclists will tolerate. A value of 1 means cyclists will only
#'   travel through the quietest streets, while a value of 4 indicates cyclists
#'   can travel through any road. Defaults to 2. Please see details for more
#'   information.
#' @param n_threads An integer. The number of threads to use when running the
#'   router in parallel. Defaults to use all available threads (Inf).
#' @param progress A logical. Whether to show a progress counter when running
#'   the router. Defaults to `FALSE`. Only works when `verbose` is set to
#'   `FALSE`, so the progress counter does not interfere with `R5`'s output
#'   messages. Setting `progress` to `TRUE` may impose a small penalty for
#'   computation efficiency, because the progress counter must be synchronized
#'   among all active threads.
#' @template time_window_related_args
#' @template draws_per_minute
#' @template verbose
#'
#' @return A `POLYGON  "sf" "data.frame"`
#'
#'
#' @family Isochrone
#' @examples \donttest{
#' library(r5r)
#'
#' # build transport network
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_core <- setup_r5(data_path = data_path)
#'
#' # load origin/point of interest
#' origins <- read.csv(file.path(data_path, "poa_hexgrid.csv"))[c(700,936),]
#'
#' departure_datetime <- as.POSIXct(
#'   "13-05-2019 14:00:00",
#'   format = "%d-%m-%Y %H:%M:%S"
#' )
#'
#'# estimate travel time matrix
#'iso <- isochrone(r5r_core,
#'                 origin = origin,
#'                 mode = c("WALK", "TRANSIT"),
#'                 departure_datetime = departure_datetime,
#'                 cutoffs = c(0, 15, 30, 45, 60, 75, 90, 120),
#'                 max_walk_dist = Inf)
#'                 }'
#'
#' @export
isochrone <- function(r5r_core,
                      origins,
                      mode = "transit",
                      mode_egress = "WALK",
                      cutoffs = c(0, 15, 30),
                      departure_datetime = Sys.time(),
                      time_window = 1L,
                      percentiles = 50L,
                      max_walk_time = Inf,
                      max_bike_time = Inf,
                      max_car_time = Inf,
                      max_trip_duration = 120L,
                      walk_speed = 3.6,
                      bike_speed = 12,
                      max_rides = 3,
                      max_lts = 2,
                      draws_per_minute = 5L,
                      n_threads = Inf,
                      verbose = FALSE,
                      progress = TRUE){


# check inputs ------------------------------------------------------------

  # check cutoffs
  checkmate::assert_numeric(cutoffs, lower = 0)

  # max cutoff is used as max_trip_duration
  max_trip_duration = as.integer(max(cutoffs))

  # include 0 in cutoffs
  if (min(cutoffs) > 0) {cutoffs <- sort(c(0, cutoffs))}


# IF no destinations input ------------------------------------------------------------

    # use all network nodes as destination points
    network <- r5r::street_network_to_sf(r5r_core)
    destinations = network$vertices

    # # sample proportion of nodes to reduce computation ?
    # sample_size <- ifelse(nrow(destinations) < 10000, 1, .33) #
    # index_sample <- sample(1:nrow(destinations), size = nrow(destinations) * sample_size, replace = FALSE)
    # destinations <- destinations[index_sample,]

    names(destinations)[1] <- 'id'
    destinations$id <- as.character(destinations$id)


    # estimate travel time matrix
    ttm <- travel_time_matrix(r5r_core = r5r_core,
                              origins = origins,
                              destinations = destinations,
                              mode = mode,
                              mode_egress = mode_egress,
                              departure_datetime = departure_datetime,
                              time_window = time_window,
                              percentiles = percentiles,
                              max_walk_time = max_walk_time,
                              max_bike_time = max_bike_time,
                              max_car_time = max_car_time,
                              max_trip_duration = max_trip_duration,
                              walk_speed = walk_speed,
                              bike_speed = bike_speed,
                              max_rides = max_rides,
                              max_lts = max_lts,
                              draws_per_minute = draws_per_minute,
                              n_threads = n_threads,
                              verbose = verbose,
                              progress = progress
                              )


    # aggregate travel-times
    ttm[, isochrone := cut(x=travel_time_p50, breaks=cutoffs)]

    # fun to get isochrones for each origin
    prep_iso <- function(orig){ # orig = '89a901280b7ffff'

      temp_ttm <- subset(ttm, from_id == orig)

      # join ttm results to destinations
      dest <- subset(destinations, id %in% temp_ttm$to_id)
      data.table::setDT(dest)[, id := as.character(id)]
      dest[temp_ttm, on=c('id' ='to_id'), c('travel_time_p50', 'isochrone') := list(i.travel_time_p50, i.isochrone)]

      # build polygons with {concaveman}
      # obs. {isoband} is much slower
      dest <- sf::st_as_sf(dest)

      get_poly <- function(cut){ # cut = 30
        temp <- subset(dest, travel_time_p50 <= cut)
        temp_iso <- concaveman::concaveman(temp)
        temp_iso$isochrone <- cut
        return(temp_iso)
      }

      iso_list <- lapply(X=cutoffs[cutoffs>0], FUN=get_poly)
      iso <- data.table::rbindlist(iso_list)
      iso$id <- orig
      iso <- sf::st_sf(iso)
      iso <- iso[ order(-iso$isochrone), ]
      data.table::setcolorder(iso, c('id', 'isochrone'))
      # plot(iso)
      return(iso)
    }

    # get the isocrhone from each origin
    iso_list <- lapply(X = unique(origins$id), FUN = prep_iso)

    # put output together
    iso <- data.table::rbindlist(iso_list)
    iso <- sf::st_sf(iso)
    #plot(iso)
    return(iso)

    # ggplot() +
    #   geom_sf(data=subset(iso, id==unique(iso$id)[1]), aes(fill=isochrone))
    # ggplot() +
    #   geom_sf(data=subset(iso, id==unique(iso$id)[2]), aes(fill=isochrone))

        # # join ttm results to destinations
    # dest <- subset(destinations, id %in% ttm$to_id)
    # data.table::setDT(dest)[, id := as.character(id)]
    # dest[ttm, on=c('id' ='to_id'), c('travel_time_p50', 'isochrone') := list(i.travel_time_p50, i.isochrone)]
    #
    #
    # # build polygons with {concaveman}
    # # obs. {isoband} is much slower
    # dest <- sf::st_as_sf(dest)
    #
    # get_poly <- function(cut){ # cut = 30
    #   temp <- subset(dest, travel_time_p50 <= cut)
    #   temp_iso <- concaveman::concaveman(temp)
    #   temp_iso$isochrone <- cut
    #   return(temp_iso)
    # }
    #
    # iso_list <- lapply(X=cutoffs[cutoffs>0], FUN=get_poly)
    # iso <- data.table::rbindlist(iso_list)
    # iso <- sf::st_sf(iso)
    # iso <- iso[ order(-iso$isochrone), ]
    # # plot(iso)

    return(iso)


# # IF destinations input are polygons ------------------------------------------------------------
#
#   if(!is.null(destinations)){
#
#     # check input
#     if (!any(class(destinations) %like% 'sf')) {stop("'destinations' must be of class 'sf' or 'sfc'")}
#     if (!any(sf::st_geometry_type(destinations) %like% 'POLYGON')) {stop("'destinations' must have geometry type 'POLYGON'")}
#     if (!'id' %in% names(destinations)) {stop("'destinations' must have an 'id' colum")}
#
#     centroids <- sf::st_centroid(destinations)
#
#     # estimate travel time matrix
#     ttm <- travel_time_matrix(r5r_core=r5r_core,
#                               origins = origin,
#                               destinations = centroids,
#                               mode = mode,
#                               departure_datetime = departure_datetime,
#                               # max_walk_dist = max_walk_dist,
#                               max_trip_duration = max_trip_duration,
#                               progress = TRUE
#                               # walk_speed = 3.6,
#                               # bike_speed = 12,
#                               # max_rides = max_rides,
#                               # n_threads = n_threads,
#                               # verbose = verbose
#                               )
#
#     # aggregate travel-times
#     ttm[, isochrone := cut(x=travel_time_p50, breaks=cutoffs)]
#
#     # add isochrone cat to polygon of origin
#
#     # join ttm results to destinations
#     data.table::setDT(destinations)
#     destinations[ttm, on=c('id' ='to_id'), c('travel_time_p50', 'isochrone') := list(i.travel_time_p50, i.isochrone)]
#
#     destinations <- sf::st_as_sf(destinations)
#     # ggplot() + geom_sf(data=destinations, aes(fill=isochrone), color=NA)
#
#     return(destinations)
#   }

}




