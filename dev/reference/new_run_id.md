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
#> [1] "db0cdea5-8f29-4222-b80a-67a32be4c0c0"
```
