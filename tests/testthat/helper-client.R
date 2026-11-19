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

# Sets the client's environment variables for the calling test, unsetting
# every one that `values` does not name.
local_client_env <- function(values = character(), .env = parent.frame()) {
  unset <- setdiff(.OPENLINEAGE_CLIENT_ENV_VARS, names(values))
  withr::local_envvar(
    c(values, stats::setNames(rep(NA_character_, length(unset)), unset)),
    .local_envir = .env
  )
}

# The Authorization header as sent, read from the request the mock received.
sent_authorization <- function(request) {
  httr2::req_get_headers(request, "reveal")$Authorization
}
