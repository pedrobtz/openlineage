# typed facets enforce their placement

    Code
      Run(fixture_run_id(), list(sql = SQLJobFacet("SELECT 1")))
    Condition
      Error:
      ! Every element of `facets` must be a compatible run facet created by a typed constructor or `ol_facet()`.

---

    Code
      Job("example", "task", list(nominal = NominalTimeRunFacet(
        "2026-01-02T03:00:00Z")))
    Condition
      Error:
      ! Every element of `facets` must be a compatible job facet created by a typed constructor or `ol_facet()`.

---

    Code
      InputDataset("example", "input", input_facets = list(stats = OutputStatisticsOutputDatasetFacet()))
    Condition
      Error:
      ! Every element of `input_facets` must be a compatible input facet created by a typed constructor or `ol_facet()`.

---

    Code
      OutputDataset("example", "output", output_facets = list(stats = InputStatisticsInputDatasetFacet()))
    Condition
      Error:
      ! Every element of `output_facets` must be a compatible output facet created by a typed constructor or `ol_facet()`.

# facet validation rejects malformed values

    Code
      ol_facet("https://example.com/facets/CustomFacet.json", `_producer` = "https://example.com/other")
    Condition
      Error:
      ! Reserved facet field must be supplied through `producer`, `schema_url`, or `deleted`: `_producer`.

---

    Code
      NominalTimeRunFacet("2026-01-02 03:00:00")
    Condition
      Error:
      ! `nominal_start_time` must be an RFC 3339 date-time with a time-zone offset.

---

    Code
      SchemaDatasetFacet(list("not a field"))
    Condition
      Error:
      ! Every element of `fields` must be a `SchemaField` object.

---

    Code
      InputStatisticsInputDatasetFacet(1.5)
    Condition
      Error:
      ! `row_count` must be an integer-like number or `NULL`.

---

    Code
      EmissionPattern("PERIODIC", "SNAPSHOT", 0L)
    Condition
      Error:
      ! `window_duration` must be an integer-like number greater than or equal to 1.

---

    Code
      TagsRunFacet(list(ol_tag("pii", "true", field = "email")))
    Condition
      Error:
      ! `field` is supported only by `TagsDatasetFacet`.

