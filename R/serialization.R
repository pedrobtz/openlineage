.ol_model_fields <- function(x, call = parent.frame()) {
  if (S7::S7_inherits(x, RunEvent)) {
    return(list(
      eventTime = S7::prop(x, "event_time"),
      eventType = S7::prop(x, "event_type"),
      inputs = S7::prop(x, "inputs"),
      job = S7::prop(x, "job"),
      outputs = S7::prop(x, "outputs"),
      producer = S7::prop(x, "producer"),
      run = S7::prop(x, "run"),
      schemaURL = S7::prop(x, "schema_url")
    ))
  }

  if (S7::S7_inherits(x, InputDataset)) {
    return(list(
      facets = S7::prop(x, "facets"),
      inputFacets = S7::prop(x, "input_facets"),
      name = S7::prop(x, "name"),
      namespace = S7::prop(x, "namespace")
    ))
  }

  if (S7::S7_inherits(x, OutputDataset)) {
    return(list(
      facets = S7::prop(x, "facets"),
      name = S7::prop(x, "name"),
      namespace = S7::prop(x, "namespace"),
      outputFacets = S7::prop(x, "output_facets")
    ))
  }

  if (S7::S7_inherits(x, Dataset)) {
    return(list(
      facets = S7::prop(x, "facets"),
      name = S7::prop(x, "name"),
      namespace = S7::prop(x, "namespace")
    ))
  }

  if (S7::S7_inherits(x, Job)) {
    return(list(
      facets = S7::prop(x, "facets"),
      name = S7::prop(x, "name"),
      namespace = S7::prop(x, "namespace")
    ))
  }

  if (S7::S7_inherits(x, Run)) {
    return(list(
      facets = S7::prop(x, "facets"),
      runId = S7::prop(x, "run_id")
    ))
  }

  if (S7::S7_inherits(x, .OpenLineageFacet)) {
    return(.ol_facet_fields(x, call = call))
  }

  record <- .ol_record_fields(x)
  if (!is.null(record)) {
    return(record)
  }

  .ol_abort(
    paste0(
      "Objects of class `",
      paste(class(x), collapse = "/"),
      "` cannot be serialized as OpenLineage."
    ),
    class = "openlineage_validation_error",
    call = call
  )
}

.ol_mapped_properties <- function(x, mapping) {
  values <- lapply(names(mapping), \(property) S7::prop(x, property))
  stats::setNames(values, unname(mapping))
}

