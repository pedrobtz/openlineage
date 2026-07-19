client_test_event <- function(state = "START") {
  RunEvent(
    Run(fixture_run_id()),
    Job("example", "client-test"),
    event_type = state,
    event_time = "2026-01-02T03:04:05.000Z"
  )
}

client_mock_response <- function(status_code, request) {
  httr2::response(
    status_code = status_code,
    url = request$url,
    method = "POST"
  )
}

client_local_env <- function(values = character()) {
  variables <- .OPENLINEAGE_CLIENT_ENV_VARS
  old <- Sys.getenv(variables, unset = NA_character_)
  names(old) <- variables

  Sys.unsetenv(variables)
  if (length(values) > 0L) {
    do.call(Sys.setenv, as.list(values))
  }

  function() {
    Sys.unsetenv(variables)
    present <- !is.na(old)
    if (any(present)) {
      do.call(Sys.setenv, as.list(old[present]))
    }
  }
}

test_that("client emits through an injected transport", {
  restore_env <- client_local_env()
  on.exit(restore_env())
  transport <- AccumulatingTransport$new()
  client <- OpenLineageClient$new(transport = transport)
  event <- client_test_event()

  result <- withVisible(client$emit(event))

  expect_s3_class(client, "OpenLineageClient")
  expect_identical(client$transport, transport)
  expect_identical(transport$events, list(event))
  expect_identical(result$value, event)
  expect_identical(result$visible, FALSE)
})

test_that("client validates events before calling a custom transport", {
  restore_env <- client_local_env()
  on.exit(restore_env())
  received <- new.env(parent = emptyenv())
  PermissiveTransport <- R6::R6Class(
    "PermissiveTransport",
    public = list(
      emit = function(event) {
        received$event <- event
      }
    )
  )
  client <- OpenLineageClient$new(transport = PermissiveTransport$new())

  expect_snapshot(error = TRUE, client$emit("serialized JSON"))
  expect_length(received, 0L)
})

test_that("client defaults to console delivery without HTTP configuration", {
  restore_env <- client_local_env()
  on.exit(restore_env())

  client <- OpenLineageClient$new()
  output <- paste(capture.output(print(client)), collapse = "\n")

  expect_s3_class(client$transport, "ConsoleTransport")
  expect_match(output, "transport: ConsoleTransport", fixed = TRUE)
})

test_that("client emits through an injected console transport", {
  restore_env <- client_local_env()
  on.exit(restore_env())
  output <- character()
  stream <- textConnection("output", "w", local = TRUE)
  on.exit(close(stream), add = TRUE)
  client <- OpenLineageClient$new(
    transport = ConsoleTransport$new(stream, pretty = FALSE)
  )
  event <- client_test_event()

  result <- withVisible(client$emit(event))

  expect_length(output, 1L)
  expect_json_semantically_equal(output, to_openlineage_json(event))
  expect_identical(result$value, event)
  expect_identical(result$visible, FALSE)
})

test_that("client emits through an explicitly configured HTTP transport", {
  restore_env <- client_local_env(c(
    OPENLINEAGE_URL = "https://environment.example.com",
    OPENLINEAGE_ENDPOINT = "environment/lineage",
    OPENLINEAGE_API_KEY = "environment-key",
    OPENLINEAGE_DISABLED = "true"
  ))
  on.exit(restore_env())
  captured <- new.env(parent = emptyenv())
  keys <- character()
  original_headers <- .ol_http_request_headers
  testthat::local_mocked_bindings(
    .ol_http_request_headers = function(api_key, headers) {
      keys <<- c(keys, api_key)
      original_headers(api_key, headers)
    },
    .package = "openlineage"
  )
  httr2::local_mocked_responses(function(req) {
    captured$request <- req
    client_mock_response(204L, req)
  })
  client <- OpenLineageClient$new(
    url = "https://explicit.example.com/base",
    endpoint = "custom/lineage",
    api_key = "explicit-key",
    disabled = FALSE
  )

  client$emit(client_test_event())

  expect_s3_class(client$transport, "HttpTransport")
  expect_identical(
    captured$request$url,
    "https://explicit.example.com/base/custom/lineage"
  )
  expect_identical(keys, "explicit-key")
})

