.ol_validate_transport_event <- function(event, call = parent.frame()) {
  if (!S7::S7_inherits(event, RunEvent)) {
    .ol_abort(
      "`event` must be a `RunEvent` object.",
      class = "openlineage_validation_error",
      call = call
    )
  }

  invisible(event)
}

.ol_validate_transport <- function(transport, call = parent.frame()) {
  valid <- inherits(transport, "R6") && is.function(transport$emit)
  if (!valid) {
    .ol_abort(
      "`transport` must be an R6 object with an `emit(event)` method.",
      class = "openlineage_config_error",
      call = call
    )
  }

  invisible(transport)
}

.ol_validate_output_connection <- function(stream, call = parent.frame()) {
  writable <- inherits(stream, "connection") &&
    tryCatch(isOpen(stream, rw = "write"), error = \(condition) FALSE)
  if (!writable) {
    .ol_abort(
      "`stream` must be an open, writable connection.",
      class = "openlineage_config_error",
      call = call
    )
  }

  invisible(stream)
}

.ol_validate_transport_flag <- function(value, arg, call = parent.frame()) {
  if (!is.logical(value) || length(value) != 1L || is.na(value)) {
    .ol_abort(
      paste0("`", arg, "` must be `TRUE` or `FALSE`."),
      class = "openlineage_config_error",
      call = call
    )
  }

  invisible(value)
}

.ol_transport_failure <- function(message, parent, call = parent.frame()) {
  cli::cli_abort(
    message,
    class = c("openlineage_transport_error", "openlineage_error"),
    parent = parent,
    call = call
  )
}

.ol_transport_emit <- function(transport, event, call = parent.frame()) {
  .ol_validate_transport(transport, call = call)
  .ol_validate_transport_event(event, call = call)

  outcome <- tryCatch(
    list(success = TRUE, value = transport$emit(event)),
    error = \(condition) list(success = FALSE, condition = condition)
  )
  if (!outcome$success) {
    condition <- outcome$condition
    if (inherits(condition, "openlineage_error")) {
      stop(condition)
    }
    .ol_transport_failure(
      "Transport failed to emit the OpenLineage event.",
      parent = condition,
      call = call
    )
  }

  invisible(event)
}

.OpenLineageTransport <- R6Class(
  "OpenLineageTransport",
  public = list(
    emit = function(event) {
      .ol_validate_transport_event(event, call = parent.frame())
      .ol_abort(
        "The transport must implement `emit(event)`.",
        class = "openlineage_transport_error",
        call = parent.frame()
      )
    },
    close = function() {
      invisible(TRUE)
    }
  )
)

#' Local OpenLineage transports
#'
#' Offline transports for testing, local development, and disabled emission.
#' Every `emit(event)` method accepts a `RunEvent` model and returns that event
#' invisibly after success.
#'
#' `AccumulatingTransport` stores emitted models in its public `events` list.
#' Its `clear()` method removes all accumulated events and returns the transport
#' invisibly.
#'
#' `ConsoleTransport` writes one JSON event to `stream`. Set `pretty = TRUE`
#' for indented output.
#'
#' `NoopTransport` validates an event but performs no output or storage.
#'
#' All transports provide `close()`, which returns `TRUE` invisibly because the
#' local transports have no pending work.
#'
#' @return An R6 transport object.
#' @name local_transports
NULL

#' @rdname local_transports
#' @export
#'
#' @examples
#' transport <- AccumulatingTransport$new()
#' event <- RunEvent(
#'   Run(new_run_id()),
#'   Job("example", "task"),
#'   event_type = "START"
#' )
#' transport$emit(event)
#' length(transport$events)
#'
#' console <- ConsoleTransport$new(pretty = FALSE)
#' noop <- NoopTransport$new()
#' noop$emit(event)
AccumulatingTransport <- R6Class(
  "AccumulatingTransport",
  inherit = .OpenLineageTransport,
  public = list(
    #' @field events Emitted `RunEvent` models in emission order.
    events = NULL,

    #' @description
    #' Create an empty accumulating transport.
    #' @returns A new `AccumulatingTransport` object.
    initialize = function() {
      self$events <- list()
      invisible(self)
    },

    #' @description
    #' Store an event.
    #' @param event A `RunEvent` model.
    #' @returns `event`, invisibly.
    emit = function(event) {
      .ol_validate_transport_event(event, call = parent.frame())
      self$events[[length(self$events) + 1L]] <- event
      invisible(event)
    },

    #' @description
    #' Remove all stored events.
    #' @returns The transport, invisibly.
    clear = function() {
      self$events <- list()
      invisible(self)
    }
  )
)

#' @rdname local_transports
#' @export
ConsoleTransport <- R6Class(
  "ConsoleTransport",
  inherit = .OpenLineageTransport,
  public = list(
    #' @description
    #' Create a console transport.
    #' @param stream An open, writable R connection.
    #' @param pretty Whether JSON should be indented.
    #' @returns A new `ConsoleTransport` object.
    initialize = function(stream = stdout(), pretty = TRUE) {
      .ol_validate_output_connection(stream, call = parent.frame())
      .ol_validate_transport_flag(pretty, "pretty", call = parent.frame())
      private$stream <- stream
      private$pretty <- pretty
      invisible(self)
    },

    #' @description
    #' Serialize and write an event to the configured connection.
    #' @param event A `RunEvent` model.
    #' @returns `event`, invisibly.
    emit = function(event) {
      caller <- parent.frame()
      .ol_validate_transport_event(event, call = caller)
      json <- to_openlineage_json(event, pretty = private$pretty)

      tryCatch(
        writeLines(json, con = private$stream, useBytes = TRUE),
        error = function(condition) {
          .ol_transport_failure(
            "Console transport failed to write the OpenLineage event.",
            parent = condition,
            call = caller
          )
        }
      )

      invisible(event)
    }
  ),
  private = list(
    stream = NULL,
    pretty = NULL
  )
)

#' @rdname local_transports
#' @export
NoopTransport <- R6Class(
  "NoopTransport",
  inherit = .OpenLineageTransport,
  public = list(
    #' @description
    #' Validate an event without emitting it.
    #' @param event A `RunEvent` model.
    #' @returns `event`, invisibly.
    emit = function(event) {
      .ol_validate_transport_event(event, call = parent.frame())
      invisible(event)
    }
  )
)
