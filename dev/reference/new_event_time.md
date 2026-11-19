# Format an OpenLineage event time

Converts an R date-time to an ISO 8601 UTC timestamp with millisecond
precision, suitable for the `eventTime` field of an OpenLineage event.

## Usage

``` r
new_event_time(time = Sys.time())
```

## Arguments

- time:

  A single, non-missing
  [`POSIXct`](https://rdrr.io/r/base/DateTimeClasses.html) or `POSIXlt`
  value. Defaults to the current time.

## Value

A single UTC timestamp string.

## Details

Sub-millisecond digits are truncated, not rounded, as in the OpenLineage
Python client. The year must be between 0001 and 9999, the range that
RFC 3339 can express.

## Examples

``` r
time <- as.POSIXct("2026-01-02 03:04:05", tz = "UTC")
new_event_time(time)
#> [1] "2026-01-02T03:04:05.000Z"
```
