http_transport_event <- function() {
  RunEvent(
    Run(fixture_run_id()),
    Job("example", "http-transport-test"),
    event_type = "START",
    event_time = "2026-01-02T03:04:05.000Z"
  )
}

http_mock_response <- function(status_code, request, headers = list()) {
  httr2::response(
    status_code = status_code,
    url = request$url,
    method = "POST",
    headers = headers
  )
}

test_that("HTTP endpoint paths are normalized", {
  cases <- list(
    c(
      url = "https://example.com",
      endpoint = "api/v1/lineage",
      expected = "https://example.com/api/v1/lineage"
    ),
    c(
      url = "https://example.com/",
      endpoint = "/api/v1/lineage/",
      expected = "https://example.com/api/v1/lineage"
    ),
    c(
      url = "https://example.com/openlineage/",
      endpoint = "api//v1/lineage",
      expected = "https://example.com/openlineage/api/v1/lineage"
    ),
    c(
      url = "https://example.com/api/v1/lineage/",
      endpoint = "api/v1/lineage",
      expected = "https://example.com/api/v1/lineage"
    )
  )

  for (case in cases) {
    expect_identical(
      .ol_normalize_http_url(case[["url"]], case[["endpoint"]]),
      case[["expected"]],
      info = case[["url"]]
    )
  }
})

test_that("HTTP transport sends the expected endpoint, headers, and body", {
  captured <- new.env(parent = emptyenv())
  httr2::local_mocked_responses(function(req) {
    captured$request <- req
    http_mock_response(201L, req)
  })
  event <- http_transport_event()
  transport <- HttpTransport$new(
    "https://example.com/openlineage/",
    endpoint = "/api/v1/lineage/",
    api_key = "test-api-key",
    headers = c(`X-Tenant` = "analytics"),
    timeout = 2.5
  )

  result <- withVisible(transport$emit(event))
  request <- captured$request
  headers <- .ol_http_request_headers(
    "test-api-key",
    c(`X-Tenant` = "analytics")
  )

  expect_identical(
    request$url,
    "https://example.com/openlineage/api/v1/lineage"
  )
  expect_identical(request$method, "POST")
  expect_identical(headers[["Authorization"]], "Bearer test-api-key")
  expect_identical(headers[["X-Tenant"]], "analytics")
  expect_setequal(names(request$headers), names(headers))
  expect_identical(request$body$content_type, "application/json")
  expect_json_semantically_equal(
    request$body$data,
    to_openlineage_json(event)
  )
  expect_identical(request$options$timeout_ms, 2500)
  expect_null(request$options$ssl_verifypeer)
  expect_identical(result$value, event)
  expect_identical(result$visible, FALSE)
})

test_that("custom authorization headers are supported and redacted", {
  captured <- new.env(parent = emptyenv())
  httr2::local_mocked_responses(function(req) {
    captured$request <- req
    http_mock_response(204L, req)
  })
  transport <- HttpTransport$new(
    "https://example.com",
    headers = c(Authorization = "Basic custom-secret")
  )

  transport$emit(http_transport_event())

  request <- captured$request
  printed_request <- capture.output(print(request))
  headers <- .ol_http_request_headers(
    NULL,
    c(Authorization = "Basic custom-secret")
  )
  expect_identical(headers[["Authorization"]], "Basic custom-secret")
  expect_named(request$headers, "Authorization")
  expect_identical(
    grepl("custom-secret", paste(printed_request, collapse = "\n")),
    FALSE
  )
})

test_that("HTTP transport printing does not expose credentials", {
  api_key <- "private-bearer-value"
  header_secret <- "private-header-value"
  transport <- HttpTransport$new(
    "https://example.com",
    api_key = api_key,
    headers = c(`X-API-Context` = header_secret)
  )

  output <- paste(capture.output(print(transport)), collapse = "\n")
  structure <- paste(capture.output(str(transport)), collapse = "\n")

  expect_match(output, "<HttpTransport>", fixed = TRUE)
  expect_match(output, "authentication: bearer", fixed = TRUE)
  expect_identical(grepl(api_key, output, fixed = TRUE), FALSE)
  expect_identical(grepl(header_secret, output, fixed = TRUE), FALSE)
  expect_identical(grepl(api_key, structure, fixed = TRUE), FALSE)
  expect_identical(grepl(header_secret, structure, fixed = TRUE), FALSE)
})

