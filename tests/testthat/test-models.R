test_that("RunState validates and stores protocol states", {
  state <- RunState("START")

  expect_s7_class(state, RunState)
  expect_identical(S7::S7_data(state), "START")
})

test_that("core models normalize empty facet maps", {
  run <- Run(fixture_run_id())
  job <- Job("example", "task")
  dataset <- Dataset("postgres://warehouse", "public.source")

  expect_s7_class(run, Run)
  expect_s7_class(job, Job)
  expect_s7_class(dataset, Dataset)
  expect_identical(names(S7::prop(run, "facets")), character())
  expect_identical(names(S7::prop(job, "facets")), character())
  expect_identical(names(S7::prop(dataset, "facets")), character())
})

test_that("input and output datasets retain their roles", {
  input <- InputDataset("postgres://warehouse", "public.source")
  output <- OutputDataset("postgres://warehouse", "analytics.result")

  expect_s7_class(input, InputDataset)
  expect_s7_class(input, Dataset)
  expect_s7_class(output, OutputDataset)
  expect_s7_class(output, Dataset)
  expect_identical(names(S7::prop(input, "input_facets")), character())
  expect_identical(names(S7::prop(output, "output_facets")), character())
})

test_that("RunEvent accepts state strings and typed datasets", {
  input <- InputDataset("postgres://warehouse", "public.source")
  output <- OutputDataset("postgres://warehouse", "analytics.result")
  event <- RunEvent(
    Run(fixture_run_id()),
    Job("example", "task"),
    event_type = "RUNNING",
    event_time = new_event_time(fixture_event_time()),
    inputs = list(input),
    outputs = list(output)
  )

  expect_s7_class(event, RunEvent)
  expect_s7_class(S7::prop(event, "event_type"), RunState)
  expect_identical(S7::prop(event, "inputs"), list(input))
  expect_identical(S7::prop(event, "outputs"), list(output))
})

test_that("optional model properties accept explicit NULL", {
  event <- RunEvent(
    Run(fixture_run_id(), facets = NULL),
    Job("example", "task", facets = NULL),
    event_time = new_event_time(fixture_event_time()),
    inputs = NULL,
    outputs = NULL
  )

  expect_null(S7::prop(event, "event_type"))
  expect_null(S7::prop(event, "inputs"))
  expect_null(S7::prop(event, "outputs"))
  expect_null(S7::prop(S7::prop(event, "run"), "facets"))
})

test_that("core model validation raises stable conditions", {
  condition <- tryCatch(Run("not-a-uuid"), error = identity)

  expect_s3_class(condition, "openlineage_validation_error")
  expect_s3_class(condition, "openlineage_error")
  expect_snapshot(error = TRUE, RunState("UNKNOWN"))
  expect_snapshot(error = TRUE, Run("not-a-uuid"))
  expect_snapshot(error = TRUE, Job("", "task"))
  expect_snapshot(error = TRUE, {
    RunEvent(
      Run(fixture_run_id()),
      Job("example", "task"),
      event_type = "START",
      event_time = "2026-01-02 03:04:05"
    )
  })
  expect_snapshot(error = TRUE, {
    RunEvent(
      Run(fixture_run_id()),
      Job("example", "task"),
      event_time = new_event_time(fixture_event_time()),
      producer = "not a uri"
    )
  })
})

test_that("RunEvent enforces dataset roles", {
  expect_snapshot(error = TRUE, {
    RunEvent(
      Run(fixture_run_id()),
      Job("example", "task"),
      event_time = new_event_time(fixture_event_time()),
      inputs = list(Dataset("example", "untyped"))
    )
  })
  expect_snapshot(error = TRUE, {
    RunEvent(
      Run(fixture_run_id()),
      Job("example", "task"),
      event_time = new_event_time(fixture_event_time()),
      outputs = list(InputDataset("example", "wrong-role"))
    )
  })
})

test_that("facet maps require unique non-empty names", {
  expect_snapshot(error = TRUE, Run(fixture_run_id(), facets = list("value")))
  expect_snapshot(
    error = TRUE,
    Job("example", "task", facets = list(a = 1, a = 2))
  )
})
