test_that("core models convert to OpenLineage wire names", {
  value <- as_openlineage_list(minimal_start_event())

  expect_named(
    value,
    c(
      "eventTime",
      "eventType",
      "inputs",
      "job",
      "outputs",
      "producer",
      "run",
      "schemaURL"
    )
  )
  expect_identical(value$eventType, "START")
  expect_identical(value$run$runId, fixture_run_id())
  expect_identical(names(value$run$facets), character())
  expect_null(names(value$inputs))
})

test_that("serialization omits explicit NULL properties", {
  event <- RunEvent(
    Run(fixture_run_id(), facets = NULL),
    Job("example", "minimal", facets = NULL),
    event_time = "2026-01-02T03:04:05.000Z",
    inputs = NULL,
    outputs = NULL
  )
  value <- as_openlineage_list(event)

  expect_named(value, c("eventTime", "job", "producer", "run", "schemaURL"))
  expect_named(value$run, "runId")
  expect_named(value$job, c("name", "namespace"))
})

test_that("NULL omission is recursive for objects and arrays", {
  value <- as_openlineage_list(list(
    object = list(keep = 1L, drop = NULL),
    array = list(NULL, "keep")
  ))

  expect_named(value$object, "keep")
  expect_identical(value$array, list("keep"))
})

test_that("input and output datasets use role-specific wire fields", {
  input <- as_openlineage_list(
    InputDataset(
      "postgres://warehouse",
      "public.source",
      input_facets = list(
        stats = ol_facet("https://example.com/InputStats.json", rowCount = 10L)
      )
    )
  )
  output <- as_openlineage_list(
    OutputDataset(
      "postgres://warehouse",
      "analytics.result",
      output_facets = list(
        stats = ol_facet("https://example.com/OutputStats.json", rowCount = 10L)
      )
    )
  )

  expect_named(input, c("facets", "inputFacets", "name", "namespace"))
  expect_named(output, c("facets", "name", "namespace", "outputFacets"))
})

test_that("minimal START event matches the Python golden fixture", {
  expected <- read_json_fixture("minimal-start.json")
  actual <- to_openlineage_json(minimal_start_event())

  expect_json_semantically_equal(actual, expected)
})

test_that("JSON serialization is deterministic and optionally pretty", {
  compact <- to_openlineage_json(minimal_start_event())
  repeated <- to_openlineage_json(minimal_start_event())
  pretty <- to_openlineage_json(minimal_start_event(), pretty = TRUE)

  expect_identical(compact, repeated)
  expect_match(pretty, "\\n")
  expect_json_semantically_equal(compact, pretty)
})

test_that("serialization rejects missing and unsupported values", {
  expect_snapshot(error = TRUE, as_openlineage_list(data.frame(x = 1)))
  expect_snapshot(error = TRUE, as_openlineage_list(list(value = NA)))
  expect_snapshot(
    error = TRUE,
    to_openlineage_json(minimal_start_event(), pretty = 1)
  )
})

test_that("numbers are written exactly, as the Python client does (#22)", {
  json <- generic_text(
    sum = 0.1 + 0.2,
    # 123456789.123456789 rounded to the nearest double, written in hex: R's
    # decimal parser mis-rounds the literal without long doubles (noLD).
    long = 0x1.d6f34547e6b75p+26,
    two53 = 2^53,
    big = 3e9,
    quadrillion = 1e15,
    count = 1234567890123456,
    negative = -2.5,
    tiny = 2^-20,
    integer = 7L
  )

  expect_identical(
    json,
    paste0(
      '{"_producer":"https://p","_schemaURL":"https://example.com/x.json",',
      '"sum":0.30000000000000004,"long":123456789.12345679,',
      '"two53":9007199254740992,"big":3000000000,',
      '"quadrillion":1000000000000000,"count":1234567890123456,',
      '"negative":-2.5,"tiny":9.5367431640625e-07,"integer":7}'
    )
  )
})

