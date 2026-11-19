test_that("scalar character validation returns its input invisibly (#41)", {
  result <- withVisible(.ol_validate_scalar_character("value", "x"))

  expect_identical(result, list(value = "value", visible = FALSE))
})

test_that("scalar character validation has stable errors", {
  condition <- tryCatch(
    .ol_validate_scalar_character(character(), "name"),
    error = identity
  )

  expect_s3_class(condition, "openlineage_validation_error")
  expect_s3_class(condition, "openlineage_error")
  expect_snapshot(error = TRUE, {
    .ol_validate_scalar_character("", "name")
  })
})

test_that("strings that are not valid UTF-8 are rejected (#31)", {
  invalid <- rawToChar(as.raw(c(0x66, 0xff, 0x6f)))
  latin1 <- iconv("café", "UTF-8", "latin1")

  expect_error(Job("ns", invalid), class = "openlineage_validation_error")
  expect_error(Job(invalid, "name"), class = "openlineage_validation_error")
  expect_snapshot(error = TRUE, Job("ns", invalid))
  expect_identical(Encoding(latin1), "latin1")
  expect_identical(
    jsonlite::fromJSON(to_openlineage_json(Job("ns", latin1)))$name,
    "café"
  )
})

test_that("RFC 3339 validation rejects impossible date-times (#36, #50)", {
  valid <- c(
    "2026-01-02T03:04:05Z",
    "0001-01-01T00:00:00Z",
    "2026-01-02T23:59:59.999+01:00",
    "2026-01-02t03:04:05z"
  )
  invalid <- c(
    "2026-13-45T00:00:00Z",
    "2026-02-30T00:00:00Z",
    "2026-01-02T24:00:00Z",
    "0000-01-01T00:00:00Z",
    "2026-01-02T03:60:00Z",
    "2026-01-02T03:04:05",
    "2026-01-02 03:04:05Z"
  )

  for (x in valid) {
    expect_no_error(.ol_validate_rfc3339(x, "event_time"))
  }
  for (x in invalid) {
    expect_error(
      .ol_validate_rfc3339(x, "event_time"),
      class = "openlineage_validation_error",
      info = x
    )
  }
})
