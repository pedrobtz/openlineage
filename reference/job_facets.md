# Typed job facets

Constructors for SQL, source location, and job-type metadata.

## Usage

``` r
SQLJobFacet(
  query,
  dialect = NULL,
  producer = OPENLINEAGE_PRODUCER,
  deleted = NULL
)

SourceCodeLocationJobFacet(
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
)

EmissionPattern(event_trigger, event_content_mode, window_duration = NULL)

JobTypeJobFacet(
  processing_type,
  integration,
  job_type = NULL,
  emission_pattern = NULL,
  producer = OPENLINEAGE_PRODUCER,
  deleted = NULL
)
```

## Arguments

- query:

  The SQL query text.

- dialect:

  An optional SQL dialect.

- producer:

  A URI identifying the facet producer.

- deleted:

  Whether this facet deletes a previously emitted facet.

- type:

  The source-control system type.

- url:

  The full source-code URL.

- repo_url, path, version, tag, branch, pull_request_number:

  Optional source location details.

- event_trigger:

  When events are emitted.

- event_content_mode:

  Whether events accumulate or contain snapshots.

- window_duration:

  An optional positive duration in seconds.

- processing_type:

  The processing type, such as `"BATCH"`.

- integration:

  The integration name, such as `"DBT"`.

- job_type:

  An optional integration-specific job type.

- emission_pattern:

  An optional `EmissionPattern`.

## Value

A typed job facet or emission-pattern S7 object.

## Examples

``` r
SQLJobFacet("SELECT 1", dialect = "ansi")
#> <openlineage::SQLJobFacet>
#>  @ producer  : chr "https://github.com/pedrobtz/openlineage"
#>  @ schema_url: chr "https://openlineage.io/spec/facets/1-1-0/SQLJobFacet.json#/$defs/SQLJobFacet"
#>  @ deleted   : NULL
#>  @ query     : chr "SELECT 1"
#>  @ dialect   : chr "ansi"
SourceCodeLocationJobFacet(
  "git",
  "https://github.com/example/project/blob/main/job.R"
)
#> <openlineage::SourceCodeLocationJobFacet>
#>  @ producer           : chr "https://github.com/pedrobtz/openlineage"
#>  @ schema_url         : chr "https://openlineage.io/spec/facets/1-1-0/SourceCodeLocationJobFacet.json#/$defs/SourceCodeLocationJobFacet"
#>  @ deleted            : NULL
#>  @ type               : chr "git"
#>  @ url                : chr "https://github.com/example/project/blob/main/job.R"
#>  @ repo_url           : NULL
#>  @ path               : NULL
#>  @ version            : NULL
#>  @ tag                : NULL
#>  @ branch             : NULL
#>  @ pull_request_number: NULL
pattern <- EmissionPattern("EVENT_BASED", "COMPLETE_SNAPSHOT")
JobTypeJobFacet("BATCH", "R", emission_pattern = pattern)
#> <openlineage::JobTypeJobFacet>
#>  @ producer        : chr "https://github.com/pedrobtz/openlineage"
#>  @ schema_url      : chr "https://openlineage.io/spec/facets/2-0-4/JobTypeJobFacet.json#/$defs/JobTypeJobFacet"
#>  @ deleted         : NULL
#>  @ processing_type : chr "BATCH"
#>  @ integration     : chr "R"
#>  @ job_type        : NULL
#>  @ emission_pattern: <openlineage::EmissionPattern>
#>  .. @ event_trigger     : chr "EVENT_BASED"
#>  .. @ event_content_mode: chr "COMPLETE_SNAPSHOT"
#>  .. @ window_duration   : NULL
```
