.ol_optional_string_property <- function(arg, uri = FALSE, time = FALSE) {
  S7::new_property(
    S7::class_any,
    validator = function(value) {
      if (is.null(value)) {
        return(NULL)
      }

      if (uri) {
        .ol_validate_uri(value, arg, call = NULL)
      } else if (time) {
        .ol_validate_rfc3339(value, arg, call = NULL)
      } else {
        .ol_validate_scalar_character(value, arg, call = NULL)
      }
      NULL
    }
  )
}

.ol_optional_flag_property <- function(arg) {
  S7::new_property(
    S7::class_any,
    validator = function(value) {
      if (!is.null(value)) {
        .ol_validate_flag(value, arg, call = NULL)
      }
      NULL
    }
  )
}

.ol_validate_integerish <- function(
  x,
  arg,
  allow_null = TRUE,
  minimum = NULL,
  call = parent.frame()
) {
  if (allow_null && is.null(x)) {
    return(invisible(x))
  }

  valid <- is.numeric(x) &&
    length(x) == 1L &&
    !is.na(x) &&
    is.finite(x) &&
    x == floor(x)
  if (valid && !is.null(minimum)) {
    valid <- x >= minimum
  }

  if (!valid) {
    detail <- if (is.null(minimum)) {
      "an integer-like number or `NULL`"
    } else {
      paste0("an integer-like number greater than or equal to ", minimum)
    }
    .ol_abort(
      paste0("`", arg, "` must be ", detail, "."),
      class = "openlineage_validation_error",
      call = call
    )
  }

  invisible(x)
}

.ol_optional_integer_property <- function(arg, minimum = NULL) {
  S7::new_property(
    S7::class_any,
    validator = function(value) {
      .ol_validate_integerish(
        value,
        arg,
        minimum = minimum,
        call = NULL
      )
      NULL
    }
  )
}

.ol_record_array <- function(x, class, arg, call = parent.frame()) {
  x <- .ol_normalize_array(x, arg, call = call)
  if (is.null(x)) {
    return(NULL)
  }

  invalid <- !vapply(x, S7::S7_inherits, logical(1), class = class)
  if (any(invalid)) {
    .ol_abort(
      paste0(
        "Every element of `",
        arg,
        "` must be a `",
        S7::prop(class, "name"),
        "` object."
      ),
      class = "openlineage_validation_error",
      call = call
    )
  }

  x
}

.ol_record_array_property <- function(class, arg) {
  S7::new_property(
    S7::class_any,
    validator = function(value) {
      .ol_record_array(value, class, arg, call = NULL)
      NULL
    }
  )
}

.ol_schema_fields_property <- S7::new_property(
  S7::class_any,
  validator = function(value) {
    .ol_record_array(value, SchemaField, "fields", call = NULL)
    NULL
  }
)

.ol_tags_property <- S7::new_property(
  S7::class_any,
  validator = function(value) {
    .ol_record_array(value, .OpenLineageTag, "tags", call = NULL)
    NULL
  }
)

.ol_root_property <- S7::new_property(
  S7::class_any,
  validator = function(value) {
    .ol_normalize_parent_root(value, call = NULL)
    NULL
  }
)

.OpenLineageFacet <- S7::new_class(
  "OpenLineageFacet",
  package = "openlineage",
  properties = list(
    producer = .ol_uri_property("producer"),
    schema_url = .ol_uri_property("schema_url"),
    deleted = .ol_optional_flag_property("deleted")
  ),
  constructor = function(producer, schema_url, deleted = NULL) {
    S7::new_object(
      S7::S7_object(),
      producer = producer,
      schema_url = schema_url,
      deleted = deleted
    )
  }
)

.RunFacet <- S7::new_class(
  "RunFacet",
  package = "openlineage",
  parent = .OpenLineageFacet,
  constructor = function(producer, schema_url) {
    S7::new_object(.OpenLineageFacet(producer, schema_url))
  }
)

.JobFacet <- S7::new_class(
  "JobFacet",
  package = "openlineage",
  parent = .OpenLineageFacet,
  constructor = function(producer, schema_url, deleted = NULL) {
    S7::new_object(.OpenLineageFacet(producer, schema_url, deleted))
  }
)

.DatasetFacet <- S7::new_class(
  "DatasetFacet",
  package = "openlineage",
  parent = .OpenLineageFacet,
  constructor = function(producer, schema_url, deleted = NULL) {
    S7::new_object(.OpenLineageFacet(producer, schema_url, deleted))
  }
)

