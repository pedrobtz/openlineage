#' Format an OpenLineage event time
#'
#' Converts an R date-time to an ISO 8601 UTC timestamp with millisecond
#' precision, suitable for the `eventTime` field of an OpenLineage event.
#'
#' Sub-millisecond digits are truncated, not rounded, as in the OpenLineage
#' Python client. The year must be between 0001 and 9999, the range that
#' RFC 3339 can express.
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
  .ol_event_time(time, "time", call = parent.frame())
}

.ol_event_time <- function(time, arg, call = parent.frame()) {
  .ol_validate_posix_time(time, arg, call = call)

  seconds <- as.numeric(time)
  whole_seconds <- floor(seconds)
  # A double near the current epoch carries about seven fractional digits, so
  # `.123` is stored as `.12299990...`. Rounding to microseconds first removes
  # that error; truncating to milliseconds then matches the Python client.
  microseconds <- round((seconds - whole_seconds) * 1e6)
  milliseconds <- min(microseconds %/% 1000, 999)
  instant <- as.POSIXlt(whole_seconds, origin = "1970-01-01", tz = "UTC")

  year <- instant$year + 1900L
  if (year < 1L || year > 9999L) {
    .ol_abort(
      paste0("`", arg, "` must fall between the years 0001 and 9999."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  paste0(
    sprintf(
      "%04d-%02d-%02dT%02d:%02d:%02d",
      year,
      instant$mon + 1L,
      instant$mday,
      instant$hour,
      instant$min,
      as.integer(instant$sec)
    ),
    sprintf(".%03dZ", as.integer(milliseconds))
  )
}
