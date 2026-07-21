complete_event_with_datasets <- function() {
  schema <- SchemaDatasetFacet(list(SchemaField("id", "INTEGER")))

  RunEvent(
    Run(
      fixture_run_id(),
      facets = list(
        nominalTime = NominalTimeRunFacet(
          "2026-01-02T03:00:00.000Z",
          "2026-01-02T04:00:00.000Z"
        )
      )
    ),
    Job(
      "example",
      "transform",
      facets = list(
        sql = SQLJobFacet("SELECT * FROM source", dialect = "ansi")
      )
    ),
    event_type = "COMPLETE",
    event_time = "2026-01-02T03:05:00.000Z",
    inputs = list(
      InputDataset(
        "postgres://warehouse",
        "public.source",
        facets = list(schema = schema),
        input_facets = list(
          inputStatistics = InputStatisticsInputDatasetFacet(
            row_count = 10L,
            size = 1024L,
            file_count = 1L
          )
        )
      )
    ),
    outputs = list(
      OutputDataset(
        "postgres://warehouse",
        "analytics.result",
        facets = list(schema = schema),
        output_facets = list(
          outputStatistics = OutputStatisticsOutputDatasetFacet(
            row_count = 10L,
            size = 512L,
            file_count = 1L
          )
        )
      )
    )
  )
}

test_that("all lifecycle states serialize", {
  states <- c("START", "RUNNING", "COMPLETE", "ABORT", "FAIL", "OTHER")

  for (state in states) {
    event <- RunEvent(
      Run(
        fixture_run_id(),
        facets = list(
          custom = ol_facet(
            "https://example.com/facets/RunMetadata.json",
            state = state
          )
        )
      ),
      Job(
        "example",
        "task",
        facets = list(sql = SQLJobFacet("SELECT 1"))
      ),
      event_type = state,
      event_time = "2026-01-02T03:04:05.000Z"
    )

    value <- as_openlineage_list(event)

    expect_identical(value$eventType, state, info = state)
    expect_identical(value$run$facets$custom$state, state, info = state)
    expect_identical(value$job$facets$sql$query, "SELECT 1", info = state)
  }
})

test_that("terminal event matches the Python golden fixture", {
  expect_json_semantically_equal(
    to_openlineage_json(complete_event_with_datasets()),
    read_json_fixture("complete-with-datasets.json")
  )
})