.InputDatasetFacet <- S7::new_class(
  "InputDatasetFacet",
  package = "openlineage",
  parent = .OpenLineageFacet,
  constructor = function(producer, schema_url) {
    S7::new_object(.OpenLineageFacet(producer, schema_url))
  }
)

.OutputDatasetFacet <- S7::new_class(
  "OutputDatasetFacet",
  package = "openlineage",
  parent = .OpenLineageFacet,
  constructor = function(producer, schema_url) {
    S7::new_object(.OpenLineageFacet(producer, schema_url))
  }
)

.GenericFacet <- S7::new_class(
  "GenericFacet",
  package = "openlineage",
  parent = .OpenLineageFacet,
  properties = list(fields = .ol_map_property("fields")),
  constructor = function(
    schema_url,
    fields,
    producer = OPENLINEAGE_PRODUCER,
    deleted = NULL
  ) {
    S7::new_object(
      .OpenLineageFacet(producer, schema_url, deleted),
      fields = .ol_normalize_map(fields, "fields", call = parent.frame())
    )
  }
)

.ol_facet_role_class <- function(role) {
  switch(
    role,
    run = .RunFacet,
    job = .JobFacet,
    dataset = .DatasetFacet,
    input = .InputDatasetFacet,
    output = .OutputDatasetFacet,
    .ol_abort(
      paste0("Unknown internal facet role `", role, "`."),
      class = "openlineage_error",
      call = parent.frame()
    )
  )
}

.ol_normalize_facet_map <- function(
  x,
  role,
  arg,
  call = parent.frame()
) {
  x <- .ol_normalize_map(x, arg, call = call)
  if (is.null(x) || length(x) == 0L) {
    return(x)
  }

  role_class <- .ol_facet_role_class(role)
  valid <- vapply(
    x,
    function(value) {
      S7::S7_inherits(value, role_class) ||
        S7::S7_inherits(value, .GenericFacet)
    },
    logical(1)
  )
  if (any(!valid)) {
    .ol_abort(
      paste0(
        "Every element of `",
        arg,
        "` must be a compatible ",
        role,
        " facet created by a typed constructor or `ol_facet()`."
      ),
      class = "openlineage_validation_error",
      call = call
    )
  }

  x
}

.ol_validate_facet_map <- function(
  x,
  role,
  arg,
  call = parent.frame()
) {
  normalized <- .ol_normalize_facet_map(x, role, arg, call = call)
  if (!identical(x, normalized)) {
    .ol_abort(
      paste0("`", arg, "` must be a named facet list or `NULL`."),
      class = "openlineage_validation_error",
      call = call
    )
  }
  invisible(x)
}

#' Create a generic OpenLineage facet
#'
#' Creates a facet for extensions or facet schemas without a typed constructor.
#' Names supplied through `...` are preserved exactly at the JSON boundary.
#'
#' @param schema_url The URI of the facet's JSON Schema definition.
#' @param ... Named facet fields using their OpenLineage wire names.
#' @param producer A URI identifying the facet producer.
#' @param deleted Whether this facet deletes a previously emitted job or
#'   dataset facet. Use only where the target schema supports `_deleted`.
#'
#' @return A generic OpenLineage facet accepted in any facet map.
#' @export
#'
#' @examples
#' facet <- ol_facet(
#'   "https://example.com/CustomRunFacet.json",
#'   customValue = "example"
#' )
#' Run(new_run_id(), facets = list(custom = facet))
ol_facet <- function(
  schema_url,
  ...,
  producer = OPENLINEAGE_PRODUCER,
  deleted = NULL
) {
  fields <- .ol_normalize_map(list(...), "...", call = parent.frame())
  reserved <- intersect(names(fields), c("_producer", "_schemaURL", "_deleted"))
  if (length(reserved) > 0L) {
    .ol_abort(
      paste0(
        "Reserved facet field",
        if (length(reserved) == 1L) "" else "s",
        " must be supplied through `producer`, `schema_url`, or `deleted`: ",
        paste0("`", reserved, "`", collapse = ", "),
        "."
      ),
      class = "openlineage_validation_error",
      call = parent.frame()
    )
  }

  .GenericFacet(schema_url, fields, producer, deleted)
}

