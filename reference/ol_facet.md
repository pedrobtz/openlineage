# Create a generic OpenLineage facet

Creates a facet for extensions or facet schemas without a typed
constructor. Names supplied through `...` are preserved exactly at the
JSON boundary.

## Usage

``` r
ol_facet(schema_url, ..., producer = OPENLINEAGE_PRODUCER, deleted = NULL)
```

## Arguments

- schema_url:

  The URI of the facet's JSON Schema definition.

- ...:

  Named facet fields using their OpenLineage wire names.

- producer:

  A URI identifying the facet producer.

- deleted:

  Whether this facet deletes a previously emitted job or dataset facet.
  Use only where the target schema supports `_deleted`.

## Value

A generic OpenLineage facet accepted in any facet map.

## Examples

``` r
facet <- ol_facet(
  "https://example.com/CustomRunFacet.json",
  customValue = "example"
)
Run(new_run_id(), facets = list(custom = facet))
#> <openlineage::Run>
#>  @ run_id: chr "c8b9d183-032f-4504-a6b5-9c57964c3ac3"
#>  @ facets:List of 1
#>  .. $ custom: <openlineage::GenericFacet>
#>  ..  ..@ producer  : chr "https://github.com/pedrobtz/openlineage"
#>  ..  ..@ schema_url: chr "https://example.com/CustomRunFacet.json"
#>  ..  ..@ deleted   : NULL
#>  ..  ..@ fields    :List of 1
#>  .. .. .. $ customValue: chr "example"
```
