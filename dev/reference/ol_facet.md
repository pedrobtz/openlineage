# Create a generic OpenLineage facet

Creates a facet for extensions or facet schemas without a typed
constructor. Names supplied through `...` are preserved exactly at the
JSON boundary.

## Usage

``` r
ol_facet(..., schema_url, producer = OPENLINEAGE_PRODUCER, deleted = NULL)
```

## Arguments

- ...:

  Named facet fields using their OpenLineage wire names, and the schema
  URL as the one unnamed argument when `schema_url` is not named.

- schema_url:

  The URI of the facet's JSON Schema definition.

- producer:

  A URI identifying the facet producer.

- deleted:

  Whether this facet deletes a previously emitted job or dataset facet.
  Use only where the target schema supports `_deleted`.

## Value

A generic OpenLineage facet accepted in any facet map.

## Details

The schema URL is either named `schema_url` or given as the one unnamed
argument, usually the first. `schema_url`, `producer` and `deleted` come
after `...`, so they are matched only by their full names: a field such
as `schema` or `prod` is a field, never a partial match for an argument.

Field values map to JSON as follows:

- A length-1 vector is a JSON scalar. Wrap it in
  [`I()`](https://rdrr.io/r/base/AsIs.html) (`I("only")`) or a
  [`list()`](https://rdrr.io/r/base/list.html) to write a one-element
  array. Longer vectors are arrays.

- A named list is an object and an unnamed list is an array. An empty
  unnamed [`list()`](https://rdrr.io/r/base/list.html) is `[]`; use
  `setNames(list(), character())` for
  [`{}`](https://rdrr.io/r/base/Paren.html).

- `NULL` fields are omitted, so a JSON `null` cannot be written.

- Integer-valued numbers up to 2^53 are written exactly; other numbers
  with the fewest digits that read back as the same double.

- A `POSIXct` value is written as an event time
  ([`new_event_time()`](https://pedrobtz.github.io/openlineage/dev/reference/new_event_time.md)),
  a `Date` as `YYYY-MM-DD` and a factor as its labels.

- Missing values, `NaN`, infinite numbers, complex and raw vectors,
  named atomic vectors, lists with repeated or empty names, text that is
  not valid UTF-8 and other classed objects raise an
  `openlineage_validation_error` when the facet is serialized.

## Examples

``` r
facet <- ol_facet(
  "https://example.com/CustomRunFacet.json",
  customValue = "example",
  tags = I("nightly")
)
Run(new_run_id(), facets = list(custom = facet))
#> <openlineage::Run>
#>  @ run_id: chr "ce229ca4-6610-48d6-93ae-14b614ce8a41"
#>  @ facets: List of 1
#>  .. $ custom: <openlineage::GenericFacet>
#>  ..  ..@ producer  : chr "https://github.com/pedrobtz/openlineage"
#>  ..  ..@ schema_url: chr "https://example.com/CustomRunFacet.json"
#>  ..  ..@ deleted   : NULL
#>  ..  ..@ fields    : List of 2
#>  .. .. .. $ customValue: chr "example"
#>  .. .. .. $ tags       : 'AsIs' chr "nightly"
```
