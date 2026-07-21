minimal_start_event <- function() {
  RunEvent(
    Run(fixture_run_id()),
    Job("example", "minimal"),
    event_type = "START",
    event_time = "2026-01-02T03:04:05.000Z"
  )
}

test_that("core models convert to OpenLineage wire names", {
  value <- as_openlineage_list(minimal_start_event())

  expect_named(
    value,
    c(
      "eventTime",
      "eventType",
      "inputs",
      "job",
      "outputs",
      "producer",
      "run",
      "schemaURL"
    )
  )
  expect_identical(value$eventType, "START")
  expect_identical(value$run$runId, fixture_run_id())
  expect_identical(names(value$run$facets), character())
  expect_null(names(value$inputs))
})

test_that("serialization omits explicit NULL properties", {
  event <- RunEvent(
    Run(fixture_run_id(), facets = NULL),
    Job("example", "minimal", facets = NULL),
    event_time = "2026-01-02T03:04:05.000Z",
    inputs = NULL,
    outputs = NULL
  )
  value <- as_openlineage_list(event)

  expect_named(value, c("eventTime", "job", "producer", "run", "schemaURL"))
  expect_named(value$run, "runId")
  expect_named(value$job, c("name", "namespace"))
})

test_that("NULL omission is recursive for objects and arrays", {
  value <- as_openlineage_list(list(
    object = list(keep = 1L, drop = NULL),
    array = list(NULL, "keep")
  ))

  expect_named(value$object, "keep")
  expect_identical(value$array, list("keep"))
})

test_that("input and output datasets use role-specific wire fields", {
  input <- as_openlineage_list(
    InputDataset(
      "postgres://warehouse",
      "public.source",
      input_facets = list(
        stats = ol_facet("https://example.com/InputStats.json", rowCount = 10L)
      )
    )
  )
  output <- as_openlineage_list(
    OutputDataset(
      "postgres://warehouse",
      "analytics.result",
      output_facets = list(
        stats = ol_facet("https://example.com/OutputStats.json", rowCount = 10L)
      )
    )
  )

  expect_named(input, c("facets", "inputFacets", "name", "namespace"))
  expect_named(output, c("facets", "name", "namespace", "outputFacets"))
})

test_that("minimal START event matches the Python golden fixture", {
  expected <- read_json_fixture("minimal-start.json")
  actual <- to_openlineage_json(minimal_start_event())

  expect_json_semantically_equal(actual, expected)
})

test_that("JSON serialization is deterministic and optionally pretty", {
  compact <- to_openlineage_json(minimal_start_event())
  repeated <- to_openlineage_json(minimal_start_event())
  pretty <- to_openlineage_json(minimal_start_event(), pretty = TRUE)

  expect_identical(compact, repeated)
  expect_match(pretty, "\\n")
  expect_json_semantically_equal(compact, pretty)
})

test_that("serialization rejects missing and unsupported values", {
  expect_snapshot(error = TRUE, as_openlineage_list(data.frame(x = 1)))
  expect_snapshot(error = TRUE, as_openlineage_list(list(value = NA)))
  expect_snapshot(
    error = TRUE,
    to_openlineage_json(minimal_start_event(), pretty = 1)
  )
})
