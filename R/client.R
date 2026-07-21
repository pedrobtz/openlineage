.OPENLINEAGE_CLIENT_ENV_VARS <- c(
  "OPENLINEAGE_URL",
  "OPENLINEAGE_ENDPOINT",
  "OPENLINEAGE_API_KEY",
  "OPENLINEAGE_DISABLED"
)

.ol_client_config_abort <- function(message) {
  condition <- structure(
    list(message = message, call = NULL),
    class = c(
      "openlineage_config_error",
      "openlineage_error",
      "error",
      "condition"
    )
  )
  stop(condition)
}

.ol_client_env_value <- function(name) {
  value <- Sys.getenv(name, unset = NA_character_)
  if (is.na(value) || !nzchar(trimws(value))) {
    return(NULL)
  }

  value
}

.ol_client_disabled <- function(disabled) {
  if (!is.null(disabled)) {
    valid <- is.logical(disabled) &&
      length(disabled) == 1L &&
      !is.na(disabled)
    if (!valid) {
      .ol_client_config_abort(
        "`disabled` must be `TRUE`, `FALSE`, or `NULL`."
      )
    }
    return(disabled)
  }

  value <- .ol_client_env_value("OPENLINEAGE_DISABLED")
  if (is.null(value)) {
    return(FALSE)
  }
  value <- tolower(trimws(value))
  if (!value %in% c("true", "false")) {
    .ol_client_config_abort(
      "`OPENLINEAGE_DISABLED` must be `true` or `false`."
    )
  }

  identical(value, "true")
}

.ol_client_explicit_http_args <- function(
  url,
  api_key,
  endpoint_missing,
  headers_missing,
  timeout_missing,
  verify_tls_missing,
  max_retries_missing
) {
  configured <- c(
    url = !is.null(url),
    endpoint = !endpoint_missing,
    api_key = !is.null(api_key),
    headers = !headers_missing,
    timeout = !timeout_missing,
    verify_tls = !verify_tls_missing,
    max_retries = !max_retries_missing
  )

  names(configured)[configured]
}

.ol_client_http_args_text <- function(arguments) {
  paste0("`", arguments, "`", collapse = ", ")
}

