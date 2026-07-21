.ol_string_property <- function(arg) {
  S7::new_property(
    S7::class_any,
    validator = function(value) {
      .ol_validate_scalar_character(value, arg, call = NULL)
      NULL
    }
  )
}

.ol_uuid_property <- function(arg) {
  S7::new_property(
    S7::class_any,
    validator = function(value) {
      .ol_validate_uuid(value, arg, call = NULL)
      NULL
    }
  )
}

.ol_time_property <- function(arg) {
  S7::new_property(
    S7::class_any,
    validator = function(value) {
      .ol_validate_rfc3339(value, arg, call = NULL)
      NULL
    }
  )
}

.ol_uri_property <- function(arg) {
  S7::new_property(
    S7::class_any,
    validator = function(value) {
      .ol_validate_uri(value, arg, call = NULL)
      NULL
    }
  )
}

.ol_map_property <- function(arg, facet_role = NULL) {
  S7::new_property(
    S7::class_any,
    validator = function(value) {
      if (is.null(facet_role)) {
        .ol_validate_normalized_map(value, arg, call = NULL)
      } else {
        .ol_validate_facet_map(value, facet_role, arg, call = NULL)
      }
      NULL
    }
  )
}

.ol_array_property <- function(arg) {
  S7::new_property(
    S7::class_any,
    validator = function(value) {
      .ol_normalize_array(value, arg, call = NULL)
      NULL
    }
  )
}

.ol_model_property <- function(class, arg, allow_null = FALSE) {
  S7::new_property(
    S7::class_any,
    validator = function(value) {
      if (allow_null && is.null(value)) {
        return(NULL)
      }

      if (!S7::S7_inherits(value, class)) {
        .ol_abort(
          paste0(
            "`",
            arg,
            "` must be a `",
            S7::prop(class, "name"),
            "` object."
          ),
          class = "openlineage_validation_error",
          call = NULL
        )
      }

      NULL
    }
  )
}

.ol_dataset_array <- function(x, class, arg) {
  x <- .ol_normalize_array(x, arg, call = parent.frame())
  if (is.null(x)) {
    return(NULL)
  }

  invalid <- !vapply(x, S7::S7_inherits, logical(1), class = class)
  if (any(invalid)) {
    .ol_abort(
      paste0(
        "Every element of `",
        arg,
        "` must be an `",
        S7::prop(class, "name"),
        "` object."
      ),
      class = "openlineage_validation_error",
      call = parent.frame()
    )
  }

  x
}

#' OpenLineage run state
#'
#' A validated lifecycle state for an OpenLineage run.
#'
#' @param value One of `"START"`, `"RUNNING"`, `"COMPLETE"`, `"ABORT"`,
#'   `"FAIL"`, or `"OTHER"`.
#'
#' @return A `RunState` S7 object.
#' @export
#'
#' @examples
#' RunState("START")
RunState <- S7::new_class(
  "RunState",
  package = "openlineage",
  parent = S7::class_character,
  constructor = function(value) {
    S7::new_object(value)
  },
  validator = function(self) {
    value <- S7::S7_data(self)
    .ol_validate_scalar_character(value, "value", call = NULL)
    if (
      !value %in% c("START", "RUNNING", "COMPLETE", "ABORT", "FAIL", "OTHER")
    ) {
      .ol_abort(
        paste0(
          "`value` must be one of `START`, `RUNNING`, `COMPLETE`, ",
          "`ABORT`, `FAIL`, or `OTHER`."
        ),
        class = "openlineage_validation_error",
        call = NULL
      )
    }
    NULL
  }
)

#' OpenLineage run
#'
#' Identifies one execution of an OpenLineage job.
#'
#' @param run_id A valid UUID string.
#' @param facets A named list of run facets, or `NULL` to omit the field.
#'
#' @return A `Run` S7 object.
#' @export
#'
#' @examples
#' Run(new_run_id())
Run <- S7::new_class(
  "Run",
  package = "openlineage",
  properties = list(
    run_id = .ol_uuid_property("run_id"),
    facets = .ol_map_property("facets", "run")
  ),
  constructor = function(run_id, facets = list()) {
    S7::new_object(
      S7::S7_object(),
      run_id = run_id,
      facets = .ol_normalize_facet_map(
        facets,
        "run",
        "facets",
        call = parent.frame()
      )
    )
  }
)

#' OpenLineage job
#'
#' Identifies a job within a producer-defined namespace.
#'
#' @param namespace A non-empty namespace string.
#' @param name A non-empty job name.
#' @param facets A named list of job facets, or `NULL` to omit the field.
#'
#' @return A `Job` S7 object.
#' @export
#'
#' @examples
#' Job("example-scheduler", "daily-report")
Job <- S7::new_class(
  "Job",
  package = "openlineage",
  properties = list(
    namespace = .ol_string_property("namespace"),
    name = .ol_string_property("name"),
    facets = .ol_map_property("facets", "job")
  ),
  constructor = function(namespace, name, facets = list()) {
    S7::new_object(
      S7::S7_object(),
      namespace = namespace,
      name = name,
      facets = .ol_normalize_facet_map(
        facets,
        "job",
        "facets",
        call = parent.frame()
      )
    )
  }
)