.SCHEMA_NOMINAL_TIME <- paste0(
  "https://openlineage.io/spec/facets/1-0-1/",
  "NominalTimeRunFacet.json#/$defs/NominalTimeRunFacet"
)
.SCHEMA_PARENT_RUN <- paste0(
  "https://openlineage.io/spec/facets/1-2-0/",
  "ParentRunFacet.json#/$defs/ParentRunFacet"
)
.SCHEMA_ERROR_MESSAGE <- paste0(
  "https://openlineage.io/spec/facets/1-0-1/",
  "ErrorMessageRunFacet.json#/$defs/ErrorMessageRunFacet"
)
.SCHEMA_PROCESSING_ENGINE <- paste0(
  "https://openlineage.io/spec/facets/1-1-1/",
  "ProcessingEngineRunFacet.json#/$defs/ProcessingEngineRunFacet"
)
.SCHEMA_SCHEMA_DATASET <- paste0(
  "https://openlineage.io/spec/facets/1-2-0/",
  "SchemaDatasetFacet.json#/$defs/SchemaDatasetFacet"
)
.SCHEMA_DATASOURCE <- paste0(
  "https://openlineage.io/spec/facets/1-0-1/",
  "DatasourceDatasetFacet.json#/$defs/DatasourceDatasetFacet"
)
.SCHEMA_SQL_JOB <- paste0(
  "https://openlineage.io/spec/facets/1-1-0/",
  "SQLJobFacet.json#/$defs/SQLJobFacet"
)
.SCHEMA_SOURCE_LOCATION <- paste0(
  "https://openlineage.io/spec/facets/1-1-0/",
  "SourceCodeLocationJobFacet.json#/$defs/SourceCodeLocationJobFacet"
)
.SCHEMA_INPUT_STATISTICS <- paste0(
  "https://openlineage.io/spec/facets/1-0-0/",
  "InputStatisticsInputDatasetFacet.json",
  "#/$defs/InputStatisticsInputDatasetFacet"
)
.SCHEMA_OUTPUT_STATISTICS <- paste0(
  "https://openlineage.io/spec/facets/1-0-2/",
  "OutputStatisticsOutputDatasetFacet.json",
  "#/$defs/OutputStatisticsOutputDatasetFacet"
)
.SCHEMA_JOB_TYPE <- paste0(
  "https://openlineage.io/spec/facets/2-0-4/",
  "JobTypeJobFacet.json#/$defs/JobTypeJobFacet"
)
.SCHEMA_TAGS_JOB <- paste0(
  "https://openlineage.io/spec/facets/1-0-0/",
  "TagsJobFacet.json#/$defs/TagsJobFacet"
)
.SCHEMA_TAGS_RUN <- paste0(
  "https://openlineage.io/spec/facets/1-0-0/",
  "TagsRunFacet.json#/$defs/TagsRunFacet"
)
.SCHEMA_TAGS_DATASET <- paste0(
  "https://openlineage.io/spec/facets/1-0-0/",
  "TagsDatasetFacet.json#/$defs/TagsDatasetFacet"
)

.ol_normalize_parent_root <- function(value, call = parent.frame()) {
  if (is.null(value)) {
    return(NULL)
  }

  valid_names <- is.list(value) &&
    identical(sort(names(value)), c("job", "run"))
  if (
    !valid_names ||
      !S7::S7_inherits(value$run, Run) ||
      !S7::S7_inherits(value$job, Job)
  ) {
    .ol_abort(
      paste0(
        "`root` must be `NULL` or `list(run = Run(...), job = Job(...))`."
      ),
      class = "openlineage_validation_error",
      call = call
    )
  }

  list(run = value$run, job = value$job)
}

#' Typed run facets
#'
#' Constructors for commonly used OpenLineage run facets.
#'
#' @param nominal_start_time The nominal start as an RFC 3339 date-time.
#' @param nominal_end_time An optional nominal end date-time.
#' @param run The parent `Run`.
#' @param job The parent `Job`.
#' @param root Optional `list(run = Run(...), job = Job(...))` for the root.
#' @param message A human-readable error message.
#' @param programming_language The language that produced the error.
#' @param stack_trace An optional stack trace.
#' @param version The processing engine version.
#' @param name The optional processing engine name.
#' @param openlineage_adapter_version The optional adapter version.
#' @param producer A URI identifying the facet producer.
#'
#' @return A typed run facet S7 object.
#' @name run_facets
NULL

