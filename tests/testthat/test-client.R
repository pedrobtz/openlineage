test_that("client emits through an injected transport", {
  local_client_env()
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
  local_client_env()
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
  local_client_env()

  client <- OpenLineageClient$new()
  output <- paste(capture.output(print(client)), collapse = "\n")

  expect_s3_class(client$transport, "ConsoleTransport")
  expect_match(output, "transport: ConsoleTransport", fixed = TRUE)
})

test_that("client emits through an injected console transport", {
  local_client_env()
  output <- character()
  stream <- textConnection("output", "w", local = TRUE)
  on.exit(close(stream), add = TRUE)
  client <- OpenLineageClient$new(
    transport = ConsoleTransport$new(stream, pretty = FALSE)
  )
  event <- minimal_start_event()

  result <- withVisible(client$emit(event))

  expect_length(output, 1L)
  expect_json_semantically_equal(
    output,
    read_json_fixture("minimal-start.json")
  )
  expect_identical(result$value, event)
  expect_identical(result$visible, FALSE)
})

test_that("client emits through an explicitly configured HTTP transport", {
  local_client_env(c(
    OPENLINEAGE_URL = "https://environment.example.com",
    OPENLINEAGE_ENDPOINT = "environment/lineage",
    OPENLINEAGE_API_KEY = "environment-key",
    OPENLINEAGE_DISABLED = "true"
  ))
  captured <- new.env(parent = emptyenv())
  keys <- character()
  httr2::local_mocked_responses(function(req) {
    captured$request <- req
    keys <<- c(keys, sent_authorization(req))
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
  expect_identical(keys, "Bearer explicit-key")
})

test_that("client configures HTTP from environment variables", {
  local_client_env(c(
    OPENLINEAGE_URL = "https://environment.example.com/base/",
    OPENLINEAGE_ENDPOINT = "/events/lineage/",
    OPENLINEAGE_API_KEY = "environment-key",
    OPENLINEAGE_DISABLED = " false "
  ))
  captured <- new.env(parent = emptyenv())
  keys <- character()
  httr2::local_mocked_responses(function(req) {
    captured$request <- req
    keys <<- c(keys, sent_authorization(req))
    client_mock_response(201L, req)
  })
  client <- OpenLineageClient$new()

  client$emit(client_test_event())

  expect_s3_class(client$transport, "HttpTransport")
  expect_identical(
    captured$request$url,
    "https://environment.example.com/base/events/lineage"
  )
  expect_identical(keys, "Bearer environment-key")
})

test_that("an explicit endpoint overrides the environment endpoint", {
  local_client_env(c(
    OPENLINEAGE_URL = "https://example.com",
    OPENLINEAGE_ENDPOINT = "environment/lineage"
  ))
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
  local_client_env(c(
    OPENLINEAGE_URL = "https://example.com",
    OPENLINEAGE_DISABLED = " TRUE "
  ))
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
  local_client_env()
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
  local_client_env(c(OPENLINEAGE_DISABLED = "yes"))

  expect_snapshot(error = TRUE, OpenLineageClient$new())
})

test_that("partial HTTP environment configuration requires a URL", {
  local_client_env(c(
    OPENLINEAGE_ENDPOINT = "orphan/lineage",
    OPENLINEAGE_API_KEY = "environment-secret"
  ))
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
  local_client_env(c(
    OPENLINEAGE_URL = "not a URL",
    OPENLINEAGE_ENDPOINT = "../invalid",
    OPENLINEAGE_API_KEY = "environment-secret",
    OPENLINEAGE_DISABLED = "false"
  ))
  transport <- AccumulatingTransport$new()
  client <- OpenLineageClient$new(transport = transport)

  client$emit(client_test_event())

  expect_identical(client$transport, transport)
  expect_length(transport$events, 1L)
})

test_that("clients keep accumulating transport state independent", {
  local_client_env()
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
  local_client_env(c(
    OPENLINEAGE_URL = "https://example.com",
    OPENLINEAGE_API_KEY = "first-client-secret"
  ))
  first <- OpenLineageClient$new()
  withr::local_envvar(OPENLINEAGE_API_KEY = "second-client-secret")
  second <- OpenLineageClient$new()
  keys <- character()
  httr2::local_mocked_responses(function(req) {
    keys <<- c(keys, sent_authorization(req))
    client_mock_response(204L, req)
  })

  first$emit(client_test_event())
  second$emit(client_test_event())
  first_structure <- paste(capture.output(str(first)), collapse = "\n")
  second_structure <- paste(capture.output(str(second)), collapse = "\n")

  expect_identical(
    keys,
    c("Bearer first-client-secret", "Bearer second-client-secret")
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
  local_client_env()
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

test_that("transport = rejects every explicit HTTP argument (#34)", {
  local_client_env()
  arguments <- list(
    url = "https://example.com",
    endpoint = "custom/lineage",
    api_key = "key",
    headers = c(`X-Tenant` = "analytics"),
    timeout = 10,
    verify_tls = FALSE,
    max_retries = 0L
  )

  for (name in names(arguments)) {
    call_args <- c(
      list(transport = AccumulatingTransport$new()),
      arguments[name]
    )
    condition <- tryCatch(
      do.call(OpenLineageClient$new, call_args),
      error = identity
    )
    expect_s3_class(condition, "openlineage_config_error")
    expect_match(conditionMessage(condition), name, fixed = TRUE, info = name)
  }
})

test_that("transport = conflicts are errors when the client is disabled (#34)", {
  local_client_env(c(OPENLINEAGE_DISABLED = "true"))

  expect_error(
    OpenLineageClient$new(
      transport = AccumulatingTransport$new(),
      url = "https://x",
      api_key = "k",
      disabled = TRUE
    ),
    class = "openlineage_config_error"
  )
  expect_error(
    OpenLineageClient$new(
      transport = AccumulatingTransport$new(),
      url = "https://x"
    ),
    class = "openlineage_config_error"
  )
  expect_s3_class(
    OpenLineageClient$new(transport = AccumulatingTransport$new())$transport,
    "NoopTransport"
  )
})

test_that("blank environment values count as unset (#36)", {
  local_client_env(c(
    OPENLINEAGE_URL = "https://example.com",
    OPENLINEAGE_ENDPOINT = "  ",
    OPENLINEAGE_API_KEY = " "
  ))
  captured <- new.env(parent = emptyenv())
  httr2::local_mocked_responses(function(req) {
    captured$request <- req
    client_mock_response(204L, req)
  })

  OpenLineageClient$new()$emit(client_test_event())

  expect_identical(captured$request$url, "https://example.com/api/v1/lineage")
  expect_null(sent_authorization(captured$request))
})

test_that("close() delegates to the transport (#47)", {
  local_client_env()
  calls <- 0L
  ClosingTransport <- R6::R6Class(
    "ClosingTransport",
    public = list(
      emit = function(event) invisible(event),
      close = function() {
        calls <<- calls + 1L
        "closed"
      }
    )
  )
  EmitOnlyTransport <- R6::R6Class(
    "EmitOnlyTransport",
    public = list(emit = function(event) invisible(event))
  )

  closing <- OpenLineageClient$new(transport = ClosingTransport$new())
  result <- withVisible(closing$close())
  emit_only <- withVisible(
    OpenLineageClient$new(transport = EmitOnlyTransport$new())$close()
  )
  built_in <- OpenLineageClient$new(transport = AccumulatingTransport$new())

  expect_identical(calls, 1L)
  expect_identical(result, list(value = "closed", visible = FALSE))
  expect_identical(emit_only, list(value = TRUE, visible = FALSE))
  expect_true(built_in$close())
  expect_true(OpenLineageClient$new(disabled = TRUE)$close())
})
