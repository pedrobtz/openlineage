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

test_that("every typed facet matches the Python golden fixture (#35)", {
  expect_json_semantically_equal(
    to_openlineage_json(all_facets_event()),
    read_json_fixture("all-facets.json")
  )
})

test_that("generic numbers match the Python golden fixture (#22)", {
  facet <- ol_facet(
    "https://example.com/NumbersRunFacet.json",
    sum = 0.1 + 0.2,
    long = 123456789.123456789,
    two53 = 2^53,
    big = 3e9,
    quadrillion = 1e15,
    negative = -2.5,
    tiny = 2^-20
  )

  expect_json_semantically_equal(
    to_openlineage_json(facet),
    read_json_fixture("generic-numbers.json")
  )
})