#' @rdname run_facets
#' @export
NominalTimeRunFacet <- S7::new_class(
  "NominalTimeRunFacet",
  package = "openlineage",
  parent = .RunFacet,
  properties = list(
    nominal_start_time = .ol_time_property("nominal_start_time"),
    nominal_end_time = .ol_optional_string_property(
      "nominal_end_time",
      time = TRUE
    )
  ),
  constructor = function(
    nominal_start_time,
    nominal_end_time = NULL,
    producer = OPENLINEAGE_PRODUCER
  ) {
    S7::new_object(
      .RunFacet(producer, .SCHEMA_NOMINAL_TIME),
      nominal_start_time = nominal_start_time,
      nominal_end_time = nominal_end_time
    )
  }
)

#' @rdname run_facets
#' @export
ParentRunFacet <- S7::new_class(
  "ParentRunFacet",
  package = "openlineage",
  parent = .RunFacet,
  properties = list(
    run = .ol_model_property(Run, "run"),
    job = .ol_model_property(Job, "job"),
    root = .ol_root_property
  ),
  constructor = function(
    run,
    job,
    root = NULL,
    producer = OPENLINEAGE_PRODUCER
  ) {
    S7::new_object(
      .RunFacet(producer, .SCHEMA_PARENT_RUN),
      run = run,
      job = job,
      root = .ol_normalize_parent_root(root, call = parent.frame())
    )
  }
)

#' @rdname run_facets
#' @export
ErrorMessageRunFacet <- S7::new_class(
  "ErrorMessageRunFacet",
  package = "openlineage",
  parent = .RunFacet,
  properties = list(
    message = .ol_string_property("message"),
    programming_language = .ol_string_property("programming_language"),
    stack_trace = .ol_optional_string_property("stack_trace")
  ),
  constructor = function(
    message,
    programming_language,
    stack_trace = NULL,
    producer = OPENLINEAGE_PRODUCER
  ) {
    S7::new_object(
      .RunFacet(producer, .SCHEMA_ERROR_MESSAGE),
      message = message,
      programming_language = programming_language,
      stack_trace = stack_trace
    )
  }
)

#' @rdname run_facets
#' @export
ProcessingEngineRunFacet <- S7::new_class(
  "ProcessingEngineRunFacet",
  package = "openlineage",
  parent = .RunFacet,
  properties = list(
    version = .ol_string_property("version"),
    name = .ol_optional_string_property("name"),
    openlineage_adapter_version = .ol_optional_string_property(
      "openlineage_adapter_version"
    )
  ),
  constructor = function(
    version,
    name = NULL,
    openlineage_adapter_version = NULL,
    producer = OPENLINEAGE_PRODUCER
  ) {
    S7::new_object(
      .RunFacet(producer, .SCHEMA_PROCESSING_ENGINE),
      version = version,
      name = name,
      openlineage_adapter_version = openlineage_adapter_version
    )
  }
)

#' Typed dataset facets
#'
#' Constructors for dataset-level schema, data-source, and tag metadata.
#'
#' @param fields For `SchemaDatasetFacet`, an unnamed list of `SchemaField`
#'   objects. For `SchemaField`, nested fields of the same type.
#' @param name A field or data-source name.
#' @param type An optional field type.
#' @param description An optional field description.
#' @param ordinal_position An optional one-based field position.
#' @param uri An optional data-source URI.
#' @param producer A URI identifying the facet producer.
#' @param deleted Whether this facet deletes a previously emitted facet.
#'
#' @return A typed dataset facet or schema-field S7 object.
#' @name dataset_facets
NULL

#' @rdname dataset_facets
#' @export
SchemaField <- S7::new_class(
  "SchemaField",
  package = "openlineage",
  properties = list(
    name = .ol_string_property("name"),
    type = .ol_optional_string_property("type"),
    description = .ol_optional_string_property("description"),
    ordinal_position = .ol_optional_integer_property(
      "ordinal_position",
      minimum = 1
    ),
    fields = .ol_schema_fields_property
  ),
  constructor = function(
    name,
    type = NULL,
    description = NULL,
    ordinal_position = NULL,
    fields = list()
  ) {
    S7::new_object(
      S7::S7_object(),
      name = name,
      type = type,
      description = description,
      ordinal_position = ordinal_position,
      fields = .ol_record_array(
        fields,
        SchemaField,
        "fields",
        call = parent.frame()
      )
    )
  }
)

