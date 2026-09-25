# Input and output statistics facets

Input and output statistics facets

## Usage

``` r
InputStatisticsInputDatasetFacet(
  row_count = NULL,
  size = NULL,
  file_count = NULL,
  producer = OPENLINEAGE_PRODUCER
)

OutputStatisticsOutputDatasetFacet(
  row_count = NULL,
  size = NULL,
  file_count = NULL,
  producer = OPENLINEAGE_PRODUCER
)
```

## Arguments

- row_count:

  The optional number of rows read or written.

- size:

  The optional number of bytes read or written.

- file_count:

  The optional number of files read or written.

- producer:

  A URI identifying the facet producer.

## Value

A typed input- or output-dataset facet S7 object.

## Examples

``` r
InputStatisticsInputDatasetFacet(row_count = 100L)
#> <openlineage::InputStatisticsInputDatasetFacet>
#>  @ producer  : chr "https://github.com/pedrobtz/openlineage"
#>  @ schema_url: chr "https://openlineage.io/spec/facets/1-0-0/InputStatisticsInputDatasetFacet.json#/$defs/InputStatisticsInputDatasetFacet"
#>  @ deleted   : NULL
#>  @ row_count : int 100
#>  @ size      : NULL
#>  @ file_count: NULL
OutputStatisticsOutputDatasetFacet(row_count = 100L, size = 2048L)
#> <openlineage::OutputStatisticsOutputDatasetFacet>
#>  @ producer  : chr "https://github.com/pedrobtz/openlineage"
#>  @ schema_url: chr "https://openlineage.io/spec/facets/1-0-2/OutputStatisticsOutputDatasetFacet.json#/$defs/OutputStatisticsOutputDatasetFacet"
#>  @ deleted   : NULL
#>  @ row_count : int 100
#>  @ size      : int 2048
#>  @ file_count: NULL
```
