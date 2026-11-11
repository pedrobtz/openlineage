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
#> [1] "f1c36fcc-c9ff-4730-8a32-1884796fc87c"
```
