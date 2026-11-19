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

# The event in fixtures/all-facets.json, built with the package's
# constructors; generate-fixtures.py builds it with the Python client.
all_facets_event <- function() {
  source_field <- ColumnLineageInputField(
    "postgres://warehouse",
    "public.source",
    "id",
    list(ColumnLineageTransformation("DIRECT", "IDENTITY", masking = FALSE))
  )

  RunEvent(
    Run(
      fixture_run_id(),
      facets = list(
        nominalTime = NominalTimeRunFacet(
          "2026-01-02T03:00:00.000Z",
          "2026-01-02T04:00:00.000Z"
        ),
        parent = ParentRunFacet(
          Run("019c0000-0000-7000-8000-000000000002"),
          Job("scheduler", "parent-dag"),
          root = list(
            run = Run("019c0000-0000-7000-8000-000000000003"),
            job = Job("scheduler", "root-dag")
          )
        ),
        errorMessage = ErrorMessageRunFacet(
          "Query failed",
          "R",
          stack_trace = "Error in f(): failed"
        ),
        processingEngine = ProcessingEngineRunFacet(
          "4.6.0",
          name = "R",
          openlineage_adapter_version = "0.2.0"
        ),
        tags = TagsRunFacet(list(ol_tag("team", "data", source = "USER")))
      )
    ),
    Job(
      "example",
      "all-facets",
      facets = list(
        sql = SQLJobFacet("SELECT * FROM source", dialect = "ansi"),
        sourceCodeLocation = SourceCodeLocationJobFacet(
          "git",
          "https://github.com/example/project/blob/main/job.R",
          repo_url = "https://github.com/example/project.git",
          path = "job.R",
          version = "0123abcd",
          tag = "v1.0.0",
          branch = "main",
          pull_request_number = "42"
        ),
        jobType = JobTypeJobFacet(
          "BATCH",
          "R",
          job_type = "QUERY",
          emission_pattern = EmissionPattern("PERIODIC", "SNAPSHOT", 300L)
        ),
        tags = TagsJobFacet(list(ol_tag("environment", "production")))
      )
    ),
    event_type = "COMPLETE",
    event_time = "2026-01-02T03:05:00.000Z",
    inputs = list(
      InputDataset(
        "postgres://warehouse",
        "public.source",
        facets = list(
          schema = SchemaDatasetFacet(list(
            SchemaField(
              "id",
              "INTEGER",
              description = "Primary key",
              ordinal_position = 1L
            ),
            SchemaField(
              "address",
              "STRUCT",
              ordinal_position = 2L,
              fields = list(SchemaField("city", "STRING"))
            )
          )),
          dataSource = DatasourceDatasetFacet(
            "warehouse",
            "postgres://warehouse"
          ),
          tags = TagsDatasetFacet(list(
            ol_tag("pii", "true", source = "USER", field = "id")
          ))
        ),
        input_facets = list(
          inputStatistics = InputStatisticsInputDatasetFacet(
            row_count = 0L,
            size = 3e9,
            file_count = 1L
          )
        )
      )
    ),
    outputs = list(
      OutputDataset(
        "postgres://warehouse",
        "analytics.result",
        facets = list(
          columnLineage = ColumnLineageDatasetFacet(
            fields = list(id = list(source_field))
          )
        ),
        output_facets = list(
          outputStatistics = OutputStatisticsOutputDatasetFacet(
            row_count = 1234567890123456,
            size = 2^53,
            file_count = 1e15
          )
        )
      )
    )
  )
}
