#' Format an OpenLineage event time
#'
#' Converts an R date-time to an ISO 8601 UTC timestamp with millisecond
#' precision, suitable for the `eventTime` field of an OpenLineage event.
#'
#' @param time A single, non-missing [`POSIXct`][base::DateTimeClasses] or
#'   `POSIXlt` value. Defaults to the current time.
#'
#' @return A single UTC timestamp string.
#' @export
#'
#' @examples
#' time <- as.POSIXct("2026-01-02 03:04:05", tz = "UTC")
#' new_event_time(time)
new_event_time <- function(time = Sys.time()) {
  .ol_validate_posix_time(time, "time", call = parent.frame())

  seconds <- as.numeric(time)
  whole_seconds <- floor(seconds)
  milliseconds <- floor((seconds - whole_seconds) * 1000 + 1e-7)
  instant <- as.POSIXct(whole_seconds, origin = "1970-01-01", tz = "UTC")

  paste0(
    format(instant, "%Y-%m-%dT%H:%M:%S", tz = "UTC", usetz = FALSE),
    sprintf(".%03dZ", milliseconds)
  )
}
