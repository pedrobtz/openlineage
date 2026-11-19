minimal_start_event <- function() {
  RunEvent(
    Run(fixture_run_id()),
    Job("example", "minimal"),
    event_type = "START",
    event_time = "2026-01-02T03:04:05.000Z"
  )
}

# A generic facet's JSON text, and its fields parsed back, for value tests.
generic_text <- function(...) {
  to_openlineage_json(
    ol_facet("https://example.com/x.json", ..., producer = "https://p")
  )
}

generic_json <- function(...) {
  json <- jsonlite::fromJSON(generic_text(...), simplifyVector = FALSE)
  json[setdiff(names(json), c("_producer", "_schemaURL"))]
}
