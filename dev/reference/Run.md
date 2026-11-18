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
#>  @ run_id: chr "c1065763-beb5-4a1d-b14d-e5f49918aab7"
#>  @ facets: Named list()
```