test_that("client configures HTTP from environment variables", {
  restore_env <- client_local_env(c(
    OPENLINEAGE_URL = "https://environment.example.com/base/",
    OPENLINEAGE_ENDPOINT = "/events/lineage/",
    OPENLINEAGE_API_KEY = "environment-key",
    OPENLINEAGE_DISABLED = " false "
  ))
  on.exit(restore_env())
  captured <- new.env(parent = emptyenv())
  keys <- character()
  original_headers <- .ol_http_request_headers
  testthat::local_mocked_bindings(
    .ol_http_request_headers = function(api_key, headers) {
      keys <<- c(keys, api_key)
      original_headers(api_key, headers)
    },
    .package = "openlineage"
  )
  httr2::local_mocked_responses(function(req) {
    captured$request <- req
    client_mock_response(201L, req)
  })
  client <- OpenLineageClient$new()

  client$emit(client_test_event())

  expect_s3_class(client$transport, "HttpTransport")
  expect_identical(
    captured$request$url,
    "https://environment.example.com/base/events/lineage"
  )
  expect_identical(keys, "environment-key")
})

test_that("an explicit endpoint overrides the environment endpoint", {
  restore_env <- client_local_env(c(
    OPENLINEAGE_URL = "https://example.com",
    OPENLINEAGE_ENDPOINT = "environment/lineage"
  ))
  on.exit(restore_env())
  captured <- new.env(parent = emptyenv())
  httr2::local_mocked_responses(function(req) {
    captured$request <- req
    client_mock_response(204L, req)
  })
  client <- OpenLineageClient$new(endpoint = "explicit/lineage")

  client$emit(client_test_event())

  expect_identical(
    captured$request$url,
    "https://example.com/explicit/lineage"
  )
})

test_that("disabled configuration selects no-op delivery", {
  restore_env <- client_local_env(c(
    OPENLINEAGE_URL = "https://example.com",
    OPENLINEAGE_DISABLED = " TRUE "
  ))
  on.exit(restore_env())
  transport <- AccumulatingTransport$new()

  environment_disabled <- OpenLineageClient$new(transport = transport)
  explicitly_disabled <- OpenLineageClient$new(
    transport = transport,
    disabled = TRUE
  )
  explicitly_enabled <- OpenLineageClient$new(disabled = FALSE)
  environment_disabled$emit(client_test_event())
  explicitly_disabled$emit(client_test_event())

  expect_s3_class(environment_disabled$transport, "NoopTransport")
  expect_s3_class(explicitly_disabled$transport, "NoopTransport")
  expect_s3_class(explicitly_enabled$transport, "HttpTransport")
  expect_length(transport$events, 0L)
})

test_that("invalid and conflicting client settings are rejected", {
  restore_env <- client_local_env()
  on.exit(restore_env())
  transport <- AccumulatingTransport$new()

  expect_snapshot(error = TRUE, OpenLineageClient$new(disabled = NA))
  expect_snapshot(error = TRUE, OpenLineageClient$new(disabled = "true"))
  expect_snapshot(
    error = TRUE,
    OpenLineageClient$new(
      transport = transport,
      url = "https://example.com"
    )
  )
  expect_snapshot(
    error = TRUE,
    OpenLineageClient$new(transport = transport, timeout = 10)
  )
  expect_snapshot(error = TRUE, OpenLineageClient$new(transport = list()))
  expect_snapshot(error = TRUE, OpenLineageClient$new(api_key = "orphan-key"))
  expect_snapshot(
    error = TRUE,
    OpenLineageClient$new(endpoint = "orphan/lineage")
  )
})

test_that("invalid disabled environment values are rejected", {
  restore_env <- client_local_env(c(OPENLINEAGE_DISABLED = "yes"))
  on.exit(restore_env())

  expect_snapshot(error = TRUE, OpenLineageClient$new())
})

