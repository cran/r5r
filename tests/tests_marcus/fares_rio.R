# options(java.parameters = '-Xmx16384m')
# options(java.parameters = c("-XX:+UseConcMarkSweepGC", "-Xmx16384m"))

# library(r5r)
devtools::load_all(".")
library(tidyverse)
library(sf)
library(h3jsr)
library(data.table)
library(viridis)
library(patchwork)
library(googlesheets4)

# build transport network
data_path <- "~/Repos/r5r_fares/rio"
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE)

# load origin/destination points

poi <- tribble(
  ~id, ~lat, ~lon,
  "centro", -22.9064720147941, -43.177139635807734,
  "catete", -22.930673881789726, -43.17764097392119,
  "copacabana", -22.96915219120712, -43.18463648168664,
  "pavuna", -22.814726, -43.362337,
  "jardim_oceanico", -23.009335, -43.312220,
  "santa_cruz", -22.914807, -43.688556,
  "madureira", -22.875438, -43.339674
)

points <- read_csv("~/Repos/r5r_fares/rio/points_rio_09_2019.csv") %>%
  rename(id = id_hex, lon=X, lat=Y) %>%
  mutate(unit = 1)
departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")

points_r8 <- h3jsr::get_parent(points$id, res = 8, simple = TRUE)
points_r8 <- unique(points_r8)
points_r8 <- h3jsr::h3_to_point(points_r8, simple = FALSE)
points_r8$id <- points_r8$h3_address
points_r8$unit <- 1
# area_sf <- h3jsr::h3_to_polygon(points$id, simple = FALSE) %>%
#   summarise()


# Setup fare calculator ---------------------------------------------------

fare_settings <- setup_fare_calculator(r5r_core,
                                       base_fare = 405,
                                       by = "MODE")


write_fare_calculator(fare_settings, file_path = here::here("tests_marcus", "rio_fares_v3.zip"))
fare_settings <- read_fare_calculator(file_path = here::here("tests_marcus", "rio_fares_v3.zip"))



fare_settings$base_fare
fare_settings$max_discounted_transfers
fare_settings$transfer_time_allowance
fare_settings$fare_cap
fare_settings$fare_per_mode %>% View()
fare_settings$fare_per_transfer %>% View()
fare_settings$routes_info %>% View()
fare_settings$debug_settings


unique(fare_settings$fares_per_route$route_id)

clipr::write_clip()
clipr::write_clip(fare_settings$fares_per_mode)
clipr::write_clip(fare_settings$fares_per_transfer)
clipr::write_clip(fare_settings$fares_per_route)

### Test --------------------------------------------------------

fare_settings <- read_fare_calculator(file_path = here::here("tests_marcus", "rio_fares_v3.zip"))

fare_settings$debug_settings$output_file <- here::here("tests_marcus", "rio_fare_calculator_output_v7.csv")

# r5r_core$setFareCalculatorDebugOutput(here::here("tests_marcus", "rio_fare_calculator_output_v4.csv"))

access <- accessibility(r5r_core,
                        origins = poi,
                        destinations = points_r8,
                        departure_datetime = departure_datetime,
                        opportunities_colname = "unit",
                        mode = c("WALK", "TRANSIT"),
                        cutoffs = c(30, 45),
                        fare_calculator_settings = fare_settings,
                        max_fare = 10,
                        max_trip_duration = 90,
                        max_walk_dist = 800,
                        time_window = 1,
                        percentiles = 50,
                        verbose = FALSE,
                        progress = TRUE)


rio_debug_v1 <- read_csv(here::here("tests_marcus", "rio_fare_calculator_output.csv"))
rio_debug_v4 <- read_csv(here::here("tests_marcus", "rio_fare_calculator_output_v4.csv"))
rio_debug_v5 <- read_csv(here::here("tests_marcus", "rio_fare_calculator_output_v5.csv"))
rio_debug_v6 <- read_csv(here::here("tests_marcus", "rio_fare_calculator_output_v6.csv"))
rio_debug_v7 <- read_csv(here::here("tests_marcus", "rio_fare_calculator_output_v7.csv"))

tn <- transit_network_to_sf(r5r_core)

mapview::mapview(points_r8, crs = 4326)
mapview::mapview(tn$routes)
rio_debug <- left_join(rio_debug_v1, rio_debug_v4, by = "pattern")

rio_debug %>%
  filter(fare.x != fare.y) %>%
  View()
# Accessibility -----------------------------------------------------------

calculate_access <- function(fares) {

  access_df <- map_df(fares, function(f) {
    f <- as.integer(f)

    r5r_core$setMaxFare(f, "rio-de-janeiro")

    access <- accessibility(r5r_core,
                            origins = points,
                            destinations = points,
                            departure_datetime = departure_datetime,
                            opportunities_colname = "unit",
                            mode = c("WALK", "TRANSIT"),
                            cutoffs = c(30, 45),
                            max_trip_duration = 45,
                            max_walk_dist = 800,
                            time_window = 1,
                            percentiles = 50,
                            verbose = FALSE)

    access$max_fare <- f

    return(access)
  })

  return(access_df)
}

access_df <- calculate_access(c(405, 500, 700)) %>%
  # access_df <- calculate_access(c(240, 480, 720, 960, -1)) %>%
  left_join(points, by = c("from_id" = "id"))

