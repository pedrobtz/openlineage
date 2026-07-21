# openlineage

`openlineage` is an R client for constructing, validating, serializing,
and emitting [OpenLineage](https://openlineage.io/) run events. It
targets the OpenLineage 2.0.2 schema and supports synchronous HTTP
delivery as well as offline transports for development and testing.

## Installation

Install the released package from CRAN with:

``` r

install.packages("openlineage")
```

## Quick start

Use an accumulating transport to exercise a complete lifecycle without a
server or network connection:

``` r

library(openlineage)

transport <- AccumulatingTransport$new()
client <- OpenLineageClient$new(transport = transport, disabled = FALSE)

run <- Run(new_run_id())
job <- Job("example", "daily-orders")

client$emit(RunEvent(run, job, event_type = "START"))
client$emit(RunEvent(run, job, event_type = "RUNNING"))
client$emit(RunEvent(run, job, event_type = "COMPLETE"))

length(transport$events)
to_openlineage_json(transport$events[[3]], pretty = TRUE)
```

See
[`vignette("openlineage-lifecycle")`](https://pedrobtz.github.io/openlineage/articles/openlineage-lifecycle.md)
for datasets, facets, configuration, authentication, and failure
handling.

## HTTP delivery and authentication

Create a client with an explicit endpoint. Constructing the client does
not make a request; `emit()` performs synchronous delivery.

``` r

client <- OpenLineageClient$new(
  url = "https://lineage.example.com",
  api_key = "replace-with-your-secret",
  timeout = 10,
  max_retries = 3L
)
```

`api_key` produces a bearer `Authorization` header. Backend-specific
headers can instead be supplied as a named character vector through
`headers`. Do not combine `api_key` with a custom `Authorization`
header. Credentials are kept out of events, printed clients, and package
conditions.

The client recognizes these environment variables when the corresponding
constructor value is absent:

| Variable | Purpose |
|----|----|
| `OPENLINEAGE_URL` | HTTP server base URL |
| `OPENLINEAGE_ENDPOINT` | Relative path; defaults to `api/v1/lineage` |
| `OPENLINEAGE_API_KEY` | Bearer API key |
| `OPENLINEAGE_DISABLED` | `true` selects no-op delivery; `false` enables emission |

Explicit values take precedence over environment values. An injected
transport ignores HTTP environment settings. With no transport or URL,
events are printed through `ConsoleTransport`.

## Facets and extensions

Typed constructors cover common run, job, dataset, and statistics
facets. Use
[`ol_facet()`](https://pedrobtz.github.io/openlineage/reference/ol_facet.md)
for a schema without a typed R constructor:

``` r

custom <- ol_facet(
  "https://example.com/facets/QualityRunFacet.json",
  score = 0.98,
  method = "rules"
)
run <- Run(new_run_id(), facets = list(quality = custom))
```

Transport failures inherit from `openlineage_transport_error`. HTTP and
authentication failures additionally use `openlineage_http_error` and
`openlineage_auth_error`, respectively. Configuration and model failures
use `openlineage_config_error` and `openlineage_validation_error`.
