# OpenLineage datasets

`Dataset` identifies a dataset. `InputDataset` and `OutputDataset` add
lifecycle-specific facet maps and are the only dataset types accepted by
a `RunEvent`.

## Usage

``` r
Dataset(namespace, name, facets = list())

InputDataset(namespace, name, facets = list(), input_facets = list())

OutputDataset(namespace, name, facets = list(), output_facets = list())
```

## Arguments

- namespace:

  A non-empty namespace string.

- name:

  A non-empty dataset name.

- facets:

  A named list of dataset facets, or `NULL` to omit the field.

- input_facets:

  A named list of input facets, or `NULL` to omit it.

- output_facets:

  A named list of output facets, or `NULL` to omit it.

## Value

A `Dataset`, `InputDataset`, or `OutputDataset` S7 object.

## Examples

``` r
Dataset("postgres://warehouse", "analytics.orders")
#> <openlineage::Dataset>
#>  @ namespace: chr "postgres://warehouse"
#>  @ name     : chr "analytics.orders"
#>  @ facets   : Named list()
InputDataset("postgres://warehouse", "raw.orders")
#> <openlineage::InputDataset>
#>  @ namespace   : chr "postgres://warehouse"
#>  @ name        : chr "raw.orders"
#>  @ facets      : Named list()
#>  @ input_facets: Named list()
OutputDataset("postgres://warehouse", "analytics.orders")
#> <openlineage::OutputDataset>
#>  @ namespace    : chr "postgres://warehouse"
#>  @ name         : chr "analytics.orders"
#>  @ facets       : Named list()
#>  @ output_facets: Named list()
```
