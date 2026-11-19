# invalid HTTP events fail before making a request

    Code
      transport$emit("serialized JSON")
    Condition
      Error:
      ! `event` must be a `RunEvent` object.

# authentication failures are classified and never retried

    Code
      HttpTransport$new("https://example.com")$emit(http_transport_event())
    Condition
      Error:
      ! OpenLineage authentication failed with HTTP 401.

# exhausted low-level failures keep their cause, not credentials (#26)

    Code
      transport$emit(http_transport_event())
    Condition
      Error:
      ! OpenLineage HTTP request failed before receiving a response.
      Caused by: Could not resolve host: example.com

# HTTP retries are bounded

    Code
      attempts <- 0L
      transport$emit(http_transport_event())
    Condition
      Error:
      ! OpenLineage server returned HTTP 503.

# disabling TLS verification warns and configures curl

    Code
      invisible(HttpTransport$new("https://example.com", verify_tls = FALSE))
    Condition
      Warning:
      TLS certificate verification is disabled. Use this only in a controlled development environment.

# HTTP configuration rejects unsafe or conflicting values

    Code
      HttpTransport$new("ftp://example.com")
    Condition
      Error:
      ! `url` must be an absolute HTTP or HTTPS URL without credentials, a query, or a fragment.

---

    Code
      HttpTransport$new("https://user:password@example.com")
    Condition
      Error:
      ! `url` must be an absolute HTTP or HTTPS URL without credentials, a query, or a fragment.

---

    Code
      HttpTransport$new("https://example.com?tenant=analytics")
    Condition
      Error:
      ! `url` must be an absolute HTTP or HTTPS URL without credentials, a query, or a fragment.

---

    Code
      HttpTransport$new("https://example.com", endpoint = "../lineage")
    Condition
      Error:
      ! `endpoint` must be a non-empty relative path without `.` or `..` segments.

---

    Code
      HttpTransport$new("https://example.com", endpoint = "")
    Condition
      Error:
      ! `endpoint` must be a non-empty string.

---

    Code
      HttpTransport$new("https://example.com", api_key = "api-key", headers = c(
        authorization = "Bearer custom"))
    Condition
      Error:
      ! Use either `api_key` or a custom `Authorization` header, not both.

---

    Code
      HttpTransport$new("https://example.com", headers = c(`Content-Type` = "text/plain"))
    Condition
      Error:
      ! `Content-Type` is managed by `HttpTransport` and cannot be customized.

---

    Code
      HttpTransport$new("https://example.com", headers = c(`X-Test` = "value\r\ninjected: true"))
    Condition
      Error:
      ! `headers` must have unique, valid names and values without line breaks.

---

    Code
      HttpTransport$new("https://example.com", headers = c(`X-Test` = "one",
        `x-test` = "two"))
    Condition
      Error:
      ! `headers` must have unique, valid names and values without line breaks.

---

    Code
      HttpTransport$new("https://example.com", timeout = 0)
    Condition
      Error:
      ! `timeout` must be a number of seconds between 0.001 and 2147483.

---

    Code
      HttpTransport$new("https://example.com", max_retries = 1.5)
    Condition
      Error:
      ! `max_retries` must be an integer-like number greater than or equal to 0.

---

    Code
      HttpTransport$new("https://example.com", api_key = "invalid key")
    Condition
      Error:
      ! `api_key` must be a non-empty string without whitespace, or `NULL`.

---

    Code
      HttpTransport$new("https://example.com", verify_tls = NA)
    Condition
      Error:
      ! `verify_tls` must be `TRUE` or `FALSE`.

# redirects are not followed and raise a classed error (#21)

    Code
      transport$emit(http_transport_event())
    Condition
      Error:
      ! OpenLineage server returned HTTP 308; redirects are not followed.

# timeout is bounded at construction (#27)

    Code
      HttpTransport$new("https://example.com", timeout = 1e-05)
    Condition
      Error:
      ! `timeout` must be a number of seconds between 0.001 and 2147483.

# URL and endpoint values that change the path are rejected (#28)

    Code
      HttpTransport$new("http://host", endpoint = "api/%2e%2e/admin")
    Condition
      Error:
      ! `endpoint` must be a non-empty relative path without `.` or `..` segments.

---

    Code
      HttpTransport$new("http://host", endpoint = "a b")
    Condition
      Error:
      ! `endpoint` must not contain whitespace or control characters.

