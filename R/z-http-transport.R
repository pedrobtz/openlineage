.OPENLINEAGE_TRANSIENT_HTTP_STATUS <- c(429L, 500L, 502L, 503L, 504L)

.ol_http_condition_abort <- function(message, class, status_code = NULL) {
  fields <- list(message = message, call = NULL)
  if (!is.null(status_code)) {
    fields$status_code <- status_code
  }
  condition <- structure(
    fields,
    class = c(class, "error", "condition")
  )
  stop(condition)
}

.ol_http_config_abort <- function(message, call = parent.frame()) {
  .ol_http_condition_abort(
    message,
    class = c("openlineage_config_error", "openlineage_error")
  )
}

.ol_normalize_http_url <- function(url, endpoint, call = parent.frame()) {
  valid_url_value <- is.character(url) &&
    length(url) == 1L &&
    !is.na(url) &&
    nzchar(url)
  valid_endpoint_value <- is.character(endpoint) &&
    length(endpoint) == 1L &&
    !is.na(endpoint) &&
    nzchar(endpoint)
  if (!valid_url_value) {
    .ol_http_config_abort("`url` must be a non-empty string.", call = call)
  }
  if (!valid_endpoint_value) {
    .ol_http_config_abort("`endpoint` must be a non-empty string.", call = call)
  }
  url <- trimws(url)
  endpoint <- trimws(endpoint)

  parsed <- tryCatch(
    httr2::url_parse(url),
    error = \(condition) NULL
  )
  valid_url <- !is.null(parsed) &&
    parsed$scheme %in% c("http", "https") &&
    !is.null(parsed$hostname) &&
    nzchar(parsed$hostname) &&
    is.null(parsed$username) &&
    is.null(parsed$password) &&
    is.null(parsed$query) &&
    is.null(parsed$fragment)
  if (!valid_url) {
    .ol_http_config_abort(
      paste0(
        "`url` must be an absolute HTTP or HTTPS URL without credentials, ",
        "a query, or a fragment."
      ),
      call = call
    )
  }

  endpoint <- gsub("^/+|/+$", "", endpoint)
  segments <- strsplit(endpoint, "/+", perl = TRUE)[[1L]]
  valid_endpoint <- nzchar(endpoint) &&
    !grepl("^[A-Za-z][A-Za-z0-9+.-]*:", endpoint) &&
    !grepl("[?#]", endpoint) &&
    !any(segments %in% c(".", ".."))
  if (!valid_endpoint) {
    .ol_http_config_abort(
      "`endpoint` must be a non-empty relative path without `.` or `..` segments.",
      call = call
    )
  }
  endpoint <- paste(segments[nzchar(segments)], collapse = "/")

  url <- sub("/+$", "", url)
  if (endsWith(url, paste0("/", endpoint))) {
    return(url)
  }

  paste0(url, "/", endpoint)
}

.ol_normalize_api_key <- function(api_key, call = parent.frame()) {
  if (is.null(api_key)) {
    return(NULL)
  }
  if (
    !is.character(api_key) ||
      length(api_key) != 1L ||
      is.na(api_key) ||
      !nzchar(api_key) ||
      grepl("[[:space:]]", api_key)
  ) {
    .ol_http_config_abort(
      "`api_key` must be a non-empty string without whitespace, or `NULL`.",
      call = call
    )
  }

  api_key
}

.ol_normalize_http_headers <- function(headers, call = parent.frame()) {
  if (!is.character(headers) || anyNA(headers)) {
    .ol_http_config_abort(
      "`headers` must be a named character vector without missing values.",
      call = call
    )
  }
  if (length(headers) == 0L) {
    return(stats::setNames(character(), character()))
  }

  header_names <- names(headers)
  valid_names <- !is.null(header_names) &&
    !anyNA(header_names) &&
    all(nzchar(header_names)) &&
    all(grepl("^[!#$%&'*+.^_`|~0-9A-Za-z-]+$", header_names)) &&
    !anyDuplicated(tolower(header_names))
  valid_values <- !any(grepl("[\r\n]", headers))
  if (!valid_names || !valid_values) {
    .ol_http_config_abort(
      paste0(
        "`headers` must have unique, valid names and values without line ",
        "breaks."
      ),
      call = call
    )
  }
  if (any(tolower(header_names) == "content-type")) {
    .ol_http_config_abort(
      "`Content-Type` is managed by `HttpTransport` and cannot be customized.",
      call = call
    )
  }

  headers
}

.ol_http_request_headers <- function(api_key, headers) {
  if (is.null(api_key)) {
    return(headers)
  }

  c(Authorization = paste("Bearer", api_key), headers)
}

