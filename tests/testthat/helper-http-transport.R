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
