# Emit an OpenLineage Run Lifecycle

`openlineage` represents protocol values with validated models and
delegates delivery to a transport. This article uses an accumulating
transport, so every example runs without an OpenLineage server or
network connection.

## Create shared run and job metadata

A lifecycle reuses one run identifier and job identity. Facets add
metadata to those core objects.

``` r

library(openlineage)

transport <- AccumulatingTransport$new()
client <- OpenLineageClient$new(transport = transport, disabled = FALSE)

run <- Run(
  new_run_id(),
  facets = list(
    nominalTime = NominalTimeRunFacet(
      "2026-01-02T03:00:00.000Z",
      "2026-01-02T04:00:00.000Z"
    ),
    tags = TagsRunFacet(list(ol_tag("environment", "production")))
  )
)
job <- Job(
  "example-scheduler",
  "daily-orders",
  facets = list(
    sql = SQLJobFacet(
      "SELECT * FROM raw.orders",
      dialect = "ansi"
    )
  )
)
```

## Describe input and output datasets

Dataset facets describe stable dataset metadata. Input- and
output-specific facets describe what happened during this run.

``` r

schema <- SchemaDatasetFacet(list(
  SchemaField("order_id", "INTEGER", ordinal_position = 1L),
  SchemaField("amount", "DECIMAL", ordinal_position = 2L)
))

input <- InputDataset(
  "postgres://warehouse",
  "raw.orders",
  facets = list(schema = schema),
  input_facets = list(
    inputStatistics = InputStatisticsInputDatasetFacet(row_count = 100L)
  )
)
output <- OutputDataset(
  "postgres://warehouse",
  "analytics.daily_orders",
  facets = list(schema = schema),
  output_facets = list(
    outputStatistics = OutputStatisticsOutputDatasetFacet(row_count = 100L)
  )
)
```

## Emit the lifecycle

Emit `START`, optional `RUNNING`, and one terminal event. Terminal
states are `COMPLETE`, `ABORT`, and `FAIL`.

``` r

client$emit(RunEvent(
  run,
  job,
  event_type = "START",
  event_time = "2026-01-02T03:04:05.000Z",
  inputs = list(input)
))
client$emit(RunEvent(
  run,
  job,
  event_type = "RUNNING",
  event_time = "2026-01-02T03:04:30.000Z",
  inputs = list(input)
))
client$emit(RunEvent(
  run,
  job,
  event_type = "COMPLETE",
  event_time = "2026-01-02T03:05:00.000Z",
  inputs = list(input),
  outputs = list(output)
))

vapply(
  transport$events,
  \(event) as_openlineage_list(event)$eventType,
  character(1)
)
#> [1] "START"    "RUNNING"  "COMPLETE"
to_openlineage_json(transport$events[[3]], pretty = TRUE)
#> [1] "{\n  \"eventTime\": \"2026-01-02T03:05:00.000Z\",\n  \"eventType\": \"COMPLETE\",\n  \"inputs\": [\n    {\n      \"facets\": {\n        \"schema\": {\n          \"_producer\": \"https://github.com/pedrobtz/openlineage\",\n          \"_schemaURL\": \"https://openlineage.io/spec/facets/1-2-0/SchemaDatasetFacet.json#/$defs/SchemaDatasetFacet\",\n          \"fields\": [\n            {\n              \"fields\": [],\n              \"name\": \"order_id\",\n              \"ordinal_position\": 1,\n              \"type\": \"INTEGER\"\n            },\n            {\n              \"fields\": [],\n              \"name\": \"amount\",\n              \"ordinal_position\": 2,\n              \"type\": \"DECIMAL\"\n            }\n          ]\n        }\n      },\n      \"inputFacets\": {\n        \"inputStatistics\": {\n          \"_producer\": \"https://github.com/pedrobtz/openlineage\",\n          \"_schemaURL\": \"https://openlineage.io/spec/facets/1-0-0/InputStatisticsInputDatasetFacet.json#/$defs/InputStatisticsInputDatasetFacet\",\n          \"rowCount\": 100\n        }\n      },\n      \"name\": \"raw.orders\",\n      \"namespace\": \"postgres://warehouse\"\n    }\n  ],\n  \"job\": {\n    \"facets\": {\n      \"sql\": {\n        \"_producer\": \"https://github.com/pedrobtz/openlineage\",\n        \"_schemaURL\": \"https://openlineage.io/spec/facets/1-1-0/SQLJobFacet.json#/$defs/SQLJobFacet\",\n        \"query\": \"SELECT * FROM raw.orders\",\n        \"dialect\": \"ansi\"\n      }\n    },\n    \"name\": \"daily-orders\",\n    \"namespace\": \"example-scheduler\"\n  },\n  \"outputs\": [\n    {\n      \"facets\": {\n        \"schema\": {\n          \"_producer\": \"https://github.com/pedrobtz/openlineage\",\n          \"_schemaURL\": \"https://openlineage.io/spec/facets/1-2-0/SchemaDatasetFacet.json#/$defs/SchemaDatasetFacet\",\n          \"fields\": [\n            {\n              \"fields\": [],\n              \"name\": \"order_id\",\n              \"ordinal_position\": 1,\n              \"type\": \"INTEGER\"\n            },\n            {\n              \"fields\": [],\n              \"name\": \"amount\",\n              \"ordinal_position\": 2,\n              \"type\": \"DECIMAL\"\n            }\n          ]\n        }\n      },\n      \"name\": \"analytics.daily_orders\",\n      \"namespace\": \"postgres://warehouse\",\n      \"outputFacets\": {\n        \"outputStatistics\": {\n          \"_producer\": \"https://github.com/pedrobtz/openlineage\",\n          \"_schemaURL\": \"https://openlineage.io/spec/facets/1-0-2/OutputStatisticsOutputDatasetFacet.json#/$defs/OutputStatisticsOutputDatasetFacet\",\n          \"rowCount\": 100\n        }\n      }\n    }\n  ],\n  \"producer\": \"https://github.com/pedrobtz/openlineage\",\n  \"run\": {\n    \"facets\": {\n      \"nominalTime\": {\n        \"_producer\": \"https://github.com/pedrobtz/openlineage\",\n        \"_schemaURL\": \"https://openlineage.io/spec/facets/1-0-1/NominalTimeRunFacet.json#/$defs/NominalTimeRunFacet\",\n        \"nominalStartTime\": \"2026-01-02T03:00:00.000Z\",\n        \"nominalEndTime\": \"2026-01-02T04:00:00.000Z\"\n      },\n      \"tags\": {\n        \"_producer\": \"https://github.com/pedrobtz/openlineage\",\n        \"_schemaURL\": \"https://openlineage.io/spec/facets/1-0-0/TagsRunFacet.json#/$defs/TagsRunFacet\",\n        \"tags\": [\n          {\n            \"key\": \"environment\",\n            \"value\": \"production\"\n          }\n        ]\n      }\n    },\n    \"runId\": \"a710be75-8ca2-4977-8800-7ac283b7a02b\"\n  },\n  \"schemaURL\": \"https://openlineage.io/spec/2-0-2/OpenLineage.json#/$defs/RunEvent\"\n}"
```

