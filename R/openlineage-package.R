#' Create and Emit OpenLineage Events
#'
#' Build validated OpenLineage 2.0.2 run events, serialize them to the protocol
#' wire format, and emit them through local or synchronous HTTP transports.
#'
#' @section Main workflow:
#' Create a [Run], [Job], and optional input/output datasets, then combine them
#' in a [RunEvent]. An [OpenLineageClient] emits the event through an injected
#' transport or through HTTP configured by constructor arguments or environment
#' variables.
#'
#' @section Facets and extensions:
#' Typed facet constructors cover common metadata. Use [ol_facet] to attach a
#' facet schema that does not yet have a typed R constructor.
#'
#' @seealso [OpenLineageClient], [RunEvent], [local_transports],
#'   [HttpTransport]
#' @importFrom R6 R6Class
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL
