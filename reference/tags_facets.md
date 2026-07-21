# Typed tags facets

Typed tags facets

## Usage

``` r
TagsJobFacet(tags = list(), producer = OPENLINEAGE_PRODUCER, deleted = NULL)

TagsRunFacet(tags = list(), producer = OPENLINEAGE_PRODUCER)

TagsDatasetFacet(
  tags = list(),
  producer = OPENLINEAGE_PRODUCER,
  deleted = NULL
)
```

## Arguments

- tags:

  An unnamed list created with
  [`ol_tag()`](https://pedrobtz.github.io/openlineage/reference/ol_tag.md).

- producer:

  A URI identifying the facet producer.

- deleted:

  Whether a job or dataset facet is being deleted.

## Value

A typed tags facet S7 object.

## Examples

``` r
tag <- ol_tag("environment", "production")
TagsJobFacet(list(tag))
#> <openlineage::TagsJobFacet>
#>  @ producer  : chr "https://github.com/pedrobtz/openlineage"
#>  @ schema_url: chr "https://openlineage.io/spec/facets/1-0-0/TagsJobFacet.json#/$defs/TagsJobFacet"
#>  @ deleted   : NULL
#>  @ tags      :List of 1
#>  .. $ : <openlineage::OpenLineageTag>
#>  ..  ..@ key   : chr "environment"
#>  ..  ..@ value : chr "production"
#>  ..  ..@ source: NULL
#>  ..  ..@ field : NULL
TagsRunFacet(list(tag))
#> <openlineage::TagsRunFacet>
#>  @ producer  : chr "https://github.com/pedrobtz/openlineage"
#>  @ schema_url: chr "https://openlineage.io/spec/facets/1-0-0/TagsRunFacet.json#/$defs/TagsRunFacet"
#>  @ deleted   : NULL
#>  @ tags      :List of 1
#>  .. $ : <openlineage::OpenLineageTag>
#>  ..  ..@ key   : chr "environment"
#>  ..  ..@ value : chr "production"
#>  ..  ..@ source: NULL
#>  ..  ..@ field : NULL
TagsDatasetFacet(list(
  ol_tag("sensitivity", "restricted", field = "customer_id")
))
#> <openlineage::TagsDatasetFacet>
#>  @ producer  : chr "https://github.com/pedrobtz/openlineage"
#>  @ schema_url: chr "https://openlineage.io/spec/facets/1-0-0/TagsDatasetFacet.json#/$defs/TagsDatasetFacet"
#>  @ deleted   : NULL
#>  @ tags      :List of 1
#>  .. $ : <openlineage::OpenLineageTag>
#>  ..  ..@ key   : chr "sensitivity"
#>  ..  ..@ value : chr "restricted"
#>  ..  ..@ source: NULL
#>  ..  ..@ field : chr "customer_id"
```
