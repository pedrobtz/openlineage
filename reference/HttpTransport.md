# Synchronous HTTP transport

Sends OpenLineage events as JSON `POST` requests. The base `url` and
relative `endpoint` are joined with one slash; a URL that already ends
in the endpoint is not duplicated.

Supply `api_key` for `Authorization: Bearer <key>` authentication, or
place authentication headers in `headers`. Supplying both an API key and
a custom `Authorization` header is an error. All custom headers are
redacted from httr2 request printing.

HTTP 429, 500, 502, 503, and 504 responses and low-level connection
failures are retried up to `max_retries` times. HTTP 401 and 403
responses are never retried. Set `verify_tls = FALSE` only for
controlled development environments; doing so raises an
`openlineage_insecure_tls_warning`.

## Value

An R6 HTTP transport object.

## See also

[local_transports](https://pedrobtz.github.io/openlineage/reference/local_transports.md)

## Super class

`OpenLineageTransport` -\> `HttpTransport`

## Methods

### Public methods

- [`HttpTransport$new()`](#method-HttpTransport-initialize)

- [`HttpTransport$emit()`](#method-HttpTransport-emit)

- [`HttpTransport$print()`](#method-HttpTransport-print)

- [`HttpTransport$clone()`](#method-HttpTransport-clone)

Inherited methods

- `OpenLineageTransport$close()`

------------------------------------------------------------------------

### `HttpTransport$new()`

Create an HTTP transport.

#### Usage

    HttpTransport$new(
      url,
      endpoint = "api/v1/lineage",
      api_key = NULL,
      headers = character(),
      timeout = 5,
      verify_tls = TRUE,
      max_retries = 3L
    )

#### Arguments

- `url`:

  An absolute HTTP or HTTPS base URL.

- `endpoint`:

  A relative OpenLineage endpoint path.

- `api_key`:

  An optional bearer API key.

- `headers`:

  Optional custom headers as a named character vector.

- `timeout`:

  A positive request timeout in seconds.

- `verify_tls`:

  Whether to verify TLS certificates.

- `max_retries`:

  A non-negative number of retries after the first request attempt.

#### Returns

A new `HttpTransport` object.

------------------------------------------------------------------------

### `HttpTransport$emit()`

Send an event to the configured OpenLineage HTTP endpoint.

#### Usage

    HttpTransport$emit(event)

#### Arguments

- `event`:

  A `RunEvent` model.

#### Returns

`event`, invisibly, after a successful HTTP response.

------------------------------------------------------------------------

### `HttpTransport$print()`

Print a redacted transport summary.

#### Usage

    HttpTransport$print(...)

#### Arguments

- `...`:

  Unused.

#### Returns

The transport, invisibly.

------------------------------------------------------------------------

### `HttpTransport$clone()`

The objects of this class are cloneable with this method.

#### Usage

    HttpTransport$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
transport <- HttpTransport$new("https://example.com")
transport
#> <HttpTransport>
#>   endpoint: https://example.com/api/v1/lineage
#>   authentication: none
```
