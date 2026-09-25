# OpenLineage run state

A validated lifecycle state for an OpenLineage run.

## Usage

``` r
RunState(value)
```

## Arguments

- value:

  One of `"START"`, `"RUNNING"`, `"COMPLETE"`, `"ABORT"`, `"FAIL"`, or
  `"OTHER"`.

## Value

A `RunState` S7 object.

## Examples

``` r
RunState("START")
#> <openlineage::RunState> chr "START"
```
