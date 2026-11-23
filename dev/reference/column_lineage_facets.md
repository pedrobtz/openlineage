# Column-lineage dataset facet

Constructors for column-level lineage: which input columns each output
column of a dataset was computed from, and which input columns affect
the whole dataset.

## Usage

``` r
ColumnLineageTransformation(
  type,
  subtype = NULL,
  description = NULL,
  masking = NULL
)

ColumnLineageInputField(namespace, name, field, transformations = list())

ColumnLineageDatasetFacet(
  fields = list(),
  dataset = list(),
  producer = OPENLINEAGE_PRODUCER,
  deleted = NULL
)
```

## Arguments

- type:

  The transformation type, such as `"DIRECT"` or `"INDIRECT"`.

- subtype:

  An optional transformation subtype, such as `"IDENTITY"`. May be
  empty, as the specification allows.

- description:

  An optional description of the transformation. May be empty, as the
  specification allows.

- masking:

  An optional flag: whether the transformation masks the data.

- namespace, name:

  The input dataset namespace and name.

- field:

  The input column name.

- transformations:

  An unnamed list of `ColumnLineageTransformation` objects.

- fields:

  A named list keyed by output column name. Each element is an unnamed
  list of `ColumnLineageInputField` objects.

- dataset:

  An unnamed list of `ColumnLineageInputField` objects that affect the
  whole dataset, such as filter, sort, grouping or join keys.

- producer:

  A URI identifying the facet producer.

- deleted:

  Whether this facet deletes a previously emitted facet.

## Value

A column-lineage facet, input-field or transformation S7 object.

## Details

`fields` is keyed by output column name. Each element is an unnamed list
of `ColumnLineageInputField` objects, possibly empty, and serializes as
`{"inputFields": [...]}`. The facet is usually attached to an output
dataset under the key `columnLineage`.

The specification describes `type` as `"DIRECT"` or `"INDIRECT"` and
leaves `subtype` free. OpenLineage documents `"IDENTITY"`,
`"TRANSFORMATION"` and `"AGGREGATION"` for direct transformations and
`"JOIN"`, `"GROUP_BY"`, `"FILTER"`, `"SORT"`, `"WINDOW"` and
`"CONDITIONAL"` for indirect ones. Both are typed as free strings in the
JSON schema, so other values are accepted, as in the Python client. The
deprecated per-column `transformationDescription` and
`transformationType` properties are not supported.

## See also

<https://openlineage.io/spec/facets/1-2-0/ColumnLineageDatasetFacet.json>

## Examples

``` r
direct <- ColumnLineageTransformation("DIRECT", "IDENTITY", masking = FALSE)
filter <- ColumnLineageTransformation("INDIRECT", "FILTER")
customers <- function(field, transformation) {
  ColumnLineageInputField(
    "postgres://warehouse",
    "public.customers",
    field,
    list(transformation)
  )
}
facet <- ColumnLineageDatasetFacet(
  fields = list(customer_name = list(customers("name", direct))),
  dataset = list(customers("active", filter))
)
OutputDataset(
  "postgres://warehouse",
  "analytics.customers",
  facets = list(columnLineage = facet)
)
#> <openlineage::OutputDataset>
#>  @ namespace    : chr "postgres://warehouse"
#>  @ name         : chr "analytics.customers"
#>  @ facets       : List of 1
#>  .. $ columnLineage: <openlineage::ColumnLineageDatasetFacet>
#>  ..  ..@ producer  : chr "https://github.com/pedrobtz/openlineage"
#>  ..  ..@ schema_url: chr "https://openlineage.io/spec/facets/1-2-0/ColumnLineageDatasetFacet.json#/$defs/ColumnLineageDatasetFacet"
#>  ..  ..@ deleted   : NULL
#>  ..  ..@ fields    : List of 1
#>  .. .. .. $ customer_name:List of 1
#>  .. .. ..  ..$ : <openlineage::ColumnLineageInputField>
#>  .. .. ..  .. ..@ namespace      : chr "postgres://warehouse"
#>  .. .. ..  .. ..@ name           : chr "public.customers"
#>  .. .. ..  .. ..@ field          : chr "name"
#>  .. .. ..  .. ..@ transformations: List of 1
#>  .. .. .. .. .. .. $ : <openlineage::ColumnLineageTransformation>
#>  .. .. .. .. .. ..  ..@ type       : chr "DIRECT"
#>  .. .. .. .. .. ..  ..@ subtype    : chr "IDENTITY"
#>  .. .. .. .. .. ..  ..@ description: NULL
#>  .. .. .. .. .. ..  ..@ masking    : logi FALSE
#>  ..  ..@ dataset   : List of 1
#>  .. .. .. $ : <openlineage::ColumnLineageInputField>
#>  .. .. ..  ..@ namespace      : chr "postgres://warehouse"
#>  .. .. ..  ..@ name           : chr "public.customers"
#>  .. .. ..  ..@ field          : chr "active"
#>  .. .. ..  ..@ transformations: List of 1
#>  .. .. .. .. .. $ : <openlineage::ColumnLineageTransformation>
#>  .. .. .. .. ..  ..@ type       : chr "INDIRECT"
#>  .. .. .. .. ..  ..@ subtype    : chr "FILTER"
#>  .. .. .. .. ..  ..@ description: NULL
#>  .. .. .. .. ..  ..@ masking    : NULL
#>  @ output_facets: Named list()
```
