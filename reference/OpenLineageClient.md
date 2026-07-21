# OpenLineage client

Coordinates event emission through an OpenLineage transport. Supply a
transport directly for local or custom delivery, or configure the
built-in HTTP transport with `url` and related arguments.

When an argument is absent, the client reads `OPENLINEAGE_URL`,
`OPENLINEAGE_ENDPOINT`, `OPENLINEAGE_API_KEY`, and
`OPENLINEAGE_DISABLED`. Explicit arguments take precedence over their
environment equivalents. `OPENLINEAGE_DISABLED` accepts only `true` or
`false`, ignoring case and surrounding whitespace.

A disabled client uses
[NoopTransport](https://pedrobtz.github.io/openlineage/reference/local_transports.md).
An injected `transport` takes precedence over HTTP environment
variables. If neither a transport nor URL is configured, the client uses
[ConsoleTransport](https://pedrobtz.github.io/openlineage/reference/local_transports.md).
Supplying partial HTTP settings without a URL is an error.

## Value

An R6 OpenLineage client object.

## See also

[local_transports](https://pedrobtz.github.io/openlineage/reference/local_transports.md),
[HttpTransport](https://pedrobtz.github.io/openlineage/reference/HttpTransport.md)

## Public fields

- `transport`:

  The configured OpenLineage transport.

## Methods

### Public methods

- [`OpenLineageClient$new()`](#method-OpenLineageClient-initialize)

- [`OpenLineageClient$emit()`](#method-OpenLineageClient-emit)

- [`OpenLineageClient$print()`](#method-OpenLineageClient-print)

- [`OpenLineageClient$clone()`](#method-OpenLineageClient-clone)

------------------------------------------------------------------------

### `OpenLineageClient$new()`

Create an OpenLineage client.

#### Usage

    OpenLineageClient$new(
      transport = NULL,
      url = NULL,
      endpoint = "api/v1/lineage",
      api_key = NULL,
      headers = character(),
      timeout = 5,
      verify_tls = TRUE,
      max_retries = 3L,
      disabled = NULL
    )

#### Arguments

- `transport`:

  An optional R6 transport with an `emit(event)` method.

- `url`:

  An optional HTTP or HTTPS base URL. If `NULL`, `OPENLINEAGE_URL` is
  used when set.

- `endpoint`:

  A relative OpenLineage endpoint path. If omitted,
  `OPENLINEAGE_ENDPOINT` is used when set.

- `api_key`:

  An optional bearer API key. If `NULL`, `OPENLINEAGE_API_KEY` is used
  when set.

- `headers`:

  Optional custom HTTP headers as a named character vector.

- `timeout`:

  A positive HTTP request timeout in seconds.

- `verify_tls`:

  Whether to verify TLS certificates.

- `max_retries`:

  A non-negative number of HTTP retries after the first request attempt.

- `disabled`:

  Whether to disable emission. If `NULL`, `OPENLINEAGE_DISABLED` is used
  when set.

#### Returns

A new `OpenLineageClient` object.

------------------------------------------------------------------------

### `OpenLineageClient$emit()`

Emit an OpenLineage event through the configured transport.

#### Usage

    OpenLineageClient$emit(event)

#### Arguments

- `event`:

  A `RunEvent` model.

#### Returns

`event`, invisibly, after successful delivery.

------------------------------------------------------------------------

### `OpenLineageClient$print()`

Print a credential-free client summary.

#### Usage

    OpenLineageClient$print(...)

#### Arguments

- `...`:

  Unused.

#### Returns

The client, invisibly.

------------------------------------------------------------------------

### `OpenLineageClient$clone()`

The objects of this class are cloneable with this method.

#### Usage

    OpenLineageClient$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
transport <- AccumulatingTransport$new()
client <- OpenLineageClient$new(transport = transport, disabled = FALSE)
event <- RunEvent(
  Run(new_run_id()),
  Job("example", "task"),
  event_type = "START"
)
client$emit(event)
length(transport$events)
#> [1] 1
```
