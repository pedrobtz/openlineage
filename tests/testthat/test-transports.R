transport_test_event <- function(state = "START") {
  RunEvent(
    Run(fixture_run_id()),
    Job("example", "transport-test"),
    event_type = state,
    event_time = "2026-01-02T03:04:05.000Z"
  )
}

console_with_closed_stream <- function(action = c("initialize", "emit")) {
  action <- match.arg(action)
  output <- character()
  stream <- textConnection("output", "w", local = TRUE)

  if (action == "initialize") {
    close(stream)
    return(ConsoleTransport$new(stream))
  }

  transport <- ConsoleTransport$new(stream)
  close(stream)
  transport$emit(transport_test_event())
}

test_that("accumulating transport stores event models in order", {
  transport <- AccumulatingTransport$new()
  start <- transport_test_event("START")
  complete <- transport_test_event("COMPLETE")

  start_result <- withVisible(transport$emit(start))
  complete_result <- withVisible(transport$emit(complete))

  expect_identical(transport$events, list(start, complete))
  expect_identical(start_result$value, start)
  expect_identical(start_result$visible, FALSE)
  expect_identical(complete_result$value, complete)
  expect_identical(complete_result$visible, FALSE)
})

test_that("accumulating transports do not share state", {
  first <- AccumulatingTransport$new()
  second <- AccumulatingTransport$new()
  first$emit(transport_test_event())

  expect_length(first$events, 1L)
  expect_length(second$events, 0L)

  result <- withVisible(first$clear())

  expect_length(first$events, 0L)
  expect_identical(result$value, first)
  expect_identical(result$visible, FALSE)
})

test_that("console transport writes compact JSON", {
  output <- character()
  stream <- textConnection("output", "w", local = TRUE)
  on.exit(close(stream))
  transport <- ConsoleTransport$new(stream, pretty = FALSE)
  event <- transport_test_event()

  result <- withVisible(transport$emit(event))

  expect_length(output, 1L)
  expect_json_semantically_equal(output, to_openlineage_json(event))
  expect_identical(result$value, event)
  expect_identical(result$visible, FALSE)
})

test_that("console transport supports pretty JSON", {
  output <- character()
  stream <- textConnection("output", "w", local = TRUE)
  on.exit(close(stream))
  transport <- ConsoleTransport$new(stream, pretty = TRUE)
  event <- transport_test_event()

  transport$emit(event)

  expect_gt(length(output), 1L)
  expect_json_semantically_equal(
    paste(output, collapse = "\n"),
    to_openlineage_json(event)
  )
})

test_that("no-op transport returns events without storing output", {
  transport <- NoopTransport$new()
  event <- transport_test_event()

  result <- withVisible(transport$emit(event))

  expect_identical(result$value, event)
  expect_identical(result$visible, FALSE)
  expect_identical(
    withVisible(transport$close()),
    list(value = TRUE, visible = FALSE)
  )
})

test_that("the transport adapter passes models and normalizes returns", {
  received <- new.env(parent = emptyenv())
  CustomTransport <- R6::R6Class(
    "CustomTransport",
    public = list(
      emit = function(event) {
        received$event <- event
        "custom return value"
      }
    )
  )
  transport <- CustomTransport$new()
  event <- transport_test_event()

  result <- withVisible(.ol_transport_emit(transport, event))

  expect_identical(received$event, event)
  expect_s7_class(received$event, RunEvent)
  expect_identical(result$value, event)
  expect_identical(result$visible, FALSE)
})

test_that("transport configuration and events are validated", {
  expect_snapshot(
    error = TRUE,
    .ol_transport_emit(list(), transport_test_event())
  )
  expect_snapshot(error = TRUE, NoopTransport$new()$emit("serialized JSON"))
  expect_snapshot(error = TRUE, ConsoleTransport$new(stdout(), pretty = 1))

  expect_snapshot(error = TRUE, console_with_closed_stream("initialize"))
})

test_that("transport failures have a stable condition class", {
  FailingTransport <- R6::R6Class(
    "FailingTransport",
    public = list(
      emit = function(event) {
        stop("offline transport failure", call. = FALSE)
      }
    )
  )
  transport <- FailingTransport$new()

  condition <- tryCatch(
    .ol_transport_emit(transport, transport_test_event()),
    error = identity
  )

  expect_s3_class(condition, "openlineage_transport_error")
  expect_s3_class(condition, "openlineage_error")
  expect_snapshot(
    error = TRUE,
    .ol_transport_emit(transport, transport_test_event())
  )
})

test_that("the transport adapter preserves classified package errors", {
  ClassifiedTransport <- R6::R6Class(
    "ClassifiedTransport",
    public = list(
      emit = function(event) {
        .ol_abort(
          "Declared transport failure.",
          class = "openlineage_transport_error",
          call = NULL
        )
      }
    )
  )

  condition <- tryCatch(
    .ol_transport_emit(ClassifiedTransport$new(), transport_test_event()),
    error = identity
  )

  expect_s3_class(condition, "openlineage_transport_error")
  expect_s3_class(condition, "openlineage_error")
  expect_identical(conditionMessage(condition), "Declared transport failure.")
  expect_null(condition$parent)
})

test_that("console write failures are transport errors", {
  condition <- tryCatch(
    console_with_closed_stream("emit"),
    error = identity
  )

  expect_s3_class(condition, "openlineage_transport_error")
  expect_snapshot(error = TRUE, console_with_closed_stream("emit"))
})