.ol_validate_http_number <- function(
  value,
  arg,
  minimum,
  integer = FALSE,
  call = parent.frame()
) {
  valid <- is.numeric(value) &&
    length(value) == 1L &&
    !is.na(value) &&
    is.finite(value) &&
    value >= minimum
  if (integer) {
    valid <- valid && value == floor(value)
  }
  if (!valid) {
    type <- if (integer) "an integer-like number" else "a number"
    .ol_http_config_abort(
      paste0(
        "`",
        arg,
        "` must be ",
        type,
        " greater than or equal to ",
        minimum,
        "."
      ),
      call = call
    )
  }

  invisible(value)
}

.ol_http_abort <- function(status_code, call = parent.frame()) {
  if (status_code %in% c(401L, 403L)) {
    .ol_http_condition_abort(
      paste0(
        "OpenLineage authentication failed with HTTP ",
        status_code,
        "."
      ),
      class = c(
        "openlineage_auth_error",
        "openlineage_http_error",
        "openlineage_transport_error",
        "openlineage_error"
      ),
      status_code = status_code
    )
  }

  .ol_http_condition_abort(
    paste0("OpenLineage server returned HTTP ", status_code, "."),
    class = c(
      "openlineage_http_error",
      "openlineage_transport_error",
      "openlineage_error"
    ),
    status_code = status_code
  )
}

.ol_http_transport_abort <- function(call = parent.frame()) {
  .ol_http_condition_abort(
    "OpenLineage HTTP request failed before receiving a response.",
    class = c("openlineage_transport_error", "openlineage_error")
  )
}

.ol_http_validate_event <- function(event) {
  if (!S7::S7_inherits(event, RunEvent)) {
    .ol_http_condition_abort(
      "`event` must be a `RunEvent` object.",
      class = c("openlineage_validation_error", "openlineage_error")
    )
  }

  invisible(event)
}

.ol_http_serialize_event <- function(event) {
  outcome <- tryCatch(
    list(value = to_openlineage_json(event)),
    error = \(condition) list(condition = condition)
  )
  if (!is.null(outcome$condition)) {
    .ol_http_condition_abort(
      conditionMessage(outcome$condition),
      class = c("openlineage_validation_error", "openlineage_error")
    )
  }

  outcome$value
}

.ol_http_tls_warning <- function() {
  condition <- structure(
    list(
      message = paste0(
        "TLS certificate verification is disabled. Use this only in a ",
        "controlled development environment."
      ),
      call = NULL
    ),
    class = c(
      "openlineage_insecure_tls_warning",
      "warning",
      "condition"
    )
  )
  warning(condition)
}

.ol_http_retry_delay <- function(response, retry_number) {
  if (!is.null(response)) {
    after <- suppressWarnings(httr2::resp_retry_after(response))
    if (length(after) == 1L && !is.na(after) && is.finite(after)) {
      return(max(0, min(after, 60)))
    }
  }

  min(2^(retry_number - 1L), 30)
}

.ol_http_retry_sleep <- function(seconds) {
  Sys.sleep(seconds)
}

