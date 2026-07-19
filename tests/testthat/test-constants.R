test_that("OpenLineage constants identify the targeted schema", {
  expect_identical(OPENLINEAGE_SCHEMA_VERSION, "2.0.2")
  expect_identical(
    OPENLINEAGE_SCHEMA_URL,
    "https://openlineage.io/spec/2-0-2/OpenLineage.json"
  )
  expect_identical(
    OPENLINEAGE_RUN_EVENT_SCHEMA_URL,
    paste0(OPENLINEAGE_SCHEMA_URL, "#/$defs/RunEvent")
  )
  expect_match(OPENLINEAGE_PRODUCER, "^https://")
})
