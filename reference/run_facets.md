# Typed run facets

Constructors for commonly used OpenLineage run facets.

## Usage

``` r
NominalTimeRunFacet(
  nominal_start_time,
  nominal_end_time = NULL,
  producer = OPENLINEAGE_PRODUCER
)

ParentRunFacet(run, job, root = NULL, producer = OPENLINEAGE_PRODUCER)

ErrorMessageRunFacet(
  message,
  programming_language,
  stack_trace = NULL,
  producer = OPENLINEAGE_PRODUCER
)

ProcessingEngineRunFacet(
  version,
  name = NULL,
  openlineage_adapter_version = NULL,
  producer = OPENLINEAGE_PRODUCER
)
```

## Arguments

- nominal_start_time:

  The nominal start as an RFC 3339 date-time.

- nominal_end_time:

  An optional nominal end date-time.

- producer:

  A URI identifying the facet producer.

- run:

  The parent `Run`.

- job:

  The parent `Job`.

- root:

  Optional `list(run = Run(...), job = Job(...))` for the root.

- message:

  A human-readable error message.

- programming_language:

  The language that produced the error.

- stack_trace:

  An optional stack trace.

- version:

  The processing engine version.

- name:

  The optional processing engine name.

- openlineage_adapter_version:

  The optional adapter version.

## Value

A typed run facet S7 object.

## Examples

``` r
NominalTimeRunFacet("2026-01-02T03:00:00.000Z")
#> <openlineage::NominalTimeRunFacet>
#>  @ producer          : chr "https://github.com/pedrobtz/openlineage"
#>  @ schema_url        : chr "https://openlineage.io/spec/facets/1-0-1/NominalTimeRunFacet.json#/$defs/NominalTimeRunFacet"
#>  @ deleted           : NULL
#>  @ nominal_start_time: chr "2026-01-02T03:00:00.000Z"
#>  @ nominal_end_time  : NULL
parent_run <- Run(new_run_id())
parent_job <- Job("example", "parent")
ParentRunFacet(parent_run, parent_job)
#> <openlineage::ParentRunFacet>
#>  @ producer  : chr "https://github.com/pedrobtz/openlineage"
#>  @ schema_url: chr "https://openlineage.io/spec/facets/1-2-0/ParentRunFacet.json#/$defs/ParentRunFacet"
#>  @ deleted   : NULL
#>  @ run       : <openlineage::Run>
#>  .. @ run_id: chr "64802f9d-4a66-4317-bcdb-ba2af13cdc96"
#>  .. @ facets: Named list()
#>  @ job       : <openlineage::Job>
#>  .. @ namespace: chr "example"
#>  .. @ name     : chr "parent"
#>  .. @ facets   : Named list()
#>  @ root      : NULL
ErrorMessageRunFacet("Query failed", "R")
#> <openlineage::ErrorMessageRunFacet>
#>  @ producer            : chr "https://github.com/pedrobtz/openlineage"
#>  @ schema_url          : chr "https://openlineage.io/spec/facets/1-0-1/ErrorMessageRunFacet.json#/$defs/ErrorMessageRunFacet"
#>  @ deleted             : NULL
#>  @ message             : chr "Query failed"
#>  @ programming_language: chr "R"
#>  @ stack_trace         : NULL
ProcessingEngineRunFacet("4.6.0", name = "R")
#> <openlineage::ProcessingEngineRunFacet>
#>  @ producer                   : chr "https://github.com/pedrobtz/openlineage"
#>  @ schema_url                 : chr "https://openlineage.io/spec/facets/1-1-1/ProcessingEngineRunFacet.json#/$defs/ProcessingEngineRunFacet"
#>  @ deleted                    : NULL
#>  @ version                    : chr "4.6.0"
#>  @ name                       : chr "R"
#>  @ openlineage_adapter_version: NULL
```
