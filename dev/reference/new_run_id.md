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
#> [1] "8e91f2d2-188a-423d-8fef-ed08cd86178f"
```
