test_that("new_event_time formats UTC with millisecond precision", {
  time <- as.POSIXct(0.123, origin = "1970-01-01", tz = "UTC")

  expect_identical(new_event_time(time), "1970-01-01T00:00:00.123Z")
})

test_that("new_event_time converts non-UTC inputs to UTC", {
  time <- as.POSIXct("2026-01-02 04:04:05", tz = "Europe/Zurich")

  expect_identical(new_event_time(time), "2026-01-02T03:04:05.000Z")
})

test_that("new_event_time supports deterministic event fixtures", {
  expect_identical(
    new_event_time(fixture_event_time()),
    "2026-01-02T03:04:05.000Z"
  )
  expect_match(
    fixture_run_id(),
    "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
  )
})

test_that("new_event_time validates its input", {
  expect_snapshot(error = TRUE, new_event_time("2026-01-02T03:04:05Z"))
  expect_snapshot(error = TRUE, new_event_time(as.POSIXct(NA)))
})
