# OpenLineage run

Identifies one execution of an OpenLineage job.

## Usage

``` r
Run(run_id, facets = list())
```

## Arguments

- run_id:

  A valid UUID string.

- facets:

  A named list of run facets, or `NULL` to omit the field.

## Value

A `Run` S7 object.

## Examples

``` r
Run(new_run_id())
#> <openlineage::Run>
#>  @ run_id: chr "8ff9e3c2-89f6-4331-9eac-29e2d4bf12f7"
#>  @ facets: Named list()
```