test_that("HTTP configuration rejects unsafe or conflicting values", {
  expect_snapshot(error = TRUE, HttpTransport$new("ftp://example.com"))
  expect_snapshot(
    error = TRUE,
    HttpTransport$new("https://user:password@example.com")
  )
  expect_snapshot(
    error = TRUE,
    HttpTransport$new("https://example.com?tenant=analytics")
  )
  expect_snapshot(
    error = TRUE,
    HttpTransport$new("https://example.com", endpoint = "../lineage")
  )
  expect_snapshot(
    error = TRUE,
    HttpTransport$new("https://example.com", endpoint = "")
  )
  expect_snapshot(
    error = TRUE,
    HttpTransport$new(
      "https://example.com",
      api_key = "api-key",
      headers = c(authorization = "Bearer custom")
    )
  )
  expect_snapshot(
    error = TRUE,
    HttpTransport$new(
      "https://example.com",
      headers = c(`Content-Type` = "text/plain")
    )
  )
  expect_snapshot(
    error = TRUE,
    HttpTransport$new(
      "https://example.com",
      headers = c(`X-Test` = "value\r\ninjected: true")
    )
  )
  expect_snapshot(
    error = TRUE,
    HttpTransport$new(
      "https://example.com",
      headers = c(`X-Test` = "one", `x-test` = "two")
    )
  )
  expect_snapshot(
    error = TRUE,
    HttpTransport$new("https://example.com", timeout = 0)
  )
  expect_snapshot(
    error = TRUE,
    HttpTransport$new("https://example.com", max_retries = 1.5)
  )
  expect_snapshot(
    error = TRUE,
    HttpTransport$new("https://example.com", api_key = "invalid key")
  )
  expect_snapshot(
    error = TRUE,
    HttpTransport$new("https://example.com", verify_tls = NA)
  )
})

test_that("authentication conflict conditions do not contain secrets", {
  condition <- tryCatch(
    HttpTransport$new(
      "https://example.com",
      api_key = "literal-private-api-key",
      headers = c(Authorization = "literal-private-header-secret")
    ),
    error = identity
  )
  rendered <- paste(capture.output(str(condition)), collapse = "\n")

  expect_s3_class(condition, "openlineage_config_error")
  expect_identical(
    grepl("literal-private-api-key", rendered, fixed = TRUE),
    FALSE
  )
  expect_identical(
    grepl("literal-private-header-secret", rendered, fixed = TRUE),
    FALSE
  )
})

test_that("disabling TLS verification warns and configures curl", {
  expect_snapshot(
    invisible(HttpTransport$new("https://example.com", verify_tls = FALSE))
  )

  warning <- NULL
  withCallingHandlers(
    HttpTransport$new("https://example.com", verify_tls = FALSE),
    warning = function(condition) {
      warning <<- condition
      invokeRestart("muffleWarning")
    }
  )
  expect_s3_class(warning, "openlineage_insecure_tls_warning")

  captured <- new.env(parent = emptyenv())
  httr2::local_mocked_responses(function(req) {
    captured$request <- req
    http_mock_response(204L, req)
  })
  transport <- suppressWarnings(
    HttpTransport$new("https://example.com", verify_tls = FALSE)
  )

  transport$emit(http_transport_event())

  expect_identical(captured$request$options$ssl_verifypeer, 0)
})

test_that("invalid HTTP events fail before making a request", {
  attempts <- 0L
  httr2::local_mocked_responses(function(req) {
    attempts <<- attempts + 1L
    http_mock_response(204L, req)
  })
  transport <- HttpTransport$new("https://example.com")

  expect_snapshot(error = TRUE, transport$emit("serialized JSON"))
  expect_identical(attempts, 0L)
})

test_that("only approved HTTP statuses are retried", {
  statuses <- c(429L, 500L, 502L, 503L, 504L)
  status_code <- statuses[[1L]]
  attempts <- 0L
  httr2::local_mocked_responses(function(req) {
    attempts <<- attempts + 1L
    if (attempts == 1L) {
      return(http_mock_response(
        status_code,
        req,
        headers = list(`Retry-After` = "0")
      ))
    }
    http_mock_response(204L, req)
  })

  for (status in statuses) {
    attempts <- 0L
    status_code <- status
    transport <- HttpTransport$new("https://example.com", max_retries = 1L)

    transport$emit(http_transport_event())

    expect_identical(attempts, 2L, info = as.character(status))
  }
})

