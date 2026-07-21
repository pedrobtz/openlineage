#' Generate a run identifier
#'
#' Generates a random UUID suitable for the `runId` field of an OpenLineage
#' run. The UUID version is an implementation detail and may change.
#'
#' @return A single UUID string.
#' @export
#'
#' @examples
#' new_run_id()
new_run_id <- function() {
  uuid::UUIDgenerate(use.time = FALSE)
}
