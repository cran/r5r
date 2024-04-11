## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = identical(tolower(Sys.getenv("NOT_CRAN")), "true"),
  out.width = "100%"
)

## ----echo = FALSE, fig.width=7, fig.height=4----------------------------------
library(ggplot2)

# data.frame
df <- structure(list(option = c(1, 2, 3, 4, 5), 
                     modes = c("Walk", "Bus","Bus + Bus", "Subway", "Bus + Subway"), 
                     time = c(50, 35, 29, 20, 15), 
                     cost = c(0, 3, 5, 6, 8)), class = "data.frame", 
                row.names = c(NA, -5L))

# figure
ggplot(data=df, aes(x=cost, y=time, label = modes)) + 
  geom_step(linetype = "dashed") +
  geom_point() +
  geom_text(color='gray30', hjust = -.2, nudge_x = 0.05, angle = 45) +
  labs(title='Pareto frontier of alternative routes from A to B', subtitle = 'Hypotetical example') +
  scale_x_continuous(name="Travel cost (BRL)", breaks=seq(0,12,3)) +
  scale_y_continuous(name="Travel time (minutes)", breaks=seq(0,60,10)) +
  coord_cartesian(xlim = c(0,14), ylim = c(0, 60)) +
  theme_classic()

## ----message = FALSE----------------------------------------------------------
# increase Java memory
options(java.parameters = "-Xmx2G")

# load libraries
library(r5r)
library(data.table)
library(ggplot2)
library(dplyr)

# build a routable transport network with r5r
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path)

# routing inputs
mode <- c('walk', 'transit')
max_trip_duration <- 90 # minutes

# load origin/destination points of interest
points <- fread(file.path(data_path, "poa_points_of_interest.csv"))


## -----------------------------------------------------------------------------
# create basic fare structure
fare_structure <- setup_fare_structure(r5r_core, 
                                       base_fare = 4.8,
                                       by = "MODE")

# update the cost of bus and train fares
fare_structure$fares_per_type[, fare := fcase(type == "BUS", 4.80,
                                             type == "RAIL", 4.50)]

# update the cost of tranfers
fare_structure$fares_per_transfer[, fare := fcase(first_leg == "BUS" & second_leg == "BUS", 7.2,
                                                 first_leg != second_leg, 8.37)]

# update transfer_time_allowance to 60 minutes
fare_structure$transfer_time_allowance <- 60

fare_structure$fares_per_type[type == "RAIL", unlimited_transfers := TRUE]
fare_structure$fares_per_type[type == "RAIL", allow_same_route_transfer := TRUE]


## -----------------------------------------------------------------------------
# save fare rules to temp file
temp_fares <- tempfile(pattern = "fares_poa", fileext = ".zip")
r5r::write_fare_structure(fare_structure, file_path = temp_fares)


fare_structure <- r5r::read_fare_structure(file.path(data_path, "fares/fares_poa.zip"))

## -----------------------------------------------------------------------------
departure_datetime <- as.POSIXct("13-05-2019 14:00:00", 
                                 format = "%d-%m-%Y %H:%M:%S")

prtf <- pareto_frontier(r5r_core,
                      origins = points,
                      destinations = points,
                      mode = c("WALK", "TRANSIT"),
                      departure_datetime = departure_datetime,
                      fare_structure = fare_structure,
                      fare_cutoffs = c(1, 4.5, 4.8, 7.20, 8.37),
                      progress = TRUE
                      )
head(prtf)


## ----echo = FALSE, fig.width=7, fig.height=4----------------------------------
# select origin and destinations
pf2 <- dplyr::filter(prtf, to_id == 'farrapos_station'  &
                       from_id %in% c('moinhos_de_vento_hospital', 
                                      'praia_de_belas_shopping_center'))

# recode modes
pf2[, modes := fcase(monetary_cost == 1,   'Walk',
                     monetary_cost == 4.5, 'Train',
                     monetary_cost == 4.8, 'Bus',
                     monetary_cost == 7.2, 'Bus + Bus',
                     monetary_cost == 8.37, 'Bus + Train')]

# plot
ggplot(data=pf2, aes(x=monetary_cost, y=travel_time, color=from_id, label = modes)) + 
  geom_step(linetype = "dashed") +
  geom_point() +
  geom_text(color='gray30', hjust = -.2, nudge_x = 0.05, angle = 45) +
  labs(title='Pareto frontier of alternative routes from Farrapos station to:', 
       subtitle = 'Praia de Belas shopping mall and Moinhos hospital',
       color='Destination') +
  scale_x_continuous(name="Travel cost ($)", breaks=seq(0,12,2)) +
  scale_y_continuous(name="Travel time (minutes)", breaks=seq(0,120,20)) +
  coord_cartesian(xlim = c(0,12), ylim = c(0, 120)) +
  theme_classic() + theme(legend.position=c(.2,0.8))

## ----message = FALSE----------------------------------------------------------
r5r::stop_r5(r5r_core)
rJava::.jgc(R.gc = TRUE)

