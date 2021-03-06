% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{check_connection}
\alias{check_connection}
\title{Check internet connection with Ipea server}
\usage{
check_connection(
  file_url = "https://www.ipea.gov.br/geobr/metadata/metadata_gpkg.csv"
)
}
\arguments{
\item{file_url}{A string with the file_url address of an geobr dataset}
}
\value{
No return value, called for side effects.
}
\description{
Checks if there is internet connection to Ipea server to download geobr data.
}
\seealso{
Other support functions: 
\code{\link{assert_decay_function}()},
\code{\link{assert_points_input}()},
\code{\link{download_metadata}()},
\code{\link{find_snap}()},
\code{\link{posix_to_string}()},
\code{\link{select_mode}()},
\code{\link{set_max_lts}()},
\code{\link{set_max_rides}()},
\code{\link{set_max_street_time}()},
\code{\link{set_n_threads}()},
\code{\link{set_speed}()},
\code{\link{set_suboptimal_minutes}()},
\code{\link{set_verbose}()},
\code{\link{stop_r5}()},
\code{\link{street_network_to_sf}()}
}
\concept{support functions}
