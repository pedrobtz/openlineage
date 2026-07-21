# Create an OpenLineage tag

Create an OpenLineage tag

## Usage

``` r
ol_tag(key, value, source = NULL, field = NULL)
```

## Arguments

- key:

  The tag key.

- value:

  The tag value.

- source:

  An optional tag source.

- field:

  An optional dataset field to which the tag applies.

## Value

A tag record for a typed tags facet.

## Examples

``` r
ol_tag("environment", "production", source = "USER")
#> <openlineage::OpenLineageTag>
#>  @ key   : chr "environment"
#>  @ value : chr "production"
#>  @ source: chr "USER"
#>  @ field : NULL
```
