# OpenLineage job

Identifies a job within a producer-defined namespace.

## Usage

``` r
Job(namespace, name, facets = list())
```

## Arguments

- namespace:

  A non-empty namespace string.

- name:

  A non-empty job name.

- facets:

  A named list of job facets, or `NULL` to omit the field.

## Value

A `Job` S7 object.

## Examples

``` r
Job("example-scheduler", "daily-report")
#> <openlineage::Job>
#>  @ namespace: chr "example-scheduler"
#>  @ name     : chr "daily-report"
#>  @ facets   : Named list()
```