#' @rdname dataset_facets
#' @export
SchemaDatasetFacet <- S7::new_class(
  "SchemaDatasetFacet",
  package = "openlineage",
  parent = .DatasetFacet,
  properties = list(fields = .ol_record_array_property(SchemaField, "fields")),
  constructor = function(
    fields = list(),
    producer = OPENLINEAGE_PRODUCER,
    deleted = NULL
  ) {
    S7::new_object(
      .DatasetFacet(producer, .SCHEMA_SCHEMA_DATASET, deleted),
      fields = .ol_record_array(
        fields,
        SchemaField,
        "fields",
        call = parent.frame()
      )
    )
  }
)

#' @rdname dataset_facets
#' @export
DatasourceDatasetFacet <- S7::new_class(
  "DatasourceDatasetFacet",
  package = "openlineage",
  parent = .DatasetFacet,
  properties = list(
    name = .ol_optional_string_property("name"),
    uri = .ol_optional_string_property("uri", uri = TRUE)
  ),
  constructor = function(
    name = NULL,
    uri = NULL,
    producer = OPENLINEAGE_PRODUCER,
    deleted = NULL
  ) {
    S7::new_object(
      .DatasetFacet(producer, .SCHEMA_DATASOURCE, deleted),
      name = name,
      uri = uri
    )
  }
)

#' Typed job facets
#'
#' Constructors for SQL, source location, and job-type metadata.
#'
#' @param query The SQL query text.
#' @param dialect An optional SQL dialect.
#' @param type The source-control system type.
#' @param url The full source-code URL.
#' @param repo_url,path,version,tag,branch,pull_request_number Optional source
#'   location details.
#' @param processing_type The processing type, such as `"BATCH"`.
#' @param integration The integration name, such as `"DBT"`.
#' @param job_type An optional integration-specific job type.
#' @param emission_pattern An optional `EmissionPattern`.
#' @param event_trigger When events are emitted.
#' @param event_content_mode Whether events accumulate or contain snapshots.
#' @param window_duration An optional positive duration in seconds.
#' @param producer A URI identifying the facet producer.
#' @param deleted Whether this facet deletes a previously emitted facet.
#'
#' @return A typed job facet or emission-pattern S7 object.
#' @name job_facets
NULL

#' @rdname job_facets
#' @export
SQLJobFacet <- S7::new_class(
  "SQLJobFacet",
  package = "openlineage",
  parent = .JobFacet,
  properties = list(
    query = .ol_string_property("query"),
    dialect = .ol_optional_string_property("dialect")
  ),
  constructor = function(
    query,
    dialect = NULL,
    producer = OPENLINEAGE_PRODUCER,
    deleted = NULL
  ) {
    S7::new_object(
      .JobFacet(producer, .SCHEMA_SQL_JOB, deleted),
      query = query,
      dialect = dialect
    )
  }
)

#' @rdname job_facets
#' @export
SourceCodeLocationJobFacet <- S7::new_class(
  "SourceCodeLocationJobFacet",
  package = "openlineage",
  parent = .JobFacet,
  properties = list(
    type = .ol_string_property("type"),
    url = .ol_uri_property("url"),
    repo_url = .ol_optional_string_property("repo_url"),
    path = .ol_optional_string_property("path"),
    version = .ol_optional_string_property("version"),
    tag = .ol_optional_string_property("tag"),
    branch = .ol_optional_string_property("branch"),
    pull_request_number = .ol_optional_string_property(
      "pull_request_number"
    )
  ),
  constructor = function(
    type,
    url,
    repo_url = NULL,
    path = NULL,
    version = NULL,
    tag = NULL,
    branch = NULL,
    pull_request_number = NULL,
    producer = OPENLINEAGE_PRODUCER,
    deleted = NULL
  ) {
    S7::new_object(
      .JobFacet(producer, .SCHEMA_SOURCE_LOCATION, deleted),
      type = type,
      url = url,
      repo_url = repo_url,
      path = path,
      version = version,
      tag = tag,
      branch = branch,
      pull_request_number = pull_request_number
    )
  }
)

