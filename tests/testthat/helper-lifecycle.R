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
