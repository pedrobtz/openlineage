# Convert an OpenLineage value to its wire representation

Recursively converts OpenLineage S7 models to named R lists. Protocol
field names are applied here, `RunState` values are unwrapped, and
`NULL` properties are omitted. Object key order is deterministic; array
order is preserved.

## Usage

``` r
as_openlineage_list(x)
```

## Arguments

- x:

  An OpenLineage model or supported nested value.

## Value

A named list for a model, or the corresponding wire value for a nested
value.

## Examples

``` r
run <- Run("019c0000-0000-7000-8000-000000000001")
as_openlineage_list(run)
#> $facets
#> named list()
#> 
#> $runId
#> [1] "019c0000-0000-7000-8000-000000000001"
#> 
```