#' OpenLineage client
#'
#' Coordinates event emission through an OpenLineage transport. Supply a
#' transport directly for local or custom delivery, or configure the built-in
#' HTTP transport with `url` and related arguments.
#'
#' When an argument is absent, the client reads `OPENLINEAGE_URL`,
#' `OPENLINEAGE_ENDPOINT`, `OPENLINEAGE_API_KEY`, and
#' `OPENLINEAGE_DISABLED`. Explicit arguments take precedence over their
#' environment equivalents. `OPENLINEAGE_DISABLED` accepts only `true` or
#' `false`, ignoring case and surrounding whitespace.
#'
#' A disabled client uses [NoopTransport]. An injected `transport` takes
#' precedence over HTTP environment variables. If neither a transport nor URL
#' is configured, the client uses [ConsoleTransport]. Supplying partial HTTP
#' settings without a URL is an error.
#'
#' @return An R6 OpenLineage client object.
#' @seealso [local_transports], [HttpTransport]
#' @export
#'
#' @examples
#' transport <- AccumulatingTransport$new()
#' client <- OpenLineageClient$new(transport = transport, disabled = FALSE)
#' event <- RunEvent(
#'   Run(new_run_id()),
#'   Job("example", "task"),
#'   event_type = "START"
#' )
#' client$emit(event)
#' length(transport$events)
OpenLineageClient <- R6Class(
  "OpenLineageClient",
  public = list(
    #' @field transport The configured OpenLineage transport.
    transport = NULL,

    #' @description
    #' Create an OpenLineage client.
    #' @param transport An optional R6 transport with an `emit(event)` method.
    #' @param url An optional HTTP or HTTPS base URL. If `NULL`,
    #'   `OPENLINEAGE_URL` is used when set.
    #' @param endpoint A relative OpenLineage endpoint path. If omitted,
    #'   `OPENLINEAGE_ENDPOINT` is used when set.
    #' @param api_key An optional bearer API key. If `NULL`,
    #'   `OPENLINEAGE_API_KEY` is used when set.
    #' @param headers Optional custom HTTP headers as a named character vector.
    #' @param timeout A positive HTTP request timeout in seconds.
    #' @param verify_tls Whether to verify TLS certificates.
    #' @param max_retries A non-negative number of HTTP retries after the first
    #'   request attempt.
    #' @param disabled Whether to disable emission. If `NULL`,
    #'   `OPENLINEAGE_DISABLED` is used when set.
    #' @returns A new `OpenLineageClient` object.
    initialize = function(
      transport = NULL,
      url = NULL,
      endpoint = "api/v1/lineage",
      api_key = NULL,
      headers = character(),
      timeout = 5,
      verify_tls = TRUE,
      max_retries = 3L,
      disabled = NULL
    ) {
      endpoint_missing <- missing(endpoint)
      headers_missing <- missing(headers)
      timeout_missing <- missing(timeout)
      verify_tls_missing <- missing(verify_tls)
      max_retries_missing <- missing(max_retries)
      explicit_http_args <- .ol_client_explicit_http_args(
        url = url,
        api_key = api_key,
        endpoint_missing = endpoint_missing,
        headers_missing = headers_missing,
        timeout_missing = timeout_missing,
        verify_tls_missing = verify_tls_missing,
        max_retries_missing = max_retries_missing
      )

      if (.ol_client_disabled(disabled)) {
        self$transport <- NoopTransport$new()
        return(invisible(self))
      }

      if (!is.null(transport)) {
        if (length(explicit_http_args) > 0L) {
          .ol_client_config_abort(
            paste0(
              "`transport` cannot be combined with HTTP argument(s): ",
              .ol_client_http_args_text(explicit_http_args),
              "."
            )
          )
        }
        .ol_validate_transport(transport, call = parent.frame())
        self$transport <- transport
        return(invisible(self))
      }

      env_endpoint <- .ol_client_env_value("OPENLINEAGE_ENDPOINT")
      env_api_key <- .ol_client_env_value("OPENLINEAGE_API_KEY")
      if (is.null(url)) {
        url <- .ol_client_env_value("OPENLINEAGE_URL")
      }
      if (endpoint_missing && !is.null(env_endpoint)) {
        endpoint <- env_endpoint
      }
      if (is.null(api_key)) {
        api_key <- env_api_key
      }

      if (is.null(url)) {
        partial_http <- unique(c(
          explicit_http_args,
          if (!is.null(env_endpoint)) "OPENLINEAGE_ENDPOINT",
          if (!is.null(env_api_key)) "OPENLINEAGE_API_KEY"
        ))
        if (length(partial_http) > 0L) {
          .ol_client_config_abort(
            paste0(
              "HTTP setting(s) ",
              .ol_client_http_args_text(partial_http),
              " require `url` or `OPENLINEAGE_URL`."
            )
          )
        }
        self$transport <- ConsoleTransport$new()
        return(invisible(self))
      }

      self$transport <- HttpTransport$new(
        url = url,
        endpoint = endpoint,
        api_key = api_key,
        headers = headers,
        timeout = timeout,
        verify_tls = verify_tls,
        max_retries = max_retries
      )
      invisible(self)
    },

    #' @description
    #' Emit an OpenLineage event through the configured transport.
    #' @param event A `RunEvent` model.
    #' @returns `event`, invisibly, after successful delivery.
    emit = function(event) {
      .ol_transport_emit(
        self$transport,
        event,
        call = parent.frame()
      )
    },

    #' @description
    #' Print a credential-free client summary.
    #' @param ... Unused.
    #' @returns The client, invisibly.
    print = function(...) {
      cat(
        "<OpenLineageClient>\n",
        "  transport: ",
        class(self$transport)[[1L]],
        "\n",
        sep = ""
      )
      invisible(self)
    }
  )
)
