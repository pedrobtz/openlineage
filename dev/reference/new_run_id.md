# Generate a run identifier

Generates a random UUID suitable for the `runId` field of an OpenLineage
run. The UUID version is an implementation detail and may change.

## Usage

``` r
new_run_id()
```

## Value

A single UUID string.

## Examples

``` r
new_run_id()
#> [1] "77b722aa-e63d-4178-88f6-8caf86358706"
```