test_that("doubles read back as the same value (#22)", {
  withr::local_seed(20261119)
  values <- c(
    runif(200, -1e6, 1e6),
    exp(rnorm(200, 0, 50)),
    .Machine$double.eps,
    .Machine$double.xmax,
    2^53 - 1,
    2^53 + 2
  )

  for (value in values) {
    text <- generic_text(v = value)
    expect_identical(
      jsonlite::fromJSON(text)$v,
      value,
      info = format(value, digits = 17)
    )
  }
})

test_that("generic values map to JSON as documented (#30, #51)", {
  json <- generic_json(
    scalar = "only",
    array = I("only"),
    vector = c(1L, 2L),
    list_array = list("a"),
    empty_array = list(),
    empty_object = stats::setNames(list(), character()),
    object = list(b = 2L, a = 1L),
    flag = TRUE,
    above_int = 2^31,
    time = as.POSIXct("2026-01-02 03:04:05.123", tz = "UTC"),
    date = as.Date("2026-01-02"),
    level = factor("low"),
    levels = factor(c("b", "a", "b")),
    boxed = I(2.5),
    boxed_int = I(3L),
    text = "zéta ✓",
    dropped = NULL
  )

  expect_identical(json$scalar, "only")
  expect_identical(json$array, list("only"))
  expect_identical(json$vector, list(1L, 2L))
  expect_identical(json$list_array, list("a"))
  expect_identical(json$empty_array, list())
  expect_identical(json$empty_object, stats::setNames(list(), character()))
  expect_identical(json$object, list(b = 2L, a = 1L))
  expect_identical(json$flag, TRUE)
  expect_identical(json$above_int, 2147483648)
  expect_identical(json$time, "2026-01-02T03:04:05.123Z")
  expect_identical(json$date, "2026-01-02")
  expect_identical(json$level, "low")
  expect_identical(json$levels, list("b", "a", "b"))
  expect_identical(json$boxed, list(2.5))
  expect_identical(json$boxed_int, list(3L))
  expect_identical(json$text, "zéta ✓")
  expect_false("dropped" %in% names(json))
  expect_match(
    generic_text(e = stats::setNames(list(), character()), a = list()),
    '"e":{},"a":[]',
    fixed = TRUE
  )
})

test_that("values jsonlite would change silently are rejected (#30, #31)", {
  invalid <- list(
    Inf,
    -Inf,
    NaN,
    NA,
    c(1, NA),
    1i,
    as.raw(1),
    c(a = 1, b = 2),
    list(a = 1, a = 2),
    list(a = 1, 2),
    stats::setNames(list(1), NA_character_),
    as.difftime(1, units = "secs"),
    rawToChar(as.raw(c(0x66, 0xff, 0x6f))),
    stats::setNames(list(1), rawToChar(as.raw(c(0x66, 0xff)))),
    as.POSIXct(NA),
    as.Date(Inf),
    as.Date(-Inf),
    as.Date(3000000),
    as.Date(-800000),
    as.Date("0000-06-01"),
    numeric_version("1.2.3"),
    structure(list(a = 1), class = "foo"),
    R.version
  )

  for (i in seq_along(invalid)) {
    expect_error(
      generic_text(v = invalid[[i]]),
      class = "openlineage_validation_error",
      info = paste("case", i)
    )
  }
  expect_snapshot(error = TRUE, generic_text(v = Inf))
  expect_snapshot(error = TRUE, generic_text(v = c(a = 1)))
  expect_snapshot(error = TRUE, generic_text(v = list(a = 1, a = 2)))
})

test_that("serialized output is the same in a hostile session", {
  facet <- ol_facet(
    "https://example.com/x.json",
    pi = pi,
    big = 123456789.25,
    count = 1e15,
    text = "zéta",
    producer = "https://p"
  )
  expected <- to_openlineage_json(facet)

  withr::local_options(OutDec = ",", scipen = -5, digits = 3)
  withr::local_locale(c(LC_COLLATE = "C", LC_CTYPE = "C"))
  expect_identical(to_openlineage_json(facet), expected)
  expect_match(expected, '"pi":3.141592653589793', fixed = TRUE)
})

