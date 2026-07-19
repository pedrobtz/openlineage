# serialization rejects missing and unsupported values

    Code
      as_openlineage_list(data.frame(x = 1))
    Condition
      Error in `as_openlineage_list()`:
      ! Data frames cannot be serialized as OpenLineage values.

---

    Code
      as_openlineage_list(list(value = NA))
    Condition
      Error in `as_openlineage_list()`:
      ! OpenLineage values must not contain unsupported objects or missing values.

---

    Code
      to_openlineage_json(minimal_start_event(), pretty = 1)
    Condition
      Error:
      ! `pretty` must be `TRUE` or `FALSE`.