#' Synchronous HTTP transport
#'
#' Sends OpenLineage events as JSON `POST` requests. The base `url` and
#' relative `endpoint` are joined with one slash; a URL that already ends in
#' the endpoint is not duplicated.
#'
#' Supply `api_key` for `Authorization: Bearer <key>` authentication, or place
#' authentication headers in `headers`. Supplying both an API key and a custom
#' `Authorization` header is an error. All custom headers are redacted from
#' httr2 request printing.
#'
#' HTTP 429, 500, 502, 503, and 504 responses and low-level connection
#' failures are retried up to `max_retries` times. HTTP 401 and 403 responses
#' are never retried. Set `verify_tls = FALSE` only for controlled development
#' environments; doing so raises an `openlineage_insecure_tls_warning`.
#'
#' @return An R6 HTTP transport object.
#' @seealso [local_transports]
#' @export
#'
#' @examples
#' transport <- HttpTransport$new("https://example.com")
#' transport
HttpTransport <- R6Class(
  "HttpTransport",
  inherit = .OpenLineageTransport,
  public = list(
    #' @description
    #' Create an HTTP transport.
    #' @param url An absolute HTTP or HTTPS base URL.
    #' @param endpoint A relative OpenLineage endpoint path.
    #' @param api_key An optional bearer API key.
    #' @param headers Optional custom headers as a named character vector.
    #' @param timeout A positive request timeout in seconds.
    #' @param verify_tls Whether to verify TLS certificates.
    #' @param max_retries A non-negative number of retries after the first
    #'   request attempt.
    #' @returns A new `HttpTransport` object.
    initialize = function(
      url,
      endpoint = "api/v1/lineage",
      api_key = NULL,
      headers = character(),
      timeout = 5,
      verify_tls = TRUE,
      max_retries = 3L
    ) {
      caller <- parent.frame()
      api_key <- .ol_normalize_api_key(api_key, call = caller)
      headers <- .ol_normalize_http_headers(headers, call = caller)
      .ol_validate_http_number(timeout, "timeout", 0, call = caller)
      if (timeout == 0) {
        .ol_http_config_abort(
          "`timeout` must be greater than zero.",
          call = caller
        )
      }
      if (
        !is.logical(verify_tls) ||
          length(verify_tls) != 1L ||
          is.na(verify_tls)
      ) {
        .ol_http_config_abort(
          "`verify_tls` must be `TRUE` or `FALSE`.",
          call = caller
        )
      }
      .ol_validate_http_number(
        max_retries,
        "max_retries",
        0,
        integer = TRUE,
        call = caller
      )
      if (
        !is.null(api_key) &&
          any(tolower(names(headers)) == "authorization")
      ) {
        .ol_http_config_abort(
          paste0(
            "Use either `api_key` or a custom `Authorization` header, not ",
            "both."
          ),
          call = caller
        )
      }

      private$url <- .ol_normalize_http_url(url, endpoint, call = caller)
      private$credentials <- new.env(parent = emptyenv())
      private$credentials$api_key <- api_key
      private$credentials$headers <- headers
      private$timeout <- timeout
      private$verify_tls <- verify_tls
      private$max_retries <- max_retries

      if (!verify_tls) {
        .ol_http_tls_warning()
      }

      invisible(self)
    },

    #' @description
    #' Send an event to the configured OpenLineage HTTP endpoint.
    #' @param event A `RunEvent` model.
    #' @returns `event`, invisibly, after a successful HTTP response.
    emit = function(event) {
      caller <- parent.frame()
      .ol_http_validate_event(event)
      request <- private$build_request(.ol_http_serialize_event(event))
      retries <- 0L

      repeat {
        outcome <- tryCatch(
          list(response = httr2::req_perform(request, error_call = caller)),
          error = \(condition) list(condition = condition)
        )

        if (!is.null(outcome$response)) {
          response <- outcome$response
          status_code <- httr2::resp_status(response)
          if (status_code >= 200L && status_code < 300L) {
            return(invisible(event))
          }
          retryable <- status_code %in% .OPENLINEAGE_TRANSIENT_HTTP_STATUS
        } else {
          response <- NULL
          status_code <- NULL
          retryable <- inherits(outcome$condition, "httr2_failure")
        }

        if (retryable && retries < private$max_retries) {
          retries <- retries + 1L
          .ol_http_retry_sleep(.ol_http_retry_delay(response, retries))
          next
        }

        if (!is.null(status_code)) {
          .ol_http_abort(status_code, call = caller)
        }
        .ol_http_transport_abort(call = caller)
      }
    },

    #' @description
    #' Print a redacted transport summary.
    #' @param ... Unused.
    #' @returns The transport, invisibly.
    print = function(...) {
      auth <- if (!is.null(private$credentials$api_key)) {
        "bearer"
      } else if (length(private$credentials$headers) > 0L) {
        "custom headers"
      } else {
        "none"
      }
      cat(
        "<HttpTransport>\n",
        "  endpoint: ",
        private$url,
        "\n",
        "  authentication: ",
        auth,
        "\n",
        sep = ""
      )
      invisible(self)
    }
  ),
  private = list(
    url = NULL,
    credentials = NULL,
    timeout = NULL,
    verify_tls = NULL,
    max_retries = NULL,
    build_request = function(body) {
      request <- httr2::request(private$url) |>
        httr2::req_method("POST") |>
        httr2::req_timeout(private$timeout) |>
        httr2::req_body_raw(body, type = "application/json") |>
        httr2::req_error(is_error = \(response) FALSE)

      if (!private$verify_tls) {
        request <- httr2::req_options(request, ssl_verifypeer = 0)
      }
      headers <- .ol_http_request_headers(
        private$credentials$api_key,
        private$credentials$headers
      )
      if (length(headers) > 0L) {
        request <- do.call(
          httr2::req_headers,
          c(
            list(.req = request),
            as.list(headers),
            list(.redact = names(headers))
          )
        )
      }

      request
    }
  )
)
