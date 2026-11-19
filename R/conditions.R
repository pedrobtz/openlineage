.ol_abort <- function(message, class = NULL, call = parent.frame()) {
  # `message` often embeds user values (column names, facet keys), so cli
  # receives it as data through `{text}`, never as a format string to
  # interpolate.
  text <- message
  cli::cli_abort(
    "{text}",
    class = c(class, "openlineage_error"),
    call = call
  )
}
