test_that("generic facets preserve extension fields", {
  facet <- ol_facet(
    "https://example.com/facets/CustomFacet.json",
    customValue = "value",
    nestedValue = list(enabled = TRUE),
    deleted = TRUE
  )

  value <- as_openlineage_list(facet)

  expect_identical(value$`_producer`, OPENLINEAGE_PRODUCER)
  expect_identical(
    value$`_schemaURL`,
    "https://example.com/facets/CustomFacet.json"
  )
  expect_true(value$`_deleted`)
  expect_identical(value$customValue, "value")
  expect_identical(value$nestedValue, list(enabled = TRUE))
})

test_that("typed run facets use OpenLineage wire fields", {
  parent_run <- Run(fixture_run_id())
  parent_job <- Job("scheduler", "parent")
  root <- list(run = parent_run, job = parent_job)
  facets <- list(
    nominal = NominalTimeRunFacet(
      "2026-01-02T03:00:00.000Z",
      "2026-01-02T04:00:00.000Z"
    ),
    parent = ParentRunFacet(parent_run, parent_job, root),
    error = ErrorMessageRunFacet("failed", "R", "trace"),
    engine = ProcessingEngineRunFacet("4.5.0", "R", "0.1.0"),
    tags = TagsRunFacet(list(ol_tag("environment", "test", "USER")))
  )

  value <- as_openlineage_list(Run(fixture_run_id(), facets))$facets

  expect_named(
    value$nominal,
    c("_producer", "_schemaURL", "nominalStartTime", "nominalEndTime")
  )
  expect_identical(value$parent$run$runId, fixture_run_id())
  expect_identical(value$parent$root$job$name, "parent")
  expect_identical(value$error$programmingLanguage, "R")
  expect_identical(value$error$stackTrace, "trace")
  expect_identical(value$engine$openlineageAdapterVersion, "0.1.0")
  expect_identical(value$tags$tags[[1]]$key, "environment")
})

test_that("typed job facets use OpenLineage wire fields", {
  facets <- list(
    sql = SQLJobFacet("SELECT 1", "ansi"),
    source = SourceCodeLocationJobFacet(
      "git",
      "https://example.com/repository/blob/main/job.R",
      repo_url = "git@example.com:repository.git",
      path = "job.R",
      version = "abc123",
      tag = "v1",
      branch = "main",
      pull_request_number = "42"
    ),
    type = JobTypeJobFacet(
      "BATCH",
      "R",
      "SCRIPT",
      EmissionPattern("EVENT_BASED", "COMPLETE_SNAPSHOT", 300L)
    ),
    tags = TagsJobFacet(list(ol_tag("owner", "analytics")))
  )

  value <- as_openlineage_list(Job("example", "task", facets))$facets

  expect_identical(value$sql$query, "SELECT 1")
  expect_identical(value$sql$dialect, "ansi")
  expect_identical(value$source$repoUrl, "git@example.com:repository.git")
  expect_identical(value$source$pullRequestNumber, "42")
  expect_identical(value$type$processingType, "BATCH")
  expect_identical(value$type$emissionPattern$eventTrigger, "EVENT_BASED")
  expect_identical(value$type$emissionPattern$windowDuration, 300L)
  expect_identical(value$tags$tags[[1]]$value, "analytics")
})

test_that("dataset facets serialize nested schema and tags", {
  field <- SchemaField(
    "record",
    "STRUCT",
    "A nested record",
    1L,
    fields = list(SchemaField("id", "INTEGER", ordinal_position = 1L))
  )
  facets <- list(
    schema = SchemaDatasetFacet(list(field)),
    dataSource = DatasourceDatasetFacet(
      "warehouse",
      "postgres://warehouse"
    ),
    tags = TagsDatasetFacet(
      list(ol_tag("pii", "true", "USER", field = "record.id"))
    )
  )

  value <- as_openlineage_list(
    Dataset("postgres://warehouse", "public.source", facets)
  )$facets

  expect_identical(value$schema$fields[[1]]$ordinal_position, 1L)
  expect_identical(value$schema$fields[[1]]$fields[[1]]$name, "id")
  expect_identical(value$dataSource$uri, "postgres://warehouse")
  expect_identical(value$tags$tags[[1]]$field, "record.id")
})

test_that("input and output statistics have distinct placement", {
  input <- InputDataset(
    "file:///data",
    "input.csv",
    input_facets = list(
      inputStatistics = InputStatisticsInputDatasetFacet(10L, 1024L, 1L)
    )
  )
  output <- OutputDataset(
    "file:///data",
    "output.csv",
    output_facets = list(
      outputStatistics = OutputStatisticsOutputDatasetFacet(9L, 512L, 1L)
    )
  )

  input_value <- as_openlineage_list(input)$inputFacets$inputStatistics
  output_value <- as_openlineage_list(output)$outputFacets$outputStatistics

  expect_identical(input_value$rowCount, 10L)
  expect_identical(input_value$fileCount, 1L)
  expect_identical(output_value$rowCount, 9L)
  expect_identical(output_value$size, 512L)
})

