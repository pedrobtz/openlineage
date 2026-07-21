# client validates events before calling a custom transport

    Code
      client$emit("serialized JSON")
    Condition
      Error:
      ! `event` must be a `RunEvent` object.

# invalid and conflicting client settings are rejected

    Code
      OpenLineageClient$new(disabled = NA)
    Condition
      Error:
      ! `disabled` must be `TRUE`, `FALSE`, or `NULL`.

---

    Code
      OpenLineageClient$new(disabled = "true")
    Condition
      Error:
      ! `disabled` must be `TRUE`, `FALSE`, or `NULL`.

---

    Code
      OpenLineageClient$new(transport = transport, url = "https://example.com")
    Condition
      Error:
      ! `transport` cannot be combined with HTTP argument(s): `url`.

---

    Code
      OpenLineageClient$new(transport = transport, timeout = 10)
    Condition
      Error:
      ! `transport` cannot be combined with HTTP argument(s): `timeout`.

---

    Code
      OpenLineageClient$new(transport = list())
    Condition
      Error in `OpenLineageClient$new()`:
      ! `transport` must be an R6 object with an `emit(event)` method.

---

    Code
      OpenLineageClient$new(api_key = "orphan-key")
    Condition
      Error:
      ! HTTP setting(s) `api_key` require `url` or `OPENLINEAGE_URL`.

---

    Code
      OpenLineageClient$new(endpoint = "orphan/lineage")
    Condition
      Error:
      ! HTTP setting(s) `endpoint` require `url` or `OPENLINEAGE_URL`.

# invalid disabled environment values are rejected

    Code
      OpenLineageClient$new()
    Condition
      Error:
      ! `OPENLINEAGE_DISABLED` must be `true` or `false`.

