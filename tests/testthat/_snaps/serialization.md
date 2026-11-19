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
      ! OpenLineage values must not contain missing values.

---

    Code
      to_openlineage_json(minimal_start_event(), pretty = 1)
    Condition
      Error:
      ! `pretty` must be `TRUE` or `FALSE`.

# values jsonlite would change silently are rejected (#30, #31)

    Code
      generic_text(v = Inf)
    Condition
      Error in `as_openlineage_list()`:
      ! OpenLineage values must not contain infinite numbers.

---

    Code
      generic_text(v = c(a = 1))
    Condition
      Error in `as_openlineage_list()`:
      ! OpenLineage values must not contain named atomic vectors.

---

    Code
      generic_text(v = list(a = 1, a = 2))
    Condition
      Error in `as_openlineage_list()`:
      ! OpenLineage values must not contain lists with repeated names.

# unknown S7 objects and unmapped facets are rejected (#36)

    Code
      as_openlineage_list(UnmappedFacet())
    Condition
      Error in `as_openlineage_list()`:
      ! No wire mapping is registered for facet `UnmappedFacet`.

