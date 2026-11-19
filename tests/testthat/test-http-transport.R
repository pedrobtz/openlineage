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
  event <- minimal_start_event()
  transport <- HttpTransport$new(
    "https://example.com/openlineage/",
    endpoint = "/api/v1/lineage/",
    api_key = "test-api-key",
    headers = c(`X-Tenant` = "analytics"),
    timeout = 2.5
  )

  result <- withVisible(transport$emit(event))
  request <- captured$request

  expect_identical(
    request$url,
    "https://example.com/openlineage/api/v1/lineage"
  )
  expect_identical(request$method, "POST")
  expect_identical(
    httr2::req_get_headers(request, "reveal"),
    list(Authorization = "Bearer test-api-key", `X-Tenant` = "analytics")
  )
  expect_identical(request$body$content_type, "application/json")
  expect_json_semantically_equal(
    request$body$data,
    read_json_fixture("minimal-start.json")
  )
  expect_identical(request$options$timeout_ms, 2500)
  expect_identical(request$options$followlocation, 0L)
  expect_null(request$options$ssl_verifypeer)
  expect_identical(result$value, event)
  expect_identical(result$visible, FALSE)
})

test_that("custom headers are sent and redacted (#33)", {
  captured <- new.env(parent = emptyenv())
  httr2::local_mocked_responses(function(req) {
    captured$request <- req
    http_mock_response(204L, req)
  })
  transport <- HttpTransport$new(
    "https://example.com",
    headers = c(
      Authorization = "Basic custom-secret",
      `X-API-Context` = "context-secret"
    )
  )

  transport$emit(http_transport_event())

  request <- captured$request
  printed_request <- paste(capture.output(print(request)), collapse = "\n")
  expect_identical(
    httr2::req_get_headers(request, "reveal"),
    list(
      Authorization = "Basic custom-secret",
      `X-API-Context` = "context-secret"
    )
  )
  expect_identical(grepl("custom-secret", printed_request, fixed = TRUE), FALSE)
  expect_identical(
    grepl("context-secret", printed_request, fixed = TRUE),
    FALSE
  )
  expect_match(printed_request, "X-API-Context", fixed = TRUE)
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
  delays <- local_recorded_sleep()
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
  expect_identical(delays(), rep(0, length(statuses)))
})

test_that("HTTP retries are bounded", {
  attempts <- 0L
  delays <- local_recorded_sleep()
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
  expect_identical(delays(), c(0, 0))
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
  delays <- local_recorded_sleep()
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
  expect_identical(delays(), numeric())
  expect_s3_class(condition, "openlineage_http_error")
  expect_identical(condition$status_code, 408L)
})

test_that("authentication failures are classified and never retried", {
  local_recorded_sleep()
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
  delays <- local_recorded_sleep()
  failure <- simpleError("private low-level detail")
  class(failure) <- c("httr2_failure", "httr2_error", class(failure))
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
  expect_identical(delays(), 1)
})

test_that("exhausted low-level failures keep their cause, not credentials (#26)", {
  local_recorded_sleep()
  request_secret <- "private-request-secret"
  httr2::local_mocked_responses(function(req) {
    cause <- structure(
      list(message = "Could not resolve host: example.com", call = NULL),
      class = c(
        "curl_error_couldnt_resolve_host",
        "curl_error",
        "error",
        "condition"
      )
    )
    failure <- structure(
      list(
        message = "Failed to perform HTTP request.",
        call = NULL,
        parent = cause,
        request = req
      ),
      class = c(
        "httr2_failure",
        "httr2_error",
        "rlang_error",
        "error",
        "condition"
      )
    )
    stop(failure)
  })
  transport <- HttpTransport$new(
    "https://example.com",
    api_key = request_secret,
    headers = c(`X-API-Context` = request_secret),
    max_retries = 0L
  )

  condition <- tryCatch(
    transport$emit(http_transport_event()),
    error = identity
  )
  rendered <- paste(capture.output(str(condition)), collapse = "\n")

  expect_s3_class(condition, "openlineage_transport_error")
  expect_null(condition$status_code)
  expect_s3_class(condition$parent, "curl_error_couldnt_resolve_host")
  expect_identical(
    conditionMessage(condition$parent),
    "Could not resolve host: example.com"
  )
  expect_null(condition$parent$request)
  expect_identical(grepl(request_secret, rendered, fixed = TRUE), FALSE)
  expect_snapshot(error = TRUE, transport$emit(http_transport_event()))
})

test_that("redirects are not followed and raise a classed error (#21)", {
  local_recorded_sleep()
  for (status in c(301L, 302L, 303L, 307L, 308L)) {
    attempts <- 0L
    httr2::local_mocked_responses(function(req) {
      attempts <<- attempts + 1L
      http_mock_response(
        status,
        req,
        headers = list(Location = "https://elsewhere.example.com/moved")
      )
    })
    transport <- HttpTransport$new(
      "https://example.com",
      headers = c(`X-Api-Key` = "secret"),
      max_retries = 3L
    )

    condition <- tryCatch(
      transport$emit(http_transport_event()),
      error = identity
    )

    expect_identical(attempts, 1L, info = as.character(status))
    expect_s3_class(condition, "openlineage_http_error")
    expect_identical(condition$status_code, status)
  }
  expect_snapshot(error = TRUE, transport$emit(http_transport_event()))
})