## Add an extension facet

Use
[`ol_facet()`](https://pedrobtz.github.io/openlineage/reference/ol_facet.md)
when the backend supports a facet schema without a typed R constructor.
Field names passed through `...` are preserved on the wire.

``` r

quality <- ol_facet(
  "https://example.com/facets/QualityRunFacet.json",
  score = 0.98,
  method = "rules"
)
extended_run <- Run(new_run_id(), facets = list(quality = quality))
as_openlineage_list(extended_run)$facets$quality$score
#> [1] 0.98
```

## Configure delivery and authentication

An explicit `transport` is best for tests and integrations. For HTTP
delivery, provide `url` directly or set `OPENLINEAGE_URL`. The client
also recognizes `OPENLINEAGE_ENDPOINT`, `OPENLINEAGE_API_KEY`, and
`OPENLINEAGE_DISABLED`. Explicit constructor values take precedence over
environment variables.

These examples construct clients but do not emit, so they remain
offline:

``` r

bearer_client <- OpenLineageClient$new(
  url = "https://lineage.example.com",
  api_key = "replace-with-your-secret",
  disabled = FALSE
)
header_client <- OpenLineageClient$new(
  url = "https://lineage.example.com",
  headers = c(`X-Tenant` = "analytics"),
  disabled = FALSE
)
bearer_client
#> <OpenLineageClient>
#>   transport: HttpTransport
header_client
#> <OpenLineageClient>
#>   transport: HttpTransport
```

API keys become bearer credentials. A custom `Authorization` header is
also supported when `api_key` is absent. Never disable TLS verification
outside a controlled development environment.

## Handle failures

Package conditions have stable classes that can be handled with
[`tryCatch()`](https://rdrr.io/r/base/conditions.html). HTTP 401 and 403
responses use `openlineage_auth_error`; other HTTP failures use
`openlineage_http_error`; delivery failures inherit from
`openlineage_transport_error`.

``` r

condition <- tryCatch(
  client$emit("not a RunEvent"),
  openlineage_error = identity
)
class(condition)
#> [1] "openlineage_validation_error" "openlineage_error"           
#> [3] "rlang_error"                  "error"                       
#> [5] "condition"
conditionMessage(condition)
#> [1] "\033[1m\033[22m`event` must be a `RunEvent` object."
```

Configuration errors use `openlineage_config_error`, while invalid
event, model, or facet values use `openlineage_validation_error`.
Conditions and printed clients omit credentials.
