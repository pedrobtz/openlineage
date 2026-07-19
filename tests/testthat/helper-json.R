read_json_fixture <- function(name) {
  jsonlite::fromJSON(
    testthat::test_path("fixtures", name),
    simplifyVector = FALSE
  )
}

parse_json_value <- function(x) {
  if (is.character(x) && length(x) == 1L) {
    return(jsonlite::fromJSON(x, simplifyVector = FALSE))
  }

  x
}

canonicalize_json <- function(x) {
  if (!is.list(x)) {
    return(x)
  }

  if (!is.null(names(x))) {
    x <- x[order(names(x))]
  }

  lapply(x, canonicalize_json)
}

expect_json_semantically_equal <- function(actual, expected) {
  testthat::expect_equal(
    canonicalize_json(parse_json_value(actual)),
    canonicalize_json(parse_json_value(expected))
  )
}