test_that("unknown S7 objects and unmapped facets are rejected (#36)", {
  Unknown <- S7::new_class("Unknown", package = NULL)
  UnmappedFacet <- S7::new_class(
    "UnmappedFacet",
    package = NULL,
    parent = .RunFacet,
    constructor = function() {
      S7::new_object(.RunFacet(
        OPENLINEAGE_PRODUCER,
        "https://example.com/x.json"
      ))
    }
  )

  expect_error(
    as_openlineage_list(Unknown()),
    class = "openlineage_validation_error"
  )
  expect_error(
    as_openlineage_list(UnmappedFacet()),
    class = "openlineage_validation_error"
  )
  expect_snapshot(error = TRUE, as_openlineage_list(UnmappedFacet()))
})

test_that("POSIXlt values are written as event times (#65)", {
  json <- generic_json(
    t = as.POSIXlt("2026-01-02 03:04:05.123", tz = "UTC"),
    at_zurich = as.POSIXlt("2026-01-02 04:04:05", tz = "Europe/Zurich")
  )

  expect_identical(json$t, "2026-01-02T03:04:05.123Z")
  expect_identical(json$at_zurich, "2026-01-02T03:04:05.000Z")
  expect_identical(
    as_openlineage_list(as.POSIXlt("2026-01-02", tz = "UTC")),
    "2026-01-02T00:00:00.000Z"
  )
})

test_that("Dates at the year limits are written; outside them rejected (#64)", {
  json <- generic_json(
    first = as.Date("0001-01-01"),
    padded = as.Date("0999-03-04"),
    last = as.Date("9999-12-31")
  )

  # glibc's `%Y` does not pad years below 1000; the output must not depend on
  # the platform's strftime().
  expect_identical(json$first, "0001-01-01")
  expect_identical(json$padded, "0999-03-04")
  expect_identical(json$last, "9999-12-31")
  expect_error(
    generic_text(v = as.Date("0001-01-01") - 1),
    class = "openlineage_validation_error"
  )
  expect_error(
    generic_text(v = as.Date("9999-12-31") + 1),
    class = "openlineage_validation_error"
  )
  expect_snapshot(error = TRUE, generic_text(v = as.Date(Inf)))
  expect_snapshot(error = TRUE, generic_text(v = R.version))
})

test_that("UTF-8 text reaches the wire as UTF-8 bytes in a C locale (#63)", {
  withr::local_locale(c(LC_CTYPE = "C"))
  text <- rawToChar(as.raw(c(0x63, 0x61, 0x66, 0xc3, 0xa9)))
  invalid <- rawToChar(as.raw(c(0x61, 0xff)))
  latin1 <- rawToChar(as.raw(c(0x63, 0x61, 0x66, 0xe9)))
  Encoding(latin1) <- "latin1"
  bytes <- function(x) charToRaw(to_openlineage_json(x))
  cafe <- as.raw(c(0x63, 0x61, 0x66, 0xc3, 0xa9))
  contains <- function(haystack, needle) {
    any(vapply(
      seq_len(length(haystack) - length(needle) + 1L),
      \(i) identical(haystack[i:(i + length(needle) - 1L)], needle),
      logical(1)
    ))
  }

  expect_true(contains(bytes(Job("ns", text)), cafe))
  expect_true(contains(bytes(Job("ns", latin1)), cafe))
  facet <- ol_facet(
    "https://example.com/x.json",
    v = text,
    n = stats::setNames(list(1L), text)
  )
  expect_identical(sum(bytes(facet) == as.raw(0xc3)), 2L)
  expect_false(grepl(
    "<",
    rawToChar(bytes(facet)),
    fixed = TRUE,
    useBytes = TRUE
  ))

  expect_error(Job("ns", invalid), class = "openlineage_validation_error")
  expect_error(
    generic_text(v = invalid),
    class = "openlineage_validation_error"
  )
  bytes_marked <- text
  Encoding(bytes_marked) <- "bytes"
  expect_error(Job("ns", bytes_marked), class = "openlineage_validation_error")
})
