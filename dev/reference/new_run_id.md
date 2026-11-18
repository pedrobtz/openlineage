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
#> [1] "21d6beb9-709c-44e8-94b5-d30500c174a8"
```
