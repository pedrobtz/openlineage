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
