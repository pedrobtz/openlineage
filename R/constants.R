#' OpenLineage protocol constants
#'
#' Constants used by `openlineage` when constructing OpenLineage events.
#' `OPENLINEAGE_SCHEMA_URL` identifies the schema document, while
#' `OPENLINEAGE_RUN_EVENT_SCHEMA_URL` identifies its `RunEvent` definition.
#'
#' @format Character scalars.
#' @name openlineage_constants
#'
#' @examples
#' OPENLINEAGE_SCHEMA_VERSION
#' OPENLINEAGE_RUN_EVENT_SCHEMA_URL
NULL

#' @rdname openlineage_constants
#' @export
OPENLINEAGE_SCHEMA_VERSION <- "2.0.2"

#' @rdname openlineage_constants
#' @export
OPENLINEAGE_SCHEMA_URL <- paste0(
  "https://openlineage.io/spec/",
  gsub("\\.", "-", OPENLINEAGE_SCHEMA_VERSION),
  "/OpenLineage.json"
)

#' @rdname openlineage_constants
#' @export
OPENLINEAGE_RUN_EVENT_SCHEMA_URL <- paste0(
  OPENLINEAGE_SCHEMA_URL,
  "#/$defs/RunEvent"
)

#' @rdname openlineage_constants
#' @export
OPENLINEAGE_PRODUCER <- "https://github.com/pedrobtz/openlineage"
