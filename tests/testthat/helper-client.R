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