#' OpenLineage datasets
#'
#' `Dataset` identifies a dataset. `InputDataset` and `OutputDataset` add
#' lifecycle-specific facet maps and are the only dataset types accepted by a
#' `RunEvent`.
#'
#' @param namespace A non-empty namespace string.
#' @param name A non-empty dataset name.
#' @param facets A named list of dataset facets, or `NULL` to omit the field.
#' @param input_facets A named list of input facets, or `NULL` to omit it.
#' @param output_facets A named list of output facets, or `NULL` to omit it.
#'
#' @return A `Dataset`, `InputDataset`, or `OutputDataset` S7 object.
#' @name datasets
#'
#' @examples
#' Dataset("postgres://warehouse", "analytics.orders")
#' InputDataset("postgres://warehouse", "raw.orders")
#' OutputDataset("postgres://warehouse", "analytics.orders")
NULL

#' @rdname datasets
#' @export
Dataset <- S7::new_class(
  "Dataset",
  package = "openlineage",
  properties = list(
    namespace = .ol_string_property("namespace"),
    name = .ol_string_property("name"),
    facets = .ol_map_property("facets", "dataset")
  ),
  constructor = function(namespace, name, facets = list()) {
    S7::new_object(
      S7::S7_object(),
      namespace = namespace,
      name = name,
      facets = .ol_normalize_facet_map(
        facets,
        "dataset",
        "facets",
        call = parent.frame()
      )
    )
  }
)

#' @rdname datasets
#' @export
InputDataset <- S7::new_class(
  "InputDataset",
  package = "openlineage",
  parent = Dataset,
  properties = list(
    input_facets = .ol_map_property("input_facets", "input")
  ),
  constructor = function(
    namespace,
    name,
    facets = list(),
    input_facets = list()
  ) {
    S7::new_object(
      Dataset(namespace, name, facets),
      input_facets = .ol_normalize_facet_map(
        input_facets,
        "input",
        "input_facets",
        call = parent.frame()
      )
    )
  }
)

#' @rdname datasets
#' @export
OutputDataset <- S7::new_class(
  "OutputDataset",
  package = "openlineage",
  parent = Dataset,
  properties = list(
    output_facets = .ol_map_property("output_facets", "output")
  ),
  constructor = function(
    namespace,
    name,
    facets = list(),
    output_facets = list()
  ) {
    S7::new_object(
      Dataset(namespace, name, facets),
      output_facets = .ol_normalize_facet_map(
        output_facets,
        "output",
        "output_facets",
        call = parent.frame()
      )
    )
  }
)

.ol_event_type_property <- S7::new_property(
  S7::class_any,
  validator = function(value) {
    if (!is.null(value) && !S7::S7_inherits(value, RunState)) {
      .ol_abort(
        "`event_type` must be a `RunState` object or `NULL`.",
        class = "openlineage_validation_error",
        call = NULL
      )
    }
    NULL
  }
)

#' OpenLineage run event
#'
#' Describes a lifecycle transition for one job run and its input and output
#' datasets.
#'
#' @param run A `Run` object.
#' @param job A `Job` object.
#' @param event_type A `RunState`, a valid state string, or `NULL` to omit it.
#' @param event_time An RFC 3339 date-time string with a time-zone offset.
#' @param inputs An unnamed list of `InputDataset` objects, or `NULL`.
#' @param outputs An unnamed list of `OutputDataset` objects, or `NULL`.
#' @param producer A URI identifying the event producer.
#' @param schema_url The RunEvent JSON Schema URL.
#'
#' @return A `RunEvent` S7 object.
#' @export
#'
#' @examples
#' run <- Run(new_run_id())
#' job <- Job("example-scheduler", "daily-report")
#' RunEvent(
#'   run,
#'   job,
#'   event_type = "START",
#'   event_time = new_event_time(as.POSIXct("2026-01-02", tz = "UTC"))
#' )
RunEvent <- S7::new_class(
  "RunEvent",
  package = "openlineage",
  properties = list(
    run = .ol_model_property(Run, "run"),
    job = .ol_model_property(Job, "job"),
    event_type = .ol_event_type_property,
    event_time = .ol_time_property("event_time"),
    inputs = .ol_array_property("inputs"),
    outputs = .ol_array_property("outputs"),
    producer = .ol_uri_property("producer"),
    schema_url = .ol_uri_property("schema_url")
  ),
  constructor = function(
    run,
    job,
    event_type = NULL,
    event_time = new_event_time(),
    inputs = list(),
    outputs = list(),
    producer = OPENLINEAGE_PRODUCER,
    schema_url = OPENLINEAGE_RUN_EVENT_SCHEMA_URL
  ) {
    if (is.character(event_type)) {
      event_type <- RunState(event_type)
    }

    S7::new_object(
      S7::S7_object(),
      run = run,
      job = job,
      event_type = event_type,
      event_time = event_time,
      inputs = .ol_dataset_array(inputs, InputDataset, "inputs"),
      outputs = .ol_dataset_array(outputs, OutputDataset, "outputs"),
      producer = producer,
      schema_url = schema_url
    )
  }
)