test_that("HTTP retries are bounded", {
  attempts <- 0L
  httr2::local_mocked_responses(function(req) {
    attempts <<- attempts + 1L
    http_mock_response(
      503L,
      req,
      headers = list(`Retry-After` = "0")
    )
  })
  transport <- HttpTransport$new("https://example.com", max_retries = 2L)

  condition <- tryCatch(
    transport$emit(http_transport_event()),
    error = identity
  )

  expect_identical(attempts, 3L)
  expect_s3_class(condition, "openlineage_http_error")
  expect_s3_class(condition, "openlineage_transport_error")
  expect_identical(condition$status_code, 503L)
  expect_snapshot(error = TRUE, {
    attempts <- 0L
    transport$emit(http_transport_event())
  })
})

test_that("non-transient HTTP errors are not retried", {
  attempts <- 0L
  httr2::local_mocked_responses(function(req) {
    attempts <<- attempts + 1L
    http_mock_response(408L, req)
  })
  transport <- HttpTransport$new("https://example.com", max_retries = 3L)

  condition <- tryCatch(
    transport$emit(http_transport_event()),
    error = identity
  )

  expect_identical(attempts, 1L)
  expect_s3_class(condition, "openlineage_http_error")
  expect_identical(condition$status_code, 408L)
})

test_that("authentication failures are classified and never retried", {
  statuses <- c(401L, 403L)
  status_code <- statuses[[1L]]
  attempts <- 0L
  httr2::local_mocked_responses(function(req) {
    attempts <<- attempts + 1L
    http_mock_response(status_code, req)
  })

  for (status in statuses) {
    attempts <- 0L
    status_code <- status
    transport <- HttpTransport$new(
      "https://example.com",
      api_key = "private-key",
      max_retries = 3L
    )

    condition <- tryCatch(
      transport$emit(http_transport_event()),
      error = identity
    )

    expect_identical(attempts, 1L, info = as.character(status))
    expect_s3_class(condition, "openlineage_auth_error")
    expect_s3_class(condition, "openlineage_http_error")
    expect_s3_class(condition, "openlineage_transport_error")
    expect_identical(condition$status_code, status)
    expect_identical(
      grepl("private-key", conditionMessage(condition), fixed = TRUE),
      FALSE
    )
  }

  status_code <- 401L
  expect_snapshot(error = TRUE, {
    HttpTransport$new("https://example.com")$emit(http_transport_event())
  })
})

test_that("chained authentication failures contain no credential trace", {
  httr2::local_mocked_responses(
    \(req) http_mock_response(401L, req)
  )

  condition <- tryCatch(
    HttpTransport$new(
      "https://example.com",
      api_key = "literal-runtime-secret",
      max_retries = 0L
    )$emit(http_transport_event()),
    error = identity
  )
  rendered <- paste(capture.output(str(condition)), collapse = "\n")

  expect_s3_class(condition, "openlineage_auth_error")
  expect_null(condition$trace)
  expect_identical(
    grepl("literal-runtime-secret", rendered, fixed = TRUE),
    FALSE
  )
})

test_that("low-level failures retry and then succeed", {
  attempts <- 0L
  delays <- numeric()
  failure <- simpleError("private low-level detail")
  class(failure) <- c("httr2_failure", "httr2_error", class(failure))
  testthat::local_mocked_bindings(
    .ol_http_retry_sleep = function(seconds) {
      delays <<- c(delays, seconds)
    },
    .package = "openlineage"
  )
  httr2::local_mocked_responses(function(req) {
    attempts <<- attempts + 1L
    if (attempts == 1L) {
      stop(failure)
    }
    http_mock_response(204L, req)
  })
  transport <- HttpTransport$new("https://example.com", max_retries = 1L)

  transport$emit(http_transport_event())

  expect_identical(attempts, 2L)
  expect_identical(delays, 1)
})

test_that("exhausted low-level failures are sanitized", {
  failure_detail <- "private low-level failure detail"
  failure <- simpleError(failure_detail)
  class(failure) <- c("httr2_failure", "httr2_error", class(failure))
  httr2::local_mocked_responses(function(req) {
    stop(failure)
  })
  transport <- HttpTransport$new("https://example.com", max_retries = 0L)

  condition <- tryCatch(
    transport$emit(http_transport_event()),
    error = identity
  )

  expect_s3_class(condition, "openlineage_transport_error")
  expect_identical(
    conditionMessage(condition),
    "OpenLineage HTTP request failed before receiving a response."
  )
  expect_identical(
    grepl(
      failure_detail,
      paste(capture.output(str(condition)), collapse = "\n"),
      fixed = TRUE
    ),
    FALSE
  )
  expect_snapshot(error = TRUE, transport$emit(http_transport_event()))
})