#' @rdname job_facets
#' @export
EmissionPattern <- S7::new_class(
  "EmissionPattern",
  package = "openlineage",
  properties = list(
    event_trigger = .ol_string_property("event_trigger"),
    event_content_mode = .ol_string_property("event_content_mode"),
    window_duration = .ol_optional_integer_property(
      "window_duration",
      minimum = 1
    )
  ),
  constructor = function(
    event_trigger,
    event_content_mode,
    window_duration = NULL
  ) {
    S7::new_object(
      S7::S7_object(),
      event_trigger = event_trigger,
      event_content_mode = event_content_mode,
      window_duration = window_duration
    )
  }
)

#' @rdname job_facets
#' @export
JobTypeJobFacet <- S7::new_class(
  "JobTypeJobFacet",
  package = "openlineage",
  parent = .JobFacet,
  properties = list(
    processing_type = .ol_string_property("processing_type"),
    integration = .ol_string_property("integration"),
    job_type = .ol_optional_string_property("job_type"),
    emission_pattern = .ol_model_property(
      EmissionPattern,
      "emission_pattern",
      allow_null = TRUE
    )
  ),
  constructor = function(
    processing_type,
    integration,
    job_type = NULL,
    emission_pattern = NULL,
    producer = OPENLINEAGE_PRODUCER,
    deleted = NULL
  ) {
    S7::new_object(
      .JobFacet(producer, .SCHEMA_JOB_TYPE, deleted),
      processing_type = processing_type,
      integration = integration,
      job_type = job_type,
      emission_pattern = emission_pattern
    )
  }
)

#' Input and output statistics facets
#'
#' @param row_count The optional number of rows read or written.
#' @param size The optional number of bytes read or written.
#' @param file_count The optional number of files read or written.
#' @param producer A URI identifying the facet producer.
#'
#' @return A typed input- or output-dataset facet S7 object.
#' @name io_statistics_facets
NULL

#' @rdname io_statistics_facets
#' @export
InputStatisticsInputDatasetFacet <- S7::new_class(
  "InputStatisticsInputDatasetFacet",
  package = "openlineage",
  parent = .InputDatasetFacet,
  properties = list(
    row_count = .ol_optional_integer_property("row_count"),
    size = .ol_optional_integer_property("size"),
    file_count = .ol_optional_integer_property("file_count")
  ),
  constructor = function(
    row_count = NULL,
    size = NULL,
    file_count = NULL,
    producer = OPENLINEAGE_PRODUCER
  ) {
    S7::new_object(
      .InputDatasetFacet(producer, .SCHEMA_INPUT_STATISTICS),
      row_count = row_count,
      size = size,
      file_count = file_count
    )
  }
)

#' @rdname io_statistics_facets
#' @export
OutputStatisticsOutputDatasetFacet <- S7::new_class(
  "OutputStatisticsOutputDatasetFacet",
  package = "openlineage",
  parent = .OutputDatasetFacet,
  properties = list(
    row_count = .ol_optional_integer_property("row_count"),
    size = .ol_optional_integer_property("size"),
    file_count = .ol_optional_integer_property("file_count")
  ),
  constructor = function(
    row_count = NULL,
    size = NULL,
    file_count = NULL,
    producer = OPENLINEAGE_PRODUCER
  ) {
    S7::new_object(
      .OutputDatasetFacet(producer, .SCHEMA_OUTPUT_STATISTICS),
      row_count = row_count,
      size = size,
      file_count = file_count
    )
  }
)

.OpenLineageTag <- S7::new_class(
  "OpenLineageTag",
  package = "openlineage",
  properties = list(
    key = .ol_string_property("key"),
    value = .ol_string_property("value"),
    source = .ol_optional_string_property("source"),
    field = .ol_optional_string_property("field")
  ),
  constructor = function(key, value, source = NULL, field = NULL) {
    S7::new_object(
      S7::S7_object(),
      key = key,
      value = value,
      source = source,
      field = field
    )
  }
)

#' Create an OpenLineage tag
#'
#' @param key The tag key.
#' @param value The tag value.
#' @param source An optional tag source.
#' @param field An optional dataset field to which the tag applies.
#'
#' @return A tag record for a typed tags facet.
#' @export
#'
#' @examples
#' ol_tag("environment", "production", source = "USER")
ol_tag <- function(key, value, source = NULL, field = NULL) {
  .OpenLineageTag(key, value, source, field)
}

