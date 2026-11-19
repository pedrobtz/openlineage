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

# Replaces the retry sleep for the calling test and returns a function giving
# the delays requested so far, so no test really sleeps.
local_recorded_sleep <- function(.env = parent.frame()) {
  delays <- numeric()
  testthat::local_mocked_bindings(
    .ol_http_retry_sleep = function(seconds) {
      delays <<- c(delays, seconds)
    },
    .package = "openlineage",
    .env = .env
  )
  function() delays
}

# Emits one event through a transport whose server answers `responses` in
# turn and returns the delays slept between them.
retry_delays <- function(responses, max_retries = length(responses)) {
  delays <- local_recorded_sleep()
  attempt <- 0L
  httr2::local_mocked_responses(function(req) {
    attempt <<- attempt + 1L
    if (attempt > length(responses)) {
      return(http_mock_response(204L, req))
    }
    responses[[attempt]](req)
  })
  HttpTransport$new("https://example.com", max_retries = max_retries)$emit(
    http_transport_event()
  )
  delays()
}

status_with <- function(status_code = 503L, ...) {
  headers <- list(...)
  function(req) http_mock_response(status_code, req, headers = headers)
}
