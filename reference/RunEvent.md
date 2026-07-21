# OpenLineage run event

Describes a lifecycle transition for one job run and its input and
output datasets.

## Usage

``` r
RunEvent(
  run,
  job,
  event_type = NULL,
  event_time = new_event_time(),
  inputs = list(),
  outputs = list(),
  producer = OPENLINEAGE_PRODUCER,
  schema_url = OPENLINEAGE_RUN_EVENT_SCHEMA_URL
)
```

## Arguments

- run:

  A `Run` object.

- job:

  A `Job` object.

- event_type:

  A `RunState`, a valid state string, or `NULL` to omit it.

- event_time:

  An RFC 3339 date-time string with a time-zone offset.

- inputs:

  An unnamed list of `InputDataset` objects, or `NULL`.

- outputs:

  An unnamed list of `OutputDataset` objects, or `NULL`.

- producer:

  A URI identifying the event producer.

- schema_url:

  The RunEvent JSON Schema URL.

## Value

A `RunEvent` S7 object.

## Examples

``` r
run <- Run(new_run_id())
job <- Job("example-scheduler", "daily-report")
RunEvent(
  run,
  job,
  event_type = "START",
  event_time = new_event_time(as.POSIXct("2026-01-02", tz = "UTC"))
)
#> <openlineage::RunEvent>
#>  @ run       : <openlineage::Run>
#>  .. @ run_id: chr "bafe7b2f-cee7-4a93-ab76-67ba1222201a"
#>  .. @ facets: Named list()
#>  @ job       : <openlineage::Job>
#>  .. @ namespace: chr "example-scheduler"
#>  .. @ name     : chr "daily-report"
#>  .. @ facets   : Named list()
#>  @ event_type: <openlineage::RunState> chr "START"
#>  @ event_time: chr "2026-01-02T00:00:00.000Z"
#>  @ inputs    : list()
#>  @ outputs   : list()
#>  @ producer  : chr "https://github.com/pedrobtz/openlineage"
#>  @ schema_url: chr "https://openlineage.io/spec/2-0-2/OpenLineage.json#/$defs/RunEvent"
```
