minimal_start_event <- function() {
  RunEvent(
    Run(fixture_run_id()),
    Job("example", "minimal"),
    event_type = "START",
    event_time = "2026-01-02T03:04:05.000Z"
  )
}