access_df %>%
  filter(cutoff == 45) %>%
  drop_na() %>%
  arrange(accessibility) %>%
  ggplot(aes(x=lon, y=lat)) +
  geom_point(size=1, aes(color=accessibility)) +
  facet_wrap(~max_fare, ncol = 2) +
  scale_color_distiller(palette = "Spectral") +
  coord_map()



# Travel Times ------------------------------------------------------------

r5r_core$setMaxFare(-1L, "rio-de-janeiro") # infinito
r5r_core$setMaxFare(405L, "rio-de-janeiro") # R$ 4,05
r5r_core$setMaxFare(500L, "rio-de-janeiro")
r5r_core$setMaxFare(700L, "rio-de-janeiro")

ttm <- travel_time_matrix(r5r_core,
                        origins = poi[1,],
                        destinations = poi[2,],
                        departure_datetime = departure_datetime,
                        mode = c("WALK", "TRANSIT"),
                        max_trip_duration = 60,
                        max_walk_dist = 800,
                        time_window = 1,
                        percentiles = 50,
                        verbose = FALSE)


# Pareto ------------------------------------------------------------------

fare_settings <- read_fare_calculator(file_path = here::here("tests_marcus", "rio_fares_v3.zip"))

pareto_cutoffs <- c(0, 3.80,  4.05,  4.70,  5.00,  6.05,  6.50,  7.10,  7.60,  8.10,  8.55,  9.40,  10.00)

system.time(
  pareto_df <- pareto_frontier(r5r_core,
                               origins = poi,
                               destinations = poi,
                               mode = c("WALK", "TRANSIT"),
                               departure_datetime = departure_datetime,
                               monetary_cost_cutoffs = pareto_cutoffs,
                               fare_calculator_settings = fare_settings,
                               max_trip_duration = 180,
                               max_walk_dist = 8000,
                               time_window = 1, #30,
                               percentiles = 50, # c(5, 50, 95),
                               max_rides = 5,
                               draws_per_minute = 5L,
                               verbose = FALSE,
                               progress = TRUE)
  )

r5r_core$getFareCalculatorCacheCalls()
r5r_core$getFareCalculatorFullCalls()

# [1] 570551246

pareto_df %>%
  mutate(percentile = factor(percentile),
         pair = paste(from_id, to_id)) %>%
  pivot_longer(cols=starts_with("monetary"), names_to = "mon", values_to="cost") %>%
  ggplot(aes(x=cost, y=travel_time, color=pair)) +
  geom_step() +
  geom_point() +
  # geom_path() +
  # scale_color_brewer(palette = "Set1") +
  # scale_x_continuous(breaks = 0:10, limits = c(0, 10)) +
  # scale_y_continuous(breaks = seq(0, 180, 30), limits = c(0, 180)) +
  theme(legend.position = "none") +
  facet_wrap(~pair)


r5r_core$setMaxFare(10L, "rio-de-janeiro")
r5r_core$verboseMode()


# Pareto Accessibility ----------------------------------------------------
# data <- pareto_df
# cost_threshold <- 1000
access_pareto_map <- function(data, cost_threshold) {
  data_filtered <- data %>%
    drop_na() %>%
    filter(monetary_cost <= cost_threshold)

  if (nrow(data_filtered) == 0) { return(NULL) }
  data_filtered$geometry <- h3jsr::h3_to_polygon(data_filtered$to_id)

  data_sf <- st_as_sf(data_filtered, crs = 4326)

  p <- data_sf %>%
    mutate(cost = cost_threshold/100) %>%
    ggplot() +
    geom_sf(data = area_sf, fill = "grey80", color = NA) +
    geom_sf(aes(fill=travel_time), color = NA) +
    coord_sf(datum = NA) +
    scale_fill_viridis(direction = -1) +
    facet_wrap(~cost) +
    theme(legend.position = "none")

  return(p)
}

pareto_cutoffs <- c(0, 380,  405,  470,  500,  605,  650,  710,  760,  810,  855,  940,  1000)

pareto_df <- pareto_frontier(r5r_core,
                             origins = poi[1,],
                             destinations = points,
                             mode = c("WALK", "TRANSIT"),
                             departure_datetime = departure_datetime,
                             monetary_cost_cutoffs = pareto_cutoffs, #seq(300, 900, 100),
                             fare_calculator = "rio-de-janeiro",
                             max_trip_duration = 90,
                             max_walk_dist = 4000,
                             time_window = 1, #30,
                             percentiles = 50, # c(5, 50, 95),
                             max_rides = 5,
                             verbose = FALSE,
                             progress = TRUE)


unique(pareto_df$monetary_cost)

plots <- map(sort(unique(pareto_df$monetary_cost)), access_pareto_map, data = pareto_df)
# plots <- map(seq(400, 900, 100), access_pareto_map, data = pareto_df)
plots[sapply(plots, is.null)] <- NULL

wrap_plots(plots, ncol = 4) + plot_annotation(title = "Centro")


# Transit Network ---------------------------------------------------------

tn = transit_network_to_sf(r5r_core)
tn$routes %>% View()

tn$routes %>% filter(route_id == 18895165)