test_that("partial HTTP environment configuration requires a URL", {
  restore_env <- client_local_env(c(
    OPENLINEAGE_ENDPOINT = "orphan/lineage",
    OPENLINEAGE_API_KEY = "environment-secret"
  ))
  on.exit(restore_env())
  condition <- tryCatch(OpenLineageClient$new(), error = identity)
  rendered <- paste(capture.output(str(condition)), collapse = "\n")

  expect_s3_class(condition, "openlineage_config_error")
  expect_match(
    conditionMessage(condition),
    "OPENLINEAGE_ENDPOINT",
    fixed = TRUE
  )
  expect_match(
    conditionMessage(condition),
    "OPENLINEAGE_API_KEY",
    fixed = TRUE
  )
  expect_identical(
    grepl("environment-secret", rendered, fixed = TRUE),
    FALSE
  )
})

test_that("injected transports ignore HTTP environment variables", {
  restore_env <- client_local_env(c(
    OPENLINEAGE_URL = "not a URL",
    OPENLINEAGE_ENDPOINT = "../invalid",
    OPENLINEAGE_API_KEY = "environment-secret",
    OPENLINEAGE_DISABLED = "false"
  ))
  on.exit(restore_env())
  transport <- AccumulatingTransport$new()
  client <- OpenLineageClient$new(transport = transport)

  client$emit(client_test_event())

  expect_identical(client$transport, transport)
  expect_length(transport$events, 1L)
})

test_that("clients keep accumulating transport state independent", {
  restore_env <- client_local_env()
  on.exit(restore_env())
  first <- OpenLineageClient$new(
    transport = AccumulatingTransport$new()
  )
  second <- OpenLineageClient$new(
    transport = AccumulatingTransport$new()
  )

  first$emit(client_test_event("START"))
  second$emit(client_test_event("COMPLETE"))

  expect_length(first$transport$events, 1L)
  expect_length(second$transport$events, 1L)
  expect_identical(
    as.character(first$transport$events[[1L]]@event_type),
    "START"
  )
  expect_identical(
    as.character(second$transport$events[[1L]]@event_type),
    "COMPLETE"
  )
})

test_that("clients capture credentials independently at construction", {
  restore_env <- client_local_env(c(
    OPENLINEAGE_URL = "https://example.com",
    OPENLINEAGE_API_KEY = "first-client-secret"
  ))
  on.exit(restore_env())
  first <- OpenLineageClient$new()
  Sys.setenv(OPENLINEAGE_API_KEY = "second-client-secret")
  second <- OpenLineageClient$new()
  keys <- character()
  original_headers <- .ol_http_request_headers
  testthat::local_mocked_bindings(
    .ol_http_request_headers = function(api_key, headers) {
      keys <<- c(keys, api_key)
      original_headers(api_key, headers)
    },
    .package = "openlineage"
  )
  httr2::local_mocked_responses(
    \(req) client_mock_response(204L, req)
  )

  first$emit(client_test_event())
  second$emit(client_test_event())
  first_structure <- paste(capture.output(str(first)), collapse = "\n")
  second_structure <- paste(capture.output(str(second)), collapse = "\n")

  expect_identical(
    keys,
    c("first-client-secret", "second-client-secret")
  )
  expect_identical(
    grepl("first-client-secret", first_structure, fixed = TRUE),
    FALSE
  )
  expect_identical(
    grepl("second-client-secret", second_structure, fixed = TRUE),
    FALSE
  )
})

test_that("client configuration conditions contain no credentials", {
  restore_env <- client_local_env()
  on.exit(restore_env())
  condition <- tryCatch(
    OpenLineageClient$new(
      transport = AccumulatingTransport$new(),
      api_key = "literal-client-secret"
    ),
    error = identity
  )
  rendered <- paste(capture.output(str(condition)), collapse = "\n")

  expect_s3_class(condition, "openlineage_config_error")
  expect_null(condition$trace)
  expect_identical(
    grepl("literal-client-secret", rendered, fixed = TRUE),
    FALSE
  )
})
