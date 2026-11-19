.ol_validate_scalar_character <- function(
  x,
  arg,
  allow_empty = FALSE,
  call = parent.frame()
) {
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    .ol_abort(
      paste0("`", arg, "` must be a single, non-missing string."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  if (!validUTF8(enc2utf8(x))) {
    .ol_abort(
      paste0("`", arg, "` must be valid UTF-8 text."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  if (!allow_empty && !nzchar(x)) {
    .ol_abort(
      paste0("`", arg, "` must not be empty."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  invisible(x)
}

.ol_validate_posix_time <- function(x, arg, call = parent.frame()) {
  if (!inherits(x, "POSIXt") || length(x) != 1L || is.na(x)) {
    .ol_abort(
      paste0("`", arg, "` must be a single, non-missing POSIXt value."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  seconds <- as.numeric(x)
  if (!is.finite(seconds)) {
    .ol_abort(
      paste0("`", arg, "` must be finite."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  invisible(x)
}

.ol_validate_uuid <- function(x, arg, call = parent.frame()) {
  .ol_validate_scalar_character(x, arg, call = call)

  if (!uuid::UUIDvalidate(x)) {
    .ol_abort(
      paste0("`", arg, "` must be a valid UUID."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  invisible(x)
}

.ol_validate_rfc3339 <- function(x, arg, call = parent.frame()) {
  .ol_validate_scalar_character(x, arg, call = call)

  pattern <- paste0(
    "^[0-9]{4}-[0-9]{2}-[0-9]{2}[Tt]",
    "[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?",
    "([Zz]|[+-][0-9]{2}:[0-9]{2})$"
  )
  valid_shape <- grepl(pattern, x, perl = TRUE)
  if (valid_shape) {
    # strptime() accepts hour 24 and year 0000, which RFC 3339 does not.
    valid_shape <- substr(x, 1L, 4L) != "0000" &&
      as.integer(substr(x, 12L, 13L)) <= 23L
  }

  normalized <- sub("t", "T", x, fixed = TRUE)
  normalized <- sub("[Zz]$", "+0000", normalized)
  normalized <- sub(
    "([+-][0-9]{2}):([0-9]{2})$",
    "\\1\\2",
    normalized
  )
  parsed <- suppressWarnings(
    strptime(normalized, "%Y-%m-%dT%H:%M:%OS%z", tz = "UTC")
  )

  if (!valid_shape || is.na(parsed)) {
    .ol_abort(
      paste0(
        "`",
        arg,
        "` must be an RFC 3339 date-time with a time-zone offset."
      ),
      class = "openlineage_validation_error",
      call = call
    )
  }

  invisible(x)
}

.ol_validate_uri <- function(x, arg, call = parent.frame()) {
  .ol_validate_scalar_character(x, arg, call = call)

  valid <- grepl(
    "^[A-Za-z][A-Za-z0-9+.-]*:[^[:space:]]+$",
    x,
    perl = TRUE
  )
  if (grepl("^https?://", x, ignore.case = TRUE)) {
    valid <- valid &&
      grepl(
        "^https?://[^/[:space:]?#]+",
        x,
        ignore.case = TRUE,
        perl = TRUE
      )
  }

  if (!valid) {
    .ol_abort(
      paste0("`", arg, "` must be a valid URI."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  invisible(x)
}

.ol_validate_flag <- function(x, arg, call = parent.frame()) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    .ol_abort(
      paste0("`", arg, "` must be `TRUE` or `FALSE`."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  invisible(x)
}

.ol_normalize_map <- function(x, arg, call = parent.frame()) {
  if (is.null(x)) {
    return(NULL)
  }

  if (!is.list(x)) {
    .ol_abort(
      paste0("`", arg, "` must be a named list or `NULL`."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  if (length(x) == 0L) {
    names(x) <- character()
    return(x)
  }

  map_names <- names(x)
  if (
    is.null(map_names) ||
      anyNA(map_names) ||
      any(!nzchar(map_names)) ||
      anyDuplicated(map_names)
  ) {
    .ol_abort(
      paste0("`", arg, "` must have unique, non-empty names."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  x
}

.ol_validate_normalized_map <- function(x, arg, call = parent.frame()) {
  normalized <- .ol_normalize_map(x, arg, call = call)

  if (!identical(x, normalized)) {
    .ol_abort(
      paste0("`", arg, "` must be a named list or `NULL`."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  invisible(x)
}

.ol_normalize_array <- function(x, arg, call = parent.frame()) {
  if (is.null(x)) {
    return(NULL)
  }

  if (!is.list(x)) {
    .ol_abort(
      paste0("`", arg, "` must be an unnamed list or `NULL`."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  if (!is.null(names(x))) {
    .ol_abort(
      paste0("`", arg, "` must be an unnamed list or `NULL`."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  x
}