.ol_validate_tags <- function(tags, allow_field, call = parent.frame()) {
  tags <- .ol_record_array(tags, .OpenLineageTag, "tags", call = call)
  if (
    !allow_field &&
      any(vapply(tags, \(tag) !is.null(S7::prop(tag, "field")), logical(1)))
  ) {
    .ol_abort(
      "`field` is supported only by `TagsDatasetFacet`.",
      class = "openlineage_validation_error",
      call = call
    )
  }
  tags
}

#' Typed tags facets
#'
#' @param tags An unnamed list created with `ol_tag()`.
#' @param producer A URI identifying the facet producer.
#' @param deleted Whether a job or dataset facet is being deleted.
#'
#' @return A typed tags facet S7 object.
#' @name tags_facets
NULL

#' @rdname tags_facets
#' @export
TagsJobFacet <- S7::new_class(
  "TagsJobFacet",
  package = "openlineage",
  parent = .JobFacet,
  properties = list(tags = .ol_tags_property),
  constructor = function(
    tags = list(),
    producer = OPENLINEAGE_PRODUCER,
    deleted = NULL
  ) {
    S7::new_object(
      .JobFacet(producer, .SCHEMA_TAGS_JOB, deleted),
      tags = .ol_validate_tags(tags, FALSE, call = parent.frame())
    )
  }
)

#' @rdname tags_facets
#' @export
TagsRunFacet <- S7::new_class(
  "TagsRunFacet",
  package = "openlineage",
  parent = .RunFacet,
  properties = list(tags = .ol_tags_property),
  constructor = function(tags = list(), producer = OPENLINEAGE_PRODUCER) {
    S7::new_object(
      .RunFacet(producer, .SCHEMA_TAGS_RUN),
      tags = .ol_validate_tags(tags, FALSE, call = parent.frame())
    )
  }
)

#' @rdname tags_facets
#' @export
TagsDatasetFacet <- S7::new_class(
  "TagsDatasetFacet",
  package = "openlineage",
  parent = .DatasetFacet,
  properties = list(tags = .ol_tags_property),
  constructor = function(
    tags = list(),
    producer = OPENLINEAGE_PRODUCER,
    deleted = NULL
  ) {
    S7::new_object(
      .DatasetFacet(producer, .SCHEMA_TAGS_DATASET, deleted),
      tags = .ol_validate_tags(tags, TRUE, call = parent.frame())
    )
  }
)

.ol_facet_wire_maps <- list(
  NominalTimeRunFacet = c(
    nominal_start_time = "nominalStartTime",
    nominal_end_time = "nominalEndTime"
  ),
  ParentRunFacet = c(run = "run", job = "job", root = "root"),
  ErrorMessageRunFacet = c(
    message = "message",
    programming_language = "programmingLanguage",
    stack_trace = "stackTrace"
  ),
  ProcessingEngineRunFacet = c(
    version = "version",
    name = "name",
    openlineage_adapter_version = "openlineageAdapterVersion"
  ),
  SchemaDatasetFacet = c(fields = "fields"),
  DatasourceDatasetFacet = c(name = "name", uri = "uri"),
  SQLJobFacet = c(query = "query", dialect = "dialect"),
  SourceCodeLocationJobFacet = c(
    type = "type",
    url = "url",
    repo_url = "repoUrl",
    path = "path",
    version = "version",
    tag = "tag",
    branch = "branch",
    pull_request_number = "pullRequestNumber"
  ),
  JobTypeJobFacet = c(
    processing_type = "processingType",
    integration = "integration",
    job_type = "jobType",
    emission_pattern = "emissionPattern"
  ),
  InputStatisticsInputDatasetFacet = c(
    row_count = "rowCount",
    size = "size",
    file_count = "fileCount"
  ),
  OutputStatisticsOutputDatasetFacet = c(
    row_count = "rowCount",
    size = "size",
    file_count = "fileCount"
  ),
  TagsJobFacet = c(tags = "tags"),
  TagsRunFacet = c(tags = "tags"),
  TagsDatasetFacet = c(tags = "tags")
)

.ol_record_wire_maps <- list(
  SchemaField = c(
    fields = "fields",
    name = "name",
    ordinal_position = "ordinal_position",
    type = "type",
    description = "description"
  ),
  EmissionPattern = c(
    event_trigger = "eventTrigger",
    event_content_mode = "eventContentMode",
    window_duration = "windowDuration"
  ),
  OpenLineageTag = c(
    field = "field",
    key = "key",
    source = "source",
    value = "value"
  )
)
