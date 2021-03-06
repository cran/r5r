# nocov start
utils::globalVariables(c(".", "%>%", ":=", "%like%", "%chin%", "set"))

.onLoad = function(lib, pkg) {
  requireNamespace("sf")
  requireNamespace("rJava")
  requireNamespace("data.table")
}

.onAttach <- function(lib, pkg) {

  packageStartupMessage(paste0("Please make sure you have already allocated ",
                               "some memory to Java by running:\n",
                               "  options(java.parameters = '-Xmx2G').\n",
                               "Currently, Java memory is set to ",
                               getOption("java.parameters")))
}



#' @importFrom data.table := %between% fifelse %chin% set
#' @importFrom methods is signature
#' @importFrom curl has_internet
NULL



## quiets concerns of R CMD check re: the .'s that appear in pipelines
if(getRversion() >= "2.15.1") utils::globalVariables(
  c('is', 'duration', 'fromId', 'toId', 'option', 'option', '.SD', 'geometry',
    'route', 'temp_duration', 'temp_route', 'route', 'temp_sign', '.I',
    'segment_duration', 'total_duration', 'wait', 'release_date', 'con',
    "start_lon", "start_lat", "end_lon", "end_lat", "slope",
    "walk_multiplier", "bike_multiplier", "found"))




# nocov end
