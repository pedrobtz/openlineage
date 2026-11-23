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
#>  @ run_id: chr "3db84dcf-9c97-4ce2-9546-7562df05e94d"
#>  @ facets: Named list()
```
