# Typed dataset facets

Constructors for dataset-level schema, data-source, and tag metadata.

## Usage

``` r
SchemaField(
  name,
  type = NULL,
  description = NULL,
  ordinal_position = NULL,
  fields = list()
)

SchemaDatasetFacet(
  fields = list(),
  producer = OPENLINEAGE_PRODUCER,
  deleted = NULL
)

DatasourceDatasetFacet(
  name = NULL,
  uri = NULL,
  producer = OPENLINEAGE_PRODUCER,
  deleted = NULL
)
```

## Arguments

- name:

  A field or data-source name.

- type:

  An optional field type.

- description:

  An optional field description.

- ordinal_position:

  An optional one-based field position.

- fields:

  For `SchemaDatasetFacet`, an unnamed list of `SchemaField` objects.
  For `SchemaField`, nested fields of the same type.

- producer:

  A URI identifying the facet producer.

- deleted:

  Whether this facet deletes a previously emitted facet.

- uri:

  An optional data-source URI.

## Value

A typed dataset facet or schema-field S7 object.

## Examples

``` r
field <- SchemaField("order_id", "INTEGER", ordinal_position = 1L)
SchemaDatasetFacet(list(field))
#> <openlineage::SchemaDatasetFacet>
#>  @ producer  : chr "https://github.com/pedrobtz/openlineage"
#>  @ schema_url: chr "https://openlineage.io/spec/facets/1-2-0/SchemaDatasetFacet.json#/$defs/SchemaDatasetFacet"
#>  @ deleted   : NULL
#>  @ fields    :List of 1
#>  .. $ : <openlineage::SchemaField>
#>  ..  ..@ name            : chr "order_id"
#>  ..  ..@ type            : chr "INTEGER"
#>  ..  ..@ description     : NULL
#>  ..  ..@ ordinal_position: int 1
#>  ..  ..@ fields          : list()
DatasourceDatasetFacet("warehouse", "postgres://warehouse")
#> <openlineage::DatasourceDatasetFacet>
#>  @ producer  : chr "https://github.com/pedrobtz/openlineage"
#>  @ schema_url: chr "https://openlineage.io/spec/facets/1-0-1/DatasourceDatasetFacet.json#/$defs/DatasourceDatasetFacet"
#>  @ deleted   : NULL
#>  @ name      : chr "warehouse"
#>  @ uri       : chr "postgres://warehouse"
```
