.ol_abort <- function(message, class = NULL, call = parent.frame()) {
  cli::cli_abort(
    message,
    class = c(class, "openlineage_error"),
    call = call
  )
}