test_that("Retry-After seconds are capped at 60 and clamped at 0 (#32)", {
  cases <- list(
    list(header = "59", delay = 59),
    list(header = "60", delay = 60),
    list(header = "61", delay = 60),
    list(header = "-5", delay = 0),
    list(header = " 2 ", delay = 2)
  )

  for (case in cases) {
    expect_identical(
      retry_delays(list(status_with(`Retry-After` = case$header))),
      case$delay,
      info = case$header
    )
  }
})

test_that("Retry-After dates are measured from Date, else now (#26, #32)", {
  date <- "Wed, 18 Nov 2026 14:48:30 GMT"

  expect_identical(
    retry_delays(list(status_with(
      `Retry-After` = date,
      Date = "Wed, 18 Nov 2026 14:48:00 GMT"
    ))),
    30
  )
  expect_identical(
    retry_delays(list(status_with(
      `Retry-After` = date,
      Date = "Wed, 18 Nov 2026 14:46:00 GMT"
    ))),
    60
  )

  testthat::local_mocked_bindings(
    .ol_http_now = function() as.POSIXct("2026-11-18 14:48:20", tz = "UTC"),
    .package = "openlineage"
  )
  expect_identical(retry_delays(list(status_with(`Retry-After` = date))), 10)
})

test_that("unreadable Retry-After falls back to back-off without warning (#49)", {
  for (header in c("soon", "Wed, 18 Foo 2026 14:48:30 GMT", "")) {
    expect_no_warning(
      delays <- retry_delays(list(status_with(`Retry-After` = header)))
    )
    expect_identical(delays, 1, info = header)
  }
})

test_that("back-off doubles from 1 s and is capped at 30 s (#32)", {
  responses <- rep(list(status_with()), 7L)

  expect_identical(retry_delays(responses), c(1, 2, 4, 8, 16, 30, 30))
})

test_that("timeout is bounded at construction (#27)", {
  for (timeout in c(0.001, 1, 2147483)) {
    expect_no_error(HttpTransport$new("https://example.com", timeout = timeout))
  }
  for (timeout in list(
    0.000999,
    0,
    -1,
    2147483.001,
    Inf,
    NA_real_,
    "5",
    c(1, 2)
  )) {
    expect_error(
      HttpTransport$new("https://example.com", timeout = timeout),
      class = "openlineage_config_error"
    )
  }
  expect_snapshot(
    error = TRUE,
    HttpTransport$new("https://example.com", timeout = 1e-5)
  )
})

test_that("URL and endpoint values that change the path are rejected (#28)", {
  cases <- list(
    list(url = "http://host/?"),
    list(url = "http://host#"),
    list(url = "http://host/a?b"),
    list(url = "http://ho st"),
    list(url = "http://host/a/../b"),
    list(url = "http://host/a/%2E%2e/b"),
    list(url = "http://host", endpoint = "api/%2e%2e/admin"),
    list(url = "http://host", endpoint = "api/%2E/lineage"),
    list(url = "http://host", endpoint = "a b"),
    list(url = "http://host", endpoint = "a\tb"),
    list(url = "http://host", endpoint = "a\001b")
  )

  for (case in cases) {
    expect_error(
      do.call(HttpTransport$new, case),
      class = "openlineage_config_error",
      info = paste(unlist(case), collapse = " ")
    )
  }
  expect_snapshot(
    error = TRUE,
    HttpTransport$new("http://host", endpoint = "api/%2e%2e/admin")
  )
  expect_snapshot(
    error = TRUE,
    HttpTransport$new("http://host", endpoint = "a b")
  )
})

test_that("a lone CR or LF in a header value is rejected (#36)", {
  for (value in c("a\nb", "a\rb", "a\r\nb")) {
    expect_error(
      HttpTransport$new("https://example.com", headers = c(`X-Test` = value)),
      class = "openlineage_config_error"
    )
  }
})

test_that("printing names the authentication kind (#36)", {
  custom <- capture.output(
    print(HttpTransport$new("https://example.com", headers = c(`X-A` = "s")))
  )
  none <- capture.output(print(HttpTransport$new("https://example.com")))

  expect_match(
    custom,
    "authentication: custom headers",
    fixed = TRUE,
    all = FALSE
  )
  expect_match(none, "authentication: none", fixed = TRUE, all = FALSE)
})

test_that("a serialization failure in emit() sends nothing and keeps its cause (#26, #36)", {
  attempts <- 0L
  httr2::local_mocked_responses(function(req) {
    attempts <<- attempts + 1L
    http_mock_response(204L, req)
  })
  event <- RunEvent(
    Run(
      fixture_run_id(),
      facets = list(custom = ol_facet("https://example.com/x.json", v = Inf))
    ),
    Job("example", "http-transport-test"),
    event_time = "2026-01-02T03:04:05.000Z"
  )

  condition <- tryCatch(
    HttpTransport$new("https://example.com")$emit(event),
    error = identity
  )

  expect_identical(attempts, 0L)
  expect_s3_class(condition, "openlineage_validation_error")
  expect_s3_class(condition$parent, "openlineage_validation_error")
  expect_identical(
    conditionMessage(condition),
    conditionMessage(condition$parent)
  )
})
