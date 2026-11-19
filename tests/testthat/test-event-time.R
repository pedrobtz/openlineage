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

test_that("new_event_time truncates exact milliseconds without losing one (#23)", {
  at <- function(seconds) {
    new_event_time(as.POSIXct(seconds, origin = "1970-01-01", tz = "UTC"))
  }
  base <- 1767323045

  expect_identical(
    new_event_time(as.POSIXct("2026-01-02 03:04:05.123", tz = "UTC")),
    "2026-01-02T03:04:05.123Z"
  )
  expect_identical(at(base + 0.9999), "2026-01-02T03:04:05.999Z")
  expect_identical(at(base + 0.1239), "2026-01-02T03:04:05.123Z")
  expect_identical(at(-0.5), "1969-12-31T23:59:59.500Z")
  expect_identical(at(0.9999996), "1970-01-01T00:00:00.999Z")

  milliseconds <- 0:999
  expected <- sprintf("2026-01-02T03:04:05.%03dZ", milliseconds)
  actual <- vapply(milliseconds, \(ms) at(base + ms / 1000), character(1))
  expect_identical(actual, expected)
})

test_that("new_event_time stays within years 0001 to 9999 (#50)", {
  at <- function(text) new_event_time(as.POSIXct(text, tz = "UTC"))

  expect_identical(at("0001-01-01 00:00:00"), "0001-01-01T00:00:00.000Z")
  expect_identical(at("9999-12-31 23:59:59"), "9999-12-31T23:59:59.000Z")
  # 10000-01-01T00:00:00Z and 0000-12-31T23:59:59Z, one second outside.
  year_10000 <- as.POSIXct(253402300800, origin = "1970-01-01", tz = "UTC")
  year_0000 <- as.POSIXct(-62135596801, origin = "1970-01-01", tz = "UTC")
  expect_error(
    new_event_time(year_10000),
    class = "openlineage_validation_error"
  )
  expect_error(
    new_event_time(year_0000),
    class = "openlineage_validation_error"
  )
  expect_snapshot(error = TRUE, new_event_time(year_10000))
})

test_that("new_event_time rejects non-finite times (#36)", {
  expect_error(
    new_event_time(as.POSIXct(Inf, origin = "1970-01-01", tz = "UTC")),
    class = "openlineage_validation_error"
  )
})

test_that("new_event_time output passes the RFC 3339 validator (#50)", {
  for (text in c(
    "0001-01-01 00:00:00",
    "9999-12-31 23:59:59.999",
    "2026-07-01 12:00:00"
  )) {
    time <- new_event_time(as.POSIXct(text, tz = "UTC"))
    expect_no_error(.ol_validate_rfc3339(time, "event_time"))
  }
})
