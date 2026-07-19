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

  c(base, .ol_mapped_properties(x, mapping))
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

  if (!is.atomic(x) || anyNA(x)) {
    .ol_abort(
      "OpenLineage values must not contain unsupported objects or missing values.",
      class = "openlineage_validation_error",
      call = call
    )
  }

  x
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
    as_openlineage_list(x),
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA,
    pretty = pretty
  ))
}
