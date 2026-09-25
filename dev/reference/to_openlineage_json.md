# Serialize an OpenLineage value to JSON

Serialize an OpenLineage value to JSON

## Usage

``` r
to_openlineage_json(x, pretty = FALSE)
```

## Arguments

- x:

  An OpenLineage model or supported nested value.

- pretty:

  Whether to add indentation and line breaks.

## Value

A single JSON string.

## Examples

``` r
event <- RunEvent(
  Run("019c0000-0000-7000-8000-000000000001"),
  Job("example", "task"),
  event_type = "START",
  event_time = "2026-01-02T03:04:05.000Z"
)
to_openlineage_json(event)
#> [1] "{\"eventTime\":\"2026-01-02T03:04:05.000Z\",\"eventType\":\"START\",\"inputs\":[],\"job\":{\"facets\":{},\"name\":\"task\",\"namespace\":\"example\"},\"outputs\":[],\"producer\":\"https://github.com/pedrobtz/openlineage\",\"run\":{\"facets\":{},\"runId\":\"019c0000-0000-7000-8000-000000000001\"},\"schemaURL\":\"https://openlineage.io/spec/2-0-2/OpenLineage.json#/$defs/RunEvent\"}"
```
