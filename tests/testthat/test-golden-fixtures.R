test_that("golden fixtures target the locked RunEvent schema", {
  start <- read_json_fixture("minimal-start.json")
  complete <- read_json_fixture("complete-with-datasets.json")

  expect_identical(start$eventType, "START")
  expect_identical(complete$eventType, "COMPLETE")
  expect_identical(start$schemaURL, OPENLINEAGE_RUN_EVENT_SCHEMA_URL)
  expect_identical(complete$schemaURL, OPENLINEAGE_RUN_EVENT_SCHEMA_URL)
  expect_length(start$inputs, 0L)
  expect_length(complete$inputs, 1L)
  expect_length(complete$outputs, 1L)
})

test_that("semantic JSON comparison ignores object key order", {
  expect_json_semantically_equal(
    '{"job":{"name":"example"},"eventType":"START"}',
    '{"eventType":"START","job":{"name":"example"}}'
  )
})

test_that("semantic JSON comparison preserves array order and empty types", {
  value <- canonicalize_json(
    parse_json_value('{"items":[2,1],"object":{},"array":[]}')
  )

  expect_identical(value$items, list(2L, 1L))
  expect_identical(names(value$object), character())
  expect_null(names(value$array))
})