test_that("generic facets are accepted in every facet map (#41)", {
  facet <- ol_facet("https://example.com/facets/CustomFacet.json", value = 1L)
  expected <- as_openlineage_list(facet)
  placed <- list(
    facets = Run(fixture_run_id(), list(custom = facet)),
    facets = Job("example", "task", list(custom = facet)),
    facets = Dataset("example", "input", list(custom = facet)),
    inputFacets = InputDataset(
      "example",
      "input",
      input_facets = list(custom = facet)
    ),
    outputFacets = OutputDataset(
      "example",
      "output",
      output_facets = list(custom = facet)
    )
  )

  for (i in seq_along(placed)) {
    value <- as_openlineage_list(placed[[i]])
    expect_identical(value[[names(placed)[[i]]]], list(custom = expected))
  }
  expect_identical(expected$value, 1L)
})

test_that("typed facets enforce their placement", {
  expect_snapshot(error = TRUE, {
    Run(fixture_run_id(), list(sql = SQLJobFacet("SELECT 1")))
  })
  expect_snapshot(error = TRUE, {
    Job(
      "example",
      "task",
      list(nominal = NominalTimeRunFacet("2026-01-02T03:00:00Z"))
    )
  })
  expect_snapshot(error = TRUE, {
    InputDataset(
      "example",
      "input",
      input_facets = list(stats = OutputStatisticsOutputDatasetFacet())
    )
  })
  expect_snapshot(error = TRUE, {
    OutputDataset(
      "example",
      "output",
      output_facets = list(stats = InputStatisticsInputDatasetFacet())
    )
  })
})

test_that("facet validation rejects malformed values", {
  expect_snapshot(error = TRUE, {
    ol_facet(
      "https://example.com/facets/CustomFacet.json",
      `_producer` = "https://example.com/other"
    )
  })
  expect_snapshot(error = TRUE, {
    NominalTimeRunFacet("2026-01-02 03:00:00")
  })
  expect_snapshot(error = TRUE, SchemaDatasetFacet(list("not a field")))
  expect_snapshot(error = TRUE, InputStatisticsInputDatasetFacet(1.5))
  expect_snapshot(error = TRUE, EmissionPattern("PERIODIC", "SNAPSHOT", 0L))
  expect_snapshot(error = TRUE, {
    TagsRunFacet(list(ol_tag("pii", "true", field = "email")))
  })
})

test_that("ol_facet() fields never partial-match its arguments (#29)", {
  url <- "https://example.com/x.json"

  for (name in c("schema", "s", "sc", "schema_ur", "prod", "del")) {
    facet <- do.call(ol_facet, c(list(url), stats::setNames(list("v"), name)))
    value <- as_openlineage_list(facet)
    expect_identical(value[["_schemaURL"]], url, info = name)
    expect_identical(value[[name]], "v", info = name)
    expect_identical(
      value[["_producer"]],
      OPENLINEAGE_PRODUCER,
      info = name
    )
  }

  named <- as_openlineage_list(ol_facet(schema = "public", schema_url = url))
  expect_identical(named[["_schemaURL"]], url)
  expect_identical(named$schema, "public")
  expect_error(ol_facet(schema = url), class = "openlineage_validation_error")
  expect_error(ol_facet(url, "other"), class = "openlineage_validation_error")
  expect_snapshot(error = TRUE, ol_facet(schema = url))
})

test_that("statistics counts must be between 0 and 2^53 (#22, #46)", {
  constructors <- list(
    InputStatisticsInputDatasetFacet,
    OutputStatisticsOutputDatasetFacet
  )
  for (constructor in constructors) {
    for (argument in c("row_count", "size", "file_count")) {
      for (value in c(0, 1, 2^53)) {
        facet <- do.call(constructor, stats::setNames(list(value), argument))
        expect_identical(S7::prop(facet, argument), value)
      }
      for (value in c(-1, 2^53 + 2, 1.5, Inf)) {
        expect_error(
          do.call(constructor, stats::setNames(list(value), argument)),
          class = "openlineage_validation_error",
          info = paste(argument, value)
        )
      }
    }
  }
  expect_snapshot(error = TRUE, InputStatisticsInputDatasetFacet(-1))
})

test_that("other integer fields are capped at 2^53 (#22)", {
  expect_no_error(SchemaField("a", ordinal_position = 2^53))
  expect_error(
    SchemaField("a", ordinal_position = 2^53 + 2),
    class = "openlineage_validation_error"
  )
  expect_error(
    EmissionPattern("PERIODIC", "SNAPSHOT", 2^53 + 2),
    class = "openlineage_validation_error"
  )
})

test_that("ParentRunFacet validates root (#36)", {
  run <- Run(fixture_run_id())
  job <- Job("example", "parent")
  invalid <- list(
    list(run = run),
    list(run = job, job = run),
    list(run = run, job = job, extra = 1),
    "root"
  )

  for (root in invalid) {
    expect_error(
      ParentRunFacet(run, job, root = root),
      class = "openlineage_validation_error"
    )
  }
  facet <- ParentRunFacet(run, job, root = list(job = job, run = run))
  expect_named(facet@root, c("run", "job"))
  expect_error(
    facet@root <- list(run = run),
    class = "openlineage_validation_error"
  )
})

test_that("tags setters keep the field restriction (#25)", {
  tag <- ol_tag("k", "v", field = "col")
  job <- TagsJobFacet()
  run <- TagsRunFacet()
  dataset <- TagsDatasetFacet()

  expect_error(job@tags <- list(tag), class = "openlineage_validation_error")
  expect_error(run@tags <- list(tag), class = "openlineage_validation_error")
  dataset@tags <- list(tag)
  expect_identical(as_openlineage_list(dataset)$tags[[1L]]$field, "col")
})
