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