.ol_facet_fields <- function(x, call = parent.frame()) {
  base <- list(
    `_producer` = S7::prop(x, "producer"),
    `_schemaURL` = S7::prop(x, "schema_url"),
    `_deleted` = S7::prop(x, "deleted")
  )

  if (S7::S7_inherits(x, .GenericFacet)) {
    fields <- S7::prop(x, "fields")
    return(c(base, fields))
  }

  class_name <- S7::prop(S7::S7_class(x), "name")
  mapping <- .ol_facet_wire_maps[[class_name]]
  if (is.null(mapping)) {
    .ol_abort(
      paste0("No wire mapping is registered for facet `", class_name, "`."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  fields <- .ol_mapped_properties(x, mapping)
  converters <- .ol_facet_wire_values[[class_name]]
  for (wire_name in names(converters)) {
    if (!is.null(fields[[wire_name]])) {
      fields[[wire_name]] <- converters[[wire_name]](fields[[wire_name]])
    }
  }

  c(base, fields)
}

.ol_record_fields <- function(x) {
  class_name <- S7::prop(S7::S7_class(x), "name")
  mapping <- .ol_record_wire_maps[[class_name]]
  if (is.null(mapping)) {
    return(NULL)
  }

  .ol_mapped_properties(x, mapping)
}

.ol_to_wire <- function(x, call = parent.frame()) {
  if (is.null(x)) {
    return(NULL)
  }

  if (S7::S7_inherits(x, RunState)) {
    return(S7::S7_data(x))
  }

  if (S7::S7_inherits(x, S7::S7_object)) {
    return(.ol_to_wire(.ol_model_fields(x, call = call), call = call))
  }

  if (is.data.frame(x)) {
    .ol_abort(
      "Data frames cannot be serialized as OpenLineage values.",
      class = "openlineage_validation_error",
      call = call
    )
  }

  if (is.list(x)) {
    object <- !is.null(names(x))
    if (object) {
      .ol_validate_wire_names(names(x), call = call)
    }
    converted <- lapply(x, .ol_to_wire, call = call)
    keep <- !vapply(converted, is.null, logical(1))
    converted <- converted[keep]

    if (object) {
      names(converted) <- names(x)[keep]
    } else {
      names(converted) <- NULL
    }

    return(converted)
  }

  .ol_atomic_to_wire(x, call = call)
}

.ol_wire_abort <- function(problem, call) {
  .ol_abort(
    paste0("OpenLineage values must not contain ", problem, "."),
    class = "openlineage_validation_error",
    call = call
  )
}

.ol_validate_wire_names <- function(x, call) {
  if (anyNA(x) || !all(nzchar(x))) {
    .ol_wire_abort("lists with missing or empty names", call)
  }
  if (anyDuplicated(x)) {
    .ol_wire_abort("lists with repeated names", call)
  }
  if (!all(validUTF8(enc2utf8(x)))) {
    .ol_wire_abort("names that are not valid UTF-8", call)
  }

  invisible(x)
}

# Converts an atomic vector to the value jsonlite writes, or rejects it when
# jsonlite would change it silently: `Inf` becoming `null`, names dropped,
# POSIXct written without `T` or an offset.
.ol_atomic_to_wire <- function(x, call) {
  if (!is.atomic(x) || is.complex(x) || is.raw(x)) {
    .ol_wire_abort("unsupported objects", call)
  }
  if (anyNA(x)) {
    .ol_wire_abort("missing values", call)
  }
  if (!is.null(names(x))) {
    .ol_wire_abort("named atomic vectors", call)
  }

  as_is <- inherits(x, "AsIs")
  if (inherits(x, "POSIXt")) {
    x <- as.POSIXct(x)
    x <- vapply(
      seq_along(x),
      \(i) .ol_event_time(x[i], "value", call = call),
      character(1)
    )
  } else if (inherits(x, "Date")) {
    x <- format(x, "%Y-%m-%d")
  } else if (is.factor(x)) {
    x <- as.character(x)
  } else if (length(setdiff(oldClass(x), "AsIs")) > 0L) {
    .ol_wire_abort(
      paste0("objects of class `", class(x)[[1L]], "`"),
      call
    )
  }

  if (is.double(x) && !all(is.finite(x))) {
    .ol_wire_abort("infinite numbers", call)
  }
  if (is.character(x)) {
    x <- enc2utf8(x)
    if (!all(validUTF8(x))) {
      .ol_wire_abort("text that is not valid UTF-8", call)
    }
  }

  if (as_is) I(x) else x
}

# Doubles are written as text before jsonlite sees them: integer-valued
# doubles up to 2^53 exactly, others with the fewest significant digits (15
# to 17) that read back as the same double, as Python's `repr()` does. The
# read-back uses jsonlite's parser (C `strtod()`), as consumers do; R's own
# `as.numeric()` is not correctly rounded for every input.
.ol_format_double <- function(x) {
  text <- character(length(x))
  exact <- x == trunc(x) & abs(x) <= 2^53
  text[exact] <- sprintf("%.0f", x[exact])

  pending <- which(!exact)
  for (digits in 15:17) {
    if (length(pending) == 0L) {
      break
    }
    candidate <- sprintf(paste0("%.", digits, "g"), x[pending])
    # 17 significant digits always identify a double.
    same <- if (digits == 17L) {
      rep(TRUE, length(pending))
    } else {
      jsonlite::parse_json(
        paste0("[", paste(candidate, collapse = ","), "]"),
        simplifyVector = TRUE
      ) ==
        x[pending]
    }
    text[pending[same]] <- candidate[same]
    pending <- pending[!same]
  }

  text
}

.ol_json_numbers <- function(x) {
  if (is.list(x)) {
    converted <- lapply(x, .ol_json_numbers)
    names(converted) <- names(x)
    return(converted)
  }
  if (!is.double(x)) {
    return(x)
  }

  text <- .ol_format_double(unclass(x))
  if (length(x) != 1L || inherits(x, "AsIs")) {
    text <- paste0("[", paste(text, collapse = ","), "]")
  }
  structure(text, class = "json")
}

#' Convert an OpenLineage value to its wire representation
#'
#' Recursively converts OpenLineage S7 models to named R lists. Protocol field
#' names are applied here, `RunState` values are unwrapped, and `NULL`
#' properties are omitted. Object key order is deterministic; array order is
#' preserved.
#'
#' @param x An OpenLineage model or supported nested value.
#'
#' @return A named list for a model, or the corresponding wire value for a
#'   nested value.
#' @export
#'
#' @examples
#' run <- Run("019c0000-0000-7000-8000-000000000001")
#' as_openlineage_list(run)
as_openlineage_list <- function(x) {
  .ol_to_wire(x, call = sys.call())
}

#' Serialize an OpenLineage value to JSON
#'
#' @param x An OpenLineage model or supported nested value.
#' @param pretty Whether to add indentation and line breaks.
#'
#' @return A single JSON string.
#' @export
#'
#' @examples
#' event <- RunEvent(
#'   Run("019c0000-0000-7000-8000-000000000001"),
#'   Job("example", "task"),
#'   event_type = "START",
#'   event_time = "2026-01-02T03:04:05.000Z"
#' )
#' to_openlineage_json(event)
to_openlineage_json <- function(x, pretty = FALSE) {
  .ol_validate_flag(pretty, "pretty", call = parent.frame())

  as.character(jsonlite::toJSON(
    .ol_json_numbers(as_openlineage_list(x)),
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    json_verbatim = TRUE,
    pretty = pretty
  ))
}
